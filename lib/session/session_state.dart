import '../domain/focus_phase.dart';

enum SessionStatus { idle, running, paused, finished }

/// Immutable snapshot of the live session, consumed by the UI.
class SessionState {
  final SessionStatus status;
  final Duration elapsed;
  final FocusPhase phase;
  final bool goalReached;

  const SessionState({
    required this.status,
    required this.elapsed,
    required this.phase,
    required this.goalReached,
  });

  factory SessionState.initial() => const SessionState(
        status: SessionStatus.idle,
        elapsed: Duration.zero,
        phase: FocusPhase.struggle,
        goalReached: false,
      );

  SessionState copyWith({
    SessionStatus? status,
    Duration? elapsed,
    FocusPhase? phase,
    bool? goalReached,
  }) =>
      SessionState(
        status: status ?? this.status,
        elapsed: elapsed ?? this.elapsed,
        phase: phase ?? this.phase,
        goalReached: goalReached ?? this.goalReached,
      );
}
