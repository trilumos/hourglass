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

  const SessionConfig({
    required this.mode,
    required this.plan,
    required this.autoContinue,
    required this.intention,
    required this.soundscape,
    required this.skinId,
  });

  /// Total planned focus time across the plan's focus segments.
  Duration get plannedFocus => plan.totalFocus;
}
