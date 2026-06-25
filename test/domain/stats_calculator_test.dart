import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:hourglass/domain/stats_calculator.dart';

SessionRecord _session({
  required DateTime startedAt,
  Duration recorded = const Duration(minutes: 25),
  bool completed = true,
  bool abandoned = false,
}) {
  return SessionRecord(
    id: 0,
    startedAt: startedAt,
    mode: SessionMode.flowBlock,
    intention: '',
    plannedDuration: const Duration(minutes: 25),
    recordedFocus: recorded,
    completed: completed,
    abandoned: abandoned,
    autoContinue: false,
    soundscape: 'sand',
    skinId: 'classic',
  );
}

void main() {
  const calc = StatsCalculator();

  test('focusOnDay sums recorded focus for completed sessions that day', () {
    final day = DateTime(2026, 6, 11, 9);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11, 9)),
      _session(startedAt: DateTime(2026, 6, 11, 14)),
      _session(startedAt: DateTime(2026, 6, 10, 9)),
    ];
    expect(calc.focusOnDay(day, sessions), const Duration(minutes: 50));
  });

  test('focusOnDay counts abandoned sessions too (all focus time shows)', () {
    final day = DateTime(2026, 6, 11);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11, 9)), // completed 25m
      _session(
          startedAt: DateTime(2026, 6, 11, 10),
          recorded: const Duration(minutes: 10),
          completed: false,
          abandoned: true), // gave up after 10m — still counts
    ];
    expect(calc.focusOnDay(day, sessions), const Duration(minutes: 35));
  });

  test('focusOnDay ignores sessions with no recorded focus', () {
    final day = DateTime(2026, 6, 11);
    final sessions = [
      _session(
          startedAt: DateTime(2026, 6, 11, 10),
          recorded: Duration.zero,
          completed: false,
          abandoned: true),
    ];
    expect(calc.focusOnDay(day, sessions), Duration.zero);
  });

  test('currentStreak bridges a single gap day (1-day grace)', () {
    final today = DateTime(2026, 6, 11);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11)),
      _session(startedAt: DateTime(2026, 6, 10)),
      _session(startedAt: DateTime(2026, 6, 9)),
      // 6/8 empty — bridged by the grace
      _session(startedAt: DateTime(2026, 6, 7)),
    ];
    // 11, 10, 9, 7 all count (8 is the bridged grace day, not counted itself).
    expect(calc.currentStreak(today, sessions), 4);
  });

  test('currentStreak holds on the grace day when today is still empty', () {
    final today = DateTime(2026, 6, 11);
    // No focus today, but yesterday focused → streak alive at 1 (the grace day).
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 10)),
      _session(startedAt: DateTime(2026, 6, 9)),
    ];
    expect(calc.currentStreak(today, sessions), 2);
  });

  test('currentStreak breaks after two consecutive empty days', () {
    final today = DateTime(2026, 6, 11);
    // Today and yesterday both empty → past the grace → 0.
    final sessions = [_session(startedAt: DateTime(2026, 6, 9))];
    expect(calc.currentStreak(today, sessions), 0);
  });

  test('currentStreak stops at a two-day internal gap', () {
    final today = DateTime(2026, 6, 11);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11)),
      _session(startedAt: DateTime(2026, 6, 10)),
      // 6/9 and 6/8 both empty (two-day gap) → run ends here
      _session(startedAt: DateTime(2026, 6, 7)),
    ];
    expect(calc.currentStreak(today, sessions), 2);
  });

  test('currentStreak counts across a month boundary', () {
    final today = DateTime(2026, 7, 1);
    final sessions = [
      _session(startedAt: DateTime(2026, 7, 1)),
      _session(startedAt: DateTime(2026, 6, 30)),
      _session(startedAt: DateTime(2026, 6, 29)),
    ];
    expect(calc.currentStreak(today, sessions), 3);
  });

  test('currentStreak counts across a year boundary', () {
    final today = DateTime(2027, 1, 1);
    final sessions = [
      _session(startedAt: DateTime(2027, 1, 1)),
      _session(startedAt: DateTime(2026, 12, 31)),
      _session(startedAt: DateTime(2026, 12, 30)),
    ];
    expect(calc.currentStreak(today, sessions), 3);
  });

  test('bestStreak counts across a month boundary', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 5, 30)),
      _session(startedAt: DateTime(2026, 5, 31)),
      _session(startedAt: DateTime(2026, 6, 1)),
      _session(startedAt: DateTime(2026, 6, 2)), // run of 4 across May→June
    ];
    expect(calc.bestStreak(sessions), 4);
  });

  test('sessionsCompleted counts only completed sessions', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11)),
      _session(startedAt: DateTime(2026, 6, 11), completed: false, abandoned: true),
    ];
    expect(calc.sessionsCompleted(sessions), 1);
  });

  test('totalFocus sums all recorded focus, ignoring zero-focus sessions', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11)), // 25m
      _session(
          startedAt: DateTime(2026, 6, 10),
          recorded: const Duration(minutes: 5)),
      _session(
          startedAt: DateTime(2026, 6, 9),
          recorded: Duration.zero,
          completed: false,
          abandoned: true),
    ];
    expect(calc.totalFocus(sessions), const Duration(minutes: 30));
  });

  test('totalFocus is zero for no sessions', () {
    expect(calc.totalFocus(const []), Duration.zero);
  });

  test('bestStreak finds the longest consecutive run ever', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 1)),
      _session(startedAt: DateTime(2026, 6, 2)),
      _session(startedAt: DateTime(2026, 6, 3)), // run of 3
      _session(startedAt: DateTime(2026, 6, 10)),
      _session(startedAt: DateTime(2026, 6, 11)), // run of 2
    ];
    expect(calc.bestStreak(sessions), 3);
  });

  test('bestStreak bridges single gap days with the grace', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 1)),
      // 6/2 empty — bridged
      _session(startedAt: DateTime(2026, 6, 3)),
      _session(startedAt: DateTime(2026, 6, 4)),
      // 6/5 empty — bridged
      _session(startedAt: DateTime(2026, 6, 6)), // run of 4 focused days (2 grace bridges)
      // 6/7 and 6/8 both empty (two-day gap) → resets
      _session(startedAt: DateTime(2026, 6, 9)),
    ];
    expect(calc.bestStreak(sessions), 4);
  });

  test('averageSession, longestSession, totalSessions ignore zero-focus', () {
    final sessions = [
      _session(
          startedAt: DateTime(2026, 6, 1),
          recorded: const Duration(minutes: 10)),
      _session(
          startedAt: DateTime(2026, 6, 2),
          recorded: const Duration(minutes: 30)),
      _session(
          startedAt: DateTime(2026, 6, 3),
          recorded: Duration.zero,
          completed: false,
          abandoned: true),
    ];
    expect(calc.averageSession(sessions), const Duration(minutes: 20));
    expect(calc.longestSession(sessions), const Duration(minutes: 30));
    expect(calc.totalSessions(sessions), 2);
  });

  test('firstSessionDate returns the earliest focused date', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 5)),
      _session(startedAt: DateTime(2026, 6, 1, 9)),
    ];
    expect(calc.firstSessionDate(sessions), DateTime(2026, 6, 1, 9));
    expect(calc.firstSessionDate(const []), isNull);
  });

  test('abandoned session counts toward focus & streak, not sessionsCompleted',
      () {
    final day = DateTime(2026, 6, 11);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11), abandoned: true),
    ];
    expect(calc.focusOnDay(day, sessions), const Duration(minutes: 25));
    expect(calc.focusInWeekEnding(day, sessions), const Duration(minutes: 25));
    expect(calc.sessionsCompleted(sessions), 0); // not a completed session
    expect(calc.currentStreak(day, sessions), 1); // but a focused day
  });

  group('focusInWeekEnding', () {
    test('includes completed sessions within the inclusive 7-day window', () {
      final day = DateTime(2026, 6, 11);
      final sessions = [
        _session(startedAt: DateTime(2026, 6, 11)), // today (window end)
        _session(startedAt: DateTime(2026, 6, 5)),  // 6 days earlier (window start, included)
      ];
      expect(calc.focusInWeekEnding(day, sessions), const Duration(minutes: 50));
    });

    test('excludes sessions just outside the 7-day window', () {
      final day = DateTime(2026, 6, 11);
      final sessions = [
        _session(startedAt: DateTime(2026, 6, 11)),
        _session(startedAt: DateTime(2026, 6, 4)), // 7 days earlier -> outside window
      ];
      expect(calc.focusInWeekEnding(day, sessions), const Duration(minutes: 25));
    });

    test('includes focus from abandoned sessions inside the window', () {
      final day = DateTime(2026, 6, 11);
      final sessions = [
        _session(startedAt: DateTime(2026, 6, 10)),
        _session(
            startedAt: DateTime(2026, 6, 10),
            recorded: const Duration(minutes: 10),
            completed: false,
            abandoned: true),
      ];
      expect(calc.focusInWeekEnding(day, sessions), const Duration(minutes: 35));
    });
  });
}
