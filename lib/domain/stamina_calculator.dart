import 'session_mode.dart';
import 'session_record.dart';

/// Computes the user's Focus Stamina from recent qualifying flow blocks.
class StaminaCalculator {
  static const Duration defaultStart = Duration(minutes: 25);
  static const Duration ceiling = Duration(minutes: 90);
  static const Duration increment = Duration(minutes: 5);
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

  /// The Flow blocks that count toward stamina, in order. A block qualifies if
  /// it was **finished to its full length** (`completed && !abandoned`), OR it
  /// was ended early but the user still **sustained longer than their stamina
  /// at that moment** (an over-reach beyond current capacity). Early bails below
  /// current stamina are ignored — so real effort always lifts stamina and a
  /// short give-up never drags it down.
  ///
  /// [flowOldestToNewest] should be every session oldest -> newest; non-Flow
  /// rows are skipped. Walks once, tracking stamina as it goes (the over-reach
  /// bar is the stamina *before* each block).
  List<SessionRecord> qualifyingFlowBlocks(
      List<SessionRecord> flowOldestToNewest) {
    final out = <SessionRecord>[];
    final durations = <Duration>[];
    var current = defaultStart;
    for (final s in flowOldestToNewest) {
      if (s.mode != SessionMode.flowBlock) continue;
      final finished = s.completed && !s.abandoned;
      if (finished || s.recordedFocus > current) {
        out.add(s);
        durations.add(s.recordedFocus);
        current = currentStamina(durations);
      }
    }
    return out;
  }

  /// Nudges the next block slightly longer (progressive overload), capped.
  Duration suggestedNextLength(Duration currentStamina) {
    final next = currentStamina + increment;
    return next > ceiling ? ceiling : next;
  }
}
