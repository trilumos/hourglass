import '../data/session_repository.dart';
import '../data/settings_repository.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import '../domain/stamina_calculator.dart';

/// Persists a finished session and, for completed flow blocks, recomputes and
/// stores the user's Focus Stamina. Pure orchestration over the Plan-1 pieces.
class SessionFinalizer {
  final SessionRepository _sessions;
  final SettingsRepository _settings;
  final StaminaCalculator _stamina;

  SessionFinalizer(this._sessions, this._settings, this._stamina);

  /// Settings key holding the user's current Focus Stamina, in seconds.
  static const staminaKey = 'staminaSeconds';

  /// Minimum focused seconds a Flow Block must reach to be recorded at all.
  /// Sub-2-min Flow ends are uncounted (no streak, Today, history, or score).
  static const flowMinSeconds = 120;

  /// Records [record] and returns its new row id, then recomputes Focus Stamina.
  /// The id lets the caller revise the same record if a Flow Block is extended.
  ///
  /// Returns `null` (records nothing) when the focus is below the keep
  /// threshold: a **Flow** block needs ≥ [flowMinSeconds]; **Pomodoro/Custom**
  /// keep any real focus (> 0s).
  Future<int?> persist(SessionRecord record) async {
    final minSeconds =
        record.mode == SessionMode.flowBlock ? flowMinSeconds : 1;
    if (record.recordedFocus.inSeconds < minSeconds) return null;
    final id = await _sessions.insertSession(record);
    await _recomputeStamina();
    return id;
  }

  /// Revises an existing session's recorded focus (a Flow Block extended via
  /// "Keep going"), then recomputes stamina. Keeps it as ONE record.
  Future<void> reviseRecordedFocus(
    int id, {
    required Duration recorded,
    required bool completed,
    required bool abandoned,
  }) async {
    await _sessions.updateRecordedFocus(
      id,
      recorded: recorded,
      completed: completed,
      abandoned: abandoned,
    );
    await _recomputeStamina();
  }

  Future<void> _recomputeStamina() async {
    final all = await _sessions.allSessions(); // oldest -> newest
    final blocks = _stamina
        .qualifyingFlowBlocks(all)
        .map((s) => s.recordedFocus)
        .toList();
    final current = _stamina.currentStamina(blocks);
    await _settings.setInt(staminaKey, current.inSeconds);
  }
}
