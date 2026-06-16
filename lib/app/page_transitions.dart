import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'tokens.dart';

/// App-wide page transition: a calm scaled shared-axis (Z) move — the incoming
/// screen fades + scales up from 92%, the outgoing fades + scales away, over a
/// warm fill. Reads as "deeper into the app", cohesive everywhere. Falls back to
/// a plain fade when the OS requests reduced motion.
class HgSharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const HgSharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      return FadeTransition(opacity: animation, child: child);
    }
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.scaled,
      fillColor: context.hg.background,
      child: child,
    );
  }
}

/// The shared-axis builder applied to every platform for a consistent feel.
const hgPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: HgSharedAxisPageTransitionsBuilder(),
    TargetPlatform.iOS: HgSharedAxisPageTransitionsBuilder(),
    TargetPlatform.fuchsia: HgSharedAxisPageTransitionsBuilder(),
    TargetPlatform.linux: HgSharedAxisPageTransitionsBuilder(),
    TargetPlatform.macOS: HgSharedAxisPageTransitionsBuilder(),
    TargetPlatform.windows: HgSharedAxisPageTransitionsBuilder(),
  },
);
