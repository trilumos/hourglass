import '../domain/analytics_calculator.dart';
import '../domain/session_mode.dart';

/// Warm, plain-language copy for the Insights page. Static descriptors say what
/// a chart is; the insight one-liners are generated from real data and read
/// like a thoughtful companion. Each insight returns null when there isn't
/// enough signal to say something true — the screen then shows just the chart.
///
/// Voice per docs/design-language.md §6: warm, present, encouraging, never
/// hustle-y; short; no emoji, no fabricated stats.
class InsightsCopy {
  const InsightsCopy._();

  // ── Static section descriptors ────────────────────────────────────────────
  static const records = "Everything you've built so far.";
  static const consistency = 'Every focused day, lately. Darker means deeper.';
  static const focusOverTime = 'How your focus rises and dips over time.';
  static const whenYouFocus = 'The times and days you tend to go deep.';
  static const byMode = 'How your focus splits across the three modes.';

  // ── Personalized insight lines (null = not enough signal) ──────────────────

  /// "You've shown up 12 of the last 30 days."
  static String? consistencyInsight(int activeDaysLast30) {
    if (activeDaysLast30 <= 0) return null;
    return "You've shown up $activeDaysLast30 of the last 30 days.";
  }

  /// "{4h 20m} of focus this week." — the warm framing of the range total.
  static String focusTotal(String formattedTotal, String periodWord) =>
      '$formattedTotal of focus $periodWord.';

  /// "+18% vs last week" / "−12% vs last month" / "about the same as last week".
  /// Null when there's no honest comparison (all-time, or no prior baseline).
  static String? comparison(
      Duration current, Duration? previous, String previousNoun) {
    if (previous == null || previous == Duration.zero) return null;
    final pct = ((current.inSeconds - previous.inSeconds) /
            previous.inSeconds *
            100)
        .round();
    if (pct.abs() < 3) return 'about the same as $previousNoun';
    if (pct > 0) return '+$pct% vs $previousNoun';
    return '−${pct.abs()}% vs $previousNoun'; // proper minus sign
  }

  /// "You go deepest in the mornings." from the peak time-of-day bar.
  static String? timeOfDayInsight(List<TimeBar> bars) {
    final peak = _peak(bars);
    if (peak == null) return null;
    final phrase = switch (peak.label) {
      'Early' => 'the early hours',
      'Morning' => 'the mornings',
      'Midday' => 'the middle of the day',
      'Afternoon' => 'the afternoons',
      'Evening' => 'the evenings',
      'Night' => 'the late hours',
      _ => peak.label.toLowerCase(),
    };
    return 'You go deepest in $phrase.';
  }

  /// "Tuesdays are your strongest day." from the peak weekday (bars are Mon→Sun).
  static String? dayOfWeekInsight(List<TimeBar> bars) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', //
      'Friday', 'Saturday', 'Sunday'
    ];
    for (var i = 0; i < bars.length && i < days.length; i++) {
      if (bars[i].highlight) return '${days[i]}s are your strongest day.';
    }
    return null;
  }

  /// "You're a Flow Block person." from the dominant mode.
  static String? modeInsight(List<ModeSlice> slices) {
    ModeSlice? top;
    for (final s in slices) {
      if (s.fraction > 0 && (top == null || s.fraction > top.fraction)) {
        top = s;
      }
    }
    if (top == null) return null;
    return switch (top.mode) {
      SessionMode.flowBlock => "You're a Flow Block person.",
      SessionMode.pomodoro => 'Pomodoro is your go-to.',
      SessionMode.custom => 'Custom sessions are your go-to.',
    };
  }

  static TimeBar? _peak(List<TimeBar> bars) {
    for (final b in bars) {
      if (b.highlight) return b;
    }
    return null;
  }
}
