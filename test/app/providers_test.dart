import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/session_repository.dart';
import 'package:hourglass/data/settings_repository.dart';

void main() {
  test('repositories resolve from an in-memory database override', () async {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) {
        final db = AppDatabase.memory();
        ref.onDispose(db.close);
        return db;
      }),
    ]);
    addTearDown(container.dispose);

    expect(container.read(sessionRepositoryProvider), isA<SessionRepository>());
    expect(container.read(settingsRepositoryProvider), isA<SettingsRepository>());
    final sessions = await container.read(sessionRepositoryProvider).allSessions();
    expect(sessions, isEmpty);
  });

  test('profileProvider self-creates a profile via the in-memory db', () async {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) {
        final db = AppDatabase.memory();
        ref.onDispose(db.close);
        return db;
      }),
    ]);
    addTearDown(container.dispose);

    final profile = await container.read(profileProvider.future);
    expect(profile.uuid, isNotEmpty);
    expect(profile.isSetUp, isFalse);
  });
}
