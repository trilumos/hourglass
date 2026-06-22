/// A ritual transition in a session that may play a sound cue. Domain-level and
/// audio-agnostic — the UI maps each to an actual sound (or ignores it). Kept
/// out of the audio layer so [SessionController] stays pure.
enum SessionCue {
  /// A session has just begun.
  started,

  /// A focus block ended and a break has begun.
  breakStarted,

  /// A break ended (work resumes, or parks at the tap-to-continue wait point).
  breakEnded,

  /// The session reached its natural end (or an endless block was ended).
  finished,
}
