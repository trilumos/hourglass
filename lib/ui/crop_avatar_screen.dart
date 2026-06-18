import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// Profile-photo cropper (Instagram/WhatsApp model): a fixed circular ring; the
/// photo zooms and pans **underneath** it, constrained so it always covers the
/// ring (can't shrink below cover). On confirm we crop exactly the ring's region
/// from the source pixels and return PNG bytes.
class CropAvatarScreen extends StatefulWidget {
  final File source;
  const CropAvatarScreen({super.key, required this.source});

  @override
  State<CropAvatarScreen> createState() => _CropAvatarScreenState();
}

class _CropAvatarScreenState extends State<CropAvatarScreen> {
  Uint8List? _bytes;
  ui.Image? _image;
  int _imgW = 0;
  int _imgH = 0;

  // Transform: a source point sp maps to viewport `_offset + sp * _scale`.
  double _scale = 1;
  Offset _offset = Offset.zero;
  double _minScale = 1;
  double _maxScale = 1;
  Offset _center = Offset.zero; // ring center (viewport coords)
  double _radius = 0; // ring radius
  bool _placed = false;
  bool _busy = false;

  // Gesture start snapshot.
  double _s0 = 1;
  Offset _o0 = Offset.zero;
  Offset _focal0 = Offset.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.source.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _image = frame.image;
      _imgW = frame.image.width;
      _imgH = frame.image.height;
    });
  }

  void _layout(Size viewport) {
    if (_image == null) return;
    _center = Offset(viewport.width / 2, viewport.height / 2);
    _radius = math.min(viewport.width, viewport.height) / 2 - 8;
    // Cover: the smaller source dimension scaled must span the ring diameter.
    _minScale = (2 * _radius) / math.min(_imgW, _imgH);
    _maxScale = _minScale * 4;
    if (!_placed) {
      _scale = _minScale;
      _offset = Offset(
        _center.dx - _imgW * _scale / 2,
        _center.dy - _imgH * _scale / 2,
      );
      _placed = true;
    }
    _offset = _clampOffset(_offset, _scale);
  }

  Offset _clampOffset(Offset o, double s) {
    final w = _imgW * s;
    final h = _imgH * s;
    final minOx = _center.dx + _radius - w;
    final maxOx = _center.dx - _radius;
    final minOy = _center.dy + _radius - h;
    final maxOy = _center.dy - _radius;
    return Offset(
      o.dx.clamp(math.min(minOx, maxOx), math.max(minOx, maxOx)),
      o.dy.clamp(math.min(minOy, maxOy), math.max(minOy, maxOy)),
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final newScale = (_s0 * d.scale).clamp(_minScale, _maxScale);
    // Keep the focal point anchored to the same source location.
    final sp = (_focal0 - _o0) / _s0; // source-space point under the focal
    var newOffset = d.focalPoint - sp * newScale;
    newOffset = _clampOffset(newOffset, newScale);
    setState(() {
      _scale = newScale;
      _offset = newOffset;
    });
  }

  Future<void> _use() async {
    if (_bytes == null || _busy) return;
    setState(() => _busy = true);
    final srcX = (_center.dx - _radius - _offset.dx) / _scale;
    final srcY = (_center.dy - _radius - _offset.dy) / _scale;
    final srcSide = (2 * _radius) / _scale;
    final out = await compute(
      _cropSquare,
      _CropJob(_bytes!, srcX.round(), srcY.round(), srcSide.round()),
    );
    if (!mounted) return;
    Navigator.of(context).pop<Uint8List?>(out);
  }

  static Uint8List _cropSquare(_CropJob job) {
    final src = img.decodeImage(job.bytes)!;
    final maxSide = math.min(src.width, src.height);
    final s = job.side.clamp(1, maxSide).toInt();
    final x = job.x.clamp(0, src.width - s).toInt();
    final y = job.y.clamp(0, src.height - s).toInt();
    final cropped = img.copyCrop(src, x: x, y: y, width: s, height: s);
    final resized = img.copyResize(cropped, width: 512, height: 512);
    return img.encodePng(resized);
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
                const SizedBox(height: HgSpacing.md),
                Text(
                  'Pinch to zoom, drag to reposition.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 14,
                    color: hg.textMuted,
                  ),
                ),
                const SizedBox(height: HgSpacing.lg),
                Expanded(
                  child: _image == null
                      ? const Center(child: CircularProgressIndicator())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            _layout(Size(
                                constraints.maxWidth, constraints.maxHeight));
                            return GestureDetector(
                              onScaleStart: (d) {
                                _s0 = _scale;
                                _o0 = _offset;
                                _focal0 = d.focalPoint;
                              },
                              onScaleUpdate: _onScaleUpdate,
                              child: ClipRect(
                                child: CustomPaint(
                                  painter: _CropPainter(
                                    image: _image!,
                                    scale: _scale,
                                    offset: _offset,
                                    center: _center,
                                    radius: _radius,
                                    scrim: hg.scrim,
                                    ring: hg.accent,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: HgSpacing.lg),
                PrimaryButton(
                  label: _busy ? 'Saving…' : 'Use photo',
                  onPressed: (_image == null || _busy) ? null : _use,
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

class _CropJob {
  final Uint8List bytes;
  final int x;
  final int y;
  final int side;
  _CropJob(this.bytes, this.x, this.y, this.side);
}

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;
  final Offset center;
  final double radius;
  final Color scrim;
  final Color ring;

  _CropPainter({
    required this.image,
    required this.scale,
    required this.offset,
    required this.center,
    required this.radius,
    required this.scrim,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The photo, transformed beneath the ring.
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();

    // Dim outside the fixed crop circle.
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = scrim);

    // The sand ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image ||
      old.scale != scale ||
      old.offset != offset ||
      old.center != center ||
      old.radius != radius;
}
