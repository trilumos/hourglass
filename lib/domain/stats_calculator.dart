import 'session_record.dart';

/// Derives focus-time and streak stats. Any session with real focus counts
/// toward today's total, the weekly total, and the streak — completed OR
/// abandoned (all focus time shows up). Only [sessionsCompleted] requires a
/// fully-completed session.
class StatsCalculator {
  const StatsCalculator();

  Duration focusOnDay(DateTime day, List<SessionRecord> sessions) {
    return sessions
        .where((s) =>
            s.recordedFocus > Duration.zero && _sameDay(s.startedAt, day))
        .fold(Duration.zero, (sum, s) => sum + s.recordedFocus);
  }

  /// Total focus in the 7-day window ending on [day] (inclusive).
  Duration focusInWeekEnding(DateTime day, List<SessionRecord> sessions) {
    final end = _dateOnly(day);
    final start = end.subtract(const Duration(days: 6));
    return sessions
        .where((s) =>
            s.recordedFocus > Duration.zero &&
            !_dateOnly(s.startedAt).isBefore(start) &&
            !_dateOnly(s.startedAt).isAfter(end))
        .fold(Duration.zero, (sum, s) => sum + s.recordedFocus);
  }

  /// The current streak, counting the days you actually focused, with a **1-day
  /// grace**: a single missed day never breaks the streak — only two consecutive
  /// empty days do. A missed day doesn't add to the count (nothing is inflated),
  /// it just keeps the run alive. If today is the (still-empty) grace day, the
  /// streak holds from yesterday; focus again within the day to keep it.
  int currentStreak(DateTime today, List<SessionRecord> sessions) {
    final days = sessions
        .where((s) => s.recordedFocus > Duration.zero)
        .map((s) => _dateOnly(s.startedAt))
        .toSet();
    if (days.isEmpty) return 0;
    var cursor = _dateOnly(today);
    // If today has no focus yet, the streak still lives on its grace day as long
    // as yesterday was focused; anchor the walk there. Two empty days = broken.
    if (!days.contains(cursor)) {
      final grace = cursor.subtract(const Duration(days: 1));
      if (days.contains(grace)) {
        cursor = grace;
      } else {
        return 0;
      }
    }
    var streak = 0;
    while (true) {
      if (days.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (days.contains(cursor.subtract(const Duration(days: 1)))) {
        // A single empty day, bridged by the grace — don't count it, keep going.
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break; // two consecutive empty days → the run ends
      }
    }
    return streak;
  }

  int sessionsCompleted(List<SessionRecord> sessions) {
    return sessions.where((s) => s.completed && !s.abandoned).length;
  }

  /// Lifetime total focus across every session that recorded real focus.
  Duration totalFocus(List<SessionRecord> sessions) => sessions
      .where((s) => s.recordedFocus > Duration.zero)
      .fold(Duration.zero, (sum, s) => sum + s.recordedFocus);

  /// The longest run of focused days the user has ever had, using the same 1-day
  /// grace as [currentStreak]: a single empty day between two focused days bridges
  /// the run (a gap of two calendar days), but two empty days break it. Counts
  /// focused days only — grace days don't inflate the total.
  int bestStreak(List<SessionRecord> sessions) {
    final days = sessions
        .where((s) => s.recordedFocus > Duration.zero)
        .map((s) => _dateOnly(s.startedAt))
        .toSet()
        .toList()
      ..sort();
    if (days.isEmpty) return 0;
    var best = 1, run = 1;
    for (var i = 1; i < days.length; i++) {
      // Gap of 1 = consecutive, 2 = one empty day bridged by the grace; both
      // continue the run. A gap of 3+ (two empty days) resets it.
      run = days[i].difference(days[i - 1]).inDays <= 2 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return best;
  }

  /// Mean focus per session (sessions with real focus). Zero if none.
  Duration averageSession(List<SessionRecord> sessions) {
    final focused =
        sessions.where((s) => s.recordedFocus > Duration.zero).toList();
    if (focused.isEmpty) return Duration.zero;
    final total = focused.fold(Duration.zero, (s, x) => s + x.recordedFocus);
    return Duration(seconds: total.inSeconds ~/ focused.length);
  }

  /// The single longest focused session.
  Duration longestSession(List<SessionRecord> sessions) => sessions
      .map((s) => s.recordedFocus)
      .fold(Duration.zero, (m, d) => d > m ? d : m);

  /// Count of sessions that recorded real focus (all modes).
  int totalSessions(List<SessionRecord> sessions) =>
      sessions.where((s) => s.recordedFocus > Duration.zero).length;

  /// The earliest focused session's date ("Focusing since"). Null if none.
  DateTime? firstSessionDate(List<SessionRecord> sessions) {
    final dates = sessions
        .where((s) => s.recordedFocus > Duration.zero)
        .map((s) => s.startedAt)
        .toList()
      ..sort();
    return dates.isEmpty ? null : dates.first;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
