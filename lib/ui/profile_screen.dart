import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import 'edit_profile_screen.dart';
import 'focus_score_screen.dart';
import 'session_format.dart';
import 'session_history_screen.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// The "you" hub: identity, headline stats, and entry points to the history and
/// Focus Score pages. (Level + Collection arrive with the V2 Levels system.)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final profile = ref.watch(profileProvider).asData?.value;
    final focusScore = ref.watch(focusScoreProvider).asData?.value ?? 0;
    final stats =
        ref.watch(profileStatsProvider).asData?.value ?? ProfileStats.empty;

    final name = (profile?.hasName ?? false) ? profile!.name : 'Add your name';

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Profile'),
                const SizedBox(height: HgSpacing.xl),

                // ── Identity ────────────────────────────────────────────────
                const Center(child: ProfileAvatar(size: 88)),
                const SizedBox(height: HgSpacing.md),
                Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: hg.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: HgSpacing.xs),
                Center(
                  child: TextButton(
                    onPressed: () => _push(context, const EditProfileScreen()),
                    child: const Text('Edit profile'),
                  ),
                ),
                if (!(profile?.isSetUp ?? false)) ...[
                  const SizedBox(height: HgSpacing.xs),
                  Center(
                    child: Text(
                      'Set up your profile',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 13,
                        color: hg.textMuted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: HgSpacing.xl),

                // ── Headline stats ─────────────────────────────────────────
                Row(
                  children: [
                    _StatCell(
                      label: 'Focus',
                      value: '$focusScore',
                      accent: true,
                      onTap: () =>
                          _push(context, const FocusScoreScreen()),
                    ),
                    _StatCell(
                        label: 'Total',
                        value: formatFocusDuration(stats.totalFocus)),
                    _StatCell(label: 'Streak', value: '${stats.streak}'),
                    _StatCell(
                        label: 'Sessions',
                        value: '${stats.sessionsCompleted}'),
                  ],
                ),
                const SizedBox(height: HgSpacing.xl),

                // ── Navigation ─────────────────────────────────────────────
                _NavRow(
                  title: 'Session history',
                  onTap: () =>
                      _push(context, const SessionHistoryScreen()),
                ),
                _NavRow(
                  title: 'Focus Score',
                  subtitle: 'How it’s calculated',
                  onTap: () => _push(context, const FocusScoreScreen()),
                ),
                const _NavRow(
                  title: 'Analytics',
                  subtitle: 'Charts of your focus',
                  soon: true,
                ),
                const SizedBox(height: HgSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  final VoidCallback? onTap;
  const _StatCell({
    required this.label,
    required this.value,
    this.accent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final cell = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: accent ? hg.accent : hg.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: HgSpacing.xs),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 10,
            letterSpacing: 1.5,
            color: hg.textMuted,
          ),
        ),
      ],
    );
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HgRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
          child: cell,
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool soon;
  const _NavRow({
    required this.title,
    this.subtitle,
    this.onTap,
    this.soon = false,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final disabled = soon || onTap == null;
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
            if (soon)
              _SoonChip()
            else
              Icon(Icons.chevron_right_rounded,
                  color: hg.textMuted, size: HgSize.iconMd),
          ],
        ),
      ),
    );
  }
}

class _SoonChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: HgSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: hg.accentMuted,
        borderRadius: BorderRadius.circular(HgRadius.pill),
      ),
      child: Text(
        'SOON',
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
          color: hg.textSecondary,
        ),
      ),
    );
  }
}
