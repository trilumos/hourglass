import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/analytics_calculator.dart';
import 'session_format.dart';
import 'widgets/contribution_graph.dart';
import 'widgets/focus_trend_chart.dart';
import 'widgets/mode_donut.dart';
import 'widgets/rhythm_bars.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';
import 'widgets/stat_tile.dart';
import 'widgets/surface_tile.dart';

/// All of a person's focus data in one place: a lifetime records scorecard, the
/// consistency heatmap, then period-scoped charts (focus over time, when you
/// focus, by mode) under one Week/Month/All toggle. Replaces the old Activity
/// screen. Built to docs/design-language.md.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final stats = ref.watch(profileStatsProvider).value ?? ProfileStats.empty;
    final daily = ref.watch(dailyFocusProvider).value ?? const {};
    final range = ref.watch(analyticsRangeProvider);
    final data = ref.watch(analyticsProvider).value;

    final hasAnyData = stats.totalSessions > 0;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Insights'),
                const SizedBox(height: HgSpacing.xl),
                if (!hasAnyData)
                  _EmptyAll()
                else ...[
                  // ── Records (lifetime scorecard, first) ──────────────────
                  _Label('RECORDS'),
                  const SizedBox(height: HgSpacing.sm),
                  _row(
                    StatTile(
                        label: 'Total focus',
                        value: formatFocusDuration(stats.totalFocus)),
                    StatTile(label: 'Current streak', value: '${stats.streak}'),
                  ),
                  const SizedBox(height: 12),
                  _row(
                    StatTile(label: 'Best streak', value: '${stats.bestStreak}'),
                    StatTile(
                        label: 'Avg session',
                        value: formatFocusDuration(stats.avgSession)),
                  ),
                  const SizedBox(height: 12),
                  _row(
                    StatTile(
                        label: 'Longest',
                        value: formatFocusDuration(stats.longestSession)),
                    StatTile(label: 'Sessions', value: '${stats.totalSessions}'),
                  ),
                  if (stats.firstDate != null) ...[
                    const SizedBox(height: HgSpacing.md),
                    Center(
                      child: Text(
                        'Focusing since ${formatDate(stats.firstDate!)}',
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 13,
                          color: context.hg.textMuted,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: HgSpacing.xl),

                  // ── Consistency (heatmap, lifetime, no toggle) ───────────
                  _Label('CONSISTENCY'),
                  const SizedBox(height: HgSpacing.md),
                  SurfaceTile(
                    padding: const EdgeInsets.all(HgSpacing.md),
                    child: ContributionGraph(data: daily, today: now),
                  ),
                  const SizedBox(height: HgSpacing.xl),

                  // ── Range toggle — governs everything below ──────────────
                  _RangeToggle(
                    value: range,
                    onChanged: (r) =>
                        ref.read(analyticsRangeProvider.notifier).set(r),
                  ),
                  const SizedBox(height: HgSpacing.lg),

                  if (data == null)
                    const SizedBox(height: 120)
                  else if (data.isEmpty)
                    _NoData()
                  else ...[
                    // ── Focus over time ───────────────────────────────────
                    _Label('FOCUS OVER TIME'),
                    const SizedBox(height: HgSpacing.xs),
                    Text(
                      '${formatFocusDuration(data.rangeTotal)} ${_periodWord(range)}',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 14,
                        color: context.hg.textSecondary,
                      ),
                    ),
                    const SizedBox(height: HgSpacing.md),
                    SurfaceTile(
                      padding: const EdgeInsets.fromLTRB(
                          HgSpacing.sm, HgSpacing.lg, HgSpacing.sm, HgSpacing.sm),
                      child: FocusTrendChart(
                        bars: data.focusOverTime,
                        sparseLabels: range == AnalyticsRange.month,
                      ),
                    ),
                    const SizedBox(height: HgSpacing.xl),

                    // ── When you focus ────────────────────────────────────
                    _Label('WHEN YOU FOCUS'),
                    const SizedBox(height: HgSpacing.md),
                    SurfaceTile(
                      padding: const EdgeInsets.all(HgSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SubLabel('Time of day'),
                          const SizedBox(height: HgSpacing.sm),
                          RhythmBars(bars: data.timeOfDay),
                          const SizedBox(height: HgSpacing.lg),
                          _SubLabel('Day of week'),
                          const SizedBox(height: HgSpacing.sm),
                          RhythmBars(bars: data.dayOfWeek),
                        ],
                      ),
                    ),
                    const SizedBox(height: HgSpacing.xl),

                    // ── By mode ───────────────────────────────────────────
                    _Label('BY MODE'),
                    const SizedBox(height: HgSpacing.md),
                    SurfaceTile(
                      padding: const EdgeInsets.all(HgSpacing.lg),
                      child: ModeDonut(slices: data.byMode),
                    ),
                  ],
                  const SizedBox(height: HgSpacing.xl),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _periodWord(AnalyticsRange r) => switch (r) {
        AnalyticsRange.week => 'this week',
        AnalyticsRange.month => 'this month',
        AnalyticsRange.all => 'all time',
      };

  Widget _row(Widget a, Widget b) => Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );
}

/// The Week / Month / All segmented control.
class _RangeToggle extends StatelessWidget {
  final AnalyticsRange value;
  final ValueChanged<AnalyticsRange> onChanged;
  const _RangeToggle({required this.value, required this.onChanged});

  static const _labels = {
    AnalyticsRange.week: 'Week',
    AnalyticsRange.month: 'Month',
    AnalyticsRange.all: 'All',
  };

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: hg.surfaceSunken,
        borderRadius: BorderRadius.circular(HgRadius.pill),
      ),
      child: Row(
        children: [
          for (final r in AnalyticsRange.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: r == value ? hg.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(HgRadius.pill),
                  ),
                  child: Text(
                    _labels[r]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: r == value ? hg.onAccent : hg.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown when the whole history is empty.
class _EmptyAll extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.only(top: HgSpacing.xl),
      child: Center(
        child: Text(
          'Your insights appear as you focus.\nBegin your first block.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 15,
            height: 1.5,
            color: hg.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Shown when there's no focus in the selected range.
class _NoData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HgSpacing.xl),
      child: Center(
        child: Text(
          'No focus in this period.',
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 14,
            color: context.hg.textMuted,
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: context.hg.textMuted,
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.hg.textSecondary,
      ),
    );
  }
}
