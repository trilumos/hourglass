import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The two "come back to keep your block" prompts. They must be PUSH
/// notifications because the grace windows happen while the user is OUTSIDE the
/// app, where in-app UI can't be shown.
enum GraceKind { leaveRunning, pauseCap }

/// Fires/cancels the grace notifications. Abstracted so tests and preview use a
/// silent no-op and never touch the notifications plugin.
abstract class SessionNotifier {
  /// Initialize the plugin + ask for notification permission. Idempotent; safe
  /// to call at session start.
  Future<void> init();

  /// Show the grace notification immediately. (We fire it the moment the user
  /// leaves — not on a scheduled alarm — because Android delays/drops inexact
  /// alarms under battery optimization, so a scheduled reminder is unreliable.)
  Future<void> showGrace(GraceKind kind);

  /// Clear the shown grace notification (the user came back in time).
  Future<void> cancel();
}

/// Does nothing — tests, theme preview, platforms without notifications.
class SilentSessionNotifier implements SessionNotifier {
  const SilentSessionNotifier();
  @override
  Future<void> init() async {}
  @override
  Future<void> showGrace(GraceKind kind) async {}
  @override
  Future<void> cancel() async {}
}

/// Real local notifications via `flutter_local_notifications`.
class LocalSessionNotifier implements SessionNotifier {
  static const _id = 7301; // single id → a new grace replaces the previous one
  static const _channelId = 'session_grace';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {/* notifications are a best-effort nudge */}
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Session reminders',
      channelDescription: 'Reminders to return to a running focus session.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    ),
  );

  ({String title, String body}) _copy(GraceKind kind) => switch (kind) {
        GraceKind.leaveRunning => (
            title: 'Come back to keep your block',
            body: 'You have 30 seconds before this block ends.'
          ),
        GraceKind.pauseCap => (
            title: 'You\'re paused',
            body: 'Come back soon to keep your block — your pause won\'t last '
                'forever.'
          ),
      };

  @override
  Future<void> showGrace(GraceKind kind) async {
    try {
      await init();
      final c = _copy(kind);
      await _plugin.show(
        id: _id,
        title: c.title,
        body: c.body,
        notificationDetails: _details,
      );
    } catch (_) {/* never let a reminder disrupt a session */}
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}
