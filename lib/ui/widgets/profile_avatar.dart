import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/tokens.dart';

/// Circular avatar: the profile image if set, else a calm default glyph.
/// Reads [profileProvider] so it stays in sync after an edit.
class ProfileAvatar extends ConsumerWidget {
  final double size;
  const ProfileAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final profile = ref.watch(profileProvider).asData?.value;
    final path = profile?.imagePath;

    Widget fallback() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: hg.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: hg.hairline),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: size * 0.55,
            color: hg.textMuted,
          ),
        );

    if (path == null) return fallback();

    // Resolved once and cached by path (see [resolvedImageProvider]) so a rebuild
    // doesn't re-run the async lookup and flash the fallback glyph.
    final file = ref.watch(resolvedImageProvider(path)).asData?.value;
    if (file == null) return fallback();
    // Avatars are stored at 512² but shown at 36–92px; decode to display
    // size so the full bitmap isn't held in the image cache (low-RAM win).
    final cachePx = (size * MediaQuery.of(context).devicePixelRatio).ceil();
    return ClipOval(
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cachePx,
        cacheHeight: cachePx,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }
}
