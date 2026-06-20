import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';

/// Soft-rect surface tile (the only place the app uses tile/bento containers —
/// stats surfaces). A raised surface + hairline, no drop shadow, so it reads as
/// a clean seamless card on every theme in both modes (a tinted/warm light-mode
/// shadow read as a rectangular smudge on cool themes). Optional tap. Never nest.
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
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
