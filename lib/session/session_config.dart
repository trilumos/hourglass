import '../domain/session_mode.dart';

/// Immutable configuration chosen on the setup screen before a session starts.
class SessionConfig {
  final SessionMode mode;
  final Duration plannedDuration;
  final bool autoContinue;
  final String intention;
  final String soundscape;
  final String skinId;

  const SessionConfig({
    required this.mode,
    required this.plannedDuration,
    required this.autoContinue,
    required this.intention,
    required this.soundscape,
    required this.skinId,
  });
}
