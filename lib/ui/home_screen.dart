import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/theme_controller.dart';
import '../app/tokens.dart';
import '../domain/session_mode.dart';
import '../hourglass/hourglass_view.dart';
import 'setup_screen.dart';
import 'widgets/adaptive_tagline.dart';
import 'widgets/greeting_line.dart';
import 'widgets/mode_selector.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// The calm landing screen. Centered wordmark, tagline and hourglass hero; a
/// left-aligned editorial greeting; a quiet centered stats + action cluster.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  SessionMode _mode = SessionMode.flowBlock;

  void _begin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SetupScreen(mode: _mode)),
    );
  }

  void _openThemeSheet() {
    final hg = context.hg;
    final current = ref.read(themeControllerProvider).mode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: hg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(HgRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: HgSpacing.md),
              for (final mode in ThemeMode.values)
                ListTile(
                  title: Text(
                    switch (mode) {
                      ThemeMode.system => 'Match system',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    },
                    style: TextStyle(
                        fontFamily: HgFont.sans, color: hg.textPrimary),
                  ),
                  trailing: mode == current
                      ? Icon(Icons.check_rounded, color: hg.accent, size: 18)
                      : null,
                  onTap: () {
                    ref.read(themeControllerProvider.notifier).setMode(mode);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: HgSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final stats = ref.watch(homeStatsProvider);

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: HgSpacing.sm),
                // ── Top: wordmark (left) + settings gear (right) ───────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'HOURGLASS',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 14,
                        letterSpacing: 3.5,
                        color: hg.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: _openThemeSheet,
                      iconSize: HgSize.iconMd,
                      color: hg.textSecondary,
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: HgSpacing.md),
                const GreetingLine(), // greeting (primary, left) + pull-quote
                // ── Hero (centered) ────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: Padding(
                      // Minimal breathing room — lets the hourglass use the
                      // available vertical space without displacing anything.
                      padding:
                          const EdgeInsets.symmetric(vertical: HgSpacing.xs),
                      child: const HourglassView(
                        progress: 0,
                        heroTag: kHourglassHeroTag,
                      ),
                    ),
                  ),
                ),
                const AdaptiveTagline(), // tagline below the hourglass, centered
                const SizedBox(height: HgSpacing.lg),
                // ── Bottom cluster (centered, as before) ───────────────────
                _StatRow(stats: stats),
                const SizedBox(height: HgSpacing.lg),
                Center(
                  child: ModeSelector(
                    selected: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                ),
                const SizedBox(height: HgSpacing.lg),
                PrimaryButton(label: 'Begin', onPressed: _begin),
                const SizedBox(height: HgSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two quiet centered stats: today's focus time and the current streak.
class _StatRow extends StatelessWidget {
  final AsyncValue<HomeStats> stats;
  const _StatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final data = stats.asData?.value ?? HomeStats.empty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stat(label: 'Today', value: _formatFocus(data.todayFocus)),
        Container(
          width: 1,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: HgSpacing.lg),
          color: hg.hairline,
        ),
        _Stat(label: 'Streak', value: _formatStreak(data.streak)),
      ],
    );
  }

  static String _formatFocus(Duration d) {
    if (d.inMinutes <= 0) return '0m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String _formatStreak(int days) => days == 1 ? '1 day' : '$days days';
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: hg.textPrimary,
          ),
        ),
        const SizedBox(height: HgSpacing.xs),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 10,
            letterSpacing: 2,
            color: hg.textMuted,
          ),
        ),
      ],
    );
  }
}
