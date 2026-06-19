import 'dart:math';

/// Part of the day, used to pick the greeting word and the matching set of
/// encouragement lines.
enum TimeSegment { morning, afternoon, evening, lateNight }

/// A short teaching shown under the greeting.
///
/// [author] is null for original Hourglass lines. Real, attributed quotes may
/// be added later — but ONLY with a verified source (the brand's honesty rule
/// forbids misattribution and fabricated science).
class FocusQuote {
  final String text;
  final String? author;
  const FocusQuote(this.text, {this.author});
}

/// The time-of-day band for [t] (uses the local hour).
TimeSegment segmentFor(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 12) return TimeSegment.morning;
  if (h >= 12 && h < 17) return TimeSegment.afternoon;
  if (h >= 17 && h < 22) return TimeSegment.evening;
  return TimeSegment.lateNight; // 22, 23, 0–4
}

/// Time-of-day greeting words for [t].
List<String> _timeGreetings(TimeSegment segment) {
  switch (segment) {
    case TimeSegment.morning:
      return const ['Good morning', 'Morning', 'Rise and focus'];
    case TimeSegment.afternoon:
      return const ['Good afternoon', 'Afternoon'];
    case TimeSegment.evening:
      return const ['Good evening', 'Evening'];
    case TimeSegment.lateNight:
      return const ['Burning the midnight oil', 'The quiet hours', 'Still going'];
  }
}

/// Warm, varied greetings for any time (the Claude-new-chat feel) — used for
/// returning users alongside the time-aware ones.
const _anyTimeGreetings = <String>[
  'Welcome back',
  'Back at it',
  'Good to see you',
  'Ready when you are',
  "Let's get focused",
  'Pick up where you left off',
  'Keep going',
];

/// Greetings for a brand-new user (no completed blocks yet).
const _newUserGreetings = <String>[
  'Welcome',
  "Let's begin",
  'Your first block awaits',
];

const _exclaimGreetings = <String>{
  'Back at it',
  "Let's get focused",
  "Let's begin",
  'Keep going',
  'Rise and focus',
  'Keep the streak alive',
};
const _questionGreetings = <String>{
  'Burning the midnight oil',
  'Still going',
  'Ready when you are',
};

/// The ending punctuation for [greeting] (varies the tone: '!', '?' or '.').
String greetingPunctuation(String greeting) {
  if (_exclaimGreetings.contains(greeting)) return '!';
  if (_questionGreetings.contains(greeting)) return '?';
  return '.';
}

/// The pool of greetings appropriate to the moment. Chosen fresh each open
/// (no name yet — name lands with onboarding). Never empty.
List<String> greetingCandidates(
  DateTime t, {
  required bool isNewUser,
  int streak = 0,
}) {
  if (isNewUser) return _newUserGreetings;
  return [
    ..._timeGreetings(segmentFor(t)),
    ..._anyTimeGreetings,
    if (streak >= 2) 'Keep the streak alive',
  ];
}

/// Curated encouragement lines, segmented by time of day. One coherent tone:
/// focus / flow fused with the value of time, with each segment's own energy.
/// All original (unattributed) for now — see [FocusQuote].
///
/// One word per line is wrapped in `*asterisks*` — the UI renders that word in
/// the accent color for a subtle highlight.
const Map<TimeSegment, List<FocusQuote>> kEncouragements = {
  TimeSegment.morning: [
    FocusQuote('The morning is *yours*. Spend it on what matters most.'),
    FocusQuote('*Begin* before the world gets loud.'),
    FocusQuote('One *deep* block now beats a scattered afternoon.'),
    FocusQuote('*Protect* the first hour and the rest will follow.'),
    FocusQuote('A clear mind and a quiet room. *Start* here.'),
    FocusQuote('Focus is a *muscle*. Time to warm it up.'),
    FocusQuote('Time spent is *never* returned. Spend this one well.'),
    FocusQuote('Start *deep*, and the day stays deep.'),
    FocusQuote("Guard your *attention*; it is the day's true currency."),
    FocusQuote('A focused morning is a *gift* to your evening self.'),
  ],
  TimeSegment.afternoon: [
    FocusQuote('The afternoon rewards those who *return* to the work.'),
    FocusQuote('One more block. The dip always *passes*.'),
    FocusQuote('Trade the scroll for a single *finished* thing.'),
    FocusQuote('*Depth* beats busy. Choose one task.'),
    FocusQuote('*Momentum* is built one block at a time.'),
    FocusQuote('An hour of focus *outlasts* a day of distraction.'),
    FocusQuote('The slump is a *signal*, not a verdict. Begin again.'),
    FocusQuote('Small blocks, stacked, become a *finished* day.'),
    FocusQuote('Energy follows *attention*. Point it somewhere worthy.'),
  ],
  TimeSegment.evening: [
    FocusQuote('A quiet evening is made for *deep* work.'),
    FocusQuote("End the day with something you're *proud* of."),
    FocusQuote('The distractions are winding down. Now is *yours*.'),
    FocusQuote('One focused hour tonight *changes* tomorrow.'),
    FocusQuote('Slow is smooth, and smooth is *focused*.'),
    FocusQuote('You can make more money, never more *time*.'),
    FocusQuote('Close the day with *intention*, not just fatigue.'),
    FocusQuote('Finish one thing, and rest will feel *earned*.'),
    FocusQuote("Tonight's focus quietly shapes *tomorrow*."),
  ],
  TimeSegment.lateNight: [
    FocusQuote('Burn the midnight oil, but burn it on what *counts*.'),
    FocusQuote('The world is quiet. Your focus can be *loud*.'),
    FocusQuote("Late nights are for the work that won't *wait*."),
    FocusQuote('Few are awake. Fewer are this *focused*.'),
    FocusQuote('Make these hours *count*, then rest well.'),
    FocusQuote('Lost time is never found again. *Use* this hour.'),
    FocusQuote('While the world sleeps, your *attention* is undivided.'),
    FocusQuote('Rest is part of the work. Focus now, then *recover*.'),
    FocusQuote('Let the stillness make your work *sharp*.'),
  ],
};

/// Picks the next index uniformly among the [count] items, never returning
/// [previous] (so the same line is never shown twice in a row).
int nextQuoteIndex(int? previous, int count, Random rng) {
  if (count <= 1) return 0;
  if (previous == null) return rng.nextInt(count);
  final r = rng.nextInt(count - 1);
  return r < previous ? r : r + 1;
}
