import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/session/session_plan.dart';

Duration m(int minutes) => Duration(minutes: minutes);

void main() {
  group('flowBlock', () {
    test('is a single focus segment', () {
      final p = SessionPlan.flowBlock(m(50));
      expect(p.segments, hasLength(1));
      expect(p.segments.single.isFocus, isTrue);
      expect(p.totalFocus, m(50));
      expect(p.totalDuration, m(50));
      expect(p.isSingleFocus, isTrue);
      expect(p.focusCount, 1);
    });
  });

  group('pomodoro', () {
    test('alternates focus/rest, ends on focus, long break every 4th', () {
      final p = SessionPlan.pomodoro(
        work: m(25),
        shortBreak: m(5),
        longBreak: m(15),
        blocks: 6,
      );
      // f r f r f r f rLONG f r f
      expect(p.focusCount, 6);
      expect(p.segments.last.isFocus, isTrue, reason: 'ends on focus');
      final rests = p.segments.where((s) => !s.isFocus).toList();
      expect(rests, hasLength(5));
      expect(rests[3].duration, m(15), reason: '4th break is long');
      expect(rests[0].duration, m(5));
      expect(p.totalFocus, m(150));
    });

    test('single block has no rest', () {
      final p = SessionPlan.pomodoro(
        work: m(25),
        shortBreak: m(5),
        longBreak: m(15),
        blocks: 1,
      );
      expect(p.segments, hasLength(1));
      expect(p.segments.single.isFocus, isTrue);
    });
  });

  group('customByCount', () {
    test('splits total work into breaks+1 focus chunks with rests between', () {
      final p = SessionPlan.customByCount(
        totalWork: m(240),
        breaks: 3,
        breakDuration: m(10),
      );
      expect(p.focusCount, 4);
      expect(p.segments.where((s) => !s.isFocus), hasLength(3));
      expect(p.totalFocus, m(240), reason: 'focus sums exactly to total work');
      expect(p.segments.last.isFocus, isTrue);
    });

    test('absorbs remainder into the last focus chunk', () {
      final p = SessionPlan.customByCount(
        totalWork: m(100),
        breaks: 2,
        breakDuration: m(5),
      );
      // 100 / 3 = 33 each, last = 34
      final focus = p.segments.where((s) => s.isFocus).toList();
      expect(focus, hasLength(3));
      expect(p.totalFocus, m(100));
    });

    test('whole-minute chunks; remainder in last (135m, 3 breaks)', () {
      final p = SessionPlan.customByCount(
        totalWork: m(135),
        breaks: 3,
        breakDuration: m(10),
      );
      final focus =
          p.segments.where((s) => s.isFocus).map((s) => s.duration).toList();
      expect(focus, [m(33), m(33), m(33), m(36)]);
      expect(p.totalFocus, m(135)); // exactly, no sub-minute drift
    });

    test('zero breaks is a single focus block', () {
      final p = SessionPlan.customByCount(
        totalWork: m(60),
        breaks: 0,
        breakDuration: m(5),
      );
      expect(p.isSingleFocus, isTrue);
      expect(p.totalFocus, m(60));
    });

    test('never produces zero-length segments, even with extreme breaks', () {
      final p = SessionPlan.customByCount(
        totalWork: const Duration(minutes: 2),
        breaks: 12,
        breakDuration: m(5),
      );
      expect(p.segments.every((s) => s.duration > Duration.zero), isTrue);
      // And when there isn't even a second per chunk, it's a single block.
      final tiny = SessionPlan.customByCount(
        totalWork: const Duration(seconds: 5),
        breaks: 12,
        breakDuration: m(5),
      );
      expect(tiny.isSingleFocus, isTrue);
    });
  });

  group('flowmodoro (by-duration)', () {
    test('exact focus, variable blocks, ~5:1 rests', () {
      final p = SessionPlan.flowmodoro(totalFocus: m(180), blocks: 4);
      final focus = p.segments.where((s) => s.isFocus).toList();
      final rests = p.segments.where((s) => !s.isFocus).toList();
      expect(focus, hasLength(4));
      expect(rests, hasLength(3));
      expect(p.totalFocus, m(180), reason: 'focus time is exact');
      expect(focus.first.duration, m(45)); // 180/4
      expect(rests.first.duration, m(9)); // 45/5
    });

    test('every focus-time change is exact (no buckets)', () {
      expect(SessionPlan.flowmodoro(totalFocus: m(180), blocks: 4).totalFocus,
          m(180));
      expect(SessionPlan.flowmodoro(totalFocus: m(195), blocks: 4).totalFocus,
          m(195));
      expect(SessionPlan.flowmodoro(totalFocus: m(210), blocks: 4).totalFocus,
          m(210));
    });

    test('one block has no rest', () {
      final p = SessionPlan.flowmodoro(totalFocus: m(90), blocks: 1);
      expect(p.isSingleFocus, isTrue);
    });
  });

  group('foolproof invariants', () {
    test('flow: total focus == length, no breaks', () {
      final p = SessionPlan.flowBlock(m(50));
      expect(p.totalFocus, m(50));
      expect(p.totalDuration, m(50));
    });

    test('pomodoro: focus == blocks×work, and changing blocks changes total',
        () {
      SessionPlan p(int blocks) => SessionPlan.pomodoro(
            work: m(25),
            shortBreak: m(5),
            longBreak: m(15),
            blocks: blocks,
          );
      expect(p(5).totalFocus, m(125)); // 5 × 25
      expect(p(6).totalFocus, m(150));
      // Distinct block counts must yield distinct totals (no rounding drift).
      expect(p(5).totalDuration, isNot(p(6).totalDuration));
      // total = focus + the breaks between blocks.
      expect(p(5).totalDuration, m(125) + m(5) * 3 + m(15)); // 4 breaks, 4th long
    });

    test('custom byCount: total focus is exactly what was asked', () {
      for (final mins in [60, 90, 100, 125, 240]) {
        for (final breaks in [0, 1, 3, 5]) {
          final p = SessionPlan.customByCount(
            totalWork: m(mins),
            breaks: breaks,
            breakDuration: m(10),
          );
          expect(p.totalFocus, m(mins),
              reason: 'mins=$mins breaks=$breaks focus must equal total work');
        }
      }
    });

    test('custom byInterval: total focus is exactly what was asked', () {
      for (final mins in [60, 100, 120, 130, 200]) {
        final p = SessionPlan.customByInterval(
          totalWork: m(mins),
          intervalWork: m(30),
          breakDuration: m(10),
        );
        expect(p.totalFocus, m(mins), reason: 'mins=$mins');
      }
    });
  });

  group('customByInterval', () {
    test('chunks total work by interval with rests between', () {
      final p = SessionPlan.customByInterval(
        totalWork: m(120),
        intervalWork: m(30),
        breakDuration: m(10),
      );
      // f30 r f30 r f30 r f30
      expect(p.focusCount, 4);
      expect(p.segments.where((s) => !s.isFocus), hasLength(3));
      expect(p.totalFocus, m(120));
      expect(p.segments.last.isFocus, isTrue);
    });

    test('final chunk is the remainder', () {
      final p = SessionPlan.customByInterval(
        totalWork: m(130),
        intervalWork: m(30),
        breakDuration: m(10),
      );
      final focus = p.segments.where((s) => s.isFocus).toList();
      expect(focus.last.duration, m(10), reason: 'remainder chunk');
      expect(p.totalFocus, m(130));
    });
  });
}
