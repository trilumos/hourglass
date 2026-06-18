import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import 'session_format.dart';
import 'widgets/contribution_graph.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';
import 'widgets/stat_tile.dart';
import 'widgets/surface_tile.dart';

/// All the focus data in one place: a GitHub-style activity grid up top, the
/// records below. Keeps the Profile hub uncluttered.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final daily = ref.watch(dailyFocusProvider).value ?? const {};
    final stats =
        ref.watch(profileStatsProvider).value ?? ProfileStats.empty;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Activity'),
                const SizedBox(height: HgSpacing.xl),

                _Label('RECENT ACTIVITY'),
                const SizedBox(height: HgSpacing.md),
                SurfaceTile(
                  padding: const EdgeInsets.all(HgSpacing.md),
                  child: ContributionGraph(data: daily, today: now),
                ),
                const SizedBox(height: HgSpacing.xl),

                _Label('RECORDS'),
                const SizedBox(height: HgSpacing.sm),
                _row(
                  StatTile(
                      label: 'This week',
                      value: formatFocusDuration(stats.weekFocus)),
                  StatTile(
                      label: 'Best streak', value: '${stats.bestStreak}'),
                ),
                const SizedBox(height: 12),
                _row(
                  StatTile(
                      label: 'Avg session',
                      value: formatFocusDuration(stats.avgSession)),
                  StatTile(
                      label: 'Longest',
                      value: formatFocusDuration(stats.longestSession)),
                ),
                const SizedBox(height: 12),
                _row(
                  StatTile(
                      label: 'Total focus',
                      value: formatFocusDuration(stats.totalFocus)),
                  StatTile(
                      label: 'Sessions', value: '${stats.totalSessions}'),
                ),
                if (stats.firstDate != null) ...[
                  const SizedBox(height: HgSpacing.lg),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Text(
      text,
      style: TextStyle(
        fontFamily: HgFont.sans,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: hg.textMuted,
      ),
    );
  }
}
