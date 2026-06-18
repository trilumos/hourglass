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

  int currentStreak(DateTime today, List<SessionRecord> sessions) {
    final days = sessions
        .where((s) => s.recordedFocus > Duration.zero)
        .map((s) => _dateOnly(s.startedAt))
        .toSet();
    var streak = 0;
    var cursor = _dateOnly(today);
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
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

  /// The longest run of consecutive focused days the user has ever had.
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
      run = days[i].difference(days[i - 1]).inDays == 1 ? run + 1 : 1;
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
