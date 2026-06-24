import 'package:app_settings/app_settings.dart';
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

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with WidgetsBindingObserver {
  bool _denied = false;
  bool _sessionGranted = false; // OS permission for session notifications

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning from the system settings page — re-check, so the warning clears
    // the moment the user enables notifications there.
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  /// Show the "blocked" note only when a reminder is on but the OS is blocking
  /// it — the actionable conflict, not an unprompted scare.
  Future<void> _refreshPermission() async {
    final granted = await ref.read(notificationServiceProvider).hasPermission();
    final prefs = ref.read(notificationPrefsProvider);
    final anyOn =
        prefs.focusReminder || prefs.quotes || prefs.streakReminder;
    if (mounted) {
      setState(() {
        _sessionGranted = granted;
        _denied = anyOn && !granted;
      });
    }
    if (granted) await syncNotifications(ref);
  }

  /// The session live timer + "come back" pushes need POST_NOTIFICATIONS. This
  /// toggle mirrors that OS permission. Turning it on asks for permission again
  /// (and, once Android stops showing the prompt after a denial, opens system
  /// settings instead); turning it off opens settings, since an app can't revoke
  /// its own permission.
  Future<void> _setSessionNotifications(bool desired) async {
    final svc = ref.read(notificationServiceProvider);
    if (desired) {
      final granted = await svc.requestPermission();
      if (!granted) {
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
      }
    } else {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    }
    await _refreshPermission();
  }

  Future<void> _afterToggle(bool turnedOn) async {
    if (turnedOn) {
      final granted =
          await ref.read(notificationServiceProvider).requestPermission();
      if (mounted) setState(() => _denied = !granted);
    } else if (mounted) {
      setState(() => _denied = false); // turning things off clears the warning
    }
    await syncNotifications(ref);
  }

  /// After a denial Android won't show the permission dialog again, so the only
  /// way back on is the system settings page — open it directly.
  Future<void> _openSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
    // _refreshPermission runs on resume (didChangeAppLifecycleState).
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
                  'Everything here is optional and stays on your device. '
                  'Session notifications power the live timer; the reminders below '
                  'are off until you turn them on.',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 14,
                    height: 1.5,
                    color: hg.textSecondary,
                  ),
                ),
                const SizedBox(height: HgSpacing.lg),

                // ── Session notifications (the live timer + grace pushes) ──────
                _SectionLabel('DURING A SESSION'),
                const SizedBox(height: HgSpacing.xs),
                _NotifSwitch(
                  title: 'Session notifications',
                  subtitle: _sessionGranted
                      ? 'The live focus timer and "come back" reminders while a '
                          'session runs. This is how Sustain protects your block.'
                      : 'Turned off in your phone settings — the live timer and '
                          '"come back" reminders can\'t show. Turn on to allow them.',
                  value: _sessionGranted,
                  onChanged: _setSessionNotifications,
                ),
                const SizedBox(height: HgSpacing.lg),

                // ── Opt-in reminders ──────────────────────────────────────────
                _SectionLabel('REMINDERS'),
                const SizedBox(height: HgSpacing.xs),
                if (_denied) ...[
                  const SizedBox(height: HgSpacing.xs),
                  _DeniedNote(onOpenSettings: _openSettings),
                  const SizedBox(height: HgSpacing.sm),
                ],

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
                  'Tip: if you blocked notifications when a session asked, turn '
                  '"Session notifications" back on above — your phone will ask '
                  'again, or take you to settings to allow them.',
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

class _DeniedNote extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _DeniedNote({required this.onOpenSettings});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications are turned off for Sustain in your phone settings, so '
            'these reminders can\'t be delivered. Open settings to allow them.',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              height: 1.4,
              color: hg.textSecondary,
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          GestureDetector(
            onTap: onOpenSettings,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded, size: 16, color: hg.accent),
                const SizedBox(width: 6),
                Text(
                  'Open notification settings',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hg.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
