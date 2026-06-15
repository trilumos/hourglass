import 'package:flutter/painting.dart';

/// Data-driven hourglass appearance so the default look and the future
/// collectible skins are just different values (no code changes).
class HourglassSkin {
  final String id;
  final Color sandColor;
  final Color glassTint;
  final Color glassOutline;

  /// Neck half-width as a fraction of the widget width (smaller = finer neck).
  final double neckWidth;

  const HourglassSkin({
    required this.id,
    required this.sandColor,
    required this.glassTint,
    required this.glassOutline,
    required this.neckWidth,
  });

  static const classic = HourglassSkin(
    id: 'classic',
    sandColor: Color(0xFFE8C9A0),
    glassTint: Color(0x14FFFFFF),
    glassOutline: Color(0x33FFFFFF),
    neckWidth: 0.012,
  );

  /// Light-theme variant: the dark-tuned glass (white tints) is invisible on a
  /// pale background, so the glass body/outline go DARK and the sand darkens to
  /// the light-theme accent so it reads on warm paper. Shape/animation identical.
  static const classicLight = HourglassSkin(
    id: 'classic',
    sandColor: Color(0xFFC69A5E),
    glassTint: Color(0xFF1F1B14),
    glassOutline: Color(0x331F1B14),
    neckWidth: 0.012,
  );
}
