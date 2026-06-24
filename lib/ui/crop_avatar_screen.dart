import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../app/tokens.dart';

/// Crop a picked photo into a square avatar using the native cropper (uCrop on
/// Android, TOCropViewController on iOS). Returns the cropped PNG bytes (512²),
/// or null if the user cancelled.
///
/// We use the native cropper on purpose: a hand-rolled canvas cropper rendered
/// blank under some Android renderers (Impeller). The native screen sidesteps
/// Flutter rendering entirely and gives the familiar move/zoom + resizable
/// circular crop frame users expect.
Future<Uint8List?> cropAvatar(BuildContext context, String sourcePath) async {
  // Capture theme colours before any await so the native UI matches the app.
  final hg = context.hg;
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    maxWidth: 512,
    maxHeight: 512,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressFormat: ImageCompressFormat.png,
    compressQuality: 100,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Adjust photo',
        toolbarColor: hg.surface,
        toolbarWidgetColor: hg.textPrimary,
        backgroundColor: hg.background,
        activeControlsWidgetColor: hg.accent,
        cropFrameColor: hg.accent,
        cropGridColor: hg.hairline,
        dimmedLayerColor: hg.scrim,
        cropStyle: CropStyle.circle,
        lockAspectRatio: true,
        hideBottomControls: true,
        initAspectRatio: CropAspectRatioPreset.square,
      ),
      IOSUiSettings(
        title: 'Adjust photo',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        cropStyle: CropStyle.circle,
      ),
    ],
  );
  if (cropped == null) return null;
  return File(cropped.path).readAsBytes();
}
