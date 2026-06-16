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

  const HourglassView({
    super.key,
    required this.progress,
    this.skin,
    this.heroTag,
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
    final progress = widget.progress.clamp(0.0, 1.0);

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
