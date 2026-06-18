import 'session_mode.dart';
import 'session_record.dart';

/// The window analytics charts are scoped to.
enum AnalyticsRange { week, month, all }

/// One labeled bar — shared by focus-over-time and both rhythm charts.
class TimeBar {
  final String label;
  final Duration focus;

  /// Visually emphasized: the current period (over-time) or the peak (rhythm).
  final bool highlight;
  const TimeBar(this.label, this.focus, {this.highlight = false});
}

/// One mode's share of focus time in the selected range.
class ModeSlice {
  final SessionMode mode;
  final Duration focus;
  final double fraction; // 0..1 of the range total (0 when total is 0)
  const ModeSlice(this.mode, this.focus, this.fraction);
}

/// Everything the Insights charts need for one range, computed in one pass.
class AnalyticsData {
  final List<TimeBar> focusOverTime; // 7 (week) | 30 (month) | N months (all)
  final List<TimeBar> timeOfDay; // always 6
  final List<TimeBar> dayOfWeek; // always 7
  final List<ModeSlice> byMode; // always 3
  final Duration rangeTotal;
  final bool isEmpty;
  const AnalyticsData({
    required this.focusOverTime,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.byMode,
    required this.rangeTotal,
    required this.isEmpty,
  });
}

/// Derives the Insights charts from focus history. Pure: no Flutter, no I/O.
/// "Now" is injected so every series is deterministically testable.
class AnalyticsCalculator {
  const AnalyticsCalculator();

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Sessions with real focus inside the range window (inclusive of today).
  List<SessionRecord> sessionsInRange(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    final focused = sessions.where((s) => s.recordedFocus > Duration.zero);
    if (range == AnalyticsRange.all) return focused.toList();
    final end = _dateOnly(now);
    final start = end.subtract(Duration(days: range == AnalyticsRange.week ? 6 : 29));
    return focused.where((s) {
      final d = _dateOnly(s.startedAt);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  /// Focus per bucket over time: daily for week/month, monthly for all.
  /// The latest bucket (today / current month) is highlighted.
  List<TimeBar> focusOverTime(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    final inRange = sessionsInRange(range, now, sessions);
    if (range == AnalyticsRange.all) {
      if (inRange.isEmpty) return const [];
      final first =
          inRange.map((s) => s.startedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      final end = DateTime(now.year, now.month);
      final bars = <TimeBar>[];
      var cursor = DateTime(first.year, first.month);
      while (!cursor.isAfter(end)) {
        final focus = inRange
            .where((s) =>
                s.startedAt.year == cursor.year &&
                s.startedAt.month == cursor.month)
            .fold(Duration.zero, (a, s) => a + s.recordedFocus);
        final isCurrent = cursor.year == end.year && cursor.month == end.month;
        bars.add(TimeBar(_monthAbbr[cursor.month - 1], focus, highlight: isCurrent));
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
      return bars;
    }
    final count = range == AnalyticsRange.week ? 7 : 30;
    final today = _dateOnly(now);
    final bars = <TimeBar>[];
    for (var i = count - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final focus = inRange
          .where((s) => _dateOnly(s.startedAt) == day)
          .fold(Duration.zero, (a, s) => a + s.recordedFocus);
      final label = range == AnalyticsRange.week
          ? _weekdayInitials[day.weekday - 1]
          : '${day.day}';
      bars.add(TimeBar(label, focus, highlight: i == 0));
    }
    return bars;
  }

  /// Focus by part of day (6 fixed buckets). Peak bucket highlighted.
  List<TimeBar> timeOfDay(List<SessionRecord> inRange) {
    const labels = ['Early', 'Morning', 'Midday', 'Afternoon', 'Evening', 'Night'];
    final totals = List.filled(6, Duration.zero);
    for (final s in inRange) {
      totals[_todBucket(s.startedAt.hour)] += s.recordedFocus;
    }
    return _bars(labels, totals);
  }

  /// Focus by weekday (Mon→Sun). Peak day highlighted.
  List<TimeBar> dayOfWeek(List<SessionRecord> inRange) {
    final totals = List.filled(7, Duration.zero);
    for (final s in inRange) {
      totals[s.startedAt.weekday - 1] += s.recordedFocus;
    }
    return _bars(_weekdayInitials, totals);
  }

  /// Focus share across the three modes (fixed order, always 3).
  List<ModeSlice> byMode(List<SessionRecord> inRange) {
    const order = [SessionMode.flowBlock, SessionMode.pomodoro, SessionMode.custom];
    final totals = {for (final m in order) m: Duration.zero};
    for (final s in inRange) {
      totals[s.mode] = totals[s.mode]! + s.recordedFocus;
    }
    final total = totals.values.fold(Duration.zero, (a, d) => a + d);
    return [
      for (final m in order)
        ModeSlice(
          m,
          totals[m]!,
          total > Duration.zero ? totals[m]!.inSeconds / total.inSeconds : 0.0,
        )
    ];
  }

  /// All series for one range in a single pass over the data.
  AnalyticsData compute(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    final inRange = sessionsInRange(range, now, sessions);
    final total = inRange.fold(Duration.zero, (a, s) => a + s.recordedFocus);
    return AnalyticsData(
      focusOverTime: focusOverTime(range, now, sessions),
      timeOfDay: timeOfDay(inRange),
      dayOfWeek: dayOfWeek(inRange),
      byMode: byMode(inRange),
      rangeTotal: total,
      isEmpty: total == Duration.zero,
    );
  }

  int _todBucket(int hour) {
    if (hour >= 5 && hour < 8) return 0; // Early
    if (hour >= 8 && hour < 12) return 1; // Morning
    if (hour >= 12 && hour < 14) return 2; // Midday
    if (hour >= 14 && hour < 17) return 3; // Afternoon
    if (hour >= 17 && hour < 21) return 4; // Evening
    return 5; // Night (21:00–04:59)
  }

  /// Builds bars and highlights the single max bucket (ties → first).
  List<TimeBar> _bars(List<String> labels, List<Duration> totals) {
    var peak = -1;
    var peakVal = Duration.zero;
    for (var i = 0; i < totals.length; i++) {
      if (totals[i] > peakVal) {
        peakVal = totals[i];
        peak = i;
      }
    }
    return [
      for (var i = 0; i < labels.length; i++)
        TimeBar(labels[i], totals[i],
            highlight: i == peak && peakVal > Duration.zero)
    ];
  }
}
