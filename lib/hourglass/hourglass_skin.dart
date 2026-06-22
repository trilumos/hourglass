import 'package:flutter/painting.dart';

/// Data-driven hourglass appearance so the default look and the future
/// collectible skins are just different values (no code changes).
class HourglassSkin {
  final String id;
  final Color sandColor;
  final Color glassTint;
  final Color glassOutline;

  /// Colour of the falling-sand grains. RULE: the falling sand must ALWAYS match
  /// the sand in the bulbs, so this is the sand colour itself, never a separate
  /// value. (A faint highlight is applied where the pile catches light, but the
  /// grains and the pile are the same material.)
  Color get grainColor => sandColor;

  /// Neck half-width as a fraction of the widget width (smaller = finer neck).
  final double neckWidth;

  /// Optional palette the **home (ambient)** hourglass slowly cycles the sand
  /// through — a premium "living" touch (a shimmering precious material). Null =
  /// static sand. NEVER used during a focus session (ambient mode only), so the
  /// session screen stays motionless except the hourglass itself. Because
  /// [grainColor] returns [sandColor], the falling sand and the pile shimmer
  /// together as one material at every step (the locked sand rule holds).
  final List<Color>? sandCycle;

  const HourglassSkin({
    required this.id,
    required this.sandColor,
    required this.glassTint,
    required this.glassOutline,
    required this.neckWidth,
    this.sandCycle,
  });

  /// A copy with a resolved sand colour — the view feeds the painter the current
  /// cycled colour while keeping every other property identical.
  HourglassSkin withSand(Color sand) => HourglassSkin(
        id: id,
        sandColor: sand,
        glassTint: glassTint,
        glassOutline: glassOutline,
        neckWidth: neckWidth,
      );

  static const classic = HourglassSkin(
    id: 'classic',
    sandColor: Color(0xFFEACA78), // warm GOLDEN sand (not grey-beige)
    glassTint: Color(0x14FFFFFF),
    glassOutline: Color(0x33FFFFFF),
    neckWidth: 0.012,
    // Golden desert shimmer (home only): light gold -> gold -> deep gold ->
    // amber-gold -> cream-gold. Stays golden, never muddy/brown.
    sandCycle: [
      Color(0xFFF3E0A4), Color(0xFFEACA78), Color(0xFFE9C068),
      Color(0xFFDEB458), Color(0xFFEFD89C),
    ],
  );

  /// Light-theme variant: the dark-tuned glass (white tints) is invisible on a
  /// pale background, so the glass body/outline go DARK and the sand darkens to
  /// the light-theme accent so it reads on warm paper. Shape/animation identical.
  static const classicLight = HourglassSkin(
    id: 'classic',
    sandColor: Color(0xFFE0A82C), // richer, cleaner GOLD (was a dull olive-tan)
    glassTint: Color(0xFF1F1B14),
    glassOutline: Color(0x331F1B14),
    neckWidth: 0.012,
    // Golden desert shimmer (home only), mirroring the dark skin's progression
    // but deeper so it reads on warm paper: light gold -> gold -> deep gold ->
    // amber-gold -> cream-gold. Stays golden, never muddy.
    sandCycle: [
      Color(0xFFEEC158), Color(0xFFE0A82C), Color(0xFFD09420),
      Color(0xFFE8B33E), Color(0xFFDCA734),
    ],
  );
}
