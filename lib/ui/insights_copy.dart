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
  static const focusScore = 'The depth of your focus, traced over time (0 to 100).';
  static const stamina =
      'The length of deep focus you can hold in one unbroken block.';
  static const followThrough = 'How often your Flow sessions reach their mark.';
  static const personalBests = 'Your records so far. Each one really happened.';
  static const dataExport = 'Your history is yours. Take a copy with you.';
  static const reportExport =
      'A clean PDF of your whole focus story — score, records, and bests.';

  // ── What feeds each section (the Flow-only vs all-modes distinction) ────────
  /// One-line legend at the top of the depth band.
  static const sourceLegend =
      'Focus Score, Stamina and Follow-through follow your Flow sessions only. '
      'Everything else counts Flow, Pomodoro and Custom.';

  /// The small tag shown on Flow-only sections.
  static const flowOnlyTag = 'FLOW ONLY';

  /// Precise per-section data rules (shown under the descriptor).
  static const focusScoreSource = 'Counts Flow sessions of 2 minutes or more.';
  static const staminaSource =
      'Starts at your first recorded Flow session, then rises when you finish a '
      'block or beat your current stamina.';

  // Honest empty lines — shown in place of a chart when there's no real series.
  static const scoreEmpty =
      'Your Focus Score trend appears once you finish a few Flow sessions.';

  /// Why the Focus Score line looks nearly flat over a short window: it's a
  /// rolling average of recent Flow sessions, so it moves gradually. Shown for
  /// Week/Month; the All range reveals the full arc.
  static const scoreSlowNote =
      "Focus Score is a rolling average of your recent Flow sessions, so it "
      "moves gently over a short window. Switch to All for the full arc.";
  static const staminaEmpty =
      'Your stamina line appears after your first recorded Flow session, then '
      'grows with you.';

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

  /// "Tuesdays are your strongest day." from the highlighted weekday bar, using
  /// its full-name detail so it's independent of the bars' order.
  static String? dayOfWeekInsight(List<TimeBar> bars) {
    for (final b in bars) {
      if (b.highlight) return '${b.readout}s are your strongest day.';
    }
    return null;
  }

  /// "You're a Flow person." from the dominant mode.
  static String? modeInsight(List<ModeSlice> slices) {
    ModeSlice? top;
    for (final s in slices) {
      if (s.fraction > 0 && (top == null || s.fraction > top.fraction)) {
        top = s;
      }
    }
    if (top == null) return null;
    return switch (top.mode) {
      SessionMode.flowBlock => "You're a Flow person.",
      SessionMode.pomodoro => 'Pomodoro is your go-to.',
      SessionMode.custom => 'Custom sessions are your go-to.',
    };
  }

  /// The trajectory of the Focus Score across the visible range, in plain words.
  /// Null when no bucket has a score yet (the chart shows [scoreEmpty] instead).
  static String? scoreTrendInsight(List<TrendPoint> points) {
    final vals = [
      for (final p in points)
        if (p.value != null) p.value!.round()
    ];
    if (vals.isEmpty) return null;
    final last = vals.last;
    if (vals.length == 1) return 'Your Focus Score is sitting at $last.';
    final delta = last - vals.first;
    if (delta >= 3) return 'Your Focus Score climbed from ${vals.first} to $last.';
    if (delta <= -3) return 'Your Focus Score eased from ${vals.first} to $last.';
    return 'Your Focus Score is holding steady around $last.';
  }

  /// The trajectory of Focus Stamina (minutes) in plain words. Null when no
  /// bucket has a value (the chart shows [staminaEmpty] instead).
  static String? staminaInsight(List<TrendPoint> points) {
    final vals = [
      for (final p in points)
        if (p.value != null) p.value!.round()
    ];
    if (vals.isEmpty) return null;
    final last = vals.last;
    // 90 min is a reference, not a cap — note approaching it, and surpassing it.
    final mark = last >= 90
        ? ' (past the 90-minute deep-work mark)'
        : last >= 75
            ? ' (nearing the 90-minute mark)'
            : '';
    if (vals.length == 1) {
      return 'You can hold about $last minutes of unbroken focus$mark.';
    }
    final delta = last - vals.first;
    if (delta >= 2) {
      return 'Your sustainable block grew from ${vals.first} to $last minutes$mark.';
    }
    if (delta <= -2) {
      return 'Your sustainable block eased from ${vals.first} to $last minutes.';
    }
    return "You're holding around $last minutes of unbroken focus$mark.";
  }

  /// "82% of your Flow sessions reached their mark." Null when no Flow sample.
  static String? followThroughLine(FollowThrough ft) {
    if (ft.sample <= 0) return null;
    return '${(ft.rate * 100).round()}% of your Flow sessions reached their mark.';
  }

  /// The follow-through comparison sub-line, in percentage points (honest: a
  /// rate vs a rate). Null for all-time or when there's no prior window.
  static String? followThroughComparison(FollowThrough ft, String previousNoun) {
    final prev = ft.prevRate;
    if (prev == null) return null;
    final pts = ((ft.rate - prev) * 100).round();
    if (pts.abs() < 3) return 'about the same as $previousNoun';
    if (pts > 0) return '+$pts pts vs $previousNoun';
    return '−${pts.abs()} pts vs $previousNoun'; // proper minus sign
  }

  static TimeBar? _peak(List<TimeBar> bars) {
    for (final b in bars) {
      if (b.highlight) return b;
    }
    return null;
  }
}
