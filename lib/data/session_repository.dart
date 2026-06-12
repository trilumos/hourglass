import 'package:drift/drift.dart';

import 'app_database.dart';
import '../domain/session_record.dart';

/// Persists and loads [SessionRecord]s, mapping to/from Drift rows.
class SessionRepository {
  final AppDatabase _db;
  SessionRepository(this._db);

  Future<void> insertSession(SessionRecord r) async {
    await _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            startedAt: r.startedAt,
            mode: r.mode,
            intention: Value(r.intention),
            plannedSeconds: r.plannedDuration.inSeconds,
            recordedSeconds: r.recordedFocus.inSeconds,
            completed: Value(r.completed),
            abandoned: Value(r.abandoned),
            autoContinue: Value(r.autoContinue),
            soundscape: Value(r.soundscape),
            skinId: Value(r.skinId),
          ),
        );
  }

  Future<List<SessionRecord>> allSessions() async {
    final query = _db.select(_db.sessions)
      ..orderBy([(t) => OrderingTerm(expression: t.startedAt)]);
    final rows = await query.get();
    return rows.map(_toRecord).toList();
  }

  SessionRecord _toRecord(Session row) => SessionRecord(
        id: row.id,
        startedAt: row.startedAt,
        mode: row.mode,
        intention: row.intention,
        plannedDuration: Duration(seconds: row.plannedSeconds),
        recordedFocus: Duration(seconds: row.recordedSeconds),
        completed: row.completed,
        abandoned: row.abandoned,
        autoContinue: row.autoContinue,
        soundscape: row.soundscape,
        skinId: row.skinId,
      );
}
