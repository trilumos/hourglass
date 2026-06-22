import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import '../notifications/notification_coordinator.dart';
import '../notifications/notification_prefs.dart';
import 'widgets/screen_background.dart';
import 'widgets/screen_header.dart';

/// Settings → Notifications. Every notification here is opt-in and OFF by
/// default — nothing is sent unless the user turns it on (the brand's "only
/// reminders you set yourself" rule). Toggling one on asks for the OS
/// permission, and every change reconciles the schedule.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _denied = false;

  Future<void> _afterToggle(bool turnedOn) async {
    if (turnedOn) {
      final granted =
          await ref.read(notificationServiceProvider).requestPermission();
      if (mounted) setState(() => _denied = !granted);
    }
    await syncNotifications(ref);
  }

  Future<void> _pickTime(int minutes, Future<void> Function(int) setter) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) {
      await setter(picked.hour * 60 + picked.minute);
      await syncNotifications(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final prefs = ref.watch(notificationPrefsProvider);
    final ctrl = ref.read(notificationPrefsProvider.notifier);

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                const ScreenHeader(title: 'Notifications'),
                const SizedBox(height: HgSpacing.md),
                Text(
                  'Everything here is optional and off until you turn it on. '
                  'Nothing nudges you unless you ask it to, and it all stays on '
                  'your device.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 14,
                    height: 1.5,
                    color: hg.textSecondary,
                  ),
                ),
                if (_denied) ...[
                  const SizedBox(height: HgSpacing.md),
                  _DeniedNote(),
                ],
                const SizedBox(height: HgSpacing.lg),

                _NotifSwitch(
                  title: 'Focus reminder',
                  subtitle: prefs.focusReminder
                      ? 'A daily nudge to train your focus.'
                      : 'A daily nudge at a time you choose.',
                  value: prefs.focusReminder,
                  onChanged: (v) async {
                    await ctrl.setFocusReminder(v);
                    await _afterToggle(v);
                  },
                ),
                if (prefs.focusReminder)
                  _TimeRow(
                    label: 'Remind me at',
                    minutes: prefs.focusReminderMinutes,
                    onTap: () => _pickTime(
                        prefs.focusReminderMinutes, ctrl.setFocusReminderMinutes),
                  ),
                _Divider(),

                _NotifSwitch(
                  title: 'Daily quote & tip',
                  subtitle: 'A short bit of encouragement or a focus tip, once a day.',
                  value: prefs.quotes,
                  onChanged: (v) async {
                    await ctrl.setQuotes(v);
                    await _afterToggle(v);
                  },
                ),
                if (prefs.quotes)
                  _TimeRow(
                    label: 'Send it at',
                    minutes: prefs.quotesMinutes,
                    onTap: () =>
                        _pickTime(prefs.quotesMinutes, ctrl.setQuotesMinutes),
                  ),
                _Divider(),

                _NotifSwitch(
                  title: 'Streak reminder',
                  subtitle: 'A gentle evening nudge only on days you have a '
                      'streak going but haven\'t focused yet. Never a guilt trip.',
                  value: prefs.streakReminder,
                  onChanged: (v) async {
                    await ctrl.setStreakReminder(v);
                    await _afterToggle(v);
                  },
                ),
                const SizedBox(height: HgSpacing.xl),
                Text(
                  'Your live session notification (the focus timer and "come '
                  'back" reminders) is always on while a session runs — it is '
                  'how Sustain protects your block.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 12.5,
                    height: 1.5,
                    color: hg.textMuted,
                  ),
                ),
                const SizedBox(height: HgSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifSwitch({
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
                    height: 1.35,
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

class _TimeRow extends StatelessWidget {
  final String label;
  final int minutes;
  final VoidCallback onTap;
  const _TimeRow(
      {required this.label, required this.minutes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HgRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: HgSpacing.sm, horizontal: HgSpacing.xs),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 14,
                color: hg.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              time.format(context),
              style: TextStyle(
                fontFamily: HgFont.sans,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: hg.accent,
              ),
            ),
            const SizedBox(width: HgSpacing.xs),
            Icon(Icons.schedule_rounded, size: 18, color: hg.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HgSpacing.sm),
        child: Divider(height: 1, color: context.hg.hairline),
      );
}

class _DeniedNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      padding: const EdgeInsets.all(HgSpacing.md),
      decoration: BoxDecoration(
        color: hg.surfaceRaised,
        borderRadius: BorderRadius.circular(HgRadius.md),
        border: Border.all(color: hg.hairline),
      ),
      child: Text(
        'Notifications are turned off for Sustain in your phone\'s settings, so '
        'these won\'t appear until you allow them there.',
        style: TextStyle(
          fontFamily: HgFont.sans,
          fontSize: 13,
          height: 1.4,
          color: hg.textSecondary,
        ),
      ),
    );
  }
}
