import 'session_mode.dart';
import 'session_record.dart';

/// Computes the user's Focus Stamina from recent qualifying flow blocks.
class StaminaCalculator {
  /// Fallback only — used by [currentStamina] when there are no qualifying
  /// blocks yet. Stamina is treated as *unset* until the first eligible Flow
  /// session (the UI shows it locked); this is not a real "starting stamina".
  static const Duration defaultStart = Duration(minutes: 25);

  /// The ~90-minute deep-work reference (from ultradian focus research). This is
  /// NOT a cap: stamina can and does exceed it. The growth chart draws it as a
  /// guide line and expands its axis past it once you surpass it.
  static const Duration referenceBlock = Duration(minutes: 90);

  /// A Flow block must record at least this much focus to count toward stamina
  /// (matches the Flow recording threshold — sub-2-min Flow isn't even stored).
  static const Duration minBlock = Duration(minutes: 2);
  static const int window = 5;

  const StaminaCalculator();

  /// [recentBlocks] ordered oldest -> newest. Returns the average of the last
  /// [window] entries, or the default when empty.
  Duration currentStamina(List<Duration> recentBlocks) {
    if (recentBlocks.isEmpty) return defaultStart;
    final take = recentBlocks.length <= window
        ? recentBlocks
        : recentBlocks.sublist(recentBlocks.length - window);
    final totalSeconds = take.fold<int>(0, (sum, d) => sum + d.inSeconds);
    return Duration(seconds: (totalSeconds / take.length).round());
  }

  /// The Flow blocks that count toward stamina, in order. The rule:
  ///
  /// - Stamina is **unset** until the first *eligible* Flow session — a Flow
  ///   block with at least [minBlock] of recorded focus. That first eligible
  ///   block **sets the baseline** (your stamina becomes its length), whatever
  ///   it was: finishing a 25-min block starts you at 25, ending one early at
  ///   12 starts you at 12. It is your real demonstrated capacity.
  /// - After the baseline, a block counts if you **finished it**
  ///   (`completed && !abandoned`) OR you **sustained longer than your current
  ///   stamina** (an over-reach). Ending early *below* your current stamina is
  ///   ignored, so a short give-up never drags stamina down — it only ever
  ///   grows from real effort.
  ///
  /// [flowOldestToNewest] should be every session oldest -> newest; non-Flow
  /// and sub-[minBlock] rows are skipped. Walks once, tracking stamina as it
  /// goes (the over-reach bar is the stamina *before* each block).
  List<SessionRecord> qualifyingFlowBlocks(
      List<SessionRecord> flowOldestToNewest) {
    final out = <SessionRecord>[];
    final durations = <Duration>[];
    for (final s in flowOldestToNewest) {
      if (s.mode != SessionMode.flowBlock || s.recordedFocus < minBlock) {
        continue;
      }
      final bool accept;
      if (durations.isEmpty) {
        accept = true; // first eligible session sets the baseline
      } else {
        final finished = s.completed && !s.abandoned;
        accept = finished || s.recordedFocus > currentStamina(durations);
      }
      if (accept) {
        out.add(s);
        durations.add(s.recordedFocus);
      }
    }
    return out;
  }
}
