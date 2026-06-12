/// The phase a focus block is in, based on elapsed time.
/// Recovery happens after the block ends and is orchestrated separately,
/// so it is not part of this enum.
enum FocusPhase { struggle, release, flow }
