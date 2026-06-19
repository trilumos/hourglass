import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/analytics_calculator.dart';
import '../session_format.dart';
import 'animated_readout.dart';

/// A bar chart with a tap-to-read detail line. The peak / current bar reads in
/// full accent by default; tapping any bar moves the accent there and the line
/// above shows its full label and exact focus. Replaces fl_chart's floating
/// tooltip with an on-brand, always-present readout that cross-fades on change.
class BarReadoutChart extends StatefulWidget {
  final List<TimeBar> bars;
  final double barWidth;
  final double height;
  final bool sparseLabels;

  /// Opacity of the non-active bars (0.55 for the trend, 0.30 for rhythms).
  final double restAlpha;

  const BarReadoutChart({
    super.key,
    required this.bars,
    this.barWidth = 14,
    this.height = 132,
    this.sparseLabels = false,
    this.restAlpha = 0.30,
  });

  @override
  State<BarReadoutChart> createState() => _BarReadoutChartState();
}

class _BarReadoutChartState extends State<BarReadoutChart> {
  int? _selected;

  int get _peakIndex {
    for (var i = 0; i < widget.bars.length; i++) {
      if (widget.bars[i].highlight) return i;
    }
    return -1;
  }

  @override
  void didUpdateWidget(BarReadoutChart old) {
    super.didUpdateWidget(old);
    // Range changed under us → drop a now-meaningless selection.
    if (old.bars.length != widget.bars.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final bars = widget.bars;
    if (bars.isEmpty) return const SizedBox.shrink();

    final maxMinutes = bars
        .map((b) => b.focus.inMinutes.toDouble())
        .fold(1.0, (m, v) => v > m ? v : m);
    final active = _selected ?? _peakIndex;
    final readout = _selected != null
        ? '${bars[_selected!].readout} · ${formatFocusDuration(bars[_selected!].focus)}'
        : 'Tap a bar to see its focus.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedReadout(
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
          child: BarChart(
            BarChartData(
              maxY: maxMinutes * 1.18,
              alignment: BarChartAlignment.spaceBetween,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  getTooltipItem: (_, _, _, _) => null, // our line replaces it
                ),
                touchCallback: (event, response) {
                  final spot = response?.spot;
                  if (spot == null) return;
                  setState(() => _selected = spot.touchedBarGroupIndex);
                },
              ),
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
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= bars.length) {
                        return const SizedBox.shrink();
                      }
                      final isEdge = i == 0 ||
                          i == bars.length - 1 ||
                          i == bars.length ~/ 2;
                      if (widget.sparseLabels && i != active && !isEdge) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          bars[i].label,
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
              barGroups: [
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].focus.inMinutes.toDouble(),
                        width: widget.barWidth,
                        borderRadius: BorderRadius.circular(3),
                        color: i == active
                            ? hg.accent
                            : hg.accent.withValues(alpha: widget.restAlpha),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
