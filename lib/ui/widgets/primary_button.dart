import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';

/// The app's single prominent call-to-action. Pill-shaped, accent-on-surface
/// with a subtle STATIC top-sheen gradient, soft press feedback. All styling
/// flows from theme tokens.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final enabled = onPressed != null;
    // A soft top-down sheen. Vary only LIGHTNESS in HSL (keep hue + saturation)
    // so a gold accent stays gold top-to-bottom instead of muddying toward
    // black/olive (a plain lerp-to-black desaturates). A theme may override it
    // (e.g. Aurora) via hg.accentGradient.
    final hsl = HSLColor.fromColor(hg.accent);
    double clampL(double l) => l.clamp(0.0, 1.0);
    final accentLight =
        hsl.withLightness(clampL(hsl.lightness + (1 - hsl.lightness) * 0.18)).toColor();
    final accentDeep = hsl.withLightness(clampL(hsl.lightness * 0.80)).toColor();
    final gradient = enabled
        ? (hg.accentGradient ??
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accentLight, hg.accent, accentDeep],
              stops: const [0.0, 0.55, 1.0],
            ))
        : null;
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Material(
        color: enabled ? hg.accent : hg.surfaceRaised,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(gradient: gradient),
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: enabled ? hg.onAccent : hg.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
