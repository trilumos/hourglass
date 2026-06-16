import 'package:flutter/material.dart';

import '../../app/tokens.dart';

/// The app's calm full-screen backdrop: a subtle radial gradient (ambient light
/// from above), `surface` → `background`. Used by every screen for a consistent,
/// premium base (no spotlight "glow blob").
class ScreenBackground extends StatelessWidget {
  final Widget child;
  const ScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.75),
          radius: 1.2,
          colors: [hg.surface, hg.background],
          stops: const [0.0, 0.7],
        ),
      ),
      child: child,
    );
  }
}
