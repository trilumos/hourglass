import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/session_repository.dart';
import '../data/settings_repository.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/session_mode.dart';
import '../domain/stamina_calculator.dart';
import '../domain/stats_calculator.dart';
import '../session/session_finalizer.dart';

/// The on-device database. Closed automatically when the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// Wall-clock injection point so screens and stats are testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Settings keys (string-typed key/value store).
class SettingsKeys {
  const SettingsKeys._();

  /// Whether the next focus block starts automatically after a break (true) or
  /// waits for the user to tap continue (false). Default: auto-advance.
  static const breakAutoAdvance = 'breakAutoAdvance';
}

/// User preference: auto-advance into the next focus block after a break.
final breakAutoAdvanceProvider = FutureProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .getBool(SettingsKeys.breakAutoAdvance, defaultValue: true),
);

/// The calm numbers shown on the home screen.
class HomeStats {
  final Duration todayFocus;
  final int streak;
  final int sessionsCompleted;

  const HomeStats({
    required this.todayFocus,
    required this.streak,
    required this.sessionsCompleted,
  });

  static const empty =
      HomeStats(todayFocus: Duration.zero, streak: 0, sessionsCompleted: 0);
}

/// Builds and persists finished sessions (and updates Focus Stamina).
final sessionFinalizerProvider = Provider<SessionFinalizer>(
  (ref) => SessionFinalizer(
    ref.watch(sessionRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    const StaminaCalculator(),
  ),
);

/// The Flow Block Focus Score (0–100) — average of the last 10 Flow Block
/// session scores (ramps over the first ~10). Flow-Block-only.
final focusScoreProvider = FutureProvider<int>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final flow = sessions
      .where((s) =>
          s.mode == SessionMode.flowBlock && s.recordedFocus.inSeconds >= 120)
      .map((s) => (chosen: s.plannedDuration, actual: s.recordedFocus))
      .toList();
  return const FocusScoreCalculator().score(flow);
});

/// The stamina-suggested next Flow Block length, derived from stored stamina.
final suggestedFlowLengthProvider = FutureProvider<Duration>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  final seconds = await settings.getInt(
    SessionFinalizer.staminaKey,
    defaultValue: StaminaCalculator.defaultStart.inSeconds,
  );
  const calc = StaminaCalculator();
  return calc.suggestedNextLength(Duration(seconds: seconds));
});

/// Loads all sessions and derives the home stats via [StatsCalculator].
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final now = ref.watch(clockProvider)();
  const stats = StatsCalculator();
  return HomeStats(
    todayFocus: stats.focusOnDay(now, sessions),
    streak: stats.currentStreak(now, sessions),
    sessionsCompleted: stats.sessionsCompleted(sessions),
  );
});
