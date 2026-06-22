import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_controller.dart';
import 'package:hourglass/session/session_cue.dart';
import 'package:hourglass/session/session_plan.dart';
import 'package:hourglass/session/ticker.dart';

class FakeTicker implements Ticker {
  void Function(Duration delta)? _cb;
  bool running = false;
  @override
  void start(void Function(Duration delta) onTick) {
    _cb = onTick;
    running = true;
  }

  @override
  void stop() => running = false;

  void advance(Duration d) {
    if (running) _cb!(d);
  }
}

Duration m(int x) => Duration(minutes: x);

SessionController controller(
  FakeTicker ticker, {
  required SessionPlan plan,
  required List<SessionCue> cues,
  bool autoContinue = false,
  bool autoAdvanceBreaks = true,
  SessionMode mode = SessionMode.flowBlock,
}) =>
    SessionController(
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
      onCue: cues.add,
    );

SessionPlan pomodoroPlan() => SessionPlan([
      SessionSegment.focus(m(25)),
      SessionSegment.rest(m(5)),
      SessionSegment.focus(m(25)),
    ]);

void main() {
  test('a flow block cues started, then finished at the mark', () {
    final t = FakeTicker();
    final cues = <SessionCue>[];
    controller(t, plan: SessionPlan.flowBlock(m(25)), cues: cues).start();
    expect(cues, [SessionCue.started]);
    t.advance(m(25));
    expect(cues, [SessionCue.started, SessionCue.finished]);
  });

  test('a pomodoro cues started, break boundaries, then finished', () {
    final t = FakeTicker();
    final cues = <SessionCue>[];
    controller(t, plan: pomodoroPlan(), cues: cues, mode: SessionMode.pomodoro)
        .start();
    t.advance(m(25)); // focus 1 ends -> break begins
    t.advance(m(5)); // break ends -> focus 2 resumes
    t.advance(m(25)); // focus 2 ends -> done
    expect(cues, [
      SessionCue.started,
      SessionCue.breakStarted,
      SessionCue.breakEnded,
      SessionCue.finished,
    ]);
  });

  test('tap-to-continue cues breakEnded when the break timer ends', () {
    final t = FakeTicker();
    final cues = <SessionCue>[];
    controller(t,
            plan: pomodoroPlan(),
            cues: cues,
            mode: SessionMode.pomodoro,
            autoAdvanceBreaks: false)
        .start();
    t.advance(m(25)); // break begins
    t.advance(m(5)); // break ends -> parks at awaitingResume
    expect(cues, [
      SessionCue.started,
      SessionCue.breakStarted,
      SessionCue.breakEnded,
    ]);
  });

  test('ending an endless block cues finished; abandoning cues nothing', () {
    final t = FakeTicker();
    final endless = <SessionCue>[];
    final c = controller(t,
        plan: SessionPlan.flowBlock(m(25)), cues: endless, autoContinue: true);
    c.start();
    t.advance(m(40)); // runs past the mark; never auto-finishes
    c.end();
    expect(endless, [SessionCue.started, SessionCue.finished]);

    final t2 = FakeTicker();
    final abandoned = <SessionCue>[];
    final c2 =
        controller(t2, plan: SessionPlan.flowBlock(m(25)), cues: abandoned);
    c2.start();
    t2.advance(m(10));
    c2.abandon(); // gave up early -> no celebratory cue
    expect(abandoned, [SessionCue.started]);
  });
}
