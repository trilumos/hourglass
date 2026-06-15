import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/session_repository.dart';
import 'package:hourglass/data/settings_repository.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:hourglass/domain/stamina_calculator.dart';
import 'package:hourglass/session/session_finalizer.dart';

SessionRecord _record({
  required Duration recorded,
  bool completed = true,
  bool abandoned = false,
  SessionMode mode = SessionMode.flowBlock,
}) {
  return SessionRecord(
    id: 0,
    startedAt: DateTime(2026, 6, 12, 9),
    mode: mode,
    intention: 'x',
    plannedDuration: const Duration(minutes: 25),
    recordedFocus: recorded,
    completed: completed,
    abandoned: abandoned,
    autoContinue: false,
    soundscape: 'sand',
    skinId: 'classic',
  );
}

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late SettingsRepository settings;
  late SessionFinalizer finalizer;

  setUp(() {
    db = AppDatabase.memory();
    sessions = SessionRepository(db);
    settings = SettingsRepository(db);
    finalizer = SessionFinalizer(sessions, settings, const StaminaCalculator());
  });
  tearDown(() async => db.close());

  test('persists a completed flow block and updates stamina', () async {
    await finalizer.persist(_record(recorded: const Duration(minutes: 30)));

    final all = await sessions.allSessions();
    expect(all, hasLength(1));
    expect(all.single.completed, isTrue);
    // currentStamina over [30 min] == 30 min == 1800 s
    expect(await settings.getInt('staminaSeconds', defaultValue: 0), 1800);
  });

  test('persists an abandoned session without changing stamina', () async {
    await settings.setInt('staminaSeconds', 1500);
    await finalizer.persist(
      _record(recorded: Duration.zero, completed: false, abandoned: true),
    );

    final all = await sessions.allSessions();
    expect(all, hasLength(1));
    expect(all.single.abandoned, isTrue);
    expect(await settings.getInt('staminaSeconds', defaultValue: 0), 1500);
  });

  test('does not update stamina for a completed non-flow-block session', () async {
    await settings.setInt('staminaSeconds', 1500);
    await finalizer.persist(
      _record(recorded: const Duration(minutes: 25), mode: SessionMode.pomodoro),
    );
    expect(await settings.getInt('staminaSeconds', defaultValue: 0), 1500);
  });
}
