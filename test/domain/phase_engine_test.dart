import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/focus_phase.dart';
import 'package:hourglass/domain/phase_engine.dart';

void main() {
  group('PhaseEngine.forBlock', () {
    test('struggle is the first quarter of the block, capped at 12 min', () {
      final engine = PhaseEngine.forBlock(const Duration(minutes: 40));
      expect(engine.struggleDuration, const Duration(minutes: 10));
    });

    test('struggle is capped at 12 minutes for long blocks', () {
      final engine = PhaseEngine.forBlock(const Duration(minutes: 90));
      expect(engine.struggleDuration, const Duration(minutes: 12));
    });

    test('phaseAt returns struggle before struggleDuration', () {
      final engine = PhaseEngine.forBlock(const Duration(minutes: 40));
      expect(engine.phaseAt(const Duration(minutes: 5)), FocusPhase.struggle);
    });

    test('phaseAt returns release during the release window', () {
      final engine = PhaseEngine.forBlock(const Duration(minutes: 40));
      expect(engine.phaseAt(const Duration(minutes: 10, seconds: 20)),
          FocusPhase.release);
    });

    test('phaseAt returns flow after struggle + release', () {
      final engine = PhaseEngine.forBlock(const Duration(minutes: 40));
      expect(engine.phaseAt(const Duration(minutes: 15)), FocusPhase.flow);
    });

    test('phaseAt stays flow past the planned duration (endless mode)', () {
      final engine = PhaseEngine.forBlock(const Duration(minutes: 40));
      expect(engine.phaseAt(const Duration(minutes: 75)), FocusPhase.flow);
    });
  });
}
