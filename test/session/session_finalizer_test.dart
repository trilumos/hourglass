import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/session_repository.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
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
  late SessionFinalizer finalizer;

  setUp(() {
    db = AppDatabase.memory();
    sessions = SessionRepository(db);
    finalizer = SessionFinalizer(sessions);
  });
  tearDown(() async => db.close());

  // The finalizer only persists; Focus Stamina is derived from the stored
  // sessions on read (covered by stamina_calculator_test / insights_extras_test).

  test('persists a completed flow block', () async {
    final id =
        await finalizer.persist(_record(recorded: const Duration(minutes: 30)));
    expect(id, isNotNull);
    final all = await sessions.allSessions();
    expect(all, hasLength(1));
    expect(all.single.completed, isTrue);
  });

  test('records nothing for a sub-2-min Flow end (returns null)', () async {
    final id = await finalizer.persist(
      _record(
          recorded: const Duration(seconds: 21),
          completed: false,
          abandoned: true),
    );
    expect(id, isNull);
    expect(await sessions.allSessions(), isEmpty);
  });

  test('keeps a sub-2-min Pomodoro/Custom session', () async {
    final id = await finalizer.persist(
      _record(recorded: const Duration(seconds: 21), mode: SessionMode.pomodoro),
    );
    expect(id, isNotNull);
    expect(await sessions.allSessions(), hasLength(1));
  });

  test('persists an abandoned-but-recorded Flow block (it still counts)',
      () async {
    final id = await finalizer.persist(_record(
        recorded: const Duration(minutes: 5),
        completed: false,
        abandoned: true));
    expect(id, isNotNull);
    final all = await sessions.allSessions();
    expect(all.single.abandoned, isTrue);
    expect(all.single.recordedFocus, const Duration(minutes: 5));
  });
}
