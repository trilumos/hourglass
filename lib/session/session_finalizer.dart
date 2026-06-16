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

  /// Records [record] and returns its new row id, then recomputes Focus Stamina.
  /// The id lets the caller revise the same record if a Flow Block is extended.
  Future<int> persist(SessionRecord record) async {
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
    final recentBlocks = all
        .where((s) =>
            s.completed && !s.abandoned && s.mode == SessionMode.flowBlock)
        .map((s) => s.recordedFocus)
        .toList();
    final current = _stamina.currentStamina(recentBlocks);
    await _settings.setInt(staminaKey, current.inSeconds);
  }
}
