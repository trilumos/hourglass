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

  /// Whether this block runs open-ended (never auto-stops). Seeded from the
  /// config's pre-set toggle, but can be switched on mid-block by the user
  /// ("don't stop" near the end).
  bool _endless = false;
  bool get isEndless => _endless;

  /// Whether breaks auto-advance into the next focus block. Seeded from config,
  /// but changeable live (mid-session quick settings).
  bool _autoAdvanceBreaks = true;
  bool get autoAdvanceBreaks => _autoAdvanceBreaks;
  void setAutoAdvanceBreaks(bool v) {
    _autoAdvanceBreaks = v;
    notifyListeners();
  }

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

  bool get _endlessSingleFocus => plan.isSingleFocus && _endless;

  void start() {
    if (_state.status != SessionStatus.idle) return;
    _endless = config.autoContinue;
    _autoAdvanceBreaks = config.autoAdvanceBreaks;
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
        if (!seg.isFocus && !_autoAdvanceBreaks) {
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

  /// Switch the running block to open-ended ("don't stop") — typically tapped
  /// near the end so the block flows past its length instead of stopping. If the
  /// block already hit its completed decision point, resume it seamlessly.
  void enableEndless() {
    if (!plan.isSingleFocus || _endless) return;
    _endless = true;
    if (_state.status == SessionStatus.completed) {
      _set(_state.copyWith(status: SessionStatus.running));
      ticker.start(_onTick);
    } else {
      notifyListeners();
    }
  }

  /// Turn endless back off before the goal (revert to stopping at the length).
  void disableEndless() {
    if (_endless && _state.status == SessionStatus.running && !_state.goalReached) {
      _endless = false;
      notifyListeners();
    }
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
  /// Recording rule: EVERY mode records the actual focused length on every end
  /// (completed, given-up, or app-left) so it shows in Today's focus and the
  /// session history. Flow Block ignores sub-2-min ends (they never count toward
  /// the Focus Score, which is Flow-Block-only). Pomodoro/Custom record whatever
  /// focus was done — there's no score or penalty, but the time still counts.
  SessionRecord finalize() {
    final completed = _state.goalReached;
    // Record the actual focused time in every mode (for Today + history). The
    // Focus Score (Flow-Block-only) separately ignores sub-2-min blocks.
    final recorded = _state.recordedFocus;
    return SessionRecord(
      id: 0,
      startedAt: _startedAt,
      mode: config.mode,
      intention: config.intention,
      plannedDuration: plan.totalFocus,
      recordedFocus: recorded,
      completed: completed,
      abandoned: !completed,
      autoContinue: _endless,
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
