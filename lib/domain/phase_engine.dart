import 'focus_phase.dart';

/// Maps elapsed time within a focus block to a [FocusPhase].
class PhaseEngine {
  final Duration struggleDuration;
  final Duration releaseDuration;

  const PhaseEngine({
    required this.struggleDuration,
    required this.releaseDuration,
  });

  /// Builds an engine sized to a planned block length.
  /// Struggle = first quarter, capped at 12 minutes.
  /// Release  = a fixed 45-second transition.
  factory PhaseEngine.forBlock(Duration planned) {
    final quarterSeconds = (planned.inSeconds * 0.25).round();
    final quarter = Duration(seconds: quarterSeconds);
    const cap = Duration(minutes: 12);
    return PhaseEngine(
      struggleDuration: quarter < cap ? quarter : cap,
      releaseDuration: const Duration(seconds: 45),
    );
  }

  FocusPhase phaseAt(Duration elapsed) {
    if (elapsed < struggleDuration) return FocusPhase.struggle;
    if (elapsed < struggleDuration + releaseDuration) return FocusPhase.release;
    return FocusPhase.flow;
  }
}
