import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';

void main() {
  test('holds the configuration for a planned session', () {
    const config = SessionConfig(
      mode: SessionMode.flowBlock,
      plannedDuration: Duration(minutes: 50),
      autoContinue: true,
      intention: 'Read chapter 4',
      soundscape: 'sand',
      skinId: 'classic',
    );
    expect(config.plannedDuration, const Duration(minutes: 50));
    expect(config.autoContinue, isTrue);
    expect(config.intention, 'Read chapter 4');
  });
}
