import 'package:flutter/material.dart';

/// A buttery readout swap for values that change on interaction — chart
/// tap-readouts, the mode donut's centre, the heatmap's detail line.
///
/// It's a **fade-through**: the old value fades out over the first half, the new
/// fades in over the second, so the two never sit half-lit on top of each other
/// (the "muddy" ghosting a plain [AnimatedSwitcher] cross-fade produces). The
/// children are stacked at [alignment] so the text never drifts sideways as its
/// width changes. Honors the design language: cross-fade for text, never a slide.
///
/// [child] MUST carry a [ValueKey] (or similar) that changes with its content,
/// so the switcher knows when to animate.
class AnimatedReadout extends StatelessWidget {
  final Widget child;
  final Alignment alignment;
  final Duration duration;

  const AnimatedReadout({
    super.key,
    required this.child,
    this.alignment = Alignment.centerLeft,
    this.duration = const Duration(milliseconds: 240),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      // Curving is done in the builder (per direction); keep the switcher linear.
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [
          ...previous,
          ?current,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        // Incoming waits, then fades in over the second half; outgoing fades out
        // over the first half (reverseCurve). No overlap → no ghosting.
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
        ),
        child: child,
      ),
      child: child,
    );
  }
}
