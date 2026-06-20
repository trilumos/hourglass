import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/backup_service.dart';
import 'package:hourglass/data/image_storage_service.dart';
import 'package:hourglass/data/profile_repository.dart';
import 'package:hourglass/data/session_repository.dart';
import 'package:hourglass/data/settings_repository.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

SessionRecord rec(DateTime at, int mins) => SessionRecord(
      id: 0,
      startedAt: at,
      mode: SessionMode.flowBlock,
      intention: 'write',
      plannedDuration: Duration(minutes: mins),
      recordedFocus: Duration(minutes: mins),
      completed: true,
      abandoned: false,
      autoContinue: false,
      soundscape: 'sand',
      skinId: 'classic',
      planJson: null,
    );

void main() {
  late SharedPreferences prefs;
  final images = ImageStorageService(baseDirOverride: () async => Directory.systemTemp);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'hg.themeId': 'tide', 'hg.mode': 2});
    prefs = await SharedPreferences.getInstance();
  });

  test('export then import on a fresh device restores everything', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await SessionRepository(db).insertSession(rec(DateTime(2026, 6, 18, 9), 25));
    await SettingsRepository(db).setInt('staminaSeconds', 1500);
    await ProfileRepository(db).update(name: 'Deep');

    final map = await BackupService(db, prefs, images).exportData();
    expect(map['format'], BackupService.formatTag);

    // Fresh device: empty DB + empty prefs.
    final db2 = AppDatabase.memory();
    addTearDown(db2.close);
    await prefs.clear();

    final added = await BackupService(db2, prefs, images).importData(map);
    expect(added, 1);
    expect((await SessionRepository(db2).allSessions()).length, 1);
    expect(await SettingsRepository(db2).getInt('staminaSeconds', defaultValue: 0), 1500);
    expect((await ProfileRepository(db2).load()).name, 'Deep');
    expect(prefs.getString('hg.themeId'), 'tide');
    expect(prefs.getInt('hg.mode'), 2);
  });

  test('re-importing the same backup adds no duplicate sessions (merge by uuid)',
      () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await SessionRepository(db).insertSession(rec(DateTime(2026, 6, 18, 9), 25));
    final map = await BackupService(db, prefs, images).exportData();

    final db2 = AppDatabase.memory();
    addTearDown(db2.close);
    final svc = BackupService(db2, prefs, images);
    expect(await svc.importData(map), 1); // first import adds it
    expect(await svc.importData(map), 0); // second import is a no-op
    expect((await SessionRepository(db2).allSessions()).length, 1);
  });

  test('importData rejects a file that is not a Sustain backup', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    expect(
      () => BackupService(db, prefs, images).importData({'format': 'something'}),
      throwsA(isA<BackupException>()),
    );
  });
}
