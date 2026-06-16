import 'package:flutter/foundation.dart';

import '../domain/focus_phase.dart';
import '../domain/phase_engine.dart';
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
          _set(_state.copyWith(
            status: SessionStatus.finished,
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

  /// Builds the record to persist. completed iff the planned end was reached.
  /// Abandoned sessions record zero focus (Plan-1 protect-the-block rule).
  SessionRecord finalize() {
    final completed = _state.goalReached;
    final recorded = completed ? _state.recordedFocus : Duration.zero;
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
