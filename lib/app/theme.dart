import 'package:flutter/material.dart';

import 'page_transitions.dart';
import 'tokens.dart';

/// Centralized non-color design tokens (color lives in [HgTokens]). Every screen
/// reads from these — never hardcodes values. See docs/design-language.md.

/// Font family (bundled, OFL). Geist — minimal/premium/productivity feel; used
/// for everything. [serif] kept as an alias so any legacy reference resolves.
class HgFont {
  static const sans = 'Geist';
  static const serif = 'Geist';
}

/// Spacing scale (8pt grid; 4pt half-step for intra-component nudges).
class HgSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
  static const xxl = 64.0;
  static const screen = 24.0; // shared left edge / horizontal screen padding
}

/// Corner radii (softened — warm, never sharp). Pill = primary action + live
/// progress + small single-select capsules only.
class HgRadius {
  static const sm = 12.0; // fields, small chips
  static const md = 16.0; // default container/surface
  static const lg = 20.0; // large tiles, sheets, hero plates
  static const pill = 999.0;
}

/// Touch & icon sizing.
class HgSize {
  static const touchMin = 48.0; // every hit area ≥ 48dp
  static const iconSm = 20.0;
  static const iconMd = 24.0; // default
  static const iconLg = 28.0;
}

/// Motion tokens — calm, decelerate-in / accelerate-out, no bounce.
class HgMotion {
  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 400);
  static const slow = Duration(milliseconds: 700);
  static const calm = Cubic(0.2, 0.0, 0.0, 1.0); // emphasized
  static const enter = Cubic(0.0, 0.0, 0.2, 1.0); // decelerate
  static const exit = Cubic(0.4, 0.0, 1.0, 1.0); // accelerate
}

/// Soft warm shadow for raised surfaces in LIGHT mode (dark uses lighter
/// surfaces, not shadows).

/// Builds a [ThemeData] for the given semantic tokens + brightness.
ThemeData buildTheme(HgTokens t, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: t.background,
    pageTransitionsTheme: hgPageTransitionsTheme,
    colorScheme: base.colorScheme.copyWith(
      brightness: brightness,
      surface: t.surface,
      primary: t.accent,
      onPrimary: t.onAccent,
      secondary: t.accent,
      error: t.danger,
    ),
    extensions: [t],
    textTheme: base.textTheme.apply(
      fontFamily: HgFont.sans,
      bodyColor: t.textPrimary,
      displayColor: t.textPrimary,
    ),
  );
}
