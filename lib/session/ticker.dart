import 'dart:async';

/// Abstraction over a periodic clock so the controller can be unit-tested
/// with a fake ticker (no real time) and run with a real one in the app.
abstract class Ticker {
  void start(void Function(Duration delta) onTick);
  void stop();
}

/// Real ticker firing every [interval] (default 1s), reporting the delta.
class PeriodicTicker implements Ticker {
  final Duration interval;
  Timer? _timer;
  PeriodicTicker({this.interval = const Duration(seconds: 1)});

  @override
  void start(void Function(Duration delta) onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => onTick(interval));
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
