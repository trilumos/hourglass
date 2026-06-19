import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/root_gate.dart';
import '../app/theme.dart';
import '../app/theme_controller.dart';
import '../app/tokens.dart';
import 'guide_screen.dart';
import 'profile_screen.dart';
import 'widgets/screen_background.dart';

/// User preferences. Calm, grouped rows — Display (theme) and Session (how
/// breaks advance). Grows as more preferences land.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final themeMode = ref.watch(themeControllerProvider).mode;
    final autoAdvance = ref.watch(breakAutoAdvanceProvider).asData?.value ?? true;
    final runUntilEnded =
        ref.watch(flowRunUntilEndedProvider).asData?.value ?? false;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: HgSize.iconMd,
                      color: hg.textSecondary,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: HgSpacing.xs),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: HgSpacing.lg),

                // ── Profile ──────────────────────────────────────────────────
                _SectionLabel('PROFILE'),
                const SizedBox(height: HgSpacing.sm),
                _ChoiceRow(
                  title: 'Profile',
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                ),

                const SizedBox(height: HgSpacing.xl),

                // ── Display ──────────────────────────────────────────────────
                _SectionLabel('DISPLAY'),
                const SizedBox(height: HgSpacing.sm),
                for (final mode in ThemeMode.values)
                  _ChoiceRow(
                    title: switch (mode) {
                      ThemeMode.system => 'Match system',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    },
                    selected: mode == themeMode,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(themeControllerProvider.notifier).setMode(mode);
                    },
                  ),

                const SizedBox(height: HgSpacing.xl),

                // ── Session ──────────────────────────────────────────────────
                _SectionLabel('SESSION'),
                const SizedBox(height: HgSpacing.sm),
                _SwitchRow(
                  title: 'Auto-start next block',
                  subtitle: autoAdvance
                      ? 'After a break, the next focus block begins on its own.'
                      : 'After a break, you tap to start the next focus block.',
                  value: autoAdvance,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(settingsRepositoryProvider)
                        .setBool(SettingsKeys.breakAutoAdvance, v);
                    ref.invalidate(breakAutoAdvanceProvider);
                  },
                ),
                const SizedBox(height: HgSpacing.sm),
                _SwitchRow(
                  title: 'Run Flow sessions until I end them',
                  subtitle:
                      "When on, a Flow session never stops on its own — it keeps "
                      "running until you tap End. When off, it stops at its set "
                      "length (with a “keep going” option near the end).",
                  value: runUntilEnded,
                  onChanged: (v) async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(settingsRepositoryProvider)
                        .setBool(SettingsKeys.flowRunUntilEnded, v);
                    ref.invalidate(flowRunUntilEndedProvider);
                  },
                ),
                const SizedBox(height: HgSpacing.xl),

                // ── About ────────────────────────────────────────────────────
                _SectionLabel('ABOUT'),
                const SizedBox(height: HgSpacing.sm),
                _ActionRow(
                  title: 'How it works',
                  subtitle: 'Modes, the Flow method, and your numbers',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GuideScreen()),
                  ),
                ),
                const SizedBox(height: HgSpacing.sm),
                _ActionRow(
                  title: 'Open-source licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Sustain',
                    applicationVersion: '1.0.0',
                  ),
                ),
                const SizedBox(height: HgSpacing.xl),

                // ── Data (last, so it's out of the way of accidental taps) ───
                _SectionLabel('DATA'),
                const SizedBox(height: HgSpacing.sm),
                _ActionRow(
                  title: 'Clear all data',
                  subtitle:
                      'Delete every session, your stats, and profile. Can’t be undone.',
                  danger: true,
                  onTap: () => _confirmClear(context, ref),
                ),
                const SizedBox(height: HgSpacing.xxl),

                // ── Version (absolute bottom) ────────────────────────────────
                Center(
                  child: Text(
                    'Sustain 1.0.0',
                    style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 12,
                      color: hg.textMuted,
                    ),
                  ),
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

Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _ClearDataDialog(),
  );
  if (ok != true) return;
  await _clearAll(ref);
  if (context.mounted) {
    // Factory reset → re-run onboarding (the clean way to recreate a profile).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootGate()),
      (route) => false,
    );
  }
}

class _ClearDataDialog extends StatefulWidget {
  const _ClearDataDialog();
  @override
  State<_ClearDataDialog> createState() => _ClearDataDialogState();
}

class _ClearDataDialogState extends State<_ClearDataDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final canDelete = _controller.text.trim() == 'Delete';
    return AlertDialog(
      backgroundColor: hg.surfaceRaised,
      title: const Text('Clear all data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'This permanently deletes every session, your stats, and your '
              'profile. This can’t be undone.'),
          const SizedBox(height: HgSpacing.md),
          Text('Type Delete to confirm.',
              style: TextStyle(color: hg.textMuted, fontSize: 13)),
          const SizedBox(height: HgSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Delete'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
          onPressed: canDelete ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: hg.danger),
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}

Future<void> _clearAll(WidgetRef ref) async {
  final profile = await ref.read(profileProvider.future);
  if (profile.imagePath != null) {
    await ref.read(imageStorageProvider).deleteAvatar(profile.imagePath!);
  }
  await ref.read(sessionRepositoryProvider).deleteAll();
  await ref.read(profileRepositoryProvider).reset();
  // Factory reset: re-run first-run onboarding next.
  await ref
      .read(settingsRepositoryProvider)
      .setBool(SettingsKeys.onboardingComplete, false);
  ref.invalidate(profileProvider);
  ref.invalidate(homeStatsProvider);
  ref.invalidate(focusScoreProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(sessionHistoryProvider);
  ref.invalidate(onboardingCompleteProvider);
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool danger;
  final VoidCallback onTap;
  const _ActionRow({
    required this.title,
    this.subtitle,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
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
                      color: danger ? hg.danger : hg.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 13,
                        height: 1.3,
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

class _ChoiceRow extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HgRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HgSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 16,
                  color: hg.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: hg.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 16,
                    color: hg.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 13,
                    height: 1.3,
                    color: hg.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: HgSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: hg.accent,
          ),
        ],
      ),
    );
  }
}
