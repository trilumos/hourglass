import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tmp;
  late String dbPath;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hg_mig');
    dbPath = p.join(tmp.path, 'hourglass.sqlite');

    // Build a v1-shaped database with two existing sessions, no sync columns.
    final raw = sqlite3.open(dbPath);
    raw.execute('''
      CREATE TABLE sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        mode INTEGER NOT NULL,
        intention TEXT NOT NULL DEFAULT '',
        planned_seconds INTEGER NOT NULL,
        recorded_seconds INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        abandoned INTEGER NOT NULL DEFAULT 0,
        auto_continue INTEGER NOT NULL DEFAULT 0,
        soundscape TEXT NOT NULL DEFAULT 'sand',
        skin_id TEXT NOT NULL DEFAULT 'classic'
      );
    ''');
    raw.execute('''
      CREATE TABLE settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO sessions (started_at, mode, planned_seconds, recorded_seconds, completed) "
      "VALUES ('2026-06-11T09:00:00.000Z', 0, 1500, 1500, 1);",
    );
    raw.execute(
      "INSERT INTO sessions (started_at, mode, planned_seconds, recorded_seconds, completed) "
      "VALUES ('2026-06-12T09:00:00.000Z', 0, 1500, 600, 0);",
    );
    raw.execute('PRAGMA user_version = 1;');
    raw.close();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('v1->v2 upgrade preserves sessions and back-fills uuid/updatedAt',
      () async {
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    // Reading triggers the migration.
    final rows = await db.select(db.sessions).get();
    expect(rows, hasLength(2), reason: 'existing rows preserved');

    expect(rows.map((r) => r.recordedSeconds).toList(), [1500, 600]);

    for (final r in rows) {
      expect(r.uuid, isNotNull);
      expect(r.uuid!.isNotEmpty, isTrue);
      expect(r.updatedAt, r.startedAt,
          reason: 'updatedAt back-filled to startedAt');
    }
    expect(rows[0].uuid, isNot(rows[1].uuid), reason: 'uuids unique');

    // Profile table now exists and is empty (created lazily, not by migration).
    final profiles = await db.select(db.profile).get();
    expect(profiles, isEmpty);
  });
}
