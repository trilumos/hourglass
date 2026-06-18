import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/analytics_calculator.dart';
import '../../domain/session_mode.dart';
import '../session_format.dart';

/// Share of focus time across the three modes as a donut + legend. Flow Block
/// leads in full accent; Pomodoro and Custom are progressively muted. Renders
/// nothing when there's no focus in range (the screen shows a quiet note).
class ModeDonut extends StatelessWidget {
  final List<ModeSlice> slices;
  const ModeDonut({super.key, required this.slices});

  Color _color(BuildContext context, SessionMode mode) {
    final accent = context.hg.accent;
    return switch (mode) {
      SessionMode.flowBlock => accent,
      SessionMode.pomodoro => accent.withValues(alpha: 0.55),
      SessionMode.custom => accent.withValues(alpha: 0.30),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final hasData = slices.any((s) => s.fraction > 0);
    if (!hasData) return const SizedBox.shrink();

    return Row(
      children: [
        SizedBox(
          width: 124,
          height: 124,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              sections: [
                for (final s in slices)
                  if (s.fraction > 0)
                    PieChartSectionData(
                      value: s.fraction,
                      color: _color(context, s.mode),
                      radius: 22,
                      showTitle: false,
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: HgSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: _color(context, s.mode),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: HgSpacing.sm),
                      Expanded(
                        child: Text(
                          modeLabel(s.mode),
                          style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 14,
                            color: hg.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${(s.fraction * 100).round()}%',
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hg.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
