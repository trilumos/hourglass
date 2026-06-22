import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme_controller.dart' show sharedPrefsProvider;

/// User control over the optional engagement notifications. Brand rule: every
/// one is **opt-in, default OFF** — nothing notifies unless the user turns it on.
class NotificationPrefs {
  /// A daily reminder the user sets ("Time to train your focus").
  final bool focusReminder;

  /// Minutes since midnight for the focus reminder (default 20:00).
  final int focusReminderMinutes;

  /// A daily quote / tip.
  final bool quotes;

  /// Minutes since midnight for the daily quote (default 09:00).
  final int quotesMinutes;

  /// A gentle evening nudge when a live streak hasn't been kept today.
  final bool streakReminder;

  const NotificationPrefs({
    this.focusReminder = false,
    this.focusReminderMinutes = 20 * 60,
    this.quotes = false,
    this.quotesMinutes = 9 * 60,
    this.streakReminder = false,
  });

  /// True when nothing is enabled — used to decide whether to ask for the OS
  /// notification permission at all.
  bool get anyEnabled => focusReminder || quotes || streakReminder;

  NotificationPrefs copyWith({
    bool? focusReminder,
    int? focusReminderMinutes,
    bool? quotes,
    int? quotesMinutes,
    bool? streakReminder,
  }) =>
      NotificationPrefs(
        focusReminder: focusReminder ?? this.focusReminder,
        focusReminderMinutes: focusReminderMinutes ?? this.focusReminderMinutes,
        quotes: quotes ?? this.quotes,
        quotesMinutes: quotesMinutes ?? this.quotesMinutes,
        streakReminder: streakReminder ?? this.streakReminder,
      );
}

class NotificationPrefsController extends Notifier<NotificationPrefs> {
  static const _kFocus = 'hg.notif.focusReminder';
  static const _kFocusMin = 'hg.notif.focusReminderMinutes';
  static const _kQuotes = 'hg.notif.quotes';
  static const _kQuotesMin = 'hg.notif.quotesMinutes';
  static const _kStreak = 'hg.notif.streakReminder';

  @override
  NotificationPrefs build() {
    final p = ref.read(sharedPrefsProvider);
    return NotificationPrefs(
      focusReminder: p.getBool(_kFocus) ?? false,
      focusReminderMinutes: p.getInt(_kFocusMin) ?? 20 * 60,
      quotes: p.getBool(_kQuotes) ?? false,
      quotesMinutes: p.getInt(_kQuotesMin) ?? 9 * 60,
      streakReminder: p.getBool(_kStreak) ?? false,
    );
  }

  Future<void> _persist(NotificationPrefs next) async {
    state = next;
    final p = ref.read(sharedPrefsProvider);
    await p.setBool(_kFocus, next.focusReminder);
    await p.setInt(_kFocusMin, next.focusReminderMinutes);
    await p.setBool(_kQuotes, next.quotes);
    await p.setInt(_kQuotesMin, next.quotesMinutes);
    await p.setBool(_kStreak, next.streakReminder);
  }

  Future<void> setFocusReminder(bool v) =>
      _persist(state.copyWith(focusReminder: v));
  Future<void> setFocusReminderMinutes(int m) =>
      _persist(state.copyWith(focusReminderMinutes: m));
  Future<void> setQuotes(bool v) => _persist(state.copyWith(quotes: v));
  Future<void> setQuotesMinutes(int m) =>
      _persist(state.copyWith(quotesMinutes: m));
  Future<void> setStreakReminder(bool v) =>
      _persist(state.copyWith(streakReminder: v));
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefs>(
        NotificationPrefsController.new);
