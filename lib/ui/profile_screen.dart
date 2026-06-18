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
import 'widgets/score_ring.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

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
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Profile'),
                const SizedBox(height: HgSpacing.xl),

                // ── Identity ────────────────────────────────────────────────
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: hg.glow, blurRadius: 28, spreadRadius: 1),
                      ],
                    ),
                    child: const ProfileAvatar(size: 92),
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
                      child: _StatTile(
                        label: 'Total focus',
                        value: formatFocusDuration(stats.totalFocus),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                          label: 'Streak', value: '${stats.streak}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
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
                  title: 'Session history',
                  onTap: () => _push(context, const SessionHistoryScreen()),
                ),
                Divider(height: 1, color: hg.hairline),
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

/// Soft-rect tile: lighter warm surface in dark, white + soft shadow in light.
class _Tile extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const _Tile({
    required this.child,
    this.padding = const EdgeInsets.all(HgSpacing.md),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final light = Theme.of(context).brightness == Brightness.light;
    return Material(
      color: hg.surfaceRaised,
      borderRadius: BorderRadius.circular(HgRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HgRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HgRadius.lg),
            border: Border.all(color: hg.hairline),
            boxShadow: light ? hgShadowSoft : null,
          ),
          child: Padding(padding: padding, child: child),
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
    return _Tile(
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
                color: hg.textPrimary,
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return _Tile(
      padding: const EdgeInsets.symmetric(
          horizontal: HgSpacing.sm, vertical: HgSpacing.md),
      child: Column(
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
                color: hg.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 9.5,
              letterSpacing: 1.2,
              color: hg.textMuted,
            ),
          ),
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
      color: hg.surfaceRaised,
      borderRadius: BorderRadius.circular(HgRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HgRadius.pill),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HgRadius.pill),
            border: Border.all(color: hg.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: HgSpacing.md, vertical: HgSpacing.sm),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: hg.textSecondary,
              ),
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
