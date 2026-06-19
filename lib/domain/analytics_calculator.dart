import 'focus_score_calculator.dart';
import 'session_mode.dart';
import 'session_record.dart';
import 'stamina_calculator.dart';

/// The window analytics charts are scoped to.
enum AnalyticsRange { week, month, all }

/// One point on a value-over-time line (Focus Score trend, Stamina growth).
/// [value] is null for buckets before the metric has any data (no fake line).
class TrendPoint {
  final String label; // short axis label (e.g. 'M', '14', 'Jun')
  final String? detail; // fuller readout (e.g. 'Tue 14', 'Jun 2026')
  final double? value;
  const TrendPoint(this.label, this.value, {this.detail});

  String get readout => detail ?? label;
}

/// Follow-through: share of Flow sessions in the range that reached their mark,
/// with the previous window's rate for a comparison line.
class FollowThrough {
  final double rate; // 0..1 (0 when no sample)
  final double? prevRate; // null for all-time or no prior sample
  final int sample; // number of Flow sessions counted
  const FollowThrough(this.rate, this.prevRate, this.sample);
}

/// One labeled bar — shared by focus-over-time and both rhythm charts.
class TimeBar {
  final String label;
  final Duration focus;

  /// Visually emphasized: the current period (over-time) or the peak (rhythm).
  final bool highlight;

  /// A fuller label for the tap-to-read detail line (e.g. 'Tuesday',
  /// 'Tue 16', 'Jun 2026'). Falls back to [label] when null.
  final String? detail;
  const TimeBar(this.label, this.focus, {this.highlight = false, this.detail});

  String get readout => detail ?? label;
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

  /// Focus in the window immediately before this one (for the comparison line).
  /// Null for the all-time range, which has no "previous period".
  final Duration? previousTotal;
  final bool isEmpty;
  const AnalyticsData({
    required this.focusOverTime,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.byMode,
    required this.rangeTotal,
    required this.previousTotal,
    required this.isEmpty,
  });
}

/// Derives the Insights charts from focus history. Pure: no Flutter, no I/O.
/// "Now" is injected so every series is deterministically testable.
class AnalyticsCalculator {
  const AnalyticsCalculator();

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayAbbr = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const _weekdayFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
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
        bars.add(TimeBar(
          _monthAbbr[cursor.month - 1],
          focus,
          highlight: isCurrent,
          detail: '${_monthAbbr[cursor.month - 1]} ${cursor.year}',
        ));
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
      final detail = range == AnalyticsRange.week
          ? '${_weekdayAbbr[day.weekday - 1]} ${day.day}'
          : '${day.day} ${_monthAbbr[day.month - 1]}';
      bars.add(TimeBar(label, focus, highlight: i == 0, detail: detail));
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
    return _bars(_weekdayInitials, totals, details: _weekdayFull);
  }

  /// Focus in the window immediately before the current one (same length).
  /// Null for all-time (no preceding period).
  Duration? previousWindowTotal(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    if (range == AnalyticsRange.all) return null;
    final span = range == AnalyticsRange.week ? 7 : 30;
    final end = _dateOnly(now);
    final prevEnd = end.subtract(Duration(days: span));
    final prevStart = end.subtract(Duration(days: 2 * span - 1));
    return sessions
        .where((s) => s.recordedFocus > Duration.zero)
        .where((s) {
          final d = _dateOnly(s.startedAt);
          return !d.isBefore(prevStart) && !d.isAfter(prevEnd);
        })
        .fold<Duration>(Duration.zero, (a, s) => a + s.recordedFocus);
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

  /// Bucket boundaries mirroring [focusOverTime] (daily for week/month, monthly
  /// for all). Each bucket carries an exclusive upper bound for "as of" filters.
  List<({String label, String? detail, DateTime endExclusive})> _trendBuckets(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    if (range == AnalyticsRange.all) {
      final focused =
          sessions.where((s) => s.recordedFocus > Duration.zero).toList();
      if (focused.isEmpty) return const [];
      final first = focused
          .map((s) => s.startedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final endMonth = DateTime(now.year, now.month);
      final out = <({String label, String? detail, DateTime endExclusive})>[];
      var cursor = DateTime(first.year, first.month);
      while (!cursor.isAfter(endMonth)) {
        out.add((
          label: _monthAbbr[cursor.month - 1],
          detail: '${_monthAbbr[cursor.month - 1]} ${cursor.year}',
          endExclusive: DateTime(cursor.year, cursor.month + 1),
        ));
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
      return out;
    }
    final count = range == AnalyticsRange.week ? 7 : 30;
    final today = _dateOnly(now);
    final out = <({String label, String? detail, DateTime endExclusive})>[];
    for (var i = count - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      out.add((
        label: range == AnalyticsRange.week
            ? _weekdayInitials[day.weekday - 1]
            : '${day.day}',
        detail: range == AnalyticsRange.week
            ? '${_weekdayAbbr[day.weekday - 1]} ${day.day}'
            : '${day.day} ${_monthAbbr[day.month - 1]}',
        endExclusive: day.add(const Duration(days: 1)),
      ));
    }
    return out;
  }

  /// Focus Score (0–100) as of the end of each bucket (cumulative; null before
  /// the first scored Flow session). The hero number's trajectory.
  List<TrendPoint> focusScoreTrend(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    const calc = FocusScoreCalculator();
    final flow = sessions
        .where((s) =>
            s.mode == SessionMode.flowBlock && s.recordedFocus.inSeconds >= 120)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return [
      for (final b in _trendBuckets(range, now, sessions))
        () {
          final upto = flow
              .where((s) => s.startedAt.isBefore(b.endExclusive))
              .map((s) => (chosen: s.plannedDuration, actual: s.recordedFocus))
              .toList();
          return TrendPoint(b.label, upto.isEmpty ? null : calc.score(upto).toDouble(),
              detail: b.detail);
        }()
    ];
  }

  /// Focus Stamina (minutes) as of the end of each bucket (cumulative; null
  /// before the first completed Flow block). Climbs toward the 90-min ceiling.
  List<TrendPoint> staminaGrowth(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    const calc = StaminaCalculator();
    final blocks = sessions
        .where((s) =>
            s.mode == SessionMode.flowBlock && s.completed && !s.abandoned)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return [
      for (final b in _trendBuckets(range, now, sessions))
        () {
          final upto = blocks
              .where((s) => s.startedAt.isBefore(b.endExclusive))
              .map((s) => s.recordedFocus)
              .toList();
          return TrendPoint(
              b.label,
              upto.isEmpty
                  ? null
                  : calc.currentStamina(upto).inMinutes.toDouble(),
              detail: b.detail);
        }()
    ];
  }

  /// An honest "you focus best in the X" caption from [inRange] time-of-day, or
  /// null when there isn't enough signal (≥3 sessions and peak ≥25% of focus).
  String? peakWindowCaption(List<SessionRecord> inRange) {
    if (inRange.length < 3) return null;
    final tod = timeOfDay(inRange);
    final total = tod.fold(Duration.zero, (a, b) => a + b.focus);
    if (total == Duration.zero) return null;
    var peak = -1;
    var peakV = Duration.zero;
    for (var i = 0; i < tod.length; i++) {
      if (tod[i].focus > peakV) {
        peakV = tod[i].focus;
        peak = i;
      }
    }
    if (peak < 0 || peakV.inSeconds < total.inSeconds * 0.25) return null;
    const clocks = [
      '5–8am', '8am–12pm', '12–2pm', '2–5pm', '5–9pm', '9pm–5am' //
    ];
    return 'You focus best in the ${tod[peak].label} (${clocks[peak]}).';
  }

  /// Share of Flow sessions in the range that reached their mark, with the
  /// previous window's rate for a comparison line.
  FollowThrough followThrough(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    double rateOf(List<SessionRecord> ss) => ss.isEmpty
        ? 0
        : ss.where((s) => s.completed && !s.abandoned).length / ss.length;
    final inRange = sessionsInRange(range, now, sessions)
        .where((s) => s.mode == SessionMode.flowBlock)
        .toList();
    double? prev;
    if (range != AnalyticsRange.all) {
      final span = range == AnalyticsRange.week ? 7 : 30;
      final end = _dateOnly(now);
      final prevEnd = end.subtract(Duration(days: span));
      final prevStart = end.subtract(Duration(days: 2 * span - 1));
      final prevSessions = sessions
          .where((s) =>
              s.mode == SessionMode.flowBlock &&
              s.recordedFocus > Duration.zero)
          .where((s) {
        final d = _dateOnly(s.startedAt);
        return !d.isBefore(prevStart) && !d.isAfter(prevEnd);
      }).toList();
      prev = prevSessions.isEmpty ? null : rateOf(prevSessions);
    }
    return FollowThrough(rateOf(inRange), prev, inRange.length);
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
      previousTotal: previousWindowTotal(range, now, sessions),
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
  List<TimeBar> _bars(List<String> labels, List<Duration> totals,
      {List<String>? details}) {
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
            highlight: i == peak && peakVal > Duration.zero,
            detail: details != null ? details[i] : null)
    ];
  }
}
