import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_controller.dart';
import 'package:hourglass/session/session_plan.dart';
import 'package:hourglass/session/session_state.dart';
import 'package:hourglass/session/strict_rules.dart';
import 'package:hourglass/session/ticker.dart';

class FakeTicker implements Ticker {
  bool running = false;
  @override
  void start(void Function(Duration delta) onTick) => running = true;
  @override
  void stop() => running = false;
}

SessionController controller({int? pauseLimit}) => SessionController(
      config: SessionConfig(
        mode: SessionMode.flowBlock,
        plan: SessionPlan.flowBlock(const Duration(minutes: 25)),
        autoContinue: false,
        intention: 'x',
        soundscape: 'sand',
        skinId: 'classic',
      ),
      ticker: FakeTicker(),
      now: () => DateTime(2026, 6, 22, 9),
      pauseLimit: pauseLimit,
    );

void main() {
  group('StrictRules', () {
    test('free vs Pro shape', () {
      expect(StrictRules.free.pauseLimit, 3);
      expect(StrictRules.free.pauseCap, const Duration(minutes: 3));
      expect(StrictRules.free.leaveGrace, const Duration(seconds: 30));
      expect(StrictRules.free.capGrace, const Duration(seconds: 15));
      expect(StrictRules.pro.unlimitedPauses, isTrue);
      expect(StrictRules.pro.pauseCap, const Duration(minutes: 10));
      expect(StrictRules.forPro(false), same(StrictRules.free));
      expect(StrictRules.forPro(true), same(StrictRules.pro));
    });

    test('leave-while-running grace (30s)', () {
      expect(StrictRules.free.endAfterAwayRunning(const Duration(seconds: 29)),
          isFalse);
      expect(StrictRules.free.endAfterAwayRunning(const Duration(seconds: 31)),
          isTrue);
    });

    test('paused past the cap + grace (3min + 15s)', () {
      final r = StrictRules.free;
      expect(r.endAfterPaused(const Duration(minutes: 3)), isFalse);
      expect(r.endAfterPaused(const Duration(minutes: 3, seconds: 14)), isFalse);
      expect(r.endAfterPaused(const Duration(minutes: 3, seconds: 16)), isTrue);
      expect(r.inCapGrace(const Duration(minutes: 3, seconds: 5)), isTrue);
      expect(r.inCapGrace(const Duration(minutes: 2)), isFalse);
      expect(r.inCapGrace(const Duration(minutes: 4)), isFalse); // past grace
    });

    test('remaining pauses', () {
      expect(StrictRules.free.remainingPauses(2), 1);
      expect(StrictRules.free.remainingPauses(3), 0);
      expect(StrictRules.free.remainingPauses(5), 0); // clamped
      expect(StrictRules.pro.remainingPauses(99), isNull);
    });
  });

  group('SessionController pause limit', () {
    test('a free user can pause only up to the limit, then the button no-ops',
        () {
      final c = controller(pauseLimit: 3);
      c.start();
      for (var i = 0; i < 3; i++) {
        expect(c.canPause, isTrue);
        c.pause();
        expect(c.state.status, SessionStatus.paused);
        c.resume();
      }
      expect(c.pauseCount, 3);
      expect(c.canPause, isFalse);
      c.pause(); // blocked
      expect(c.state.status, SessionStatus.running); // never paused a 4th time
      expect(c.pauseCount, 3);
    });

    test('null limit (Pro / default) means unlimited pauses', () {
      final c = controller();
      c.start();
      for (var i = 0; i < 6; i++) {
        c.pause();
        expect(c.state.status, SessionStatus.paused);
        c.resume();
      }
      expect(c.canPause, isTrue);
    });
  });
}
