import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../domain/session_mode.dart';

part 'app_database.g.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get mode => intEnum<SessionMode>()();
  TextColumn get intention => text().withDefault(const Constant(''))();
  IntColumn get plannedSeconds => integer()();
  IntColumn get recordedSeconds => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get abandoned => boolean().withDefault(const Constant(false))();
  BoolColumn get autoContinue => boolean().withDefault(const Constant(false))();
  TextColumn get soundscape => text().withDefault(const Constant('sand'))();
  TextColumn get skinId => text().withDefault(const Constant('classic'))();
  TextColumn get uuid => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Serialized [SessionConfig] (segments + flags) so a session can be replayed
  /// exactly ("Start again"). Null for rows created before schema v3.
  TextColumn get planJson => text().nullable()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// The single on-device user profile. The repository keeps exactly one row.
/// [uuid] + [updatedAt] make a future cloud sync a clean add-on.
class Profile extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [Sessions, Settings, Profile])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file.
  factory AppDatabase.open() {
    return AppDatabase(LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'hourglass.sqlite'));
      return NativeDatabase.createInBackground(file);
    }));
  }

  /// In-memory database for tests.
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Additive, non-destructive AND idempotent. Drift only bumps
            // user_version after onUpgrade returns; if a prior attempt was
            // interrupted (process killed mid-migration), this re-runs from
            // from==1 — so every step is guarded to never fail on re-apply.
            final sessionCols =
                await customSelect("PRAGMA table_info('sessions')")
                    .get()
                    .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
            if (!sessionCols.contains('uuid')) {
              await m.addColumn(sessions, sessions.uuid);
            }
            if (!sessionCols.contains('updated_at')) {
              await m.addColumn(sessions, sessions.updatedAt);
            }
            final hasProfile = await customSelect(
              "SELECT 1 FROM sqlite_master WHERE type='table' AND name='profile'",
            ).get().then((rows) => rows.isNotEmpty);
            if (!hasProfile) {
              await m.createTable(profile);
            }
            // Back-fill sync metadata only for rows still missing it.
            const gen = Uuid();
            final rows = await select(sessions).get();
            await batch((b) {
              for (final row in rows) {
                if (row.uuid == null) {
                  b.update(
                    sessions,
                    SessionsCompanion(
                      uuid: Value(gen.v4()),
                      updatedAt: Value(row.updatedAt ?? row.startedAt),
                    ),
                    where: (t) => t.id.equals(row.id),
                  );
                }
              }
            });
          }
          if (from < 3) {
            // Add the nullable planJson column (idempotent; re-run safe).
            final cols = await customSelect("PRAGMA table_info('sessions')")
                .get()
                .then((rows) => rows.map((r) => r.read<String>('name')).toSet());
            if (!cols.contains('plan_json')) {
              await m.addColumn(sessions, sessions.planJson);
            }
          }
        },
      );

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
