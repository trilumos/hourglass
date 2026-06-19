import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/personal_bests.dart';
import 'package:hourglass/domain/session_csv.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';

SessionRecord rec(
  DateTime at, {
  Duration focus = const Duration(minutes: 25),
  Duration? planned,
  bool completed = true,
  bool abandoned = false,
  SessionMode mode = SessionMode.flowBlock,
  String intention = '',
}) =>
    SessionRecord(
      id: 0,
      startedAt: at,
      mode: mode,
      intention: intention,
      plannedDuration: planned ?? focus,
      recordedFocus: focus,
      completed: completed,
      abandoned: abandoned,
      autoContinue: false,
      soundscape: 'sand',
      skinId: 'classic',
    );

void main() {
  group('PersonalBestsCalculator', () {
    test('empty → isEmpty, null fields, zero streak', () {
      final pb = const PersonalBestsCalculator().compute(const []);
      expect(pb.isEmpty, isTrue);
      expect(pb.longestSession, isNull);
      expect(pb.highestFocusScore, isNull);
      expect(pb.bestStreak, 0);
    });

    test('derives best day, longest, since, and a Focus Score peak', () {
      final s = [
        rec(DateTime(2026, 6, 10), focus: const Duration(minutes: 20)),
        rec(DateTime(2026, 6, 12), focus: const Duration(minutes: 50)), // longest
        rec(DateTime(2026, 6, 12), focus: const Duration(minutes: 30)), // same day
      ];
      final pb = const PersonalBestsCalculator().compute(s);
      expect(pb.focusingSince, DateTime(2026, 6, 10));
      expect(pb.longestSession, const Duration(minutes: 50));
      expect(pb.longestSessionDate, DateTime(2026, 6, 12));
      // best day = Jun 12 (50 + 30 = 80 min)
      expect(pb.bestDayDate, DateTime(2026, 6, 12));
      expect(pb.bestDayFocus, const Duration(minutes: 80));
      expect(pb.highestFocusScore, isNotNull);
    });
  });

  group('sessionsToCsv', () {
    test('header + rows + intention escaping', () {
      final csv = sessionsToCsv([
        rec(DateTime(2026, 6, 12, 9), focus: const Duration(minutes: 25),
            intention: 'Write, focus "hard"'),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines.first,
          'startedAt,mode,plannedMinutes,focusedMinutes,completed,abandoned,intention');
      expect(lines[1], contains('flowBlock'));
      expect(lines[1], contains('25.0'));
      // comma + quotes → field wrapped and inner quotes doubled
      expect(lines[1], contains('"Write, focus ""hard"""'));
    });

    test('empty list → header only', () {
      expect(sessionsToCsv(const []).trim(),
          'startedAt,mode,plannedMinutes,focusedMinutes,completed,abandoned,intention');
    });
  });
}
