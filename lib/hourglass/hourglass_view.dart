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

  const HourglassView({
    super.key,
    required this.progress,
    this.skin,
    this.heroTag,
    this.animate = true,
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
    if (!widget.animate) {
      // Frozen: show the exact level (e.g. the settled completion hourglass).
      _shown = widget.progress.clamp(0.0, 1.0);
      if (_ticker.isTicking) _ticker.stop();
    } else if (!_ticker.isTicking) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin ??
        (Theme.of(context).brightness == Brightness.dark
            ? HourglassSkin.classic
            : HourglassSkin.classicLight);
    final progress = (widget.animate ? _shown : widget.progress).clamp(0.0, 1.0);

    Widget visual = RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 0.52,
        child: CustomPaint(
          size: Size.infinite,
          painter: HourglassPainter(progress: progress, time: _time, skin: skin),
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
              painter:
                  HourglassPainter(progress: progress, time: 0, skin: skin),
            ),
          ),
        ),
        child: visual,
      );
    }
    return visual;
  }
}
