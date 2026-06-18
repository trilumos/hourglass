import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/analytics_calculator.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/ui/insights_copy.dart';

void main() {
  group('consistencyInsight', () {
    test('reports active days', () {
      expect(InsightsCopy.consistencyInsight(12),
          "You've shown up 12 of the last 30 days.");
    });
    test('null when no active days', () {
      expect(InsightsCopy.consistencyInsight(0), isNull);
    });
  });

  group('timeOfDayInsight', () {
    test('names the peak part of day', () {
      final bars = [
        const TimeBar('Early', Duration(minutes: 5)),
        const TimeBar('Morning', Duration(minutes: 40), highlight: true),
        const TimeBar('Midday', Duration.zero),
        const TimeBar('Afternoon', Duration.zero),
        const TimeBar('Evening', Duration.zero),
        const TimeBar('Night', Duration.zero),
      ];
      expect(InsightsCopy.timeOfDayInsight(bars),
          'You go deepest in the mornings.');
    });
    test('null when no peak', () {
      final bars = [
        const TimeBar('Early', Duration.zero),
        const TimeBar('Morning', Duration.zero),
      ];
      expect(InsightsCopy.timeOfDayInsight(bars), isNull);
    });
  });

  group('dayOfWeekInsight', () {
    test('names the strongest weekday (bars Mon..Sun)', () {
      final bars = [
        const TimeBar('M', Duration.zero),
        const TimeBar('T', Duration(minutes: 50), highlight: true), // Tuesday
        const TimeBar('W', Duration.zero),
        const TimeBar('T', Duration.zero),
        const TimeBar('F', Duration.zero),
        const TimeBar('S', Duration.zero),
        const TimeBar('S', Duration.zero),
      ];
      expect(InsightsCopy.dayOfWeekInsight(bars),
          'Tuesdays are your strongest day.');
    });
  });

  group('modeInsight', () {
    test('names the dominant mode', () {
      final slices = [
        const ModeSlice(SessionMode.flowBlock, Duration(minutes: 60), 0.7),
        const ModeSlice(SessionMode.pomodoro, Duration(minutes: 20), 0.3),
        const ModeSlice(SessionMode.custom, Duration.zero, 0.0),
      ];
      expect(InsightsCopy.modeInsight(slices), "You're a Flow person.");
    });
    test('null when there is no focus', () {
      final slices = [
        const ModeSlice(SessionMode.flowBlock, Duration.zero, 0.0),
        const ModeSlice(SessionMode.pomodoro, Duration.zero, 0.0),
        const ModeSlice(SessionMode.custom, Duration.zero, 0.0),
      ];
      expect(InsightsCopy.modeInsight(slices), isNull);
    });
  });

  group('focusTotal', () {
    test('frames the range total warmly', () {
      expect(InsightsCopy.focusTotal('4h 20m', 'this week'),
          '4h 20m of focus this week.');
    });
  });

  group('comparison', () {
    test('reports an increase', () {
      expect(
        InsightsCopy.comparison(
            const Duration(minutes: 118), const Duration(minutes: 100), 'last week'),
        '+18% vs last week',
      );
    });
    test('reports a decrease with a real minus sign', () {
      expect(
        InsightsCopy.comparison(
            const Duration(minutes: 80), const Duration(minutes: 100), 'last week'),
        '−20% vs last week',
      );
    });
    test('calls small changes about the same', () {
      expect(
        InsightsCopy.comparison(
            const Duration(minutes: 101), const Duration(minutes: 100), 'last month'),
        'about the same as last month',
      );
    });
    test('null when no prior baseline or all-time', () {
      expect(
          InsightsCopy.comparison(
              const Duration(minutes: 50), Duration.zero, 'last week'),
          isNull);
      expect(
          InsightsCopy.comparison(const Duration(minutes: 50), null, 'last week'),
          isNull);
    });
  });
}
