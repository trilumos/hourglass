import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/focus_phase.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_controller.dart';
import 'package:hourglass/session/session_plan.dart';
import 'package:hourglass/session/session_state.dart';
import 'package:hourglass/session/ticker.dart';

/// A ticker we advance manually in tests.
class FakeTicker implements Ticker {
  void Function(Duration delta)? _cb;
  bool running = false;
  @override
  void start(void Function(Duration delta) onTick) {
    _cb = onTick;
    running = true;
  }

  @override
  void stop() {
    running = false;
  }

  void advance(Duration delta) {
    if (running) _cb!(delta);
  }
}

SessionController _controller(
  FakeTicker ticker, {
  required SessionPlan plan,
  bool autoContinue = false,
  SessionMode mode = SessionMode.flowBlock,
}) {
  return SessionController(
    config: SessionConfig(
      mode: mode,
      plan: plan,
      autoContinue: autoContinue,
      intention: 'x',
      soundscape: 'sand',
      skinId: 'classic',
    ),
    ticker: ticker,
    now: () => DateTime(2026, 6, 12, 9),
  );
}

Duration m(int minutes) => Duration(minutes: minutes);

void main() {
  group('single flow block', () {
    test('starts in struggle and tracks elapsed as the ticker advances', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      expect(c.state.status, SessionStatus.running);
      expect(c.state.phase, FocusPhase.struggle);
      ticker.advance(m(15));
      expect(c.state.elapsed, m(15));
      expect(c.state.phase, FocusPhase.flow);
    });

    test('fixed mode auto-finishes exactly at the planned mark', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(25));
      expect(c.state.status, SessionStatus.finished);
      expect(ticker.running, isFalse);
      final record = c.finalize();
      expect(record.completed, isTrue);
      expect(record.abandoned, isFalse);
      expect(record.recordedFocus, m(25));
    });

    test('endless signals goal reached but keeps running past planned', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: SessionPlan.flowBlock(m(25)), autoContinue: true);
      c.start();
      ticker.advance(m(25));
      expect(c.state.goalReached, isTrue);
      expect(c.state.status, SessionStatus.running);
      ticker.advance(m(12));
      expect(c.state.elapsed, m(37));
      c.end();
      expect(c.state.status, SessionStatus.finished);
      final record = c.finalize();
      expect(record.completed, isTrue);
      expect(record.recordedFocus, m(37));
    });

    test('ending before the goal records an abandoned, uncounted session', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(10));
      c.abandon();
      expect(c.state.status, SessionStatus.finished);
      final record = c.finalize();
      expect(record.completed, isFalse);
      expect(record.abandoned, isTrue);
      expect(record.recordedFocus, Duration.zero);
    });

    test('pause stops accumulating; resume continues', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(5));
      c.pause();
      expect(ticker.running, isFalse);
      c.resume();
      ticker.advance(m(5));
      expect(c.state.elapsed, m(10));
    });

    test('calling start twice is a safe no-op and does not reset', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(3));
      c.start();
      expect(c.state.status, SessionStatus.running);
      expect(c.state.elapsed, m(3));
    });
  });

  group('multi-segment plan', () {
    // f25 · r5 · f25
    SessionPlan twoBlocks() => SessionPlan.pomodoro(
          work: m(25),
          shortBreak: m(5),
          longBreak: m(15),
          blocks: 2,
        );

    test('runs focus → rest → focus and records focus time only', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro);
      c.start();
      expect(c.state.currentKind, SegmentKind.focus);

      ticker.advance(m(25)); // finish first focus
      expect(c.state.isResting, isTrue);
      expect(c.state.segmentIndex, 1);
      expect(c.state.recordedFocus, m(25));
      expect(c.state.status, SessionStatus.running);

      ticker.advance(m(5)); // finish the rest
      expect(c.state.isResting, isFalse);
      expect(c.state.segmentIndex, 2);
      expect(c.state.recordedFocus, m(25), reason: 'rest adds no focus');

      ticker.advance(m(25)); // finish last focus
      expect(c.state.status, SessionStatus.finished);
      expect(c.state.goalReached, isTrue);
      final record = c.finalize();
      expect(record.recordedFocus, m(50));
      expect(record.plannedDuration, m(50));
      expect(record.completed, isTrue);
    });

    test('carries delta across a segment boundary in one tick', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: SessionPlan.customByInterval(
            totalWork: m(20),
            intervalWork: m(10),
            breakDuration: m(5),
          )); // f10 r5 f10
      c.start();
      ticker.advance(m(12)); // 10 focus done, 2 into the rest
      expect(c.state.segmentIndex, 1);
      expect(c.state.isResting, isTrue);
      expect(c.state.segmentElapsed, m(2));
      expect(c.state.elapsed, m(12));
      expect(c.state.recordedFocus, m(10));
    });
  });
}
