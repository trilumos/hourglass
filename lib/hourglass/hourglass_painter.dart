import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'hourglass_skin.dart';

double _smooth(double x) {
  final double c = x.clamp(0.0, 1.0).toDouble();
  return c * c * (3 - 2 * c);
}

/// Vary only HSL lightness so a gold stays gold (lerping a colour toward
/// black/white desaturates and muddies it). Used for the sand gradient.
Color _deeper(Color c, double amount) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness * (1 - amount)).clamp(0.0, 1.0)).toColor();
}

Color _lighter(Color c, double amount) {
  final h = HSLColor.fromColor(c);
  return h
      .withLightness((h.lightness + (1 - h.lightness) * amount).clamp(0.0, 1.0))
      .toColor();
}

/// Draws a premium hourglass. [progress] is session progress (0 = top full,
/// 1 = pile full). [time] is elapsed seconds — it drives the falling spray and
/// the kinematic liquid top surface.
///
/// The top surface is a closed-form travelling wave (a Gaussian-windowed
/// Gerstner swell over a faint sum-of-sines), NOT a spring simulation — so it
/// reads as a natural swell crossing the water, not a bouncing jelly.
class HourglassPainter extends CustomPainter {
  final double progress;
  final double time;
  final HourglassSkin skin;

  /// Ambient idle mode: sand falls continuously with a FULL top and NO bottom
  /// pile accumulating — an "alive" hourglass that implies no countdown (Home).
  final bool ambient;

  HourglassPainter({
    required this.progress,
    required this.time,
    required this.skin,
    this.ambient = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double maxHalf = w * 0.30;
    final double neckHalf = w * skin.neckWidth;
    final double topPad = h * 0.04;
    final double usableH = h - topPad * 2;
    final double drain = progress.clamp(0.0, 1.0).toDouble();

    double yToPx(double y) => topPad + y * usableH;
    double rx(double half) => cx + half;
    double lx(double half) => cx - half;

    // --- elegant elongated glass ---
    final Path glass = Path()..moveTo(cx, yToPx(0.0));
    glass.cubicTo(rx(maxHalf * 0.86), yToPx(0.010), rx(maxHalf), yToPx(0.05),
        rx(maxHalf), yToPx(0.14));
    glass.cubicTo(rx(maxHalf), yToPx(0.30), rx(neckHalf), yToPx(0.40),
        rx(neckHalf), yToPx(0.5));
    glass.cubicTo(rx(neckHalf), yToPx(0.60), rx(maxHalf), yToPx(0.70),
        rx(maxHalf), yToPx(0.86));
    glass.cubicTo(rx(maxHalf), yToPx(0.95), rx(maxHalf * 0.86), yToPx(0.990),
        cx, yToPx(1.0));
    glass.cubicTo(lx(maxHalf * 0.86), yToPx(0.990), lx(maxHalf), yToPx(0.95),
        lx(maxHalf), yToPx(0.86));
    glass.cubicTo(lx(maxHalf), yToPx(0.70), lx(neckHalf), yToPx(0.60),
        lx(neckHalf), yToPx(0.5));
    glass.cubicTo(lx(neckHalf), yToPx(0.40), lx(maxHalf), yToPx(0.30),
        lx(maxHalf), yToPx(0.14));
    glass.cubicTo(lx(maxHalf), yToPx(0.05), lx(maxHalf * 0.86), yToPx(0.010),
        cx, yToPx(0.0));
    glass.close();
    canvas.drawPath(
      glass,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(lx(maxHalf), yToPx(0.0)),
          Offset(rx(maxHalf), yToPx(1.0)),
          [
            skin.glassTint.withValues(alpha: 0.10),
            skin.glassTint.withValues(alpha: 0.02),
          ],
        ),
    );

    // ---- pile geometry (two-phase volume-driven cone -> fill) ----
    final double floorY = yToPx(1.0);
    const double f0 = 0.30;
    const double s = 0.62;
    final double pileW = maxHalf * 0.92;
    final double coneR =
        drain <= 0 ? 0.0 : (drain <= f0 ? pileW * math.sqrt(drain / f0) : pileW);
    final double coneMax = (s * pileW).clamp(0.0, usableH * 0.14).toDouble();
    final double coneH = drain <= f0
        ? coneMax * math.sqrt((drain / f0).clamp(0.0, 1.0))
        : coneMax * (1 - 0.5 * ((drain - f0) / (1 - f0)).clamp(0.0, 1.0));
    final double maxFill = (floorY - yToPx(0.66)); // pile tops out below the neck
    final double baseRise =
        maxFill * _smooth(((drain - f0) / (1 - f0)).clamp(0.0, 1.0));

    double pileHeightAt(double x) {
      final double dr = (x - cx).abs();
      final double bump = (coneR <= 0 || dr >= coneR)
          ? 0.0
          : coneH * math.pow(math.cos((dr / coneR) * math.pi / 2), 1.2).toDouble();
      return baseRise + bump;
    }

    // Ambient: nothing accumulates, so grains fall the full lower chamber.
    final double landY = ambient ? floorY : floorY - pileHeightAt(cx);

    canvas.save();
    canvas.clipPath(glass);

    // TOP liquid: a kinematic travelling swell crossing the surface.
    if (drain < 1.0) {
      // Top never completely fills (12% headroom) and drains down to the neck.
      final double restSurf = yToPx(0.12 + 0.38 * drain);
      final double neckPx = yToPx(0.5);

      // andyfitz "gentle wave" parallax, customised to sand: ONE fixed wave
      // shape drawn as 3 stacked, tinted layers, each SCROLLING horizontally at
      // a DIFFERENT speed (his 12s / 5s / 3s). The layers beat against each
      // other at the top edge -> living water. Pure horizontal scroll of a
      // fixed shape — no morphing. Rendered with Catmull-Rom -> cubic bezier.
      final double waveLen = w * 0.85; // ~1.2 waves across the surface
      final double kk = 2 * math.pi / waveLen;
      // Fade the wave to flat as the top empties (last 15%) so the surface
      // smoothly drains to nothing instead of a band popping out at 100%.
      final double waveFade = 1 - _smooth((drain - 0.85) / 0.15);
      final double amp = maxHalf * 0.075 * waveFade;

      void drawWaveLayer(double dy, double speed, double phase0, Paint paint) {
        final double phi = 2 * math.pi * speed * time + phase0;
        const int nPts = 40;
        final List<Offset> pts = List.generate(nPts + 1, (i) {
          final double x = w * i / nPts;
          return Offset(x, restSurf + dy - amp * math.sin(kk * x - phi));
        });
        final Path p = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (int i = 0; i < pts.length - 1; i++) {
          final Offset p0 = pts[i == 0 ? 0 : i - 1];
          final Offset p1 = pts[i];
          final Offset p2 = pts[i + 1];
          final Offset p3 = pts[i + 2 >= pts.length ? pts.length - 1 : i + 2];
          final Offset c1 = p1 + (p2 - p0) / 6.0;
          final Offset c2 = p2 - (p3 - p1) / 6.0;
          p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
        }
        // Taper the sand to the central aperture instead of a flat cap at the
        // neck (which read as a rigid horizontal line). It converges DOWN to the
        // hole and never spills below the neck into the lower chamber; the
        // shoulders lift slightly into the top bulb. Eases flat as the top
        // empties (waveFade → 0).
        final double rise = usableH * 0.028 * waveFade;
        final double mouth = neckHalf * 1.8;
        p.lineTo(w, neckPx);
        p.lineTo(cx + mouth, neckPx - rise);
        p.quadraticBezierTo(cx + mouth * 0.5, neckPx, cx, neckPx);
        p.quadraticBezierTo(cx - mouth * 0.5, neckPx, cx - mouth, neckPx - rise);
        p.lineTo(0, neckPx);
        p.close();
        canvas.drawPath(p, paint);
      }

      // Two layers moving in sympathy: close speeds (~1.4x) so they flow
      // together as one body with subtle depth, beating just enough to feel
      // alive. back = light sand (highest); front = base sand (bulk). The back
      // crest is brightened IN-HUE (not toward white, which desaturated to the
      // same tone as the front surface and made the second wave vanish — worst
      // on the already-light Sand gold in dark mode) and peeks a touch higher.
      drawWaveLayer(-amp * 1.1, 0.24, 0.6,
          Paint()..color = _lighter(skin.sandColor, 0.46));
      // Front (bulk) layer: a 3-stop vertical gradient — lighter at the surface,
      // base sand in the middle, darker toward the neck — so the top sand reads
      // with depth (light top -> dark bottom), like the buttons.
      drawWaveLayer(
        0.0,
        0.34,
        4.0,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, restSurf),
            Offset(cx, neckPx),
            [
              _lighter(skin.sandColor, 0.14),
              skin.sandColor,
              _deeper(skin.sandColor, 0.20),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    // BOTTOM pile (never in ambient mode — nothing accumulates).
    if (!ambient && drain > 0.0) {
      final Path pile = Path();
      const int pn = 72;
      for (int i = 0; i <= pn; i++) {
        final double x = w * i / pn;
        final double sy = floorY - pileHeightAt(x);
        if (i == 0) {
          pile.moveTo(x, sy);
        } else {
          pile.lineTo(x, sy);
        }
      }
      pile.lineTo(w, floorY);
      pile.lineTo(0, floorY);
      pile.close();
      // 3-stop fill anchored to the pile: lighter at its surface, base sand in
      // the middle, darker at the floor (matches the top sand + the buttons).
      final double pileTopY = floorY - math.max(pileHeightAt(cx), 1.0);
      canvas.drawPath(
        pile,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, pileTopY),
            Offset(cx, floorY),
            [
              _lighter(skin.sandColor, 0.26),
              skin.sandColor,
              _deeper(skin.sandColor, 0.22),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }

    // FALLING SAND: a thin, near-straight central column of matte grains that
    // ACCELERATE under gravity (slow + packed at the hole, fast + sparse at the
    // pile). No glow, no cone, no splash. Fades as the gap shrinks / top empties.
    if (ambient || (drain > 0.0 && drain < 1.0)) {
      final double holeY = yToPx(0.5);
      final double gapNow = landY - holeY;
      final double gapFade = (gapNow / (usableH * 0.06)).clamp(0.0, 1.0);
      const double drainCutoff = 0.92;
      final double supplyFade =
          (1.0 - (drain - drainCutoff) / (1.0 - drainCutoff)).clamp(0.0, 1.0);
      final double gate = gapFade * supplyFade;
      if (gate > 0.01 && gapNow > 1) {
        final Color grain = skin.grainColor;
        const int grainCount = 80;
        // Ambient (Home) falls a little slower — calmer, less timer-like.
        final double fallPeriod = ambient ? 0.78 : 0.5;
        const double v0Frac = 0.10; // small exit speed; rest is gravity (phase^2)
        final double colHalf = neckHalf * 1.3; // thin column ~ the hole width
        final math.Random rng = math.Random(7); // seeded -> stable per grain
        // One reusable Paint for the whole spray (we only mutate its colour each
        // grain) — avoids ~80 Paint allocations every frame. Output is identical.
        final Paint grainPaint = Paint();
        for (int i = 0; i < grainCount; i++) {
          final double lane = rng.nextDouble() * 2 - 1;
          final double laneR = rng.nextDouble();
          final double sizeR = rng.nextDouble();
          final double speedR = 0.8 + 0.4 * rng.nextDouble(); // varied fall speed
          final double offR = rng.nextDouble(); // irregular spacing (not a pattern)
          final double phase = ((time / (fallPeriod * speedR)) + offR) % 1.0;
          final double fall = v0Frac * phase + (1 - v0Frac) * phase * phase;
          final double py = holeY + fall * gapNow;
          if (py >= landY) continue; // landed -> don't draw into the pile
          final double px = cx +
              lane.abs() * lane * colHalf +
              math.sin(phase * 2 * math.pi + i) * 0.5;
          // Fine grains: a touch over 1px leaving the hole, tapering finer as
          // they fall — a delicate spray, not chunky dots.
          final double r = ((1.05 - 0.4 * fall) * (0.55 + 0.4 * sizeR))
              .clamp(0.4, 1.1)
              .toDouble();
          final double a = ((1.0 - 0.16 * fall) * (0.82 + 0.18 * laneR) * gate)
              .clamp(0.0, 1.0)
              .toDouble();
          // Ambient has no pile to land on → fade grains out earlier and softer
          // (no hard floor, calmer look).
          final double drop =
              ((py - holeY) / (floorY - holeY)).clamp(0.0, 1.0);
          final double aFade =
              ambient ? 0.78 * (1.0 - _smooth((drop - 0.42) / 0.58)) : 1.0;
          grainPaint.color = grain.withValues(alpha: a * aFade);
          canvas.drawCircle(Offset(px, py), r, grainPaint);
        }

        // IMPACT SCATTER: grains the stream kicks off the pile apex. Each is a
        // tiny ballistic hop — launched out at a random low angle; gravity pulls
        // it back to the slope (g = 2·v·sinθ, so it lands exactly at p=1, giving
        // the parabola v·sinθ·p·(1−p)). Count and energy GROW with the pile, so
        // a small pile barely stirs and a tall pile visibly sprays. The grain
        // disappears the instant it meets the surface at its x — no floating.
        final double fill = drain.clamp(0.0, 1.0);
        final int scatterN = ambient ? 0 : (3 + 13 * fill).round();
        final double hScale = maxHalf * (0.10 + 0.40 * fill) * 2.2;
        final double vScale = usableH * (0.010 + 0.055 * fill) * 2.2;
        final math.Random erng = math.Random(31);
        final Paint scatterPaint = Paint(); // reused across the scatter hops
        for (int i = 0; i < scatterN; i++) {
          // Alternate sides by index so the spray is always balanced left/right
          // (a seeded coin-flip skewed to one side with so few grains).
          final double dir = i.isEven ? -1.0 : 1.0;
          final double ang = (20 + 65 * erng.nextDouble()) * math.pi / 180;
          final double v = 0.55 + 0.45 * erng.nextDouble();
          final double sizeR = erng.nextDouble();
          final double per = 0.30 + 0.35 * erng.nextDouble(); // varied cycle
          final double offR = erng.nextDouble();
          final double p = ((time / per) + offR) % 1.0;
          final double vsin = v * math.sin(ang);
          final double yUp = vsin * p * (1 - p); // 0 at p=0 and p=1, peak mid-flight
          final double ex = cx + dir * (v * math.cos(ang)) * p * hScale;
          final double ey = landY - yUp * vScale;
          final double surf = floorY - pileHeightAt(ex); // pile top at this x
          if (ey >= surf) continue; // fallen back onto the slope → gone
          final double r = 0.25 + 0.35 * sizeR; // fine grains
          final double a = ((1 - p) * 0.8 * gate).clamp(0.0, 1.0).toDouble();
          if (a <= 0.02) continue;
          scatterPaint.color = grain.withValues(alpha: a);
          canvas.drawCircle(Offset(ex, ey), r, scatterPaint);
        }
      }
    }
    canvas.restore();

    // ---- glass highlights on top ----
    final Path spec = Path()
      ..moveTo(lx(maxHalf * 0.62), yToPx(0.06))
      ..cubicTo(lx(maxHalf * 0.92), yToPx(0.12), lx(maxHalf * 0.55),
          yToPx(0.30), lx(neckHalf * 1.5), yToPx(0.46));
    canvas.drawPath(
      spec,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = skin.glassOutline,
    );
  }

  @override
  bool shouldRepaint(covariant HourglassPainter old) =>
      old.time != time ||
      old.progress != progress ||
      old.skin != skin ||
      old.ambient != ambient;
}
