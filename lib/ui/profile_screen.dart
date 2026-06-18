import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import 'edit_profile_screen.dart';
import 'focus_score_screen.dart';
import 'guide_screen.dart';
import 'insights_screen.dart';
import 'photo_viewer_screen.dart';
import 'session_format.dart';
import 'session_history_screen.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/score_ring.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';
import 'widgets/stat_tile.dart';
import 'widgets/surface_tile.dart';

/// The "you" hub: identity, a warm stats bento led by the Focus Score, and
/// entry points to history. (Level + Collection arrive with the V2 Levels
/// system.) Built to docs/design-language.md — bento is reserved for stats.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final profile = ref.watch(profileProvider).value;
    final focusScore = ref.watch(focusScoreProvider).value ?? 0;
    final stats =
        ref.watch(profileStatsProvider).value ?? ProfileStats.empty;

    final hasName = profile?.hasName ?? false;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Profile'),
                const SizedBox(height: HgSpacing.xl),

                // ── Identity ────────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final path = profile?.imagePath;
                      if (path != null) {
                        _push(context, PhotoViewerScreen(imagePath: path));
                      } else {
                        _push(context, const EditProfileScreen());
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: hg.glow, blurRadius: 28, spreadRadius: 1),
                        ],
                      ),
                      child: const ProfileAvatar(size: 92),
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.md),
                Center(
                  child: Text(
                    hasName ? profile!.name : 'Add your name',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: hasName ? hg.textPrimary : hg.textMuted,
                    ),
                  ),
                ),
                if (stats.firstDate != null) ...[
                  const SizedBox(height: HgSpacing.xs),
                  Center(
                    child: Text(
                      'Focusing since ${formatDate(stats.firstDate!)}',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 13,
                        color: hg.textMuted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: HgSpacing.md),
                Center(
                  child: _Capsule(
                    label: hasName ? 'Edit profile' : 'Set up your profile',
                    onTap: () => _push(context, const EditProfileScreen()),
                  ),
                ),
                const SizedBox(height: HgSpacing.xl),

                // ── Focus Score — the signature tile ────────────────────────
                _FocusTile(
                  score: focusScore,
                  onTap: () => _push(context, const FocusScoreScreen()),
                ),
                const SizedBox(height: 12),

                // ── Supporting stats ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Total focus',
                        value: formatFocusDuration(stats.totalFocus),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                          label: 'Streak', value: '${stats.streak}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                          label: 'Sessions',
                          value: '${stats.sessionsCompleted}'),
                    ),
                  ],
                ),
                const SizedBox(height: HgSpacing.xl),

                // ── More ────────────────────────────────────────────────────
                _SectionLabel('MORE'),
                const SizedBox(height: HgSpacing.xs),
                _NavRow(
                  title: 'Insights',
                  subtitle: 'Charts of your focus',
                  onTap: () => _push(context, const InsightsScreen()),
                ),
                Divider(height: 1, color: hg.hairline),
                const SizedBox(height: HgSpacing.xs),
                _NavRow(
                  title: 'Session history',
                  onTap: () => _push(context, const SessionHistoryScreen()),
                ),
                Divider(height: 1, color: hg.hairline),
                _NavRow(
                  title: 'How Hourglass works',
                  onTap: () => _push(context, const GuideScreen()),
                ),
                const SizedBox(height: HgSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusTile extends StatelessWidget {
  final int score;
  final VoidCallback onTap;
  const _FocusTile({required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SurfaceTile(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.lg, vertical: HgSpacing.lg),
      child: Row(
        children: [
          ScoreRing(
            value: score,
            size: 72,
            stroke: 6,
            child: Text(
              '$score',
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: hg.accent,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: HgSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FOCUS SCORE',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: hg.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your recent focus ability',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 14,
                    height: 1.3,
                    color: hg.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: hg.textMuted),
        ],
      ),
    );
  }
}

class _Capsule extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Capsule({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Material(
      color: hg.accent,
      borderRadius: BorderRadius.circular(HgRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HgRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: HgSpacing.lg, vertical: HgSpacing.sm),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: hg.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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

class _NavRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _NavRow({
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HgRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HgSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 16,
                      color: disabled ? hg.textMuted : hg.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 13,
                        color: hg.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: hg.textMuted, size: HgSize.iconMd),
          ],
        ),
      ),
    );
  }
}
