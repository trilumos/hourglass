import 'focus_score_calculator.dart';
import 'session_mode.dart';
import 'session_record.dart';
import 'stats_calculator.dart';

/// A user's lifetime records, each null-safe (null when there's no data yet).
class PersonalBests {
  final Duration? bestDayFocus;
  final DateTime? bestDayDate;
  final Duration? longestSession;
  final DateTime? longestSessionDate;
  final int bestStreak; // days; 0 when none
  final int? highestFocusScore; // 0–100, null before any scored Flow session
  final DateTime? focusingSince;

  const PersonalBests({
    required this.bestDayFocus,
    required this.bestDayDate,
    required this.longestSession,
    required this.longestSessionDate,
    required this.bestStreak,
    required this.highestFocusScore,
    required this.focusingSince,
  });

  bool get isEmpty => focusingSince == null;
}

/// Derives [PersonalBests] from focus history. Pure: no Flutter, no I/O.
class PersonalBestsCalculator {
  const PersonalBestsCalculator();

  PersonalBests compute(List<SessionRecord> sessions) {
    final focused =
        sessions.where((s) => s.recordedFocus > Duration.zero).toList();
    if (focused.isEmpty) {
      return const PersonalBests(
        bestDayFocus: null,
        bestDayDate: null,
        longestSession: null,
        longestSessionDate: null,
        bestStreak: 0,
        highestFocusScore: null,
        focusingSince: null,
      );
    }

    // Best focus day (most total focus in a single calendar day).
    final perDay = <DateTime, Duration>{};
    for (final s in focused) {
      final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      perDay[d] = (perDay[d] ?? Duration.zero) + s.recordedFocus;
    }
    DateTime? bestDay;
    var bestDayFocus = Duration.zero;
    perDay.forEach((day, focus) {
      if (focus > bestDayFocus) {
        bestDayFocus = focus;
        bestDay = day;
      }
    });

    // Longest single session.
    var longest = focused.first;
    for (final s in focused) {
      if (s.recordedFocus > longest.recordedFocus) longest = s;
    }

    // Highest Focus Score ever reached (running, over valid Flow sessions).
    const fsc = FocusScoreCalculator();
    final flow = focused
        .where((s) =>
            s.mode == SessionMode.flowBlock && s.recordedFocus.inSeconds >= 120)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    int? highest;
    final acc = <({Duration chosen, Duration actual})>[];
    for (final s in flow) {
      acc.add((chosen: s.plannedDuration, actual: s.recordedFocus));
      final sc = fsc.score(acc);
      if (highest == null || sc > highest) highest = sc;
    }

    final since = focused
        .map((s) => s.startedAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    return PersonalBests(
      bestDayFocus: bestDayFocus,
      bestDayDate: bestDay,
      longestSession: longest.recordedFocus,
      longestSessionDate: longest.startedAt,
      bestStreak: const StatsCalculator().bestStreak(sessions),
      highestFocusScore: highest,
      focusingSince: since,
    );
  }
}
