import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import '../domain/session_record.dart';

/// Persists and loads [SessionRecord]s, mapping to/from Drift rows.
class SessionRepository {
  final AppDatabase _db;
  final String Function() _uuidGen;
  final DateTime Function() _now;

  SessionRepository(
    this._db, {
    String Function()? uuidGen,
    DateTime Function()? clock,
  })  : _uuidGen = uuidGen ?? (() => const Uuid().v4()),
        _now = clock ?? DateTime.now;

  /// Inserts [r] and returns the new row id (used to revise the same record when
  /// a Flow Block is extended via "Keep going").
  Future<int> insertSession(SessionRecord r) async {
    return _db.into(_db.sessions).insert(
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
            uuid: Value(_uuidGen()),
            updatedAt: Value(_now()),
          ),
        );
  }

  /// Revises the recorded focus (and completed/abandoned flags) of an existing
  /// session — used when a Flow Block is extended past its original length.
  Future<void> updateRecordedFocus(
    int id, {
    required Duration recorded,
    required bool completed,
    required bool abandoned,
  }) async {
    await (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        recordedSeconds: Value(recorded.inSeconds),
        completed: Value(completed),
        abandoned: Value(abandoned),
        updatedAt: Value(_now()),
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
