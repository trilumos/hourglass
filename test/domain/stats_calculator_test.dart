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

  test('focusOnDay ignores abandoned sessions', () {
    final day = DateTime(2026, 6, 11);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11, 9)),
      _session(
          startedAt: DateTime(2026, 6, 11, 10),
          completed: false,
          abandoned: true),
    ];
    expect(calc.focusOnDay(day, sessions), const Duration(minutes: 25));
  });

  test('currentStreak counts consecutive days ending today', () {
    final today = DateTime(2026, 6, 11);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11)),
      _session(startedAt: DateTime(2026, 6, 10)),
      _session(startedAt: DateTime(2026, 6, 9)),
      _session(startedAt: DateTime(2026, 6, 7)),
    ];
    expect(calc.currentStreak(today, sessions), 3);
  });

  test('currentStreak is 0 when there is no completed session today', () {
    final today = DateTime(2026, 6, 11);
    final sessions = [_session(startedAt: DateTime(2026, 6, 10))];
    expect(calc.currentStreak(today, sessions), 0);
  });

  test('sessionsCompleted counts only completed sessions', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11)),
      _session(startedAt: DateTime(2026, 6, 11), completed: false, abandoned: true),
    ];
    expect(calc.sessionsCompleted(sessions), 1);
  });

  test('a session marked both completed and abandoned is never counted', () {
    final day = DateTime(2026, 6, 11);
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11), abandoned: true),
    ];
    expect(calc.focusOnDay(day, sessions), Duration.zero);
    expect(calc.focusInWeekEnding(day, sessions), Duration.zero);
    expect(calc.sessionsCompleted(sessions), 0);
    expect(calc.currentStreak(day, sessions), 0);
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

    test('excludes abandoned sessions inside the window', () {
      final day = DateTime(2026, 6, 11);
      final sessions = [
        _session(startedAt: DateTime(2026, 6, 10)),
        _session(
            startedAt: DateTime(2026, 6, 10),
            completed: false,
            abandoned: true),
      ];
      expect(calc.focusInWeekEnding(day, sessions), const Duration(minutes: 25));
    });
  });
}
