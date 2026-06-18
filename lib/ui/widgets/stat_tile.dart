import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import 'surface_tile.dart';

/// A compact label + value stat tile (sits in a stats bento). Optional tap and
/// accent value.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final VoidCallback? onTap;
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SurfaceTile(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.sm, vertical: HgSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: accent ? hg.accent : hg.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 9.5,
              letterSpacing: 1.2,
              color: hg.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
