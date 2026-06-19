import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/analytics_calculator.dart';
import '../domain/personal_bests.dart';
import '../domain/session_csv.dart';
import '../domain/stamina_calculator.dart';
import 'insights_copy.dart';
import 'session_format.dart';
import 'widgets/bar_readout_chart.dart';
import 'widgets/contribution_graph.dart';
import 'widgets/line_readout_chart.dart';
import 'widgets/mode_donut.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';
import 'widgets/stat_tile.dart';
import 'widgets/surface_tile.dart';

/// All of a person's focus data in one place. Two bands: a free **glance** —
/// lifetime Records + the consistency heatmap — then the Pro **depth band**
/// ([_DepthBand]): the Week/Month/All-scoped story (Focus Score & Stamina
/// trends, focus over time, when you focus, follow-through, by mode) plus
/// lifetime personal bests and a data export. The depth band is one cohesive
/// subtree so a later entitlement gate wraps it in a single line. Replaces the
/// old Activity screen. Built to docs/design-language.md.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final stats = ref.watch(profileStatsProvider).value ?? ProfileStats.empty;
    final daily = ref.watch(dailyFocusProvider).value ?? const {};

    final hasAnyData = stats.totalSessions > 0;
    final activeDays = _activeDaysLast30(daily, now);

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
                  const SizedBox(height: HgSpacing.xs),
                  const _Descriptor(InsightsCopy.records),
                  const SizedBox(height: HgSpacing.md),
                  _row(
                    StatTile(
                        label: 'Total focus',
                        value: formatFocusDuration(stats.totalFocus),
                        large: true),
                    StatTile(
                        label: 'Current streak',
                        value: '${stats.streak}',
                        large: true),
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
                  const SizedBox(height: HgSpacing.xs),
                  const _Descriptor(InsightsCopy.consistency),
                  const SizedBox(height: HgSpacing.md),
                  SurfaceTile(
                    padding: const EdgeInsets.all(HgSpacing.md),
                    child: ContributionGraph(data: daily, today: now),
                  ),
                  _Insight(InsightsCopy.consistencyInsight(activeDays)),
                  const SizedBox(height: HgSpacing.xl),

                  // ── Pro depth band (one wrappable subtree) ───────────────
                  const _DepthBand(),
                  const SizedBox(height: HgSpacing.xl),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Widget a, Widget b) => Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );
}

/// The Pro "depth" band: everything under the Week/Month/All toggle, kept as a
/// single subtree so a later entitlement gate wraps it in one line. Range-scoped
/// sections sit under the toggle; lifetime sections (personal bests, export)
/// follow, since those don't respond to the range.
class _DepthBand extends ConsumerWidget {
  const _DepthBand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeProvider);
    final data = ref.watch(analyticsProvider).value;
    final extras = ref.watch(insightsExtrasProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RangeToggle(
          value: range,
          onChanged: (r) => ref.read(analyticsRangeProvider.notifier).set(r),
        ),
        const SizedBox(height: HgSpacing.md),
        const _Descriptor(InsightsCopy.sourceLegend),
        const SizedBox(height: HgSpacing.lg),
        if (data == null || extras == null)
          const SizedBox(height: 200)
        else ...[
          if (data.isEmpty)
            const _NoData()
          else
            ..._rangeScoped(context, range, data, extras),

          // ── Personal bests (lifetime; ignores the range) ───────────────
          if (!extras.bests.isEmpty) ...[
            const SizedBox(height: HgSpacing.xl),
            _Label('PERSONAL BESTS'),
            const SizedBox(height: HgSpacing.xs),
            const _Descriptor(InsightsCopy.personalBests),
            const SizedBox(height: HgSpacing.md),
            _BestsList(extras.bests),
          ],

          // ── Export (lifetime; your data) ───────────────────────────────
          const SizedBox(height: HgSpacing.xl),
          _Label('YOUR DATA'),
          const SizedBox(height: HgSpacing.xs),
          const _Descriptor(InsightsCopy.dataExport),
          const SizedBox(height: HgSpacing.md),
          _ExportButton(onExport: () => _export(context, ref)),
        ],
      ],
    );
  }

  /// The range-governed story, in narrative order: how deep → how long you can
  /// hold → how much → when → how reliably → what kind.
  List<Widget> _rangeScoped(BuildContext context, AnalyticsRange range,
      AnalyticsData data, InsightsExtras extras) {
    final ft = extras.followThrough;
    return [
      // Focus Score trend
      _LineSection(
        label: 'FOCUS SCORE',
        descriptor: InsightsCopy.focusScore,
        flowOnly: true,
        source: InsightsCopy.focusScoreSource,
        points: extras.scoreTrend,
        minY: 0,
        maxY: 100,
        formatValue: (v) => '${v.round()}',
        emptyCopy: InsightsCopy.scoreEmpty,
        insight: InsightsCopy.scoreTrendInsight(extras.scoreTrend),
        note: range == AnalyticsRange.all ? null : InsightsCopy.scoreSlowNote,
      ),
      const SizedBox(height: HgSpacing.xl),

      // Focus Stamina growth
      _LineSection(
        label: 'FOCUS STAMINA',
        descriptor: InsightsCopy.stamina,
        flowOnly: true,
        source: InsightsCopy.staminaSource,
        points: extras.staminaGrowth,
        minY: 0,
        maxY: _staminaAxisMax(extras.staminaGrowth),
        guideY: StaminaCalculator.referenceBlock.inMinutes.toDouble(),
        guideLabel: '${StaminaCalculator.referenceBlock.inMinutes} min',
        formatValue: (v) => '${v.round()} min',
        emptyCopy: InsightsCopy.staminaEmpty,
        insight: InsightsCopy.staminaInsight(extras.staminaGrowth),
      ),
      const SizedBox(height: HgSpacing.xl),

      // Focus over time
      _Label('FOCUS OVER TIME'),
      const SizedBox(height: HgSpacing.xs),
      const _Descriptor(InsightsCopy.focusOverTime),
      const SizedBox(height: HgSpacing.md),
      SurfaceTile(
        padding: const EdgeInsets.all(HgSpacing.md),
        child: BarReadoutChart(
          bars: data.focusOverTime,
          height: 168,
          barWidth: range == AnalyticsRange.month ? 5 : 13,
          restAlpha: 0.55,
          sparseLabels: range == AnalyticsRange.month,
        ),
      ),
      _Insight(InsightsCopy.focusTotal(
          formatFocusDuration(data.rangeTotal), _periodWord(range))),
      _Subtle(InsightsCopy.comparison(
          data.rangeTotal, data.previousTotal, _periodNoun(range))),
      const SizedBox(height: HgSpacing.xl),

      // When you focus (+ peak-window recommendation)
      _Label('WHEN YOU FOCUS'),
      const SizedBox(height: HgSpacing.xs),
      const _Descriptor(InsightsCopy.whenYouFocus),
      const SizedBox(height: HgSpacing.md),
      SurfaceTile(
        padding: const EdgeInsets.all(HgSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SubLabel('Time of day'),
            const SizedBox(height: HgSpacing.sm),
            BarReadoutChart(bars: data.timeOfDay),
            _Insight(InsightsCopy.timeOfDayInsight(data.timeOfDay)),
            const SizedBox(height: HgSpacing.lg),
            _SubLabel('Day of week'),
            const SizedBox(height: HgSpacing.sm),
            BarReadoutChart(bars: data.dayOfWeek),
            _Insight(InsightsCopy.dayOfWeekInsight(data.dayOfWeek)),
          ],
        ),
      ),
      if (extras.peakWindow != null) _RecPanel(extras.peakWindow!),
      const SizedBox(height: HgSpacing.xl),

      // Follow-through (only when there are Flow sessions to speak for it)
      if (ft.sample > 0) ...[
        _Label('FOLLOW-THROUGH', tag: InsightsCopy.flowOnlyTag),
        const SizedBox(height: HgSpacing.xs),
        const _Descriptor(InsightsCopy.followThrough),
        const SizedBox(height: HgSpacing.md),
        _FollowThroughTile(ft, _periodNoun(range)),
        const SizedBox(height: HgSpacing.xl),
      ],

      // By mode
      _Label('BY MODE'),
      const SizedBox(height: HgSpacing.xs),
      const _Descriptor(InsightsCopy.byMode),
      const SizedBox(height: HgSpacing.md),
      SurfaceTile(
        padding: const EdgeInsets.all(HgSpacing.lg),
        child: ModeDonut(slices: data.byMode),
      ),
      _Insight(InsightsCopy.modeInsight(data.byMode)),
    ];
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final sessions = await ref.read(allSessionsProvider.future);
      if (sessions.isEmpty) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Nothing to export yet.')));
        return;
      }
      final csv = sessionsToCsv(sessions);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sustain-focus-history.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Sustain — focus history',
        text: 'My focus history from Sustain.',
      ));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't export right now.")));
    }
  }
}

/// The stamina chart's y-max. Always keeps the 90-min reference in view, and
/// expands past it (with headroom, rounded to 10) when the user's stamina
/// exceeds it — stamina has no cap, so the axis shows whatever they reach.
double _staminaAxisMax(List<TrendPoint> points) {
  var peak = StaminaCalculator.referenceBlock.inMinutes.toDouble();
  for (final p in points) {
    final v = p.value;
    if (v != null && v > peak) peak = v;
  }
  return (peak * 1.1 / 10).ceilToDouble() * 10;
}

String _periodWord(AnalyticsRange r) => switch (r) {
      AnalyticsRange.week => 'this week',
      AnalyticsRange.month => 'this month',
      AnalyticsRange.all => 'in total',
    };

String _periodNoun(AnalyticsRange r) => switch (r) {
      AnalyticsRange.week => 'last week',
      AnalyticsRange.month => 'last month',
      AnalyticsRange.all => '',
    };

/// Days in the last 30 (inclusive of today) that recorded any focus.
int _activeDaysLast30(Map<DateTime, DayStat> daily, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  var count = 0;
  for (var i = 0; i < 30; i++) {
    final stat = daily[today.subtract(Duration(days: i))];
    if (stat != null && stat.focus > Duration.zero) count++;
  }
  return count;
}

/// A line-chart section (Focus Score / Stamina) with an honest empty fallback:
/// when no bucket has a value yet, the chart is replaced by a plain teaching
/// line — never a fabricated flat line at zero.
class _LineSection extends StatelessWidget {
  final String label;
  final String descriptor;
  final List<TrendPoint> points;
  final double minY;
  final double maxY;
  final double? guideY;
  final String? guideLabel;
  final String Function(double) formatValue;
  final String emptyCopy;
  final String? insight;

  /// A quiet caveat under the insight (e.g. why a rolling average moves slowly).
  final String? note;

  /// Marks the section "FLOW ONLY" and shows the precise data rule [source].
  final bool flowOnly;
  final String? source;

  const _LineSection({
    required this.label,
    required this.descriptor,
    required this.points,
    required this.minY,
    required this.maxY,
    required this.formatValue,
    required this.emptyCopy,
    required this.insight,
    this.guideY,
    this.guideLabel,
    this.note,
    this.flowOnly = false,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    final hasSeries = points.any((p) => p.value != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, tag: flowOnly ? InsightsCopy.flowOnlyTag : null),
        const SizedBox(height: HgSpacing.xs),
        _Descriptor(descriptor),
        if (source != null) _Subtle(source),
        const SizedBox(height: HgSpacing.md),
        if (!hasSeries)
          _EmptyLine(emptyCopy)
        else ...[
          SurfaceTile(
            padding: const EdgeInsets.all(HgSpacing.md),
            child: LineReadoutChart(
              points: points,
              minY: minY,
              maxY: maxY,
              guideY: guideY,
              guideLabel: guideLabel,
              formatValue: formatValue,
            ),
          ),
          _Insight(insight),
          _Subtle(note),
        ],
      ],
    );
  }
}

/// The follow-through stat: a focal rate, a plain caption, a sample count for
/// trust, and the period comparison. Neutral framing, never guilt.
class _FollowThroughTile extends StatelessWidget {
  final FollowThrough ft;
  final String previousNoun;
  const _FollowThroughTile(this.ft, this.previousNoun);

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final pct = (ft.rate * 100).round();
    final comparison = InsightsCopy.followThroughComparison(ft, previousNoun);
    return SurfaceTile(
      padding: const EdgeInsets.all(HgSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$pct%',
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: hg.accent,
                ),
              ),
              const SizedBox(width: HgSpacing.md),
              Expanded(
                child: Text(
                  'of your Flow sessions reached their mark',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 14,
                    height: 1.3,
                    color: hg.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: HgSpacing.sm),
          Text(
            'Across ${ft.sample} Flow ${ft.sample == 1 ? 'session' : 'sessions'}'
            '${comparison == null ? '' : ' · $comparison'}',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              color: hg.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The lifetime records list — label · value · date rows, hairline-separated
/// (no nested cards). Each entry is omitted when there's no data for it.
class _BestsList extends StatelessWidget {
  final PersonalBests bests;
  const _BestsList(this.bests);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void add(String label, String value, {DateTime? on}) {
      rows.add(_BestRow(
        label: label,
        value: value,
        date: on == null ? null : formatDate(on),
      ));
    }

    if (bests.bestDayFocus != null) {
      add('Best focus day', formatFocusDuration(bests.bestDayFocus!),
          on: bests.bestDayDate);
    }
    if (bests.longestSession != null) {
      add('Longest session', formatFocusDuration(bests.longestSession!),
          on: bests.longestSessionDate);
    }
    if (bests.bestStreak > 0) {
      add('Best streak',
          '${bests.bestStreak} ${bests.bestStreak == 1 ? 'day' : 'days'}');
    }
    if (bests.highestFocusScore != null) {
      add('Highest Focus Score', '${bests.highestFocusScore}');
    }
    if (bests.focusingSince != null) {
      add('Focusing since', formatDate(bests.focusingSince!));
    }

    return SurfaceTile(
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.md, vertical: HgSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: context.hg.hairline),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _BestRow extends StatelessWidget {
  final String label;
  final String value;
  final String? date;
  const _BestRow({required this.label, required this.value, this.date});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HgSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                color: hg.textSecondary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: hg.textPrimary,
                ),
              ),
              if (date != null) ...[
                const SizedBox(height: 1),
                Text(
                  date!,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 11.5,
                    color: hg.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The calm CSV-export action — a secondary surface (pill is reserved for the
/// primary action), full-width, with a quiet share glyph.
class _ExportButton extends StatelessWidget {
  final VoidCallback onExport;
  const _ExportButton({required this.onExport});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SurfaceTile(
      onTap: onExport,
      padding: const EdgeInsets.symmetric(vertical: HgSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ios_share_rounded,
              size: HgSize.iconSm, color: hg.textSecondary),
          const SizedBox(width: HgSpacing.sm),
          Text(
            'Export CSV',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hg.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft accent-muted recommendation panel (the peak-window advice). Distinct
/// from an [_Insight] line: it reads as a gentle suggestion, not a stat.
class _RecPanel extends StatelessWidget {
  final String text;
  const _RecPanel(this.text);

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      margin: const EdgeInsets.only(top: HgSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.md, vertical: HgSpacing.sm + 2),
      decoration: BoxDecoration(
        color: hg.accentMuted,
        borderRadius: BorderRadius.circular(HgRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_twilight_rounded,
              size: HgSize.iconSm, color: hg.accent),
          const SizedBox(width: HgSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: hg.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  const _NoData();
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

/// An honest stand-in for a chart that has no data yet — a plain teaching line
/// in a quiet surface, never a flat zero line.
class _EmptyLine extends StatelessWidget {
  final String text;
  const _EmptyLine(this.text);
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SurfaceTile(
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.md, vertical: HgSpacing.lg),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 14,
          height: 1.4,
          color: hg.textMuted,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  /// Optional scope chip beside the label (e.g. "FLOW ONLY").
  final String? tag;
  const _Label(this.text, {this.tag});
  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: context.hg.textMuted,
      ),
    );
    if (tag == null) return label;
    return Row(
      children: [
        label,
        const SizedBox(width: HgSpacing.sm),
        _Tag(tag!),
      ],
    );
  }
}

/// A small accent-muted scope chip — marks which sections track Flow only.
class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hg.accentMuted,
        borderRadius: BorderRadius.circular(HgRadius.sm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 9,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
          color: hg.accent,
        ),
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

/// A plain-language line under a section label saying what the chart shows.
class _Descriptor extends StatelessWidget {
  final String text;
  const _Descriptor(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 13,
        height: 1.35,
        color: context.hg.textMuted,
      ),
    );
  }
}

/// The personalized takeaway under a chart — accent voice. Renders nothing
/// (and takes no space) when there isn't enough data to say something true.
class _Insight extends StatelessWidget {
  final String? text;
  const _Insight(this.text);
  @override
  Widget build(BuildContext context) {
    final t = text;
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: HgSpacing.sm),
      child: Text(
        t,
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: context.hg.accent,
        ),
      ),
    );
  }
}

/// A quiet secondary line (e.g. the period comparison). Hidden when null.
class _Subtle extends StatelessWidget {
  final String? text;
  const _Subtle(this.text);
  @override
  Widget build(BuildContext context) {
    final t = text;
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        t,
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 13,
          color: context.hg.textMuted,
        ),
      ),
    );
  }
}
