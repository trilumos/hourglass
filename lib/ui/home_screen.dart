import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/session_mode.dart';
import '../hourglass/hourglass_view.dart';
import 'focus_score_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';
import 'widgets/adaptive_tagline.dart';
import 'widgets/greeting_line.dart';
import 'widgets/mode_selector.dart';
import 'widgets/primary_button.dart';
import 'widgets/profile_avatar.dart';
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: GestureDetector(
                          onTap: _openProfile,
                          behavior: HitTestBehavior.opaque,
                          child: const ProfileAvatar(size: 36),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'SUSTAIN',
                          style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 14,
                            letterSpacing: 3.5,
                            color: hg.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _openSettings,
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
                _StatRow(
                  stats: stats,
                  focusScore: ref.watch(focusScoreProvider).value,
                ),
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

/// Quiet centered stats: Focus Score (the Flow Block metric), today's focus, streak.
class _StatRow extends StatelessWidget {
  final AsyncValue<HomeStats> stats;
  final int? focusScore;
  const _StatRow({required this.stats, required this.focusScore});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final data = stats.value ?? HomeStats.empty;
    Widget divider() => Container(
          width: 1,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: HgSpacing.lg),
          color: hg.hairline,
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FocusScoreScreen()),
          ),
          child: _Stat(
            label: 'Focus',
            value: '${focusScore ?? 0}',
            animatedNumber: focusScore ?? 0,
            accent: true,
          ),
        ),
        divider(),
        _Stat(label: 'Today', value: _formatFocus(data.todayFocus)),
        divider(),
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
  final bool accent;

  /// When set, the value animates (counts up/down) from its previous number to
  /// this one whenever it changes — used for the Focus Score after a session.
  final int? animatedNumber;
  const _Stat({
    required this.label,
    required this.value,
    this.accent = false,
    this.animatedNumber,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final style = TextStyle(
      fontFamily: HgFont.sans,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: accent ? hg.accent : hg.textPrimary,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (animatedNumber != null)
          TweenAnimationBuilder<double>(
            tween: Tween(end: animatedNumber!.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: HgMotion.calm,
            builder: (_, v, _) => Text('${v.round()}', style: style),
          )
        else
          Text(value, style: style),
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
