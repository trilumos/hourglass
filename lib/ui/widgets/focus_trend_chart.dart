import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/analytics_calculator.dart';
import '../session_format.dart';

/// Focus-minutes bars over the selected range. The current period (today /
/// this month) reads in full accent; the rest are muted. Tap a bar for its
/// exact value. When [sparseLabels] (the 30-bar month view) only the first,
/// middle, and last labels render so the axis stays calm.
class FocusTrendChart extends StatelessWidget {
  final List<TimeBar> bars;
  final bool sparseLabels;
  const FocusTrendChart({
    super.key,
    required this.bars,
    this.sparseLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    if (bars.isEmpty) return const SizedBox.shrink();
    final maxMinutes = bars
        .map((b) => b.focus.inMinutes.toDouble())
        .fold(1.0, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 168,
      child: BarChart(
        BarChartData(
          maxY: maxMinutes * 1.18,
          alignment: BarChartAlignment.spaceBetween,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => hg.surfaceRaised,
              getTooltipItem: (group, _, _, _) => BarTooltipItem(
                formatFocusDuration(bars[group.x].focus),
                TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hg.textPrimary,
                ),
              ),
            ),
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
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  if (sparseLabels &&
                      i != 0 &&
                      i != bars.length - 1 &&
                      i != bars.length ~/ 2) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      bars[i].label,
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 10,
                        color: hg.textMuted,
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
                    width: sparseLabels ? 5 : 13,
                    borderRadius: BorderRadius.circular(3),
                    color: bars[i].highlight
                        ? hg.accent
                        : hg.accent.withValues(alpha: 0.55),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
