import 'analytics_calculator.dart';
import 'focus_score_calculator.dart';
import 'personal_bests.dart';
import 'session_mode.dart';
import 'session_record.dart';
import 'stamina_calculator.dart';
import 'stats_calculator.dart';

/// One mode's lifetime focus + how many sessions + average length. Augments the
/// [ModeSlice] fraction with count/avg for the report's by-mode rows.
class ModeStat {
  final SessionMode mode;
  final int count;
  final Duration totalFocus;
  final Duration avg;
  final double fraction;
  const ModeStat(this.mode, this.count, this.totalFocus, this.avg, this.fraction);
}

/// A dated (or undated achievement) moment on the report's milestone timeline.
class Milestone {
  final DateTime? date;
  final String label;
  const Milestone(this.date, this.label);
}

/// The most-focused-on words across the user's session intentions. Null below
/// the stability threshold so the report never invents a theme.
class IntentionThemes {
  final int sessionsWithIntention;
  final int totalSessions;
  final List<({String phrase, int count})> topPhrases;
  const IntentionThemes(
      this.sessionsWithIntention, this.totalSessions, this.topPhrases);
}

/// A single, context-free snapshot of everything the PDF Focus Report renders —
/// computed once from the full session list at generation time. The report
/// builder selects and draws from this; it does not compute. Pure: no Flutter,
/// no I/O, so it is fully unit-testable. Grows richer as history grows.
class FocusReportData {
  final String name;
  final DateTime now;
  final bool isPro;

  // Lifetime aggregates.
  final Duration totalFocus;
  final int totalSessions;
  final int sessionsCompleted;
  final Duration avgSession;
  final Duration longestSession;
  final DateTime? longestSessionDate;
  final DateTime? firstSessionDate;

  // As of [now].
  final int currentStreak;
  final Duration todayFocus;
  final Duration weekFocus;

  // Scores & stamina (null until the metric has any Flow data).
  final int? focusScore;
  final int? highestFocusScore;
  final int? currentStaminaMinutes;

  // Personal bests.
  final Duration? bestDayFocus;
  final DateTime? bestDayDate;
  final int bestStreak;

  // Lifetime analytics (AnalyticsRange.all).
  final List<ModeSlice> byMode;
  final List<TimeBar> focusOverTime; // one bar per month
  final List<TrendPoint> scoreTrend;
  final List<TrendPoint> staminaGrowth;
  final FollowThrough followThrough;
  final List<TimeBar> timeOfDay; // 6 buckets
  final List<TimeBar> dayOfWeek; // 7, Sun→Sat
  final String? peakWindowCaption;

  // Derived for the report.
  final int activeDaysTotal;
  final int activeDaysLast30;
  final double? completionRate;
  final List<Duration> last14Strip; // oldest → newest, ending today
  final List<ModeStat> modeStats;
  final List<Milestone> milestones;
  final IntentionThemes? intentionThemes;

  const FocusReportData({
    required this.name,
    required this.now,
    required this.isPro,
    required this.totalFocus,
    required this.totalSessions,
    required this.sessionsCompleted,
    required this.avgSession,
    required this.longestSession,
    required this.longestSessionDate,
    required this.firstSessionDate,
    required this.currentStreak,
    required this.todayFocus,
    required this.weekFocus,
    required this.focusScore,
    required this.highestFocusScore,
    required this.currentStaminaMinutes,
    required this.bestDayFocus,
    required this.bestDayDate,
    required this.bestStreak,
    required this.byMode,
    required this.focusOverTime,
    required this.scoreTrend,
    required this.staminaGrowth,
    required this.followThrough,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.peakWindowCaption,
    required this.activeDaysTotal,
    required this.activeDaysLast30,
    required this.completionRate,
    required this.last14Strip,
    required this.modeStats,
    required this.milestones,
    required this.intentionThemes,
  });

  bool get hasData => totalSessions > 0;

  /// Number of months the history spans (1 + months between first and now).
  int get monthsSpanned {
    final first = firstSessionDate;
    if (first == null) return 0;
    return (now.year - first.year) * 12 + (now.month - first.month) + 1;
  }

  factory FocusReportData.from({
    required List<SessionRecord> sessions,
    required DateTime now,
    required String name,
    required bool isPro,
  }) {
    const stats = StatsCalculator();
    const analytics = AnalyticsCalculator();
    final bests = const PersonalBestsCalculator().compute(sessions);

    // Focus Score (null when no qualifying Flow session ever — never 0/100).
    final flowTuples = sessions
        .where((s) =>
            s.mode == SessionMode.flowBlock && s.recordedFocus.inSeconds >= 120)
        .map((s) => (chosen: s.plannedDuration, actual: s.recordedFocus))
        .toList();
    final focusScore =
        flowTuples.isEmpty ? null : const FocusScoreCalculator().score(flowTuples);

    // Focus Stamina (null until the first qualifying Flow block).
    const staminaCalc = StaminaCalculator();
    final blocks = staminaCalc.qualifyingFlowBlocks(sessions);
    final currentStaminaMinutes = blocks.isEmpty
        ? null
        : staminaCalc
            .currentStamina(blocks.map((s) => s.recordedFocus).toList())
            .inMinutes;

    const all = AnalyticsRange.all;
    final data = analytics.compute(all, now, sessions);
    final focusedAll = analytics.sessionsInRange(all, now, sessions);

    // Per-day focus map → active days + the 14-day strip.
    DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final daily = <DateTime, Duration>{};
    for (final s in focusedAll) {
      final d = dayOnly(s.startedAt);
      daily[d] = (daily[d] ?? Duration.zero) + s.recordedFocus;
    }
    final today = dayOnly(now);
    var activeDaysLast30 = 0;
    for (var i = 0; i < 30; i++) {
      if (daily.containsKey(today.subtract(Duration(days: i)))) activeDaysLast30++;
    }
    final last14 = [
      for (var i = 13; i >= 0; i--)
        daily[today.subtract(Duration(days: i))] ?? Duration.zero
    ];

    final totalSessions = stats.totalSessions(sessions);
    final sessionsCompleted = stats.sessionsCompleted(sessions);
    final completionRate =
        totalSessions < 3 ? null : sessionsCompleted / totalSessions;

    // Per-mode count + average (paired with the byMode fractions).
    final modeStats = <ModeStat>[];
    for (final slice in data.byMode) {
      final ss = focusedAll.where((s) => s.mode == slice.mode).toList();
      if (ss.isEmpty) continue;
      final tot = ss.fold(Duration.zero, (a, s) => a + s.recordedFocus);
      modeStats.add(ModeStat(slice.mode, ss.length, tot,
          Duration(seconds: tot.inSeconds ~/ ss.length), slice.fraction));
    }

    return FocusReportData(
      name: name,
      now: now,
      isPro: isPro,
      totalFocus: stats.totalFocus(sessions),
      totalSessions: totalSessions,
      sessionsCompleted: sessionsCompleted,
      avgSession: stats.averageSession(sessions),
      longestSession: bests.longestSession ?? Duration.zero,
      longestSessionDate: bests.longestSessionDate,
      firstSessionDate: bests.focusingSince,
      currentStreak: stats.currentStreak(now, sessions),
      todayFocus: stats.focusOnDay(now, sessions),
      weekFocus: stats.focusInWeekEnding(now, sessions),
      focusScore: focusScore,
      highestFocusScore: bests.highestFocusScore,
      currentStaminaMinutes: currentStaminaMinutes,
      bestDayFocus: bests.bestDayFocus,
      bestDayDate: bests.bestDayDate,
      bestStreak: bests.bestStreak,
      byMode: data.byMode,
      focusOverTime: data.focusOverTime,
      scoreTrend: analytics.focusScoreTrend(all, now, sessions),
      staminaGrowth: analytics.staminaGrowth(all, now, sessions),
      followThrough: analytics.followThrough(all, now, sessions),
      timeOfDay: data.timeOfDay,
      dayOfWeek: data.dayOfWeek,
      peakWindowCaption: analytics.peakWindowCaption(focusedAll),
      activeDaysTotal: daily.length,
      activeDaysLast30: activeDaysLast30,
      completionRate: completionRate,
      last14Strip: last14,
      modeStats: modeStats,
      milestones: _milestones(bests, stats.totalFocus(sessions)),
      intentionThemes: _intentionThemes(focusedAll, totalSessions),
    );
  }
}

List<Milestone> _milestones(PersonalBests bests, Duration totalFocus) {
  final dated = <Milestone>[];
  if (bests.focusingSince != null) {
    dated.add(Milestone(bests.focusingSince, 'Started focusing'));
  }
  if (bests.bestDayDate != null) {
    dated.add(Milestone(bests.bestDayDate, 'Your best focus day'));
  }
  if (bests.longestSessionDate != null) {
    dated.add(Milestone(bests.longestSessionDate, 'Your longest single block'));
  }
  dated.sort((a, b) => a.date!.compareTo(b.date!));

  final marks = <Milestone>[];
  if (bests.bestStreak >= 7) marks.add(const Milestone(null, 'Reached a 7-day streak'));
  if (bests.bestStreak >= 30) {
    marks.add(const Milestone(null, 'Reached a 30-day streak'));
  }
  final hours = totalFocus.inMinutes / 60.0;
  for (final t in const [500, 250, 100, 50, 25, 10]) {
    if (hours >= t) {
      marks.add(Milestone(null, 'Crossed $t hours of total focus'));
      break;
    }
  }
  if (bests.highestFocusScore != null) {
    marks.add(Milestone(null, 'Highest Focus Score: ${bests.highestFocusScore}'));
  }
  return [...dated, ...marks];
}

const _stopWords = {
  'the', 'a', 'an', 'to', 'of', 'for', 'on', 'my', 'and', 'in', 'with', 'at',
  'is', 'it', 'be', 'do', 'me', 'up', 'or', 'as', 'by'
};

IntentionThemes? _intentionThemes(List<SessionRecord> focused, int totalSessions) {
  final withIntention =
      focused.where((s) => s.intention.trim().isNotEmpty).toList();
  if (withIntention.length < 5) return null;
  final freq = <String, int>{};
  for (final s in withIntention) {
    for (final raw in s.intention.toLowerCase().split(RegExp(r'\s+'))) {
      final w = raw.replaceAll(RegExp('[^a-z0-9]'), '');
      if (w.length < 2 || _stopWords.contains(w)) continue;
      freq[w] = (freq[w] ?? 0) + 1;
    }
  }
  if (freq.isEmpty) return null;
  final entries = freq.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return IntentionThemes(
    withIntention.length,
    totalSessions,
    [for (final e in entries.take(5)) (phrase: e.key, count: e.value)],
  );
}
