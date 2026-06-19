import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/analytics_calculator.dart';
import 'package:hourglass/domain/focus_score_calculator.dart';
import 'package:hourglass/domain/stamina_calculator.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';

SessionRecord rec(
  DateTime at, {
  Duration focus = const Duration(minutes: 25),
  Duration? planned,
  bool completed = true,
  bool abandoned = false,
  SessionMode mode = SessionMode.flowBlock,
}) =>
    SessionRecord(
      id: 0,
      startedAt: at,
      mode: mode,
      intention: '',
      plannedDuration: planned ?? focus,
      recordedFocus: focus,
      completed: completed,
      abandoned: abandoned,
      autoContinue: false,
      soundscape: '',
      skinId: '',
    );

void main() {
  const calc = AnalyticsCalculator();
  final now = DateTime(2026, 6, 18, 10); // Thursday

  group('focusScoreTrend', () {
    test('empty history → all-null (no buckets for all-range)', () {
      expect(calc.focusScoreTrend(AnalyticsRange.all, now, const []), isEmpty);
      // week always has 7 buckets, all null when no data
      final wk = calc.focusScoreTrend(AnalyticsRange.week, now, const []);
      expect(wk.length, 7);
      expect(wk.every((p) => p.value == null), isTrue);
    });

    test('last bucket equals FocusScoreCalculator over sessions so far', () {
      final sessions = [
        rec(DateTime(2026, 6, 16), focus: const Duration(minutes: 25)),
        rec(DateTime(2026, 6, 18), focus: const Duration(minutes: 40)),
      ];
      final trend = calc.focusScoreTrend(AnalyticsRange.week, now, sessions);
      final expected = const FocusScoreCalculator().score([
        (chosen: const Duration(minutes: 25), actual: const Duration(minutes: 25)),
        (chosen: const Duration(minutes: 40), actual: const Duration(minutes: 40)),
      ]).toDouble();
      expect(trend.last.value, expected);
      // buckets before the first session are null
      expect(trend.first.value, isNull);
    });

    test('ignores sub-2-min and non-Flow sessions', () {
      final sessions = [
        rec(DateTime(2026, 6, 17), focus: const Duration(seconds: 30)), // sub-2-min
        rec(DateTime(2026, 6, 17),
            focus: const Duration(minutes: 25), mode: SessionMode.pomodoro),
      ];
      final trend = calc.focusScoreTrend(AnalyticsRange.week, now, sessions);
      expect(trend.every((p) => p.value == null), isTrue);
    });
  });

  group('staminaGrowth', () {
    test('last bucket equals StaminaCalculator over completed blocks', () {
      final sessions = [
        rec(DateTime(2026, 6, 15), focus: const Duration(minutes: 20)),
        rec(DateTime(2026, 6, 17), focus: const Duration(minutes: 30)),
      ];
      final trend = calc.staminaGrowth(AnalyticsRange.week, now, sessions);
      final expected = const StaminaCalculator()
          .currentStamina(const [Duration(minutes: 20), Duration(minutes: 30)])
          .inMinutes
          .toDouble();
      expect(trend.last.value, expected);
    });

    test('the first recorded Flow session sets the baseline (even abandoned)',
        () {
      final sessions = [
        rec(DateTime(2026, 6, 17),
            focus: const Duration(minutes: 40),
            completed: false,
            abandoned: true), // first eligible → baseline 40
      ];
      final trend = calc.staminaGrowth(AnalyticsRange.week, now, sessions);
      expect(trend.last.value, 40.0);
    });

    test('a later early stop below current stamina does not lower it', () {
      final sessions = [
        rec(DateTime(2026, 6, 16), focus: const Duration(minutes: 30)),
        rec(DateTime(2026, 6, 17),
            focus: const Duration(minutes: 10),
            completed: false,
            abandoned: true), // 10 < 30 → ignored
      ];
      final trend = calc.staminaGrowth(AnalyticsRange.week, now, sessions);
      expect(trend.last.value, 30.0);
    });
  });

  group('peakWindowCaption', () {
    test('null below 3 sessions', () {
      final s = [rec(DateTime(2026, 6, 18, 9)), rec(DateTime(2026, 6, 18, 10))];
      expect(calc.peakWindowCaption(s), isNull);
    });

    test('names the dominant window when concentrated', () {
      final s = [
        rec(DateTime(2026, 6, 18, 9), focus: const Duration(minutes: 40)),
        rec(DateTime(2026, 6, 17, 9), focus: const Duration(minutes: 40)),
        rec(DateTime(2026, 6, 16, 9), focus: const Duration(minutes: 40)),
      ];
      final cap = calc.peakWindowCaption(s);
      expect(cap, isNotNull);
      expect(cap, contains('Morning'));
    });
  });

  group('followThrough', () {
    test('rate = completed / total Flow in range; sample counts both', () {
      final s = [
        rec(DateTime(2026, 6, 18)), // completed
        rec(DateTime(2026, 6, 17)), // completed
        rec(DateTime(2026, 6, 16)), // completed
        rec(DateTime(2026, 6, 15),
            focus: const Duration(minutes: 10), completed: false, abandoned: true),
      ];
      final ft = calc.followThrough(AnalyticsRange.week, now, s);
      expect(ft.sample, 4);
      expect(ft.rate, 0.75);
    });

    test('all-range has no previous rate', () {
      final ft = calc.followThrough(
          AnalyticsRange.all, now, [rec(DateTime(2026, 6, 18))]);
      expect(ft.prevRate, isNull);
      expect(ft.rate, 1.0);
    });
  });
}
