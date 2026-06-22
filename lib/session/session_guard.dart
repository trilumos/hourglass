import 'dart:ui' show Color;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

/// Warm Sand-accent used behind the status-bar hourglass on the notification.
const _brandAccent = Color(0xFFC8841E);

/// Owns the session's FOREGROUND-SERVICE notification — a persistent, lock-screen
/// notification present for the whole session that becomes a live, non-dismissable
/// countdown when the user leaves or pauses-and-leaves, plus discrete buzzing
/// alerts at each transition. All of it runs in the service isolate (see
/// [SessionGuardHandler]) so the live countdown + alerts stay accurate even when
/// the app is closed / the screen is off.
///
/// Started at session begin (while foreground — Android forbids starting a
/// foreground service from the background). Abstracted so tests/preview use a
/// silent no-op and never touch the service.
abstract class SessionGuard {
  /// Start the service (call at session begin, while the app is foreground).
  Future<void> start();

  /// Normal focus — calm "Focusing, tap to return" notification.
  Future<void> focusing();

  /// A break began — a live break countdown ending at [endsAt] + a start alert.
  Future<void> breakStarted(DateTime endsAt);

  /// Manually paused inside the app.
  Future<void> paused();

  /// Left the app while running — a live countdown ending at [endsAt].
  Future<void> leaveGrace(DateTime endsAt);

  /// Paused then left — counts down to the cap ([capAt], an alert there), then to
  /// [endsAt] (the 15s "pause is up" grace, an alert at the end).
  Future<void> pauseAway(DateTime capAt, DateTime endsAt);

  /// Stop the service (session ended / screen disposed).
  Future<void> stop();
}

/// Does nothing — tests, theme preview, platforms without the service.
class SilentSessionGuard implements SessionGuard {
  const SilentSessionGuard();
  @override
  Future<void> start() async {}
  @override
  Future<void> focusing() async {}
  @override
  Future<void> breakStarted(DateTime endsAt) async {}
  @override
  Future<void> paused() async {}
  @override
  Future<void> leaveGrace(DateTime endsAt) async {}
  @override
  Future<void> pauseAway(DateTime capAt, DateTime endsAt) async {}
  @override
  Future<void> stop() async {}
}

/// Real foreground-service guard via `flutter_foreground_task`.
class FgsSessionGuard implements SessionGuard {
  bool _running = false;

  @override
  Future<void> start() async {
    if (_running) return;
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'session_fgs',
          channelName: 'Focus session',
          channelDescription: 'Your live focus session + return reminders.',
          channelImportance: NotificationChannelImportance.DEFAULT,
          priority: NotificationPriority.DEFAULT,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: false,
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(1000),
          autoRunOnBoot: false,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.specialUse],
        notificationTitle: 'Sustain',
        notificationText: 'Focusing — tap to return',
        notificationIcon: const NotificationIcon(
          metaDataName: 'com.trilumos.sustain.NOTIFICATION_ICON',
          backgroundColor: _brandAccent,
        ),
        notificationButtons: const [
          NotificationButton(id: 'return', text: 'Return'),
        ],
        callback: sessionGuardCallback,
      );
      _running = true;
    } catch (_) {/* a notification must never disrupt a session */}
  }

  Future<void> _send(Map<String, dynamic> data) async {
    if (!_running) return;
    try {
      FlutterForegroundTask.sendDataToTask(data);
    } catch (_) {}
  }

  @override
  Future<void> focusing() => _send({'mode': 'focus'});

  @override
  Future<void> breakStarted(DateTime endsAt) =>
      _send({'mode': 'break', 'end': endsAt.millisecondsSinceEpoch});

  @override
  Future<void> paused() => _send({'mode': 'paused'});

  @override
  Future<void> leaveGrace(DateTime endsAt) =>
      _send({'mode': 'leave', 'end': endsAt.millisecondsSinceEpoch});

  @override
  Future<void> pauseAway(DateTime capAt, DateTime endsAt) => _send({
        'mode': 'pauseAway',
        'cap': capAt.millisecondsSinceEpoch,
        'end': endsAt.millisecondsSinceEpoch,
      });

  @override
  Future<void> stop() async {
    // Always attempt the stop (not gated on _running) so a cold launch can
    // clear a service orphaned by a force-killed session.
    _running = false;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }
}

// ── Service isolate ───────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void sessionGuardCallback() {
  FlutterForegroundTask.setTaskHandler(SessionGuardHandler());
}

/// Runs in the service isolate. Keeps the FGS notification's live countdown
/// accurate every second, and fires discrete buzzing alerts (via
/// `flutter_local_notifications`) at each transition — break start/end, the
/// pause cap, and the grace ends — so they land even with the app closed.
class SessionGuardHandler extends TaskHandler {
  final fln.FlutterLocalNotificationsPlugin _alerts =
      fln.FlutterLocalNotificationsPlugin();
  bool _alertsReady = false;

  String _mode = 'focus';
  int _cap = 0;
  int _end = 0;
  bool _firedCap = false;
  bool _firedEnd = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      await _alerts.initialize(
        settings: const fln.InitializationSettings(
          android: fln.AndroidInitializationSettings('ic_stat_hourglass'),
        ),
      );
      _alertsReady = true;
    } catch (_) {}
    _render();
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final mode = (data['mode'] as String?) ?? 'focus';
    final cap = (data['cap'] as int?) ?? 0;
    final end = (data['end'] as int?) ?? 0;
    if (mode != _mode || cap != _cap || end != _end) {
      _firedCap = false;
      _firedEnd = false;
    }
    _mode = mode;
    _cap = cap;
    _end = end;
    _render();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    switch (_mode) {
      case 'pauseAway':
        if (!_firedCap && _cap > 0 && now >= _cap) {
          _firedCap = true;
          _ding('Your pause is up', 'Return within 15s to keep your block.');
        }
        if (!_firedEnd && _end > 0 && now >= _end) {
          _firedEnd = true;
          _ding('Block ended', 'Your pause ran out.');
        }
      case 'leave':
        if (!_firedEnd && _end > 0 && now >= _end) {
          _firedEnd = true;
          _ding('Block ended', 'You were away too long.');
        }
    }
    _render();
  }

  void _render() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final String title;
    final String text;
    switch (_mode) {
      case 'break':
        title = 'On a break';
        text = now < _end
            ? 'Break — ${_fmt(_end - now)} left. Rest your eyes.'
            : 'Break\'s over — back to focus.';
      case 'leave':
        title = 'Come back to keep your block';
        text = '${_fmt(_end - now)} left before it ends.';
      case 'paused':
        title = 'Paused';
        text = 'Tap to return to your session.';
      case 'pauseAway':
        if (now < _cap) {
          title = 'You\'re paused';
          text = 'Come back — ${_fmt(_cap - now)} before your pause runs out.';
        } else if (now < _end) {
          title = 'Your pause is up';
          text = 'Return now — ${_fmt(_end - now)} to keep your block.';
        } else {
          title = 'Block ended';
          text = 'Your pause ran out.';
        }
      default:
        title = 'Sustain';
        text = 'Focusing — tap to return.';
    }
    FlutterForegroundTask.updateService(
        notificationTitle: title, notificationText: text);
  }

  Future<void> _ding(String title, String body) async {
    if (!_alertsReady) return;
    try {
      await _alerts.show(
        id: 9100,
        title: title,
        body: body,
        notificationDetails: const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'session_alerts',
            'Session alerts',
            channelDescription:
                'Break and return alerts during a focus session.',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            category: fln.AndroidNotificationCategory.reminder,
            visibility: fln.NotificationVisibility.public,
            icon: 'ic_stat_hourglass',
          ),
        ),
      );
    } catch (_) {}
  }

  String _fmt(int ms) {
    var s = (ms / 1000).round();
    if (s < 0) s = 0;
    final m = s ~/ 60;
    final ss = s % 60;
    return m > 0 ? '$m:${ss.toString().padLeft(2, '0')}' : '${ss}s';
  }

  @override
  void onNotificationButtonPressed(String id) =>
      FlutterForegroundTask.launchApp();

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
