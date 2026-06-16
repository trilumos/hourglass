import 'package:flutter/foundation.dart';

import '../domain/focus_phase.dart';
import '../domain/phase_engine.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import 'session_config.dart';
import 'session_plan.dart';
import 'session_state.dart';
import 'ticker.dart';

/// Owns the live session: runs the [SessionPlan]'s focus/rest segments via an
/// injectable [Ticker], tracks elapsed/recorded focus and the focus phase, and
/// finalizes into a [SessionRecord]. UI listens via [ChangeNotifier].
class SessionController extends ChangeNotifier {
  final SessionConfig config;
  final Ticker ticker;
  final DateTime Function() now;

  SessionState _state = SessionState.initial();
  late final DateTime _startedAt;

  SessionController({
    required this.config,
    required this.ticker,
    required this.now,
  });

  SessionState get state => _state;

  SessionPlan get plan => config.plan;

  SessionSegment get currentSegment => plan.segments[_state.segmentIndex];

  Duration get segmentRemaining {
    final r = currentSegment.duration - _state.segmentElapsed;
    return r.isNegative ? Duration.zero : r;
  }

  /// Progress within the current segment, 0..1 (drives the hourglass).
  double get segmentProgress {
    final total = currentSegment.duration.inSeconds;
    if (total <= 0) return 0;
    return (_state.segmentElapsed.inSeconds / total).clamp(0.0, 1.0);
  }

  /// Overall session progress, 0..1.
  double get progress {
    final total = plan.totalDuration.inSeconds;
    if (total <= 0) return 0;
    return (_state.elapsed.inSeconds / total).clamp(0.0, 1.0);
  }

  bool get _endlessSingleFocus => plan.isSingleFocus && config.autoContinue;

  void start() {
    if (_state.status != SessionStatus.idle) return;
    _startedAt = now();
    _set(_state.copyWith(
      status: SessionStatus.running,
      currentKind: plan.segments.first.kind,
    ));
    ticker.start(_onTick);
  }

  FocusPhase _phaseFor(Duration focusDuration, Duration inSegment) =>
      PhaseEngine.forBlock(focusDuration).phaseAt(inSegment);

  void _onTick(Duration delta) {
    // Endless single-focus: never auto-finish; overflow counts as focus.
    if (_endlessSingleFocus) {
      final focusDur = plan.segments.first.duration;
      final elapsed = _state.elapsed + delta;
      _set(_state.copyWith(
        elapsed: elapsed,
        segmentElapsed: elapsed,
        recordedFocus: elapsed,
        phase: _phaseFor(focusDur, elapsed),
        goalReached: _state.goalReached || elapsed >= focusDur,
      ));
      return;
    }

    final segs = plan.segments;
    var remaining = delta;
    var idx = _state.segmentIndex;
    var segElapsed = _state.segmentElapsed;
    var elapsed = _state.elapsed;
    var recorded = _state.recordedFocus;

    while (remaining > Duration.zero) {
      final seg = segs[idx];
      final room = seg.duration - segElapsed;
      if (remaining < room) {
        segElapsed += remaining;
        elapsed += remaining;
        if (seg.isFocus) recorded += remaining;
        remaining = Duration.zero;
      } else {
        // Segment completes; carry the rest into the next.
        elapsed += room;
        if (seg.isFocus) recorded += room;
        remaining -= room;
        if (idx == segs.length - 1) {
          ticker.stop();
          // A Flow Block (single focus) pauses at a "completed" decision point
          // so the user can collect it or keep going. Everything else finishes.
          final completable =
              plan.isSingleFocus && config.mode == SessionMode.flowBlock;
          _set(_state.copyWith(
            status: completable
                ? SessionStatus.completed
                : SessionStatus.finished,
            segmentIndex: idx,
            currentKind: seg.kind,
            segmentElapsed: seg.duration,
            elapsed: elapsed,
            recordedFocus: recorded,
            phase: seg.isFocus
                ? _phaseFor(seg.duration, seg.duration)
                : _state.phase,
            goalReached: true,
          ));
          return;
        }
        // Tap-to-continue: a break just ended → wait for the user before the
        // next focus block (drop the tiny leftover delta).
        if (!seg.isFocus && !config.autoAdvanceBreaks) {
          ticker.stop();
          final next = segs[idx + 1];
          _set(_state.copyWith(
            status: SessionStatus.awaitingResume,
            segmentIndex: idx + 1,
            currentKind: next.kind,
            segmentElapsed: Duration.zero,
            elapsed: elapsed,
            recordedFocus: recorded,
            phase: _phaseFor(next.duration, Duration.zero),
          ));
          return;
        }
        idx += 1;
        segElapsed = Duration.zero;
      }
    }

    final cur = segs[idx];
    _set(_state.copyWith(
      segmentIndex: idx,
      currentKind: cur.kind,
      segmentElapsed: segElapsed,
      elapsed: elapsed,
      recordedFocus: recorded,
      phase: cur.isFocus ? _phaseFor(cur.duration, segElapsed) : _state.phase,
    ));
  }

  void pause() {
    if (_state.status != SessionStatus.running) return;
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.paused));
  }

  void resume() {
    if (_state.status != SessionStatus.paused) return;
    _set(_state.copyWith(status: SessionStatus.running));
    ticker.start(_onTick);
  }

  /// Start the next focus block after a break (tap-to-continue mode).
  void continueToNext() {
    if (_state.status != SessionStatus.awaitingResume) return;
    _set(_state.copyWith(status: SessionStatus.running));
    ticker.start(_onTick);
  }

  /// Skip the current break — advance straight to the boundary (which either
  /// starts the next block, or parks at the wait point in tap-to-continue mode).
  void skipRest() {
    if (_state.status != SessionStatus.running || !_state.isResting) return;
    _onTick(segmentRemaining);
  }

  /// Extend a completed Flow Block: drain the same block again (the hourglass
  /// refills and flips), accumulating focus. Overflow past the chosen length
  /// rewards the Focus Score. Reaching the length again returns to `completed`.
  void keepGoing() {
    if (_state.status != SessionStatus.completed) return;
    _set(_state.copyWith(
      status: SessionStatus.running,
      segmentElapsed: Duration.zero, // drain from full again
      phase: _phaseFor(currentSegment.duration, Duration.zero),
    ));
    ticker.start(_onTick);
  }

  /// User ends the session (e.g. an endless block, or stopping early).
  void end() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
  }

  /// Session abandoned before the goal (e.g. left the app, protect-the-block).
  void abandon() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
  }

  /// Builds the record to persist. `completed` iff the planned end was reached.
  ///
  /// Recording rule: **Flow Block** records the actual focused length on EVERY
  /// end (completed, given-up, or app-left) if ≥ 2 min — this feeds the Focus
  /// Score. Pomodoro/Custom keep the older rule (only a completed session counts).
  SessionRecord finalize() {
    final completed = _state.goalReached;
    final Duration recorded;
    if (config.mode == SessionMode.flowBlock) {
      recorded = _state.recordedFocus.inSeconds >= 120
          ? _state.recordedFocus
          : Duration.zero;
    } else {
      recorded = completed ? _state.recordedFocus : Duration.zero;
    }
    return SessionRecord(
      id: 0,
      startedAt: _startedAt,
      mode: config.mode,
      intention: config.intention,
      plannedDuration: plan.totalFocus,
      recordedFocus: recorded,
      completed: completed,
      abandoned: !completed,
      autoContinue: config.autoContinue,
      soundscape: config.soundscape,
      skinId: config.skinId,
    );
  }

  void _set(SessionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    ticker.stop();
    super.dispose();
  }
}
