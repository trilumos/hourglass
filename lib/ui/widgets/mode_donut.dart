import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../../domain/analytics_calculator.dart';
import '../../domain/session_mode.dart';
import '../session_format.dart';

/// Share of focus across the three modes as a donut + legend. The center reads
/// the period total by default; tapping a mode (donut segment or legend row)
/// pulls it out and shows that mode's time and share in the center. Flow Block
/// leads in full accent; Pomodoro and Custom are progressively muted.
class ModeDonut extends StatefulWidget {
  final List<ModeSlice> slices;
  const ModeDonut({super.key, required this.slices});

  @override
  State<ModeDonut> createState() => _ModeDonutState();
}

class _ModeDonutState extends State<ModeDonut> {
  SessionMode? _selected;

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
    final slices = widget.slices;
    final visible = slices.where((s) => s.fraction > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final total =
        slices.fold(Duration.zero, (a, s) => a + s.focus);
    final sel =
        _selected == null ? null : slices.firstWhere((s) => s.mode == _selected);

    final centerTop =
        sel != null ? '${(sel.fraction * 100).round()}%' : formatFocusDuration(total);
    final centerBottom = sel != null ? modeLabel(sel.mode) : 'total focus';

    return Row(
      children: [
        SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 38,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final section = response?.touchedSection;
                      if (section == null) return;
                      final idx = section.touchedSectionIndex;
                      if (idx < 0 || idx >= visible.length) return;
                      final mode = visible[idx].mode;
                      setState(() => _selected = _selected == mode ? null : mode);
                    },
                  ),
                  sections: [
                    for (final s in visible)
                      PieChartSectionData(
                        value: s.fraction,
                        color: _color(context, s.mode),
                        radius: s.mode == _selected ? 26 : 20,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTop,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: hg.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    centerBottom,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 10.5,
                      letterSpacing: 0.5,
                      color: hg.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: HgSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in slices)
                _LegendRow(
                  color: _color(context, s.mode),
                  label: modeLabel(s.mode),
                  percent: (s.fraction * 100).round(),
                  selected: s.mode == _selected,
                  onTap: () => setState(
                      () => _selected = _selected == s.mode ? null : s.mode),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int percent;
  final bool selected;
  final VoidCallback onTap;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HgRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: HgSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? hg.textPrimary : hg.textSecondary,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? hg.accent : hg.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
