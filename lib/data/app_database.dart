import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Sessions, Settings])
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
  int get schemaVersion => 1;

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
