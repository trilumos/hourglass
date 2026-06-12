/// Computes the user's Focus Stamina from recent completed flow blocks.
class StaminaCalculator {
  static const Duration defaultStart = Duration(minutes: 25);
  static const Duration ceiling = Duration(minutes: 90);
  static const Duration increment = Duration(minutes: 5);
  static const int window = 5;

  const StaminaCalculator();

  /// [recentCompletedBlocks] ordered oldest -> newest. Returns the average
  /// of the last [window] entries, or the default when empty.
  Duration currentStamina(List<Duration> recentCompletedBlocks) {
    if (recentCompletedBlocks.isEmpty) return defaultStart;
    final take = recentCompletedBlocks.length <= window
        ? recentCompletedBlocks
        : recentCompletedBlocks.sublist(recentCompletedBlocks.length - window);
    final totalSeconds = take.fold<int>(0, (sum, d) => sum + d.inSeconds);
    return Duration(seconds: (totalSeconds / take.length).round());
  }

  /// Nudges the next block slightly longer (progressive overload), capped.
  Duration suggestedNextLength(Duration currentStamina) {
    final next = currentStamina + increment;
    return next > ceiling ? ceiling : next;
  }
}
