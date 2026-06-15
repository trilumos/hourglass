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

  /// Records [record], then (only for a completed, non-abandoned Flow Block)
  /// recomputes Focus Stamina from recent completed flow blocks and stores it.
  /// Abandoned sessions and non-flow-block sessions are persisted but never
  /// affect stamina.
  Future<void> persist(SessionRecord record) async {
    await _sessions.insertSession(record);

    final countsTowardStamina = record.completed &&
        !record.abandoned &&
        record.mode == SessionMode.flowBlock;
    if (!countsTowardStamina) return;

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
