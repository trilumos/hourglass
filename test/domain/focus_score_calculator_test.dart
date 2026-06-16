import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/focus_score_calculator.dart';

Duration m(int minutes) => Duration(minutes: minutes);

void main() {
  const calc = FocusScoreCalculator();

  group('sessionScore (0-100)', () {
    test('depth bonus: longer completed blocks score higher than linear', () {
      expect(calc.sessionScore(chosen: m(25), actual: m(25)), 33);
      expect(calc.sessionScore(chosen: m(50), actual: m(50)), 78);
      expect(calc.sessionScore(chosen: m(60), actual: m(60)), 100); // anchor
    });

    test('caps at 100 beyond the anchor', () {
      expect(calc.sessionScore(chosen: m(90), actual: m(90)), 100);
      expect(calc.sessionScore(chosen: m(120), actual: m(120)), 100);
    });

    test('partial completion is penalized hard (squared)', () {
      // chose 50, did 25 (50%) -> much less than completing 25
      final half = calc.sessionScore(chosen: m(50), actual: m(25));
      expect(half, lessThan(calc.sessionScore(chosen: m(25), actual: m(25))));
      expect(half, inInclusiveRange(18, 22));
    });

    test('pushing past the chosen length adds a bonus', () {
      final pushed = calc.sessionScore(chosen: m(25), actual: m(40));
      expect(pushed, greaterThan(calc.sessionScore(chosen: m(25), actual: m(25))));
      expect(pushed, inInclusiveRange(58, 66));
    });

    test('sessions under 2 minutes score 0', () {
      expect(calc.sessionScore(chosen: m(25), actual: const Duration(seconds: 90)), 0);
    });
  });

  group('score (0-100, ramps over 10 sessions)', () {
    List<({Duration chosen, Duration actual})> reps(int n, Duration d) =>
        List.generate(n, (_) => (chosen: d, actual: d));

    test('one perfect session yields ~10 (divisor is always 10)', () {
      expect(calc.score([(chosen: m(60), actual: m(60))]), 10);
    });

    test('ten perfect sessions reach 100', () {
      expect(calc.score(reps(10, m(60))), 100);
    });

    test('ramps with count', () {
      expect(calc.score(reps(5, m(60))), 50);
    });

    test('uses only the last 10 sessions', () {
      final many = [...reps(5, m(25)), ...reps(10, m(60))]; // last 10 are perfect
      expect(calc.score(many), 100);
    });

    test('ignores sessions under 2 minutes (no slot used)', () {
      final list = [
        (chosen: m(25), actual: const Duration(seconds: 60)),
        (chosen: m(60), actual: m(60)),
      ];
      expect(calc.score(list), 10); // only the 60-min one counts
    });

    test('empty history is 0', () {
      expect(calc.score(const []), 0);
    });
  });
}
