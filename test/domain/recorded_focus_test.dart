import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/recorded_focus.dart';

void main() {
  group('computeRecordedFocus', () {
    test('fixed mode records exactly the planned duration', () {
      final result = computeRecordedFocus(
        plannedDuration: const Duration(minutes: 25),
        elapsed: const Duration(minutes: 25),
        autoContinue: false,
      );
      expect(result, const Duration(minutes: 25));
    });

    test('endless mode records the full elapsed time past planned', () {
      final result = computeRecordedFocus(
        plannedDuration: const Duration(minutes: 25),
        elapsed: const Duration(minutes: 47),
        autoContinue: true,
      );
      expect(result, const Duration(minutes: 47));
    });

    test('endless mode never records less than planned', () {
      final result = computeRecordedFocus(
        plannedDuration: const Duration(minutes: 25),
        elapsed: const Duration(minutes: 25),
        autoContinue: true,
      );
      expect(result, const Duration(minutes: 25));
    });
  });
}
