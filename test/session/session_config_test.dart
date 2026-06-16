import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_plan.dart';

void main() {
  test('holds the plan and configuration for a session', () {
    const config = SessionConfig(
      mode: SessionMode.flowBlock,
      plan: SessionPlan([SessionSegment.focus(Duration(minutes: 50))]),
      autoContinue: true,
      intention: 'Read chapter 4',
      soundscape: 'sand',
      skinId: 'classic',
    );
    expect(config.plannedFocus, const Duration(minutes: 50));
    expect(config.plan.isSingleFocus, isTrue);
    expect(config.autoContinue, isTrue);
    expect(config.intention, 'Read chapter 4');
  });
}
