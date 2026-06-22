import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Stable notification IDs (so we can cancel/replace). The quote stream uses a
/// small contiguous range (one per upcoming day).
class HgNotif {
  static const focusReminder = 3001;
  static const streakReminder = 3003;
  static const quoteBase = 3100; // quoteBase .. quoteBase + quoteDays - 1
  static const quoteDays = 7;

  static const channel = 'engagement';
}

/// Wraps `flutter_local_notifications` for the MAIN isolate: permission + the
/// opt-in scheduled engagement notifications (focus reminder, daily quote/tip,
/// streak nudge). The live in-session alerts are separate — they run in the
/// foreground-service isolate (see `session_guard.dart`). Every call is guarded
/// so a notification failure can never disrupt the app.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_hourglass'),
        ),
      );
      _ready = true;
    } catch (_) {}
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Ask for POST_NOTIFICATIONS (Android 13+). Returns whether it's granted.
  Future<bool> requestPermission() async {
    await init();
    if (!Platform.isAndroid) return false;
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          HgNotif.channel,
          'Reminders & encouragement',
          channelDescription:
              'Focus reminders, daily quotes & tips, and gentle streak nudges. '
              'All optional — you choose which to receive.',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          icon: 'ic_stat_hourglass',
          styleInformation: BigTextStyleInformation(''),
        ),
      );

  /// Schedule a daily-repeating notification at [hour]:[minute] local time.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOf(hour, minute),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // repeats daily
      );
    } catch (_) {}
  }

  /// Schedule a one-shot notification at a specific local [when].
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    await init();
    if (!_ready) return;
    try {
      final tzWhen = tz.TZDateTime.from(when, tz.local);
      if (!tzWhen.isAfter(tz.TZDateTime.now(tz.local))) return; // past — skip
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzWhen,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {}
  }

  /// Fire an immediate in-session alert (break start/end, session complete) on
  /// the same high-priority channel the foreground-service isolate uses, so they
  /// read as one consistent stream. Used from the foreground (in-app) where the
  /// main isolate is reliably alive.
  Future<void> showSessionAlert(String title, String body) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: 9100,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'session_alerts',
            'Session alerts',
            channelDescription:
                'Break and return alerts during a focus session.',
            importance: Importance.max,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            icon: 'ic_stat_hourglass',
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    await init();
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelRange(int base, int count) async {
    for (var i = 0; i < count; i++) {
      await cancel(base + i);
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }
}
