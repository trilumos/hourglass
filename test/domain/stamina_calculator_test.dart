import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:hourglass/domain/stamina_calculator.dart';

SessionRecord _flow(
  DateTime at,
  Duration focus, {
  bool completed = true,
  bool abandoned = false,
  SessionMode mode = SessionMode.flowBlock,
}) =>
    SessionRecord(
      id: 0,
      startedAt: at,
      mode: mode,
      intention: '',
      plannedDuration: focus,
      recordedFocus: focus,
      completed: completed,
      abandoned: abandoned,
      autoContinue: false,
      soundscape: '',
      skinId: '',
    );

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

  group('qualifyingFlowBlocks (over-reach rule)', () {
    test('completed blocks all qualify, in order', () {
      final blocks = calc.qualifyingFlowBlocks([
        _flow(DateTime(2026, 6, 1), const Duration(minutes: 20)),
        _flow(DateTime(2026, 6, 2), const Duration(minutes: 30)),
      ]);
      expect(blocks.map((s) => s.recordedFocus).toList(),
          const [Duration(minutes: 20), Duration(minutes: 30)]);
    });

    test('the first eligible session sets the baseline even if abandoned', () {
      // No prior stamina → the first recorded Flow block is the baseline,
      // whatever its length (here a 12-min early stop).
      final blocks = calc.qualifyingFlowBlocks([
        _flow(DateTime(2026, 6, 1), const Duration(minutes: 12),
            completed: false, abandoned: true),
      ]);
      expect(blocks.map((s) => s.recordedFocus.inMinutes).toList(), [12]);
    });

    test('a sub-2-min Flow block is never eligible', () {
      final blocks = calc.qualifyingFlowBlocks([
        _flow(DateTime(2026, 6, 1), const Duration(seconds: 90),
            completed: false, abandoned: true),
      ]);
      expect(blocks, isEmpty);
    });

    test('a later early stop below current stamina is ignored', () {
      final blocks = calc.qualifyingFlowBlocks([
        _flow(DateTime(2026, 6, 1), const Duration(minutes: 30)), // baseline 30
        _flow(DateTime(2026, 6, 2), const Duration(minutes: 10),
            completed: false, abandoned: true), // 10 < 30 → ignored
      ]);
      expect(blocks.map((s) => s.recordedFocus.inMinutes).toList(), [30]);
    });

    test('a later abandoned over-reach (beyond current stamina) qualifies', () {
      final blocks = calc.qualifyingFlowBlocks([
        _flow(DateTime(2026, 6, 1), const Duration(minutes: 20)), // baseline 20
        _flow(DateTime(2026, 6, 2), const Duration(minutes: 40),
            completed: false, abandoned: true), // 40 > 20 → counts
      ]);
      expect(blocks.map((s) => s.recordedFocus.inMinutes).toList(), [20, 40]);
    });

    test('the over-reach bar rises as stamina grows', () {
      final blocks = calc.qualifyingFlowBlocks([
        _flow(DateTime(2026, 6, 1), const Duration(minutes: 30)), // → stamina 30
        _flow(DateTime(2026, 6, 2), const Duration(minutes: 32),
            completed: false, abandoned: true), // 32>30 → counts; stamina 31
        _flow(DateTime(2026, 6, 3), const Duration(minutes: 31),
            completed: false, abandoned: true), // 31 !> 31 → ignored
      ]);
      expect(blocks.map((s) => s.recordedFocus.inMinutes).toList(), [30, 32]);
    });

    test('non-Flow sessions never qualify', () {
      final blocks = calc.qualifyingFlowBlocks([
        _flow(DateTime(2026, 6, 1), const Duration(minutes: 40),
            mode: SessionMode.pomodoro),
      ]);
      expect(blocks, isEmpty);
    });
  });

}
