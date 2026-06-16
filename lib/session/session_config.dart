import '../domain/session_mode.dart';
import 'session_plan.dart';

/// Immutable configuration chosen on the setup screen before a session starts.
/// The [plan] is the sequence of focus/rest segments to run.
class SessionConfig {
  final SessionMode mode;
  final SessionPlan plan;
  final bool autoContinue;
  final String intention;
  final String soundscape;
  final String skinId;

  /// When false, the session pauses after each break and waits for the user to
  /// start the next focus block ("tap to continue"). When true (default), the
  /// next focus block begins automatically. A user-level preference.
  final bool autoAdvanceBreaks;

  const SessionConfig({
    required this.mode,
    required this.plan,
    required this.autoContinue,
    required this.intention,
    required this.soundscape,
    required this.skinId,
    this.autoAdvanceBreaks = true,
  });

  /// Total planned focus time across the plan's focus segments.
  Duration get plannedFocus => plan.totalFocus;
}
