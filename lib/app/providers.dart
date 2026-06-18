import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/image_storage_service.dart';
import '../data/profile_repository.dart';
import '../data/session_repository.dart';
import '../data/settings_repository.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import '../domain/stamina_calculator.dart';
import '../domain/stats_calculator.dart';
import '../domain/user_profile.dart';
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

  /// Whether Flow Blocks run open-ended by default — until the user ends the
  /// session manually — instead of auto-stopping at their length. Default: off
  /// (the block auto-ends, offering a "don't stop" nudge near the end).
  static const flowRunUntilEnded = 'flowRunUntilEnded';
}

/// User preference: auto-advance into the next focus block after a break.
final breakAutoAdvanceProvider = FutureProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .getBool(SettingsKeys.breakAutoAdvance, defaultValue: true),
);

/// User preference: Flow Blocks run until manually ended (open-ended by default).
final flowRunUntilEndedProvider = FutureProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .getBool(SettingsKeys.flowRunUntilEnded, defaultValue: false),
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

/// The single on-device profile (self-creating). Invalidate after an edit.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final imageStorageProvider =
    Provider<ImageStorageService>((ref) => ImageStorageService());

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).load(),
);

/// All sessions that recorded real focus, newest first (for the history list).
final sessionHistoryProvider = FutureProvider<List<SessionRecord>>((ref) async {
  final all = await ref.watch(sessionRepositoryProvider).allSessions();
  return all
      .where((s) => s.recordedFocus > Duration.zero)
      .toList()
      .reversed
      .toList();
});

/// Stats shown on the Profile hub (headline + records).
class ProfileStats {
  final Duration totalFocus;
  final int streak;
  final int sessionsCompleted;
  final Duration weekFocus;
  final int bestStreak;
  final Duration avgSession;
  final Duration longestSession;
  final int totalSessions;
  final DateTime? firstDate;
  const ProfileStats({
    required this.totalFocus,
    required this.streak,
    required this.sessionsCompleted,
    required this.weekFocus,
    required this.bestStreak,
    required this.avgSession,
    required this.longestSession,
    required this.totalSessions,
    required this.firstDate,
  });
  static const empty = ProfileStats(
    totalFocus: Duration.zero,
    streak: 0,
    sessionsCompleted: 0,
    weekFocus: Duration.zero,
    bestStreak: 0,
    avgSession: Duration.zero,
    longestSession: Duration.zero,
    totalSessions: 0,
    firstDate: null,
  );
}

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final now = ref.watch(clockProvider)();
  const stats = StatsCalculator();
  return ProfileStats(
    totalFocus: stats.totalFocus(sessions),
    streak: stats.currentStreak(now, sessions),
    sessionsCompleted: stats.sessionsCompleted(sessions),
    weekFocus: stats.focusInWeekEnding(now, sessions),
    bestStreak: stats.bestStreak(sessions),
    avgSession: stats.averageSession(sessions),
    longestSession: stats.longestSession(sessions),
    totalSessions: stats.totalSessions(sessions),
    firstDate: stats.firstSessionDate(sessions),
  );
});

/// Per-day focus + session count, keyed by date-only — for the activity graph.
class DayStat {
  final Duration focus;
  final int sessions;
  const DayStat(this.focus, this.sessions);
}

final dailyFocusProvider = FutureProvider<Map<DateTime, DayStat>>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final map = <DateTime, DayStat>{};
  for (final s in sessions) {
    if (s.recordedFocus <= Duration.zero) continue;
    final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
    final prev = map[d];
    map[d] = DayStat(
      (prev?.focus ?? Duration.zero) + s.recordedFocus,
      (prev?.sessions ?? 0) + 1,
    );
  }
  return map;
});
