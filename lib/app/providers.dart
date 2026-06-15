import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/session_repository.dart';
import '../data/settings_repository.dart';
import '../domain/stats_calculator.dart';

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
