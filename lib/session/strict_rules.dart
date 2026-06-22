/// The strict anti-abuse session rules (pure, no Flutter) — what a free vs Pro
/// user gets for pausing and for leaving the app mid-block, and the grace-window
/// decisions. The UI drives timers/notifications from these values and asks the
/// decision methods what to do; this keeps the policy testable in one place.
///
/// See docs/superpowers/specs/2026-06-22-strict-sessions-and-monetization-design.md.
class StrictRules {
  /// Max manual pauses per session; null = unlimited (Pro).
  final int? pauseLimit;

  /// Longest a single pause may last before its grace begins.
  final Duration pauseCap;

  /// Grace after the pause cap is hit ("return within 15s to keep your block").
  final Duration capGrace;

  /// Grace after leaving the app while *running* ("come back, 30s").
  final Duration leaveGrace;

  const StrictRules({
    required this.pauseLimit,
    required this.pauseCap,
    required this.capGrace,
    required this.leaveGrace,
  });

  static const free = StrictRules(
    pauseLimit: 3,
    pauseCap: Duration(minutes: 3),
    capGrace: Duration(seconds: 15),
    leaveGrace: Duration(seconds: 30),
  );

  static const pro = StrictRules(
    pauseLimit: null, // unlimited
    pauseCap: Duration(minutes: 10),
    capGrace: Duration(seconds: 15),
    leaveGrace: Duration(seconds: 30),
  );

  static StrictRules forPro(bool isPro) => isPro ? pro : free;

  bool get unlimitedPauses => pauseLimit == null;

  /// Pauses still available given how many were already used this session.
  /// Returns null when unlimited.
  int? remainingPauses(int used) =>
      pauseLimit == null ? null : (pauseLimit! - used).clamp(0, pauseLimit!);

  /// A running block that was away (backgrounded) longer than the leave grace
  /// is lost.
  bool endAfterAwayRunning(Duration away) => away > leaveGrace;

  /// A pause is lost once total paused time exceeds the cap PLUS its grace.
  bool endAfterPaused(Duration totalPaused) => totalPaused > pauseCap + capGrace;

  /// Whether [totalPaused] has entered the post-cap grace window (cap hit, grace
  /// not yet expired) — when the "return within 15s" prompt should be showing.
  bool inCapGrace(Duration totalPaused) =>
      totalPaused > pauseCap && totalPaused <= pauseCap + capGrace;
}
