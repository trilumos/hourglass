import 'focus_quotes.dart';
import 'focus_tips.dart';

/// One day's optional notification — a quote or a tip — ready to display.
class DailyNudge {
  final String title;
  final String body;
  const DailyNudge(this.title, this.body);
}

/// The full pool the daily "quotes & tips" notification rotates through: every
/// encouragement line (across all times of day, accent markers stripped) plus
/// the practical tips. Deterministic order so day-indexing rotates predictably.
List<DailyNudge> dailyNudgePool() {
  final out = <DailyNudge>[];
  for (final segment in TimeSegment.values) {
    for (final q in kEncouragements[segment] ?? const <FocusQuote>[]) {
      out.add(DailyNudge('A moment for focus', q.text.replaceAll('*', '')));
    }
  }
  for (final tip in kFocusTips) {
    out.add(DailyNudge('Focus tip', tip));
  }
  return out;
}

/// The nudge for a given day, rotating through the pool by [dayIndex] (e.g. the
/// day-of-epoch) so consecutive days differ and it wraps cleanly.
DailyNudge nudgeForDay(int dayIndex) {
  final pool = dailyNudgePool();
  return pool[dayIndex % pool.length];
}
