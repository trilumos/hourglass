import '../domain/focus_phase.dart';
import 'session_plan.dart';

enum SessionStatus {
  idle,
  running,
  paused,

  /// A break finished and the session is waiting for the user to start the next
  /// focus block (tap-to-continue mode). [currentKind] already points at the
  /// upcoming focus segment.
  awaitingResume,

  /// A Flow Block reached its planned length and stopped, offering the user a
  /// choice: collect it (Done) or "Keep going" to extend the same block.
  completed,
  finished,
}

/// Immutable snapshot of the live session, consumed by the UI.
class SessionState {
  final SessionStatus status;

  /// Index of the current segment within the plan.
  final int segmentIndex;

  /// Kind of the current segment (focus or rest).
  final SegmentKind currentKind;

  /// Time elapsed within the current segment.
  final Duration segmentElapsed;

  /// Time elapsed across the whole session.
  final Duration elapsed;

  /// Focus time accrued so far (focus segments only).
  final Duration recordedFocus;

  /// Phase within the current focus segment (Struggle/Release/Flow).
  final FocusPhase phase;

  /// The planned end has been passed (the completion chime fires).
  final bool goalReached;

  const SessionState({
    required this.status,
    required this.segmentIndex,
    required this.currentKind,
    required this.segmentElapsed,
    required this.elapsed,
    required this.recordedFocus,
    required this.phase,
    required this.goalReached,
  });

  factory SessionState.initial() => const SessionState(
        status: SessionStatus.idle,
        segmentIndex: 0,
        currentKind: SegmentKind.focus,
        segmentElapsed: Duration.zero,
        elapsed: Duration.zero,
        recordedFocus: Duration.zero,
        phase: FocusPhase.struggle,
        goalReached: false,
      );

  bool get isResting => currentKind == SegmentKind.rest;

  SessionState copyWith({
    SessionStatus? status,
    int? segmentIndex,
    SegmentKind? currentKind,
    Duration? segmentElapsed,
    Duration? elapsed,
    Duration? recordedFocus,
    FocusPhase? phase,
    bool? goalReached,
  }) =>
      SessionState(
        status: status ?? this.status,
        segmentIndex: segmentIndex ?? this.segmentIndex,
        currentKind: currentKind ?? this.currentKind,
        segmentElapsed: segmentElapsed ?? this.segmentElapsed,
        elapsed: elapsed ?? this.elapsed,
        recordedFocus: recordedFocus ?? this.recordedFocus,
        phase: phase ?? this.phase,
        goalReached: goalReached ?? this.goalReached,
      );
}
