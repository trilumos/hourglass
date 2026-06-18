import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/analytics_calculator.dart';
import '../session_format.dart';

/// A small bar chart for the "when you focus" rhythms (time-of-day, day-of-week).
/// The peak bar reads in full accent; the rest are quietly muted. Every label
/// shows. Tap a bar for its exact focus value.
class RhythmBars extends StatelessWidget {
  final List<TimeBar> bars;
  const RhythmBars({super.key, required this.bars});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    if (bars.isEmpty) return const SizedBox.shrink();
    final maxMinutes = bars
        .map((b) => b.focus.inMinutes.toDouble())
        .fold(1.0, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 132,
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
                '${bars[group.x].label}\n${formatFocusDuration(bars[group.x].focus)}',
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
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      bars[i].label,
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 10,
                        color: bars[i].highlight ? hg.accent : hg.textMuted,
                        fontWeight:
                            bars[i].highlight ? FontWeight.w600 : FontWeight.w400,
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
                    width: 14,
                    borderRadius: BorderRadius.circular(3),
                    color: bars[i].highlight
                        ? hg.accent
                        : hg.accent.withValues(alpha: 0.30),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
