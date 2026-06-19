import 'package:flutter/material.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../session_format.dart';

/// A GitHub-style daily activity grid: one square per day over the last
/// [weeks] weeks, shaded by how much focus that day held. Tap a square to see
/// that day's detail in the bar above the grid.
class ContributionGraph extends StatefulWidget {
  final Map<DateTime, DayStat> data;
  final DateTime today;
  final int weeks;
  const ContributionGraph({
    super.key,
    required this.data,
    required this.today,
    this.weeks = 15,
  });

  @override
  State<ContributionGraph> createState() => _ContributionGraphState();
}

class _ContributionGraphState extends State<ContributionGraph> {
  DateTime? _selected;

  DateTime get _todayDate =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  // Sunday of the earliest visible week (weeks start Sunday). DateTime.weekday
  // is Mon=1..Sun=7, so `weekday % 7` is days since the most recent Sunday.
  DateTime get _start {
    final sundayThisWeek =
        _todayDate.subtract(Duration(days: _todayDate.weekday % 7));
    return sundayThisWeek.subtract(Duration(days: (widget.weeks - 1) * 7));
  }

  Color _cellColor(BuildContext context, Duration focus) {
    final hg = context.hg;
    final m = focus.inMinutes;
    final t = m <= 0
        ? 0.0
        : m < 15
            ? 0.3
            : m < 30
                ? 0.55
                : m < 60
                    ? 0.8
                    : 1.0;
    if (t == 0) return hg.surfaceSunken;
    return Color.lerp(hg.surfaceSunken, hg.accent, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    const gap = 3.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = ((constraints.maxWidth - gap * (widget.weeks - 1)) /
                widget.weeks)
            .floorToDouble();
        final start = _start;

        final columns = <Widget>[];
        for (var w = 0; w < widget.weeks; w++) {
          final cells = <Widget>[];
          for (var d = 0; d < 7; d++) {
            final date = start.add(Duration(days: w * 7 + d));
            final isFuture = date.isAfter(_todayDate);
            final stat = widget.data[date];
            final selected = _selected == date;
            cells.add(Padding(
              padding: EdgeInsets.only(bottom: d == 6 ? 0 : gap),
              child: isFuture
                  ? SizedBox(width: cell, height: cell)
                  : GestureDetector(
                      onTap: () => setState(
                          () => _selected = selected ? null : date),
                      child: Container(
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: _cellColor(
                              context, stat?.focus ?? Duration.zero),
                          borderRadius: BorderRadius.circular(3),
                          border: selected
                              ? Border.all(color: hg.textPrimary, width: 1.5)
                              : null,
                        ),
                      ),
                    ),
            ));
          }
          columns.add(Padding(
            padding: EdgeInsets.only(right: w == widget.weeks - 1 ? 0 : gap),
            child: Column(children: cells),
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailBar(selected: _selected, data: widget.data, today: _todayDate),
            const SizedBox(height: HgSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: columns,
            ),
            const SizedBox(height: HgSpacing.sm),
            _Legend(),
          ],
        );
      },
    );
  }
}

class _DetailBar extends StatelessWidget {
  final DateTime? selected;
  final Map<DateTime, DayStat> data;
  final DateTime today;
  const _DetailBar({
    required this.selected,
    required this.data,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final String text;
    if (selected == null) {
      text = 'Tap a day to see its focus.';
    } else {
      final stat = data[selected!];
      final when = dayHeading(selected!, today);
      if (stat == null) {
        text = '$when · no focus';
      } else {
        final n = stat.sessions;
        text =
            '$when · ${formatFocusDuration(stat.focus)} · $n session${n == 1 ? '' : 's'}';
      }
    }
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: selected == null ? hg.textMuted : hg.textPrimary,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    Widget swatch(double t) => Container(
          width: 11,
          height: 11,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: t == 0
                ? hg.surfaceSunken
                : Color.lerp(hg.surfaceSunken, hg.accent, t),
            borderRadius: BorderRadius.circular(3),
          ),
        );
    final style = TextStyle(
      fontFamily: HgFont.sans,
      fontSize: 11,
      color: hg.textMuted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: style),
        const SizedBox(width: 4),
        swatch(0),
        swatch(0.3),
        swatch(0.55),
        swatch(0.8),
        swatch(1.0),
        const SizedBox(width: 4),
        Text('More', style: style),
      ],
    );
  }
}
