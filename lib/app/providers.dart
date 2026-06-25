import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/backup_service.dart';
import '../data/image_storage_service.dart';
import '../data/profile_repository.dart';
import '../data/session_repository.dart';
import '../data/settings_repository.dart';
import '../domain/analytics_calculator.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/personal_bests.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import '../domain/stamina_calculator.dart';
import '../domain/stats_calculator.dart';
import '../domain/user_profile.dart';
import '../session/session_finalizer.dart';
import 'theme_controller.dart';

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

  /// Whether first-run onboarding has been completed. Default: false (show it).
  static const onboardingComplete = 'onboardingComplete';
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

/// True when first-run onboarding should be SKIPPED — either it was completed,
/// or the migration guard found existing data (so an updating user is never
/// shown onboarding again). False means a fresh install: show onboarding.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  if (await settings.getBool(SettingsKeys.onboardingComplete,
      defaultValue: false)) {
    return true;
  }
  // Migration guard: any prior sessions or a saved profile name = existing user.
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final profile = await ref.watch(profileRepositoryProvider).load();
  if (sessions.isNotEmpty || profile.name.trim().isNotEmpty) {
    await settings.setBool(SettingsKeys.onboardingComplete, true);
    return true;
  }
  return false;
});

/// The calm numbers shown on the home screen.
class HomeStats {
  final Duration todayFocus;
  final int streak;
  final int sessionsCompleted;

  /// Mean focused time per session across ALL modes — the easy-to-grasp
  /// companion to the (Flow-only) Focus Score.
  final Duration avgSession;

  const HomeStats({
    required this.todayFocus,
    required this.streak,
    required this.sessionsCompleted,
    required this.avgSession,
  });

  static const empty = HomeStats(
    todayFocus: Duration.zero,
    streak: 0,
    sessionsCompleted: 0,
    avgSession: Duration.zero,
  );
}

/// Builds and persists finished sessions. (Focus Stamina is derived from the
/// sessions on read — see [staminaProvider] — not stored here.)
final sessionFinalizerProvider = Provider<SessionFinalizer>(
  (ref) => SessionFinalizer(ref.watch(sessionRepositoryProvider)),
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

/// The user's Focus Stamina, derived from sessions via the single stamina rule
/// ([StaminaCalculator.qualifyingFlowBlocks]). [established] is false until the
/// first eligible Flow session; [value] is meaningful only once established
/// (the Flow setup shows a locked chip until then).
class StaminaInfo {
  final bool established;
  final Duration value;
  const StaminaInfo(this.established, this.value);
}

/// Backs the Flow setup's stamina-matched length. Recomputed from sessions so
/// it always agrees with the stored stamina (both use the same rule).
final staminaProvider = FutureProvider<StaminaInfo>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  const calc = StaminaCalculator();
  final blocks = calc.qualifyingFlowBlocks(sessions);
  return StaminaInfo(
    blocks.isNotEmpty,
    calc.currentStamina(blocks.map((s) => s.recordedFocus).toList()),
  );
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
    avgSession: stats.averageSession(sessions),
  );
});

/// The single on-device profile (self-creating). Invalidate after an edit.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final imageStorageProvider =
    Provider<ImageStorageService>((ref) => ImageStorageService());

/// Resolves a stored relative image path to an absolute [File], cached by path.
/// Widgets (e.g. [ProfileAvatar]) watch this instead of building a fresh
/// `FutureBuilder` future every rebuild — which reset to the loading state and
/// flashed the fallback glyph, and re-ran the platform documents-dir lookup each
/// frame. A new path (avatars use a unique filename per save) is a new key, so
/// an updated photo still refreshes.
final resolvedImageProvider = FutureProvider.autoDispose
    .family<File, String>((ref, relativePath) =>
        ref.watch(imageStorageProvider).resolve(relativePath));

/// Manual data backup/restore (export/import all on-device data as JSON).
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(databaseProvider),
    ref.watch(sharedPrefsProvider),
    ref.watch(imageStorageProvider),
  ),
);

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

/// The selected Insights window. Defaults to week; [set] swaps it.
class AnalyticsRangeController extends Notifier<AnalyticsRange> {
  @override
  AnalyticsRange build() => AnalyticsRange.week;
  void set(AnalyticsRange range) => state = range;
}

final analyticsRangeProvider =
    NotifierProvider<AnalyticsRangeController, AnalyticsRange>(
        AnalyticsRangeController.new);

/// All Insights chart series for the selected range.
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final now = ref.watch(clockProvider)();
  final range = ref.watch(analyticsRangeProvider);
  return const AnalyticsCalculator().compute(range, now, sessions);
});

/// The enhanced (Pro) Insights series for the selected range — Focus Score
/// trend, Focus Stamina growth, peak-window caption, follow-through rate, and
/// lifetime personal bests. Computed in one pass.
class InsightsExtras {
  final List<TrendPoint> scoreTrend;
  final List<TrendPoint> staminaGrowth;
  final String? peakWindow;
  final FollowThrough followThrough;
  final PersonalBests bests;
  const InsightsExtras({
    required this.scoreTrend,
    required this.staminaGrowth,
    required this.peakWindow,
    required this.followThrough,
    required this.bests,
  });
}

final insightsExtrasProvider = FutureProvider<InsightsExtras>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final now = ref.watch(clockProvider)();
  final range = ref.watch(analyticsRangeProvider);
  const calc = AnalyticsCalculator();
  final inRange = calc.sessionsInRange(range, now, sessions);
  return InsightsExtras(
    scoreTrend: calc.focusScoreTrend(range, now, sessions),
    staminaGrowth: calc.staminaGrowth(range, now, sessions),
    peakWindow: calc.peakWindowCaption(inRange),
    followThrough: calc.followThrough(range, now, sessions),
    bests: const PersonalBestsCalculator().compute(sessions),
  );
});

/// All sessions (newest first) for the CSV export — Pro.
final allSessionsProvider = FutureProvider<List<SessionRecord>>((ref) async {
  final all = await ref.watch(sessionRepositoryProvider).allSessions();
  return all.reversed.toList();
});
