import 'package:flutter/foundation.dart';

import '../domain/phase_engine.dart';
import '../domain/recorded_focus.dart';
import '../domain/session_record.dart';
import 'session_config.dart';
import 'session_state.dart';
import 'ticker.dart';

/// Owns the live session: elapsed time, phase, goal/auto-continue handling,
/// and finalization into a [SessionRecord]. UI listens via [ChangeNotifier].
class SessionController extends ChangeNotifier {
  final SessionConfig config;
  final Ticker ticker;
  final DateTime Function() now;
  final PhaseEngine _engine;

  SessionState _state = SessionState.initial();
  late final DateTime _startedAt;

  SessionController({
    required this.config,
    required this.ticker,
    required this.now,
  }) : _engine = PhaseEngine.forBlock(config.plannedDuration);

  SessionState get state => _state;

  void start() {
    if (_state.status != SessionStatus.idle) return;
    _startedAt = now();
    _set(_state.copyWith(status: SessionStatus.running));
    ticker.start(_onTick);
  }

  void _onTick(Duration delta) {
    final elapsed = _state.elapsed + delta;
    final reachedGoal = elapsed >= config.plannedDuration;

    if (reachedGoal && !config.autoContinue) {
      ticker.stop();
      _set(_state.copyWith(
        elapsed: config.plannedDuration,
        phase: _engine.phaseAt(config.plannedDuration),
        goalReached: true,
        status: SessionStatus.finished,
      ));
      return;
    }

    _set(_state.copyWith(
      elapsed: elapsed,
      phase: _engine.phaseAt(elapsed),
      goalReached: _state.goalReached || reachedGoal,
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

  /// User ends an endless session that has reached its goal.
  void end() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
  }

  /// Session abandoned before the goal (e.g. left the app, protect-the-block).
  void abandon() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
  }

  /// Builds the record to persist. completed iff the goal was reached.
  SessionRecord finalize() {
    final completed = _state.goalReached;
    final recorded = completed
        ? computeRecordedFocus(
            plannedDuration: config.plannedDuration,
            elapsed: _state.elapsed,
            autoContinue: config.autoContinue,
          )
        : Duration.zero;
    return SessionRecord(
      id: 0,
      startedAt: _startedAt,
      mode: config.mode,
      intention: config.intention,
      plannedDuration: config.plannedDuration,
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
