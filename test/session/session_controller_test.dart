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
  bool autoAdvanceBreaks = true,
  bool allowContinue = false,
  SessionMode mode = SessionMode.flowBlock,
}) {
  return SessionController(
    config: SessionConfig(
      mode: mode,
      plan: plan,
      autoContinue: autoContinue,
      autoAdvanceBreaks: autoAdvanceBreaks,
      intention: 'x',
      soundscape: 'sand',
      skinId: 'classic',
    ),
    ticker: ticker,
    now: () => DateTime(2026, 6, 12, 9),
    allowContinue: allowContinue,
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

    test('fixed Flow Block stops at the mark in a completable state', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(25));
      // Not finished — it waits, offering Done / Keep going.
      expect(c.state.status, SessionStatus.completed);
      expect(c.state.goalReached, isTrue);
      expect(ticker.running, isFalse);
      final record = c.finalize();
      expect(record.completed, isTrue);
      expect(record.abandoned, isFalse);
      expect(record.recordedFocus, m(25));
    });

    test('keepGoing extends a completed block — drains again, accumulates', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(25));
      expect(c.state.status, SessionStatus.completed);
      c.keepGoing();
      expect(c.state.status, SessionStatus.running);
      expect(c.state.segmentElapsed, Duration.zero, reason: 'drains from full');
      ticker.advance(m(10));
      expect(c.state.recordedFocus, m(35)); // 25 + 10 accumulated
      c.end();
      expect(c.state.status, SessionStatus.finished);
      final record = c.finalize();
      expect(record.recordedFocus, m(35));
      expect(record.plannedDuration, m(25), reason: 'overflow rewards score');
    });

    test('enableEndless near the end keeps the block running past its length', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(24));
      c.enableEndless(); // "don't stop"
      ticker.advance(m(6)); // would normally have completed at 25
      expect(c.state.status, SessionStatus.running);
      expect(c.state.goalReached, isTrue);
      expect(c.state.recordedFocus, m(30));
      c.end();
      expect(c.finalize().recordedFocus, m(30));
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

    test('Flow Block records actual focused length on give-up (>= 2 min)', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(m(10));
      c.abandon(); // gave up before the goal
      expect(c.state.status, SessionStatus.finished);
      final record = c.finalize();
      expect(record.completed, isFalse, reason: 'goal not reached');
      expect(record.abandoned, isTrue);
      // New rule: the 10 focused minutes ARE recorded (feeds Focus Score).
      expect(record.recordedFocus, m(10));
    });

    test('Flow Block under 2 min records the time (counts for Today, not score)',
        () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: SessionPlan.flowBlock(m(25)));
      c.start();
      ticker.advance(const Duration(seconds: 90));
      c.abandon();
      // Recorded for Today/history; the score provider filters out < 2 min.
      expect(c.finalize().recordedFocus, const Duration(seconds: 90));
    });

    test('non-Flow abandon now records the focus done (for Today/history)', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          mode: SessionMode.custom,
          plan: SessionPlan.customByCount(
              totalWork: m(60), breaks: 1, breakDuration: m(5)));
      c.start();
      ticker.advance(m(10));
      c.abandon();
      // New rule: the 10 focused minutes count (no score, but Today/history do).
      expect(c.finalize().recordedFocus, m(10));
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

    test('tap-to-continue: a break waits at the boundary, then continues', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(),
          mode: SessionMode.pomodoro,
          autoAdvanceBreaks: false);
      c.start();
      ticker.advance(m(25)); // first focus done → into the break
      expect(c.state.isResting, isTrue);

      ticker.advance(m(5)); // break done → wait for the user
      expect(c.state.status, SessionStatus.awaitingResume);
      expect(c.state.segmentIndex, 2, reason: 'parked at the next focus block');
      expect(c.state.currentKind, SegmentKind.focus);
      expect(c.state.recordedFocus, m(25));
      expect(ticker.running, isFalse, reason: 'clock stops while waiting');

      ticker.advance(m(10)); // ignored while waiting (ticker stopped)
      expect(c.state.recordedFocus, m(25));

      c.continueToNext();
      expect(c.state.status, SessionStatus.running);
      expect(ticker.running, isTrue);
      ticker.advance(m(25)); // finish the last focus block
      expect(c.state.status, SessionStatus.finished);
      expect(c.finalize().recordedFocus, m(50));
    });

    test('auto-advance (default) flows break → next focus with no wait', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: twoBlocks(), mode: SessionMode.pomodoro);
      c.start();
      ticker.advance(m(25));
      ticker.advance(m(5)); // break ends and the next focus starts immediately
      expect(c.state.status, SessionStatus.running);
      expect(c.state.isResting, isFalse);
      expect(c.state.segmentIndex, 2);
    });

    test('skipRest jumps straight to the next focus block', () {
      final ticker = FakeTicker();
      final c = _controller(ticker, plan: twoBlocks(), mode: SessionMode.pomodoro);
      c.start();
      ticker.advance(m(25)); // into the break
      expect(c.state.isResting, isTrue);
      c.skipRest();
      expect(c.state.isResting, isFalse);
      expect(c.state.segmentIndex, 2);
      expect(c.state.status, SessionStatus.running);
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

  group('continue (Pomodoro/Custom, Pro)', () {
    // f25 · r5 · f25  (50 min planned focus)
    SessionPlan twoBlocks() => SessionPlan.pomodoro(
          work: m(25),
          shortBreak: m(5),
          longBreak: m(15),
          blocks: 2,
        );

    test('without allowContinue, a pomodoro still finishes at the end', () {
      final ticker = FakeTicker();
      final c =
          _controller(ticker, plan: twoBlocks(), mode: SessionMode.pomodoro);
      c.start();
      ticker.advance(m(55)); // 25 + 5 + 25
      expect(c.state.status, SessionStatus.finished);
    });

    test('with allowContinue, a pomodoro parks at completed instead', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro, allowContinue: true);
      c.start();
      ticker.advance(m(55));
      expect(c.state.status, SessionStatus.completed);
      expect(c.state.goalReached, isTrue);
      expect(c.state.recordedFocus, m(50));
    });

    test('addBlock appends a focus block, resumes, then re-parks at completed',
        () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro, allowContinue: true);
      c.start();
      ticker.advance(m(55)); // → completed (50 focus)

      c.addBlock(m(10)); // +10 min straight focus
      expect(c.state.status, SessionStatus.running);
      expect(ticker.running, isTrue);
      ticker.advance(m(10));
      expect(c.state.status, SessionStatus.completed,
          reason: 'back to the decision point');
      expect(c.state.recordedFocus, m(60));
      final rec = c.finalize();
      expect(rec.recordedFocus, m(60));
      expect(rec.completed, isTrue);
    });

    test('addBlock with a preceding rest runs the break before the block', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro, allowContinue: true);
      c.start();
      ticker.advance(m(55)); // completed
      c.addBlock(m(25), precedingRest: m(5));
      expect(c.state.isResting, isTrue, reason: 'the inserted break runs first');
      ticker.advance(m(5));
      expect(c.state.isResting, isFalse);
      ticker.advance(m(25));
      expect(c.state.status, SessionStatus.completed);
      expect(c.state.recordedFocus, m(75));
    });

    test('repeatPlan appends the whole plan again', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro, allowContinue: true);
      c.start();
      ticker.advance(m(55)); // completed (50 focus)
      c.repeatPlan();
      expect(c.state.status, SessionStatus.running);
      ticker.advance(m(55)); // run the repeated plan
      expect(c.state.status, SessionStatus.completed);
      expect(c.state.recordedFocus, m(100));
    });

    test('giving up a bonus block still finalizes the session as completed', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro, allowContinue: true);
      c.start();
      ticker.advance(m(55)); // completed
      c.addBlock(m(25));
      ticker.advance(m(10)); // 10 into the bonus block
      c.end(); // give up the bonus
      expect(c.state.status, SessionStatus.finished);
      final rec = c.finalize();
      expect(rec.completed, isTrue,
          reason: 'the planned session was already completed');
      expect(rec.recordedFocus, m(60));
    });

    test('extendNow (near-end nudge) flows past the original end without stopping',
        () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro, allowContinue: true);
      c.start();
      ticker.advance(m(25)); // f1 done → break
      ticker.advance(m(5)); // break done → the last focus block
      expect(c.isLastSegment, isTrue);

      c.extendNow(m(25), precedingRest: m(5)); // add another block while running
      expect(c.isLastSegment, isFalse, reason: 'appended segments now follow');

      ticker.advance(m(25)); // finish the original last block
      expect(c.state.goalReached, isTrue,
          reason: 'the original plan reached its planned focus');
      expect(c.state.status, SessionStatus.running,
          reason: 'flows straight on, no stop at the end');

      ticker.advance(m(30)); // the appended break (5) + block (25)
      expect(c.state.status, SessionStatus.completed);
      expect(c.state.recordedFocus, m(75));
    });

    test('extendNow needs Pro (allowContinue) and a running session', () {
      final ticker = FakeTicker();
      final c =
          _controller(ticker, plan: twoBlocks(), mode: SessionMode.pomodoro);
      c.start();
      ticker.advance(m(25));
      ticker.advance(m(5)); // last block
      c.extendNow(m(25)); // not Pro → ignored
      ticker.advance(m(25)); // finish the original plan
      expect(c.state.status, SessionStatus.finished,
          reason: 'no extension was applied');
    });

    test('addBlock is a no-op unless parked at completed', () {
      final ticker = FakeTicker();
      final c = _controller(ticker,
          plan: twoBlocks(), mode: SessionMode.pomodoro, allowContinue: true);
      c.start();
      c.addBlock(m(10)); // running, not completed → ignored
      expect(c.state.status, SessionStatus.running);
      expect(c.state.segmentIndex, 0);
    });
  });
}
