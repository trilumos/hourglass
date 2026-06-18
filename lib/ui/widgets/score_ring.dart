import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';

/// A calm radial gauge for a 0–100 score: a hairline track with a sand accent
/// arc sweeping clockwise from the top. The brand's "instrument reading" — used
/// large on the Focus Score page and small on a session summary. Animates the
/// sweep in on appear/change (no glow, no bounce — per the design language).
class ScoreRing extends StatelessWidget {
  final int value;
  final double size;
  final double stroke;
  final Widget? child;
  final Duration duration;

  const ScoreRing({
    super.key,
    required this.value,
    this.size = 200,
    this.stroke = 10,
    this.child,
    this.duration = HgMotion.slow,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 100) / 100),
        duration: duration,
        curve: HgMotion.calm,
        builder: (_, fraction, _) => CustomPaint(
          painter: _RingPainter(
            fraction: fraction,
            accent: hg.accent,
            track: hg.hairline,
            stroke: stroke,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color accent;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.fraction,
    required this.accent,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = accent;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, arcPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.accent != accent ||
      old.track != track ||
      old.stroke != stroke;
}
