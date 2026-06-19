import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/analytics_calculator.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';

SessionRecord rec(DateTime at, Duration focus,
        {SessionMode mode = SessionMode.flowBlock}) =>
    SessionRecord(
      id: 0,
      startedAt: at,
      mode: mode,
      intention: '',
      plannedDuration: focus,
      recordedFocus: focus,
      completed: true,
      abandoned: false,
      autoContinue: false,
      soundscape: '',
      skinId: '',
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
      expect(bars.first.label, 'Apr');
      expect(bars.last.label, 'Jun');
      expect(bars.last.highlight, isTrue); // current month
    });
    test('all → empty when no sessions', () {
      expect(calc.focusOverTime(AnalyticsRange.all, now, []), isEmpty);
    });
  });

  group('timeOfDay', () {
    test('always 6 buckets in order; bucket boundaries', () {
      final bars = calc.timeOfDay([
        rec(DateTime(2026, 6, 18, 7, 59), const Duration(minutes: 10)), // Early
        rec(DateTime(2026, 6, 18, 8, 0), const Duration(minutes: 30)), // Morning
        rec(DateTime(2026, 6, 18, 23, 0), const Duration(minutes: 5)), // Night
        rec(DateTime(2026, 6, 18, 4, 59), const Duration(minutes: 5)), // Night
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
    test('always 7 Sun..Sat (week starts Sunday); peak highlighted', () {
      final bars = calc.dayOfWeek([
        rec(DateTime(2026, 6, 18), const Duration(minutes: 40)), // Thu
        rec(DateTime(2026, 6, 15), const Duration(minutes: 10)), // Mon
      ]);
      expect(bars.map((b) => b.label).toList(),
          ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
      expect(bars[4].focus, const Duration(minutes: 40)); // Thu = index 4
      expect(bars[4].highlight, isTrue);
      expect(bars[4].readout, 'Thursday'); // full-name detail for the readout
      expect(bars[1].focus, const Duration(minutes: 10)); // Mon = index 1
    });
  });

  group('previousWindowTotal', () {
    test('week sums the prior 7-day window only', () {
      final s = [
        rec(DateTime(2026, 6, 18), const Duration(minutes: 10)), // this week
        rec(DateTime(2026, 6, 13), const Duration(minutes: 20)), // 5 days ago: this week
        rec(DateTime(2026, 6, 12), const Duration(minutes: 30)), // 6 days ago: this week
        rec(DateTime(2026, 6, 11), const Duration(minutes: 40)), // 7 days ago: prev week
        rec(DateTime(2026, 6, 5), const Duration(minutes: 50)), // 13 days ago: prev week
        rec(DateTime(2026, 6, 4), const Duration(minutes: 99)), // 14 days ago: out
      ];
      expect(calc.previousWindowTotal(AnalyticsRange.week, now, s),
          const Duration(minutes: 90)); // 40 + 50
    });
    test('all-time has no previous window', () {
      expect(calc.previousWindowTotal(AnalyticsRange.all, now, []), isNull);
    });
    test('compute carries previousTotal', () {
      final data = calc.compute(AnalyticsRange.week, now, [
        rec(DateTime(2026, 6, 11), const Duration(minutes: 25)),
      ]);
      expect(data.previousTotal, const Duration(minutes: 25));
    });
  });

  group('byMode', () {
    test('always 3 in fixed order; fractions sum to ~1', () {
      final slices = calc.byMode([
        rec(DateTime(2026, 6, 18), const Duration(minutes: 60),
            mode: SessionMode.flowBlock),
        rec(DateTime(2026, 6, 18), const Duration(minutes: 20),
            mode: SessionMode.pomodoro),
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
      expect(data.dayOfWeek.length, 7);
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
}
