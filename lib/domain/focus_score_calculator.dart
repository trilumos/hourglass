import 'dart:math' as math;

/// Computes the Flow Block **Focus Score** — a 0–100 number reflecting the user's
/// current focus ability. Each session is scored 0–100 (weighted by length,
/// completion, and overflow); the Focus Score is the sum of the last 10 session
/// scores divided by 10 (divisor always 10), so it ramps over the first ~10
/// sessions and then becomes a rolling recent-10 average. See docs/superpowers/
/// specs/2026-06-16-flow-block-focus-score-design.md.
class FocusScoreCalculator {
  /// A completed block of this length scores 100 (the "perfect session" anchor).
  static const double perfectMinutes = 60;

  /// Depth-bonus scaling: per-minute value = 1 + length/depthD.
  static const double depthD = 100;

  /// Multiplier on minutes focused past the chosen length (the grit reward).
  static const double overflowMultiplier = 1.5;

  /// Sessions shorter than this don't count at all.
  static const double minMinutes = 2;

  /// Window for the rolling average / ramp.
  static const int window = 10;

  const FocusScoreCalculator();

  double _base(double minutes) => minutes + minutes * minutes / depthD;

  /// 0–100 score for a single Flow Block session.
  int sessionScore({required Duration chosen, required Duration actual}) {
    final a = actual.inSeconds / 60.0;
    final c = chosen.inSeconds / 60.0;
    if (a < minMinutes || c <= 0) return 0;
    final completion = math.min(a / c, 1.0);
    final overflow = a > c ? a - c : 0.0;
    final overflowRate = (1 + c / depthD) * overflowMultiplier;
    final raw = _base(c) * completion * completion + overflow * overflowRate;
    final scaled = raw / _base(perfectMinutes) * 100;
    return scaled.round().clamp(0, 100);
  }

  /// Focus Score (0–100) from Flow Block sessions, oldest → newest. Sessions
  /// under [minMinutes] are ignored (they take no slot); the last [window] of
  /// the rest are summed and divided by [window].
  int score(List<({Duration chosen, Duration actual})> sessions) {
    final valid = sessions
        .where((s) => s.actual.inSeconds / 60.0 >= minMinutes)
        .toList();
    final recent =
        valid.length <= window ? valid : valid.sublist(valid.length - window);
    final sum = recent.fold<int>(
        0, (s, x) => s + sessionScore(chosen: x.chosen, actual: x.actual));
    return (sum / window).round().clamp(0, 100);
  }
}
