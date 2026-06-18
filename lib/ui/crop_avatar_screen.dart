import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// Lets the user frame their photo (drag + pinch) inside a circular crop, then
/// captures exactly that square region as PNG bytes and returns them.
/// Pops `Uint8List?` (null = cancelled).
class CropAvatarScreen extends StatefulWidget {
  final File source;
  const CropAvatarScreen({super.key, required this.source});

  @override
  State<CropAvatarScreen> createState() => _CropAvatarScreenState();
}

class _CropAvatarScreenState extends State<CropAvatarScreen> {
  final _boundaryKey = GlobalKey();
  final _controller = TransformationController();
  bool _capturing = false;

  Future<void> _use(double side) async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 512 / side);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List?>(data?.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Adjust photo'),
                const SizedBox(height: HgSpacing.lg),
                Text(
                  'Drag and pinch to frame your photo.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 14,
                    color: hg.textMuted,
                  ),
                ),
                const SizedBox(height: HgSpacing.lg),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final side = constraints.maxWidth.clamp(0.0, 360.0);
                        return SizedBox(
                          width: side,
                          height: side,
                          child: Stack(
                            children: [
                              ClipRect(
                                child: RepaintBoundary(
                                  key: _boundaryKey,
                                  child: ColoredBox(
                                    color: hg.surfaceSunken,
                                    child: InteractiveViewer(
                                      transformationController: _controller,
                                      boundaryMargin:
                                          const EdgeInsets.all(double.infinity),
                                      minScale: 1,
                                      maxScale: 5,
                                      child: Image.file(
                                        widget.source,
                                        width: side,
                                        height: side,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Circular crop mask + ring (does not get captured;
                              // it sits above the RepaintBoundary).
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _CircleMaskPainter(
                                      scrim: hg.scrim,
                                      ring: hg.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.lg),
                LayoutBuilder(
                  builder: (context, _) {
                    // Re-derive the same side for the capture pixelRatio.
                    final width = MediaQuery.sizeOf(context).width -
                        HgSpacing.screen * 2;
                    final side = width.clamp(0.0, 360.0);
                    return PrimaryButton(
                      label: _capturing ? 'Saving…' : 'Use photo',
                      onPressed: _capturing ? null : () => _use(side),
                    );
                  },
                ),
                const SizedBox(height: HgSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  final Color scrim;
  final Color ring;
  _CircleMaskPainter({required this.scrim, required this.ring});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    // Dim everything outside the crop circle.
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = scrim);
    // The sand crop ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) =>
      old.scrim != scrim || old.ring != ring;
}
