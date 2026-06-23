// Not a real test — a one-shot generator. Renders the REAL hourglass into app
// icon source PNGs (1024) so the launcher icon is the actual brand motif.
// Run: flutter test test/tool/generate_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/hourglass/hourglass_skin.dart';
import 'package:hourglass/hourglass/hourglass_view.dart';

Future<void> _render(
  WidgetTester tester, {
  required String path,
  required Widget background,
  required HourglassSkin skin,
  double heightFactor = 0.60,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: 1024,
          height: 1024,
          child: Stack(
            fit: StackFit.expand,
            children: [
              background,
              Center(
                child: FractionallySizedBox(
                  heightFactor: heightFactor,
                  child: HourglassView(
                      progress: 0.5, animate: false, skin: skin),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  // toImage / toByteData must run in REAL async (not the test's fake-async zone),
  // or they hang forever.
  final pngBytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(pngBytes!);
}

void main() {
  const obsidian = Color(0xFF0E0B07);
  const gold = Color(0xFFC8841E);

  testWidgets('generate app icon variants', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Obsidian: bright-gold hourglass glowing on near-black (most striking).
    await _render(tester,
        path: 'assets/icon/icon_obsidian.png',
        background: const ColoredBox(color: obsidian),
        skin: HourglassSkin.classic);

    // Warm gold: deep-gold hourglass on a Sand-gold field.
    await _render(tester,
        path: 'assets/icon/icon_gold.png',
        background: const ColoredBox(color: gold),
        skin: HourglassSkin.classicLight);

    // Gold radial gradient.
    await _render(tester,
        path: 'assets/icon/icon_gradient.png',
        background: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.1),
              radius: 0.95,
              colors: [Color(0xFFE0A22E), Color(0xFFB5740F)],
            ),
          ),
        ),
        skin: HourglassSkin.classicLight);

    // Transparent foreground for the adaptive icon (sits on the bg colour).
    await _render(tester,
        path: 'assets/icon/icon_fg.png',
        background: const SizedBox.shrink(),
        skin: HourglassSkin.classic,
        heightFactor: 0.52);
  });
}
