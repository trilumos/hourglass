import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'hourglass_painter.dart';
import 'hourglass_skin.dart';

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

  const HourglassView({
    super.key,
    required this.progress,
    this.skin,
  });

  @override
  State<HourglassView> createState() => _HourglassViewState();
}

class _HourglassViewState extends State<HourglassView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _time = elapsed.inMicroseconds / 1e6);
    })..start();
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
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 0.52,
        child: CustomPaint(
          size: Size.infinite,
          painter: HourglassPainter(
            progress: widget.progress.clamp(0.0, 1.0),
            time: _time,
            skin: skin,
          ),
        ),
      ),
    );
  }
}
