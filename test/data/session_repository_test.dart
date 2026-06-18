import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/session_repository.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';

void main() {
  late AppDatabase db;
  late SessionRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = SessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('inserting then loading returns an equivalent record', () async {
    final draft = SessionRecord(
      id: 0,
      startedAt: DateTime(2026, 6, 11, 9),
      mode: SessionMode.flowBlock,
      intention: 'Write essay intro',
      plannedDuration: const Duration(minutes: 25),
      recordedFocus: const Duration(minutes: 25),
      completed: true,
      abandoned: false,
      autoContinue: false,
      soundscape: 'sand',
      skinId: 'classic',
    );

    await repo.insertSession(draft);
    final all = await repo.allSessions();

    expect(all, hasLength(1));
    final loaded = all.single;
    expect(loaded.intention, 'Write essay intro');
    expect(loaded.mode, SessionMode.flowBlock);
    expect(loaded.plannedDuration, const Duration(minutes: 25));
    expect(loaded.recordedFocus, const Duration(minutes: 25));
    expect(loaded.completed, isTrue);
    expect(loaded.startedAt, DateTime(2026, 6, 11, 9));
    expect(loaded.id, greaterThan(0));
  });

  test('allSessions returns sessions ordered oldest first', () async {
    await repo.insertSession(_draft(DateTime(2026, 6, 11)));
    await repo.insertSession(_draft(DateTime(2026, 6, 9)));
    final all = await repo.allSessions();
    expect(all.first.startedAt, DateTime(2026, 6, 9));
    expect(all.last.startedAt, DateTime(2026, 6, 11));
  });

  test('insertSession stamps a uuid and updatedAt', () async {
    final repo2 = SessionRepository(db,
        uuidGen: () => 'sess-uuid', clock: () => DateTime(2026, 6, 17, 12));
    await repo2.insertSession(_draft(DateTime(2026, 6, 11)));
    final row = await (db.select(db.sessions)).getSingle();
    expect(row.uuid, 'sess-uuid');
    expect(row.updatedAt, DateTime(2026, 6, 17, 12));
  });

  test('updateRecordedFocus bumps updatedAt', () async {
    var t = DateTime(2026, 6, 17, 12);
    final repo2 = SessionRepository(db, clock: () => t);
    final id = await repo2.insertSession(_draft(DateTime(2026, 6, 11)));
    t = DateTime(2026, 6, 17, 13);
    await repo2.updateRecordedFocus(id,
        recorded: const Duration(minutes: 40),
        completed: true,
        abandoned: false);
    final row = await (db.select(db.sessions)..where((s) => s.id.equals(id)))
        .getSingle();
    expect(row.updatedAt, DateTime(2026, 6, 17, 13));
    expect(row.recordedSeconds, 40 * 60);
  });
}

SessionRecord _draft(DateTime startedAt) => SessionRecord(
      id: 0,
      startedAt: startedAt,
      mode: SessionMode.flowBlock,
      intention: '',
      plannedDuration: const Duration(minutes: 25),
      recordedFocus: const Duration(minutes: 25),
      completed: true,
      abandoned: false,
      autoContinue: false,
      soundscape: 'sand',
      skinId: 'classic',
    );
