import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/analytics_calculator.dart';

/// A smooth value-over-time line (Focus Score trend, Stamina growth) with the
/// same tap-to-read affordance as [BarReadoutChart]: one always-present readout
/// line above, an on-brand accent curve, the active point dotted, and an
/// optional faint "ideal" guide line. fl_chart's floating tooltip is replaced
/// by our readout so the chart stays calm and on-theme.
///
/// [points] may carry leading nulls (a metric has no value before its first
/// qualifying session); those buckets are skipped so the line starts where the
/// data really begins — no fabricated zero. Callers should show empty copy
/// instead of this chart when no point has a value.
class LineReadoutChart extends StatefulWidget {
  final List<TrendPoint> points;
  final double minY;
  final double maxY;

  /// Optional dashed reference line (e.g. the 90-minute stamina ceiling).
  final double? guideY;
  final String? guideLabel;

  /// Renders a point's value for the readout line (e.g. '84' or '32 min').
  final String Function(double) formatValue;

  final double height;

  const LineReadoutChart({
    super.key,
    required this.points,
    required this.minY,
    required this.maxY,
    required this.formatValue,
    this.guideY,
    this.guideLabel,
    this.height = 168,
  });

  @override
  State<LineReadoutChart> createState() => _LineReadoutChartState();
}

class _LineReadoutChartState extends State<LineReadoutChart> {
  int? _selected;

  /// The last bucket that has a value — the metric's current standing, shown
  /// active by default so the chart opens on the most relevant point.
  int get _defaultActive {
    for (var i = widget.points.length - 1; i >= 0; i--) {
      if (widget.points[i].value != null) return i;
    }
    return -1;
  }

  @override
  void didUpdateWidget(LineReadoutChart old) {
    super.didUpdateWidget(old);
    if (old.points.length != widget.points.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final pts = widget.points;
    final spots = <FlSpot>[
      for (var i = 0; i < pts.length; i++)
        if (pts[i].value != null) FlSpot(i.toDouble(), pts[i].value!),
    ];
    if (spots.isEmpty) return const SizedBox.shrink();

    final active = (_selected != null && pts[_selected!].value != null)
        ? _selected!
        : _defaultActive;
    final readout = _selected != null && pts[_selected!].value != null
        ? '${pts[_selected!].readout} · ${widget.formatValue(pts[_selected!].value!)}'
        : 'Tap a point to read it.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: HgMotion.fast,
          switchInCurve: HgMotion.enter,
          child: Text(
            readout,
            key: ValueKey(readout),
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _selected != null ? hg.textPrimary : hg.textMuted,
            ),
          ),
        ),
        const SizedBox(height: HgSpacing.md),
        SizedBox(
          height: widget.height,
          child: LineChart(
            LineChartData(
              minY: widget.minY,
              maxY: widget.maxY,
              minX: 0,
              maxX: (pts.length - 1).toDouble(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= pts.length) {
                        return const SizedBox.shrink();
                      }
                      final isEdge = i == 0 ||
                          i == pts.length - 1 ||
                          i == pts.length ~/ 2;
                      // Sparse like the bar charts: keep edges + the active label.
                      if (pts.length > 10 && i != active && !isEdge) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          pts[i].label,
                          style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 10,
                            color: i == active ? hg.accent : hg.textMuted,
                            fontWeight: i == active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: widget.guideY == null
                  ? const ExtraLinesData()
                  : ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: widget.guideY!,
                        color: hg.hairline,
                        strokeWidth: 1,
                        dashArray: const [4, 5],
                        label: HorizontalLineLabel(
                          show: widget.guideLabel != null,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 2, bottom: 2),
                          labelResolver: (_) => widget.guideLabel!,
                          style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 9.5,
                            color: hg.textMuted,
                          ),
                        ),
                      ),
                    ]),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  getTooltipItems: (spots) =>
                      spots.map((_) => null).toList(), // our line replaces it
                ),
                getTouchedSpotIndicator: (bar, indexes) => indexes
                    .map((_) => TouchedSpotIndicatorData(
                          FlLine(
                              color: hg.accent.withValues(alpha: 0.25),
                              strokeWidth: 1),
                          const FlDotData(show: false),
                        ))
                    .toList(),
                touchCallback: (event, response) {
                  final touched = response?.lineBarSpots;
                  if (touched == null || touched.isEmpty) return;
                  setState(() => _selected = touched.first.x.toInt());
                },
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.28,
                  preventCurveOverShooting: true,
                  color: hg.accent,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, bar) => spot.x.toInt() == active,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: hg.accent,
                      strokeWidth: 2,
                      strokeColor: hg.surfaceRaised,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        hg.accent.withValues(alpha: 0.16),
                        hg.accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
