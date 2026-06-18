# Insights (Analytics) Page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single **Insights** page that merges the existing Activity screen with new analytics charts (focus-over-time, when-you-focus rhythm, by-mode), governed by a Week/Month/All toggle.

**Architecture:** A pure-Dart `AnalyticsCalculator` (domain layer, TDD) derives all series from `List<SessionRecord>`. A `StateProvider` holds the selected range; a `FutureProvider` recomputes the `AnalyticsData` on range/data change. Thin `fl_chart` wrapper widgets render bars/donut, themed entirely through existing tokens. `ActivityScreen` is reworked into `InsightsScreen`.

**Tech Stack:** Flutter, Riverpod, Drift (read-only here), fl_chart, flutter_test.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-06-18-hourglass-insights-analytics-design.md` (locked).
- All colors/sizes from tokens via `context.hg` + `HgSpacing`/`HgRadius`/`HgFont`/`HgSize`. **No hardcoded hex.** Mode/rhythm tints are opacity derivations of `accent`.
- Only sessions with `recordedFocus > Duration.zero` count. "Now" injected via `clockProvider`.
- Keep `flutter test` green (115 baseline) and `flutter analyze` clean.
- Build/run env: Flutter `D:\Dev\tools\flutter`, `JAVA_HOME` jdk-21, `MSYS_NO_PATHCONV=1`. Device V2521 `10MG18FQQG0008L`, adb at `C:\Users\morni\AppData\Local\Android\Sdk\platform-tools\adb.exe`, package `com.trilumos.hourglass`.
- Section order (locked): Records → Consistency(heatmap) → [toggle] → Focus over time → When you focus (Time of day, Day of week) → By mode.

---

### Task 1: Add fl_chart dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1:** Run `flutter pub add fl_chart` (resolves + pins latest stable).
- [ ] **Step 2:** Run `flutter pub get`; confirm no version conflicts.
- [ ] **Step 3:** Run `flutter analyze`; expect no new issues.
- [ ] **Step 4:** Commit. `git add pubspec.yaml pubspec.lock && git commit -m "build: add fl_chart"`

---

### Task 2: AnalyticsCalculator — value types + sessionsInRange + focusOverTime (TDD)

**Files:**
- Create: `lib/domain/analytics_calculator.dart`
- Test: `test/domain/analytics_calculator_test.dart`

**Interfaces:**
- Consumes: `SessionRecord` (`lib/domain/session_record.dart`), `SessionMode` (`lib/domain/session_mode.dart`).
- Produces: `enum AnalyticsRange { week, month, all }`; `class TimeBar { String label; Duration focus; bool highlight; }`; `class ModeSlice { SessionMode mode; Duration focus; double fraction; }`; `class AnalyticsData { List<TimeBar> focusOverTime, timeOfDay, dayOfWeek; List<ModeSlice> byMode; Duration rangeTotal; bool isEmpty; }`; `class AnalyticsCalculator` with `List<SessionRecord> sessionsInRange(...)`, `List<TimeBar> focusOverTime(...)`, `List<TimeBar> timeOfDay(...)`, `List<TimeBar> dayOfWeek(...)`, `List<ModeSlice> byMode(...)`, `AnalyticsData compute(...)`.

- [ ] **Step 1: Write failing tests** for value types + the two methods:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/analytics_calculator.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';

SessionRecord rec(DateTime at, Duration focus, {SessionMode mode = SessionMode.flowBlock}) =>
    SessionRecord(
      id: 0, startedAt: at, mode: mode, intention: '',
      plannedDuration: focus, recordedFocus: focus,
      completed: true, abandoned: false, autoContinue: false,
      soundscape: '', skinId: '',
    );

void main() {
  const calc = AnalyticsCalculator();
  final now = DateTime(2026, 6, 18, 10); // Thursday

  group('sessionsInRange', () {
    test('week keeps last 7 days inclusive, drops the 8th', () {
      final s = [
        rec(DateTime(2026, 6, 18), const Duration(minutes: 10)), // today
        rec(DateTime(2026, 6, 12), const Duration(minutes: 10)), // 6 days ago (in)
        rec(DateTime(2026, 6, 11), const Duration(minutes: 10)), // 7 days ago (out)
      ];
      expect(calc.sessionsInRange(AnalyticsRange.week, now, s).length, 2);
    });
    test('drops zero-focus sessions', () {
      final s = [rec(DateTime(2026, 6, 18), Duration.zero)];
      expect(calc.sessionsInRange(AnalyticsRange.all, now, s), isEmpty);
    });
    test('all keeps everything with focus', () {
      final s = [rec(DateTime(2024, 1, 1), const Duration(minutes: 5))];
      expect(calc.sessionsInRange(AnalyticsRange.all, now, s).length, 1);
    });
  });

  group('focusOverTime', () {
    test('week → 7 bars, last is today and highlighted', () {
      final bars = calc.focusOverTime(AnalyticsRange.week, now, [
        rec(DateTime(2026, 6, 18), const Duration(minutes: 30)),
      ]);
      expect(bars.length, 7);
      expect(bars.last.focus, const Duration(minutes: 30));
      expect(bars.last.highlight, isTrue);
      expect(bars.first.focus, Duration.zero);
    });
    test('month → 30 bars', () {
      expect(calc.focusOverTime(AnalyticsRange.month, now, []).length, 30);
    });
    test('all → one bar per month from first session to now', () {
      final bars = calc.focusOverTime(AnalyticsRange.all, now, [
        rec(DateTime(2026, 4, 10), const Duration(minutes: 10)),
      ]);
      expect(bars.length, 3); // Apr, May, Jun
      expect(bars.last.highlight, isTrue); // current month
    });
    test('all → empty when no sessions', () {
      expect(calc.focusOverTime(AnalyticsRange.all, now, []), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run** `flutter test test/domain/analytics_calculator_test.dart` → expect FAIL (type/class not defined).
- [ ] **Step 3: Implement** `lib/domain/analytics_calculator.dart` (value types + the two methods; remaining methods added in Tasks 3–4):

```dart
import 'session_mode.dart';
import 'session_record.dart';

enum AnalyticsRange { week, month, all }

/// One labeled bar — used by focus-over-time and both rhythm charts.
class TimeBar {
  final String label;
  final Duration focus;
  final bool highlight;
  const TimeBar(this.label, this.focus, {this.highlight = false});
}

class ModeSlice {
  final SessionMode mode;
  final Duration focus;
  final double fraction; // 0..1 of range total
  const ModeSlice(this.mode, this.focus, this.fraction);
}

class AnalyticsData {
  final List<TimeBar> focusOverTime;
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

class AnalyticsCalculator {
  const AnalyticsCalculator();

  static const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthAbbr = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<SessionRecord> sessionsInRange(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    final focused = sessions.where((s) => s.recordedFocus > Duration.zero);
    if (range == AnalyticsRange.all) return focused.toList();
    final end = _dateOnly(now);
    final days = range == AnalyticsRange.week ? 6 : 29;
    final start = end.subtract(Duration(days: days));
    return focused.where((s) {
      final d = _dateOnly(s.startedAt);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  List<TimeBar> focusOverTime(
      AnalyticsRange range, DateTime now, List<SessionRecord> sessions) {
    final inRange = sessionsInRange(range, now, sessions);
    if (range == AnalyticsRange.all) {
      if (inRange.isEmpty) return const [];
      final first = inRange
          .map((s) => s.startedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final bars = <TimeBar>[];
      var cursor = DateTime(first.year, first.month);
      final end = DateTime(now.year, now.month);
      while (!cursor.isAfter(end)) {
        final focus = inRange
            .where((s) =>
                s.startedAt.year == cursor.year &&
                s.startedAt.month == cursor.month)
            .fold(Duration.zero, (a, s) => a + s.recordedFocus);
        final isCurrent = cursor.year == end.year && cursor.month == end.month;
        bars.add(TimeBar(_monthAbbr[cursor.month - 1], focus,
            highlight: isCurrent));
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
      return bars;
    }
    // week (7) / month (30): one bar per day ending today.
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
}
```

- [ ] **Step 4: Run** the test file → expect PASS.
- [ ] **Step 5: Commit.** `git add lib/domain/analytics_calculator.dart test/domain/analytics_calculator_test.dart && git commit -m "feat(analytics): calculator value types + focusOverTime"`

---

### Task 3: timeOfDay + dayOfWeek (TDD)

**Files:**
- Modify: `lib/domain/analytics_calculator.dart`
- Modify: `test/domain/analytics_calculator_test.dart`

**Interfaces:**
- Consumes: value types from Task 2.
- Produces: `List<TimeBar> timeOfDay(List<SessionRecord> inRange)` (always 6, order Early·Morning·Midday·Afternoon·Evening·Night); `List<TimeBar> dayOfWeek(List<SessionRecord> inRange)` (always 7, Mon→Sun). Both take an already-range-filtered list. Peak bar (max focus > 0) has `highlight: true`, ties → first.

- [ ] **Step 1: Add failing tests:**

```dart
  group('timeOfDay', () {
    test('always 6 buckets in order; bucket boundaries', () {
      final bars = calc.timeOfDay([
        rec(DateTime(2026, 6, 18, 7, 59), const Duration(minutes: 10)),  // Early
        rec(DateTime(2026, 6, 18, 8, 0), const Duration(minutes: 30)),   // Morning
        rec(DateTime(2026, 6, 18, 23, 0), const Duration(minutes: 5)),   // Night
        rec(DateTime(2026, 6, 18, 4, 59), const Duration(minutes: 5)),   // Night
      ]);
      expect(bars.map((b) => b.label).toList(),
          ['Early', 'Morning', 'Midday', 'Afternoon', 'Evening', 'Night']);
      expect(bars[0].focus, const Duration(minutes: 10));
      expect(bars[1].focus, const Duration(minutes: 30));
      expect(bars[5].focus, const Duration(minutes: 10));
      expect(bars[1].highlight, isTrue); // Morning is the peak
    });
    test('empty → 6 zero bars, none highlighted', () {
      final bars = calc.timeOfDay([]);
      expect(bars.length, 6);
      expect(bars.any((b) => b.highlight), isFalse);
    });
  });

  group('dayOfWeek', () {
    test('always 7 Mon..Sun; peak highlighted', () {
      final bars = calc.dayOfWeek([
        rec(DateTime(2026, 6, 18), const Duration(minutes: 40)), // Thu
        rec(DateTime(2026, 6, 15), const Duration(minutes: 10)), // Mon
      ]);
      expect(bars.map((b) => b.label).toList(),
          ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      expect(bars[3].focus, const Duration(minutes: 40)); // Thu
      expect(bars[3].highlight, isTrue);
    });
  });
```

- [ ] **Step 2: Run** → FAIL (methods undefined).
- [ ] **Step 3: Implement** (add to `AnalyticsCalculator`):

```dart
  int _todBucket(int hour) {
    if (hour >= 5 && hour < 8) return 0;   // Early
    if (hour >= 8 && hour < 12) return 1;  // Morning
    if (hour >= 12 && hour < 14) return 2; // Midday
    if (hour >= 14 && hour < 17) return 3; // Afternoon
    if (hour >= 17 && hour < 21) return 4; // Evening
    return 5;                              // Night (21..04)
  }

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
        TimeBar(labels[i], totals[i], highlight: i == peak && peakVal > Duration.zero)
    ];
  }

  List<TimeBar> timeOfDay(List<SessionRecord> inRange) {
    const labels = ['Early', 'Morning', 'Midday', 'Afternoon', 'Evening', 'Night'];
    final totals = List.filled(6, Duration.zero);
    for (final s in inRange) {
      final i = _todBucket(s.startedAt.hour);
      totals[i] += s.recordedFocus;
    }
    return _bars(labels, totals);
  }

  List<TimeBar> dayOfWeek(List<SessionRecord> inRange) {
    final totals = List.filled(7, Duration.zero);
    for (final s in inRange) {
      totals[s.startedAt.weekday - 1] += s.recordedFocus;
    }
    return _bars(_weekdayInitials, totals);
  }
```

- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit.** `git commit -am "feat(analytics): timeOfDay + dayOfWeek"`

---

### Task 4: byMode + compute (TDD)

**Files:**
- Modify: `lib/domain/analytics_calculator.dart`, `test/domain/analytics_calculator_test.dart`

**Interfaces:**
- Produces: `List<ModeSlice> byMode(List<SessionRecord> inRange)` (always 3, order `[flowBlock, pomodoro, custom]`, `fraction` of total focus, 0 when total 0); `AnalyticsData compute(AnalyticsRange range, DateTime now, List<SessionRecord> sessions)`.

- [ ] **Step 1: Add failing tests:**

```dart
  group('byMode', () {
    test('always 3 in fixed order; fractions sum to ~1', () {
      final slices = calc.byMode([
        rec(DateTime(2026, 6, 18), const Duration(minutes: 60), mode: SessionMode.flowBlock),
        rec(DateTime(2026, 6, 18), const Duration(minutes: 20), mode: SessionMode.pomodoro),
      ]);
      expect(slices.map((s) => s.mode).toList(),
          [SessionMode.flowBlock, SessionMode.pomodoro, SessionMode.custom]);
      expect(slices[0].fraction, closeTo(0.75, 0.001));
      expect(slices[2].fraction, 0.0);
    });
    test('empty → all zero fractions', () {
      final slices = calc.byMode([]);
      expect(slices.every((s) => s.fraction == 0.0), isTrue);
    });
  });

  group('compute', () {
    test('isEmpty when no focus in range', () {
      final data = calc.compute(AnalyticsRange.week, now, []);
      expect(data.isEmpty, isTrue);
      expect(data.timeOfDay.length, 6);
      expect(data.byMode.length, 3);
    });
    test('rangeTotal sums in-range focus', () {
      final data = calc.compute(AnalyticsRange.week, now, [
        rec(DateTime(2026, 6, 18), const Duration(minutes: 25)),
      ]);
      expect(data.rangeTotal, const Duration(minutes: 25));
      expect(data.isEmpty, isFalse);
    });
  });
```

- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement:**

```dart
  List<ModeSlice> byMode(List<SessionRecord> inRange) {
    const order = [SessionMode.flowBlock, SessionMode.pomodoro, SessionMode.custom];
    final totals = {for (final m in order) m: Duration.zero};
    for (final s in inRange) {
      totals[s.mode] = totals[s.mode]! + s.recordedFocus;
    }
    final total = totals.values.fold(Duration.zero, (a, d) => a + d);
    return [
      for (final m in order)
        ModeSlice(m, totals[m]!,
            total > Duration.zero ? totals[m]!.inSeconds / total.inSeconds : 0.0)
    ];
  }

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
```

- [ ] **Step 4: Run** full file → PASS.
- [ ] **Step 5: Commit.** `git commit -am "feat(analytics): byMode + compute"`

---

### Task 5: Providers

**Files:**
- Modify: `lib/app/providers.dart`

**Interfaces:**
- Consumes: `AnalyticsCalculator`, `AnalyticsData`, `AnalyticsRange`, `sessionRepositoryProvider`, `clockProvider`.
- Produces: `analyticsRangeProvider` (StateProvider<AnalyticsRange>), `analyticsProvider` (FutureProvider<AnalyticsData>).

- [ ] **Step 1:** Add import `import '../domain/analytics_calculator.dart';` and at the end of the file:

```dart
/// Selected analytics window. Default: week.
final analyticsRangeProvider =
    StateProvider<AnalyticsRange>((ref) => AnalyticsRange.week);

/// All analytics series for the selected range.
final analyticsProvider = FutureProvider<AnalyticsData>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final now = ref.watch(clockProvider)();
  final range = ref.watch(analyticsRangeProvider);
  return const AnalyticsCalculator().compute(range, now, sessions);
});
```

- [ ] **Step 2:** Run `flutter analyze` → clean.
- [ ] **Step 3: Commit.** `git commit -am "feat(analytics): range + analytics providers"`

---

### Task 6: FocusTrendChart + RhythmBars widgets

**Files:**
- Create: `lib/ui/widgets/focus_trend_chart.dart`
- Create: `lib/ui/widgets/rhythm_bars.dart`

**Interfaces:**
- Consumes: `TimeBar`, `context.hg`, tokens, `fl_chart`.
- Produces: `FocusTrendChart({required List<TimeBar> bars, bool sparseLabels})`; `RhythmBars({required List<TimeBar> bars})`.

- [ ] **Step 1:** Implement `focus_trend_chart.dart`. Vertical bars; height ~160; today/current bar full `accent`, others `accent.withOpacity(0.55)`; rounded top; x labels from `bar.label`; when `sparseLabels` (month view), render a label only on first/middle/last index; y axis hidden; grid off; `BarTouchData` tooltip shows `formatFocusDuration(bar.focus)` (import from `../session_format.dart`). Empty list → `SizedBox.shrink()` (screen handles the "no focus" copy).

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/analytics_calculator.dart';
import '../session_format.dart';

class FocusTrendChart extends StatelessWidget {
  final List<TimeBar> bars;
  final bool sparseLabels;
  const FocusTrendChart({super.key, required this.bars, this.sparseLabels = false});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    if (bars.isEmpty) return const SizedBox.shrink();
    final maxY = bars
        .map((b) => b.focus.inMinutes.toDouble())
        .fold(1.0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: 160,
      child: BarChart(BarChartData(
        maxY: maxY * 1.15,
        alignment: BarChartAlignment.spaceBetween,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, r, ri) => BarTooltipItem(
              formatFocusDuration(bars[g.x].focus),
              TextStyle(fontFamily: HgFont.sans, fontSize: 12, color: hg.onAccent),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                if (sparseLabels &&
                    i != 0 && i != bars.length - 1 && i != bars.length ~/ 2) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(bars[i].label,
                      style: TextStyle(
                          fontFamily: HgFont.sans, fontSize: 10, color: hg.textMuted)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < bars.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: bars[i].focus.inMinutes.toDouble(),
                width: sparseLabels ? 5 : 12,
                borderRadius: BorderRadius.circular(3),
                color: bars[i].highlight ? hg.accent : hg.accent.withOpacity(0.55),
              )
            ]),
        ],
      )),
    );
  }
}
```

- [ ] **Step 2:** Implement `rhythm_bars.dart` — same `BarChart` shape, height ~140, peak bar full `accent`, others `accent.withOpacity(0.3)`, always show every label, same tooltip. (Copy the structure above; set bar color `bars[i].highlight ? hg.accent : hg.accent.withOpacity(0.3)`, `width: 14`, `sparseLabels` always false.)
- [ ] **Step 3:** Run `flutter analyze` → clean.
- [ ] **Step 4: Commit.** `git commit -m "feat(analytics): trend + rhythm bar charts"`

---

### Task 7: ModeDonut widget

**Files:**
- Create: `lib/ui/widgets/mode_donut.dart`

**Interfaces:**
- Consumes: `ModeSlice`, `SessionMode`, tokens, `fl_chart`.
- Produces: `ModeDonut({required List<ModeSlice> slices})` — donut + legend (swatch + name + `NN%`). Mode colors: flow `accent`, pomodoro `accent.withOpacity(0.55)`, custom `accent.withOpacity(0.3)`. Mode names: Flow Block / Pomodoro / Custom. If all fractions 0 → `SizedBox.shrink()`.

- [ ] **Step 1:** Implement with `PieChart(PieChartData(centerSpaceRadius: 38, sectionsSpace: 2, sections: [...]))`; a section per slice with `value: fraction`, `radius: 18`, `showTitle: false`; skip zero-fraction sections in the ring but still list them in the legend. Donut in a fixed `SizedBox(height: 150, width: 150)` (or `AspectRatio`) on the left, legend column on the right inside a `Row`. Legend `%` = `(fraction * 100).round()`.
- [ ] **Step 2:** Run `flutter analyze` → clean.
- [ ] **Step 3: Commit.** `git commit -m "feat(analytics): mode donut"`

---

### Task 8: InsightsScreen (rework ActivityScreen) + range toggle + empty states

**Files:**
- Create: `lib/ui/insights_screen.dart`
- Delete: `lib/ui/activity_screen.dart`
- Modify: `lib/ui/profile_screen.dart`

**Interfaces:**
- Consumes: `profileStatsProvider`, `dailyFocusProvider`, `analyticsProvider`, `analyticsRangeProvider`, `ContributionGraph`, `FocusTrendChart`, `RhythmBars`, `ModeDonut`, existing `StatTile`/`SurfaceTile`/`ScreenHeader`/`ScreenBackground`/`_Label` pattern, `formatFocusDuration`/`formatDate`.
- Produces: `InsightsScreen` (ConsumerWidget). Profile MORE shows one row → InsightsScreen.

- [ ] **Step 1:** Create `insights_screen.dart` rendering, in order: `ScreenHeader('Insights')`; **RECORDS** (the 6 `StatTile`s from current Activity "RECORDS" block: Total focus, Current streak `stats.streak`, Best streak, Avg session, Longest, Sessions `stats.totalSessions`; + "Focusing since" caption); **CONSISTENCY** label + `SurfaceTile(ContributionGraph(data: daily, today: now))`; a **range toggle** (`SegmentedButton<AnalyticsRange>` or a custom pill row reading/writing `analyticsRangeProvider`); then from `analyticsProvider.value` (`AnalyticsData? data`): **FOCUS OVER TIME** (`data.rangeTotal` caption via `formatFocusDuration` + `FocusTrendChart(bars: data.focusOverTime, sparseLabels: range == month)`), **WHEN YOU FOCUS** (`RhythmBars(data.timeOfDay)` then `RhythmBars(data.dayOfWeek)` with sub-labels "Time of day" / "Day of week"), **BY MODE** (`ModeDonut(data.byMode)`). For each toggled chart, when its series is empty / `data.isEmpty`, show a quiet `"No focus in this period."` line instead. When `profileStats.totalSessions == 0`, render only the header + one centered line `"Your insights appear as you focus. Begin your first block."` and skip the rest. Reuse the local `_Label` and `_row(a,b)` helpers from the old Activity screen (copy them in).
- [ ] **Step 2:** Delete `lib/ui/activity_screen.dart`.
- [ ] **Step 3:** In `profile_screen.dart`: replace the `import 'activity_screen.dart';` with `import 'insights_screen.dart';`; in the MORE section, **remove** the `_NavRow(title:'Activity'…)` + its Divider AND the `_NavRow(title:'Analytics', soon:true)`; **add** one row near the top of MORE: `_NavRow(title: 'Insights', subtitle: 'Charts of your focus', onTap: () => _push(context, const InsightsScreen()))`. Keep Session history + How Hourglass works rows.
- [ ] **Step 4:** Run `flutter analyze` → clean.
- [ ] **Step 5: Commit.** `git commit -m "feat(analytics): Insights screen, merge Activity, wire Profile"`

---

### Task 9: Widget smoke tests

**Files:**
- Create: `test/ui/insights_screen_test.dart`

- [ ] **Step 1:** Write tests pumping `InsightsScreen` wrapped in `ProviderScope(overrides: [...])` + `MaterialApp`. Override `sessionRepositoryProvider`/`clockProvider` (follow the pattern used by existing screen tests — check `test/` for the established harness). Case A: empty sessions → finds the "Begin your first block" copy. Case B: a populated session list → finds "RECORDS" and "FOCUS OVER TIME"; no exception. Case C: read `analyticsRangeProvider`, set it to `month`, pump, expect no throw.
- [ ] **Step 2:** Run `flutter test test/ui/insights_screen_test.dart` → PASS (fix until green).
- [ ] **Step 3: Commit.** `git commit -m "test(analytics): InsightsScreen smoke tests"`

---

### Task 10: Verify — full suite, analyze, device

**Files:** none (verification).

- [ ] **Step 1:** `flutter test` → all green (≥115 + new).
- [ ] **Step 2:** `flutter analyze` → clean.
- [ ] **Step 3:** Build + deploy the real app to the V2521 and open Profile → Insights:
```
flutter build apk --debug
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk
"$ADB" shell am start -n com.trilumos.hourglass/.MainActivity
```
- [ ] **Step 4:** Screenshot Insights (records, heatmap, toggle, trend, rhythm, donut). Confirm toggle switches series, empty states read well, nothing overflows.
- [ ] **Step 5: Commit** any fixes. Update `.remember/remember.md` + `docs/project-context.md` roadmap (mark Analytics done; record the Activity+Analytics→Insights merge decision). Push `master`.

---

## Self-Review

**Spec coverage:** merge into one page ✓ (T8); naming "Insights" ✓ (T8); entry point replaces both rows ✓ (T8); final order Records→Heatmap→toggle→Trend→Rhythm→Mode ✓ (T8); range windows ✓ (T2); 6 time buckets w/ boundaries ✓ (T3); day-of-week ✓ (T3); by-mode 3 fixed ✓ (T4); AnalyticsCalculator pure + TDD ✓ (T2–4); providers ✓ (T5); fl_chart token-driven widgets ✓ (T6–7); empty/low-data states ✓ (T8); responsiveness via ListView/LayoutBuilder + textScaler ✓ (T6–8 use width-flexible charts; verify T10); tests ✓ (T2–4, T9); delete activity_screen ✓ (T8); out-of-scope items excluded ✓.

**Placeholder scan:** Task 6 RhythmBars and Task 7 ModeDonut describe structure rather than full code — acceptable because they reuse Task 6 Step 1's complete `BarChart`/`PieChart` config with the stated color/width deltas; no "TBD"/"handle edge cases" left.

**Type consistency:** `TimeBar(label, focus, {highlight})`, `ModeSlice(mode, focus, fraction)`, `AnalyticsData` fields, `compute`/`focusOverTime`/`timeOfDay`/`dayOfWeek`/`byMode`/`sessionsInRange` signatures match across Tasks 2–8. `AnalyticsRange` values `week/month/all` consistent. `analyticsProvider`/`analyticsRangeProvider` names consistent T5↔T8.
