import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/focus_phase.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_controller.dart';
import 'package:hourglass/session/session_state.dart';
import 'package:hourglass/session/ticker.dart';

/// A ticker we advance manually in tests.
class FakeTicker implements Ticker {
  void Function(Duration delta)? _cb;
  bool running = false;
  @override
  void start(void Function(Duration delta) onTick) { _cb = onTick; running = true; }
  @override
  void stop() { running = false; }
  void advance(Duration delta) { if (running) _cb!(delta); }
}

SessionController _controller(FakeTicker ticker, {required bool autoContinue}) {
  return SessionController(
    config: SessionConfig(
      mode: SessionMode.flowBlock,
      plannedDuration: const Duration(minutes: 25),
      autoContinue: autoContinue,
      intention: 'x',
      soundscape: 'sand',
      skinId: 'classic',
    ),
    ticker: ticker,
    now: () => DateTime(2026, 6, 12, 9),
  );
}

void main() {
  test('starts in struggle and tracks elapsed as the ticker advances', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    expect(c.state.status, SessionStatus.running);
    expect(c.state.phase, FocusPhase.struggle);
    ticker.advance(const Duration(minutes: 15));
    expect(c.state.elapsed, const Duration(minutes: 15));
    expect(c.state.phase, FocusPhase.flow);
  });

  test('fixed mode auto-finishes exactly at the planned mark', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    ticker.advance(const Duration(minutes: 25));
    expect(c.state.status, SessionStatus.finished);
    expect(ticker.running, isFalse);
    final record = c.finalize();
    expect(record.completed, isTrue);
    expect(record.abandoned, isFalse);
    expect(record.recordedFocus, const Duration(minutes: 25));
  });

  test('endless mode signals goal reached but keeps running past planned', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: true);
    c.start();
    ticker.advance(const Duration(minutes: 25));
    expect(c.state.goalReached, isTrue);
    expect(c.state.status, SessionStatus.running);
    ticker.advance(const Duration(minutes: 12));
    expect(c.state.elapsed, const Duration(minutes: 37));
    c.end();
    expect(c.state.status, SessionStatus.finished);
    final record = c.finalize();
    expect(record.completed, isTrue);
    expect(record.recordedFocus, const Duration(minutes: 37));
  });

  test('ending before the goal records an abandoned, uncounted session', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    ticker.advance(const Duration(minutes: 10));
    c.abandon();
    expect(c.state.status, SessionStatus.finished);
    final record = c.finalize();
    expect(record.completed, isFalse);
    expect(record.abandoned, isTrue);
    expect(record.recordedFocus, Duration.zero);
  });

  test('pause stops accumulating; resume continues', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    ticker.advance(const Duration(minutes: 5));
    c.pause();
    expect(ticker.running, isFalse);
    c.resume();
    ticker.advance(const Duration(minutes: 5));
    expect(c.state.elapsed, const Duration(minutes: 10));
  });
}
