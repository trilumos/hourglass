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
    test('names the strongest weekday from the highlighted bar (Sun..Sat)', () {
      final bars = [
        const TimeBar('S', Duration.zero, detail: 'Sunday'),
        const TimeBar('M', Duration.zero, detail: 'Monday'),
        const TimeBar('T', Duration(minutes: 50),
            highlight: true, detail: 'Tuesday'),
        const TimeBar('W', Duration.zero, detail: 'Wednesday'),
        const TimeBar('T', Duration.zero, detail: 'Thursday'),
        const TimeBar('F', Duration.zero, detail: 'Friday'),
        const TimeBar('S', Duration.zero, detail: 'Saturday'),
      ];
      expect(InsightsCopy.dayOfWeekInsight(bars),
          'Tuesdays are your strongest day.');
    });
    test('null when no peak', () {
      expect(
          InsightsCopy.dayOfWeekInsight(
              const [TimeBar('S', Duration.zero, detail: 'Sunday')]),
          isNull);
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

  group('scoreTrendInsight', () {
    TrendPoint p(double? v) => TrendPoint('x', v);
    test('reports a climb', () {
      expect(InsightsCopy.scoreTrendInsight([p(60), p(70), p(84)]),
          'Your Focus Score climbed from 60 to 84.');
    });
    test('reports an ease back', () {
      expect(InsightsCopy.scoreTrendInsight([p(84), p(70)]),
          'Your Focus Score eased from 84 to 70.');
    });
    test('calls a flat line steady', () {
      expect(InsightsCopy.scoreTrendInsight([p(80), p(81)]),
          'Your Focus Score is holding steady around 81.');
    });
    test('a single point reads as sitting at', () {
      expect(InsightsCopy.scoreTrendInsight([p(null), p(72)]),
          'Your Focus Score is sitting at 72.');
    });
    test('null when no point has a value', () {
      expect(InsightsCopy.scoreTrendInsight([p(null), p(null)]), isNull);
      expect(InsightsCopy.scoreTrendInsight(const []), isNull);
    });
  });

  group('staminaInsight', () {
    TrendPoint p(double? v) => TrendPoint('x', v);
    test('reports growth in minutes', () {
      expect(InsightsCopy.staminaInsight([p(24), p(32)]),
          'Your sustainable block grew from 24 to 32 minutes.');
    });
    test('notes nearing the ceiling', () {
      expect(InsightsCopy.staminaInsight([p(82)]),
          'You can hold about 82 minutes of unbroken focus — nearing the 90-minute ceiling.');
    });
    test('null before any block', () {
      expect(InsightsCopy.staminaInsight([p(null)]), isNull);
    });
  });

  group('followThrough copy', () {
    test('frames the rate neutrally', () {
      expect(
          InsightsCopy.followThroughLine(const FollowThrough(0.82, null, 11)),
          '82% of your Flow sessions reached their mark.');
    });
    test('null when no sample', () {
      expect(InsightsCopy.followThroughLine(const FollowThrough(0, null, 0)),
          isNull);
    });
    test('comparison in percentage points', () {
      expect(
          InsightsCopy.followThroughComparison(
              const FollowThrough(0.82, 0.76, 11), 'last week'),
          '+6 pts vs last week');
    });
    test('comparison null without a prior window', () {
      expect(
          InsightsCopy.followThroughComparison(
              const FollowThrough(0.82, null, 11), ''),
          isNull);
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
