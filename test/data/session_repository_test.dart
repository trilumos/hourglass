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
