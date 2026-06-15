import 'package:flutter/material.dart';
import 'hourglass/hourglass_preview.dart';

/// Standalone entrypoint for previewing the hourglass on a device without
/// touching the real app. Run with:
///   flutter run -t lib/hourglass_preview_main.dart -d DEVICE_ID
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HourglassPreview(),
    ),
  );
}
