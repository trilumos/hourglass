import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/config_codec.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_plan.dart';

SessionConfig cfg(SessionMode mode, SessionPlan plan,
        {bool autoContinue = false, bool autoAdvanceBreaks = true}) =>
    SessionConfig(
      mode: mode,
      plan: plan,
      autoContinue: autoContinue,
      intention: 'should not be encoded',
      soundscape: 'rain',
      skinId: 'obsidian',
      autoAdvanceBreaks: autoAdvanceBreaks,
    );

void _expectSameSegments(SessionPlan a, SessionPlan b) {
  expect(b.segments.length, a.segments.length);
  for (var i = 0; i < a.segments.length; i++) {
    expect(b.segments[i].kind, a.segments[i].kind);
    expect(b.segments[i].duration, a.segments[i].duration);
  }
}

void main() {
  test('round-trips a Flow plan (single focus)', () {
    final c = cfg(SessionMode.flowBlock, SessionPlan.flowBlock(const Duration(minutes: 25)));
    final back = decodeConfig(encodeConfig(c), intention: 'Write')!;
    expect(back.mode, SessionMode.flowBlock);
    _expectSameSegments(c.plan, back.plan);
    expect(back.soundscape, 'rain');
    expect(back.skinId, 'obsidian');
    expect(back.intention, 'Write'); // supplied by caller, not encoded
  });

  test('round-trips a Pomodoro plan (focus/rest cadence + long break)', () {
    final c = cfg(
      SessionMode.pomodoro,
      SessionPlan.pomodoro(
        work: const Duration(minutes: 25),
        shortBreak: const Duration(minutes: 5),
        longBreak: const Duration(minutes: 15),
        blocks: 4,
      ),
      autoAdvanceBreaks: false,
    );
    final back = decodeConfig(encodeConfig(c))!;
    expect(back.mode, SessionMode.pomodoro);
    _expectSameSegments(c.plan, back.plan);
    expect(back.autoAdvanceBreaks, isFalse);
  });

  test('round-trips a Custom by-interval plan', () {
    final c = cfg(
      SessionMode.custom,
      SessionPlan.customByInterval(
        totalWork: const Duration(minutes: 60),
        intervalWork: const Duration(minutes: 20),
        breakDuration: const Duration(minutes: 4),
      ),
    );
    _expectSameSegments(c.plan, decodeConfig(encodeConfig(c))!.plan);
  });

  test('bad / empty input → null (graceful)', () {
    expect(decodeConfig(null), isNull);
    expect(decodeConfig(''), isNull);
    expect(decodeConfig('not json'), isNull);
    expect(decodeConfig('{"v":1,"mode":"flowBlock","segments":[]}'), isNull);
    expect(decodeConfig('{"v":1,"mode":"bogus","segments":[{"k":"focus","s":60}]}'),
        isNull);
  });
}
