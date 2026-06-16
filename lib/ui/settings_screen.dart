import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/theme_controller.dart';
import '../app/tokens.dart';
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
                const SizedBox(height: HgSpacing.xl),
              ],
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
