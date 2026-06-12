import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/stamina_calculator.dart';

void main() {
  final calc = const StaminaCalculator();

  group('currentStamina', () {
    test('returns the 25-minute default when there is no history', () {
      expect(calc.currentStamina(const []), const Duration(minutes: 25));
    });

    test('averages the recent completed blocks', () {
      final result = calc.currentStamina(const [
        Duration(minutes: 20),
        Duration(minutes: 30),
      ]);
      expect(result, const Duration(minutes: 25));
    });

    test('uses only the last 5 blocks', () {
      final result = calc.currentStamina(const [
        Duration(minutes: 60),
        Duration(minutes: 10),
        Duration(minutes: 10),
        Duration(minutes: 10),
        Duration(minutes: 10),
        Duration(minutes: 10),
      ]);
      expect(result, const Duration(minutes: 10));
    });
  });

  group('suggestedNextLength', () {
    test('adds a 5-minute progressive-overload increment', () {
      expect(calc.suggestedNextLength(const Duration(minutes: 25)),
          const Duration(minutes: 30));
    });

    test('caps the suggestion at 90 minutes', () {
      expect(calc.suggestedNextLength(const Duration(minutes: 88)),
          const Duration(minutes: 90));
    });
  });
}
