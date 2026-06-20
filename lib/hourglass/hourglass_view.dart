import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'hourglass_painter.dart';
import 'hourglass_skin.dart';

/// Shared [Hero] tag so the hourglass flies as one continuous object between
/// screens that both show it (e.g. Home ↔ Session).
const kHourglassHeroTag = 'hourglass-hero';

/// Animated hourglass widget. Pass [progress] (0..1) to set the sand level.
/// A ticker advances [time] each frame, which drives the kinematic liquid
/// surface and the falling spray. Repaints are isolated behind a
/// [RepaintBoundary].
class HourglassView extends StatefulWidget {
  final double progress;

  /// Explicit skin override. When null, the skin is chosen from the current
  /// theme brightness (dark = [HourglassSkin.classic], light =
  /// [HourglassSkin.classicLight]) so the hourglass stays visible in both modes.
  final HourglassSkin? skin;

  /// When set, the hourglass becomes a [Hero] with this tag so it animates
  /// continuously between routes. The flight uses a frozen (cheap) painter to
  /// avoid running the live simulation during the transition.
  final String? heroTag;

  /// Whether the live sand simulation advances. When false the sand freezes
  /// mid-fall (used to make a paused session unmistakable). Default true.
  final bool animate;

  /// Ambient idle mode: sand falls continuously, the top stays full, and NO
  /// pile accumulates in the bottom (used on Home so it reads as alive, not a
  /// running countdown).
  final bool ambient;

  const HourglassView({
    super.key,
    required this.progress,
    this.skin,
    this.heroTag,
    this.animate = true,
    this.ambient = false,
  });

  @override
  State<HourglassView> createState() => _HourglassViewState();
}

class _HourglassViewState extends State<HourglassView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;
  double _last = 0; // previous frame's elapsed seconds

  /// The level actually drawn. The session clock only ticks once per second, so
  /// we ease this toward [widget.progress] every frame — the sand flows like
  /// water instead of stepping. Big backward jumps (a flip/reset) snap.
  late double _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.progress.clamp(0.0, 1.0);
    _ticker = createTicker(_onFrame);
    if (widget.animate) _ticker.start();
  }

  void _onFrame(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final dt = (t - _last).clamp(0.0, 0.1);
    _last = t;
    final target = widget.progress.clamp(0.0, 1.0);
    setState(() {
      _time = t;
      if (target < _shown - 0.2) {
        _shown = target; // reset / flip refill — snap, the flip hides it
      } else {
        // Exponential ease (~0.35s time constant) → smooth, watery descent.
        _shown += (target - _shown) * (1 - math.exp(-dt / 0.35));
        if ((target - _shown).abs() < 0.0005) _shown = target;
      }
    });
  }

  @override
  void didUpdateWidget(HourglassView old) {
    super.didUpdateWidget(old);
    // Use isActive (started, regardless of TickerMode mute), NOT isTicking
    // (active AND unmuted). A theme change rebuilds this widget; while the view
    // is muted (e.g. covered by another route) isTicking is false even though
    // the ticker is already started, so guarding on isTicking would call
    // start() on an active ticker -> "A ticker was started twice" + leaked frame
    // callbacks (the seed of the stale/ghost hourglass). isActive is correct.
    if (!widget.animate) {
      // Frozen: show the exact level (e.g. the settled completion hourglass).
      _shown = widget.progress.clamp(0.0, 1.0);
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Smoothly cycle a sand palette by time: a slow, calm hue drift through the
  /// palette (smoothstep between neighbours) plus a gentle "breathing" glow on a
  /// DIFFERENT period, so the two never sync and the sand reads as a living,
  /// glowing precious material. A couple of cheap ops per frame.
  static Color _cycledSand(List<Color> palette, double time) {
    final n = palette.length;
    Color hue;
    if (n <= 1) {
      hue = palette.first;
    } else {
      const secondsPerColor = 12.0; // slow + premium
      final pos = (time / secondsPerColor) % n;
      final i = pos.floor();
      final f = pos - i;
      final e = f * f * (3 - 2 * f); // smoothstep ease
      hue = Color.lerp(palette[i], palette[(i + 1) % n], e)!;
    }
    // Gentle ±~4.5% luminance breath (~14s period) — a subtle glow.
    final glow = 0.045 * math.sin(time * 0.45);
    return glow >= 0
        ? Color.lerp(hue, const Color(0xFFFFFFFF), glow)!
        : Color.lerp(hue, const Color(0xFF000000), -glow)!;
  }

  @override
  Widget build(BuildContext context) {
    final baseSkin = widget.skin ??
        (Theme.of(context).brightness == Brightness.dark
            ? HourglassSkin.classic
            : HourglassSkin.classicLight);
    // Home (ambient) "living" sand: if the theme supplies a sandCycle, slowly
    // shimmer the sand through it. Ambient-only, so a focus session never
    // animates colour (motion rule). Grain colour follows sand, so the falling
    // sand and the bulb sand shimmer as one material.
    final cycle = baseSkin.sandCycle;
    final skin = (cycle != null &&
            cycle.isNotEmpty &&
            widget.ambient &&
            widget.animate)
        ? baseSkin.withSand(_cycledSand(cycle, _time))
        : baseSkin;
    final progress = (widget.animate ? _shown : widget.progress).clamp(0.0, 1.0);

    Widget visual = RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 0.52,
        child: CustomPaint(
          size: Size.infinite,
          painter: HourglassPainter(
              progress: progress, time: _time, skin: skin, ambient: widget.ambient),
        ),
      ),
    );

    final tag = widget.heroTag;
    if (tag != null) {
      visual = Hero(
        tag: tag,
        // Cheap, frozen hourglass during flight — don't run the live sim while
        // the route is also animating. AspectRatio stays locked so the glass
        // never warps; only the box size lerps.
        flightShuttleBuilder: (_, _, _, _, _) => RepaintBoundary(
          child: AspectRatio(
            aspectRatio: 0.52,
            child: CustomPaint(
              size: Size.infinite,
              painter: HourglassPainter(
                  progress: progress,
                  time: 0,
                  skin: skin,
                  ambient: widget.ambient),
            ),
          ),
        ),
        child: visual,
      );
    }
    return visual;
  }
}
