import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';

/// The app's single prominent call-to-action. Pill-shaped, accent-on-surface,
/// soft press feedback. All styling flows from theme tokens.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: hg.accent,
          foregroundColor: hg.onAccent,
          disabledBackgroundColor: hg.surfaceRaised,
          disabledForegroundColor: hg.textMuted,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
