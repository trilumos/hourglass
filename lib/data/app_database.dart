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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Additive, non-destructive: existing sessions are preserved and
            // back-filled with sync metadata; the Profile table is created
            // (its row self-creates lazily via ProfileRepository).
            await m.addColumn(sessions, sessions.uuid);
            await m.addColumn(sessions, sessions.updatedAt);
            await m.createTable(profile);
            const gen = Uuid();
            final rows = await select(sessions).get();
            await batch((b) {
              for (final row in rows) {
                b.update(
                  sessions,
                  SessionsCompanion(
                    uuid: Value(gen.v4()),
                    updatedAt: Value(row.startedAt),
                  ),
                  where: (t) => t.id.equals(row.id),
                );
              }
            });
          }
        },
      );

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
