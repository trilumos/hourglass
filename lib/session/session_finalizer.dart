import '../data/session_repository.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';

/// Persists a finished session. Focus Stamina is derived from the stored
/// sessions wherever it's needed (see [StaminaCalculator.qualifyingFlowBlocks]
/// via `staminaProvider`), so there is nothing to recompute or cache here — the
/// sessions are the single source of truth.
class SessionFinalizer {
  final SessionRepository _sessions;

  SessionFinalizer(this._sessions);

  /// Minimum focused seconds a Flow Block must reach to be recorded at all.
  /// Sub-2-min Flow ends are uncounted (no streak, Today, history, or score).
  static const flowMinSeconds = 120;

  /// Records [record] and returns its new row id, or null when focus is below
  /// the keep threshold: a **Flow** block needs ≥ [flowMinSeconds];
  /// **Pomodoro/Custom** keep any real focus (> 0s). The id lets the caller
  /// revise the same record if a Flow Block is extended.
  Future<int?> persist(SessionRecord record) async {
    final minSeconds =
        record.mode == SessionMode.flowBlock ? flowMinSeconds : 1;
    if (record.recordedFocus.inSeconds < minSeconds) return null;
    return _sessions.insertSession(record);
  }

  /// Revises an existing session's recorded focus (a Flow Block extended via
  /// "Keep going"). Keeps it as ONE record.
  Future<void> reviseRecordedFocus(
    int id, {
    required Duration recorded,
    required bool completed,
    required bool abandoned,
  }) {
    return _sessions.updateRecordedFocus(
      id,
      recorded: recorded,
      completed: completed,
      abandoned: abandoned,
    );
  }
}
