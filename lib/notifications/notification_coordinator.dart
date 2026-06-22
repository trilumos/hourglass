import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart' show sessionRepositoryProvider;
import '../content/daily_nudges.dart';
import '../domain/session_record.dart';
import '../domain/stats_calculator.dart';
import 'notification_prefs.dart';
import 'notification_service.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// Reconciles the OS notification schedule with the user's [NotificationPrefs]
/// and current data. Idempotent — safe to call on every app open and after each
/// session: it cancels anything turned off and (re)schedules anything on.
class NotificationCoordinator {
  final NotificationService service;
  const NotificationCoordinator(this.service);

  static const _calc = StatsCalculator();

  Future<void> sync({
    required NotificationPrefs prefs,
    required List<SessionRecord> sessions,
    required DateTime now,
  }) async {
    // Focus reminder — a daily repeat at the user's chosen time.
    if (prefs.focusReminder) {
      await service.scheduleDaily(
        id: HgNotif.focusReminder,
        hour: prefs.focusReminderMinutes ~/ 60,
        minute: prefs.focusReminderMinutes % 60,
        title: 'Time to train your focus',
        body: 'A few minutes of deep focus is enough to keep building.',
      );
    } else {
      await service.cancel(HgNotif.focusReminder);
    }

    // Daily quote / tip — schedule the next few days individually so they rotate.
    if (prefs.quotes) {
      await _scheduleQuotes(prefs, now);
    } else {
      await service.cancelRange(HgNotif.quoteBase, HgNotif.quoteDays);
    }

    // Streak nudge — only when a live streak hasn't been kept today, framed as
    // encouragement, never as failure.
    final nudgeAt = _streakNudgeTime(now);
    if (prefs.streakReminder && _streakAtRisk(sessions, now)) {
      await service.scheduleAt(
        id: HgNotif.streakReminder,
        when: nudgeAt,
        title: 'Keep your streak alive',
        body: 'A few minutes of focus keeps it going — and no worries if today '
            'is a rest day.',
      );
    } else {
      await service.cancel(HgNotif.streakReminder);
    }
  }

  Future<void> _scheduleQuotes(NotificationPrefs prefs, DateTime now) async {
    final h = prefs.quotesMinutes ~/ 60;
    final m = prefs.quotesMinutes % 60;
    final today = DateTime(now.year, now.month, now.day);
    final epochDay = today.difference(DateTime(2020)).inDays;
    for (var i = 0; i < HgNotif.quoteDays; i++) {
      final day = today.add(Duration(days: i));
      final when = DateTime(day.year, day.month, day.day, h, m);
      if (!when.isAfter(now)) continue; // today's time already passed
      final nudge = nudgeForDay(epochDay + i);
      await service.scheduleAt(
        id: HgNotif.quoteBase + i,
        when: when,
        title: nudge.title,
        body: nudge.body,
      );
    }
  }

  bool _streakAtRisk(List<SessionRecord> sessions, DateTime now) {
    if (_calc.focusOnDay(now, sessions) > Duration.zero) return false; // safe
    return _calc.currentStreak(now, sessions) >= 1; // a streak worth keeping
  }

  /// 20:00 today; if it's already evening, ~15 min out; after 22:00 it returns a
  /// past time so [NotificationService.scheduleAt] skips it (too late to nudge).
  DateTime _streakNudgeTime(DateTime now) {
    final eight = DateTime(now.year, now.month, now.day, 20);
    if (now.isBefore(eight)) return eight;
    final cutoff = DateTime(now.year, now.month, now.day, 22);
    if (now.isAfter(cutoff)) return now.subtract(const Duration(minutes: 1));
    return now.add(const Duration(minutes: 15));
  }
}

/// Read prefs + sessions from providers and reconcile the schedule. Call on app
/// launch and after a session ends. Never throws.
Future<void> syncNotifications(WidgetRef ref) async {
  try {
    final prefs = ref.read(notificationPrefsProvider);
    final sessions = await ref.read(sessionRepositoryProvider).allSessions();
    await NotificationCoordinator(ref.read(notificationServiceProvider))
        .sync(prefs: prefs, sessions: sessions, now: DateTime.now());
  } catch (_) {}
}
