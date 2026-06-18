import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/tokens.dart';

/// Full-screen view of the profile photo: pinch to zoom, tap (or the close
/// button) to dismiss.
class PhotoViewerScreen extends ConsumerWidget {
  final String imagePath;
  const PhotoViewerScreen({super.key, required this.imagePath});

  static const _bg = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: FutureBuilder<File>(
                  future: ref.read(imageStorageProvider).resolve(imagePath),
                  builder: (context, snap) {
                    final file = snap.data;
                    if (file == null) return const SizedBox.shrink();
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.file(file, fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
                color: hg.textPrimary,
                tooltip: 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
