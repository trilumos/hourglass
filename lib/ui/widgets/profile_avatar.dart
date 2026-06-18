import 'dart:io';

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

    return FutureBuilder<File>(
      future: ref.watch(imageStorageProvider).resolve(path),
      builder: (context, snap) {
        final file = snap.data;
        if (file == null) return fallback();
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => fallback(),
          ),
        );
      },
    );
  }
}
