import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';

/// Soft-rect surface tile (the only place the app uses tile/bento containers —
/// stats surfaces). Lighter warm surface + hairline in dark; white + soft warm
/// shadow in light. Optional tap. Never nest these.
class SurfaceTile extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const SurfaceTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HgSpacing.md),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final light = Theme.of(context).brightness == Brightness.light;
    return Material(
      color: hg.surfaceRaised,
      borderRadius: BorderRadius.circular(HgRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HgRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HgRadius.lg),
            border: Border.all(color: hg.hairline),
            boxShadow: light ? hgSoftShadow(hg.textPrimary) : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
