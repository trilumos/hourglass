/// Computes how much focus time a *completed* block records.
///
/// Fixed mode (autoContinue == false): always the planned length.
/// Endless mode (autoContinue == true): the full elapsed time, which is
/// never less than the planned length (a completed block reached planned).
Duration computeRecordedFocus({
  required Duration plannedDuration,
  required Duration elapsed,
  required bool autoContinue,
}) {
  if (!autoContinue) return plannedDuration;
  return elapsed > plannedDuration ? elapsed : plannedDuration;
}
