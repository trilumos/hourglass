import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/domain/session_record.dart';

ProviderContainer _container() {
  final c = ProviderContainer(overrides: [
    databaseProvider.overrideWith((ref) {
      final db = AppDatabase.memory();
      ref.onDispose(db.close);
      return db;
    }),
  ]);
  addTearDown(c.dispose);
  return c;
}

SessionRecord _record() => SessionRecord(
      id: 0,
      startedAt: DateTime(2026, 1, 1, 9),
      mode: SessionMode.flowBlock,
      intention: 'Focus',
      plannedDuration: const Duration(minutes: 25),
      recordedFocus: const Duration(minutes: 25),
      completed: true,
      abandoned: false,
      autoContinue: false,
      soundscape: 'sand',
      skinId: 'classic',
    );

void main() {
  test('fresh install (no data, flag unset) -> show onboarding (false)',
      () async {
    final c = _container();
    expect(await c.read(onboardingCompleteProvider.future), isFalse);
  });

  test('flag stored true -> skip onboarding (true)', () async {
    final c = _container();
    await c
        .read(settingsRepositoryProvider)
        .setBool(SettingsKeys.onboardingComplete, true);
    expect(await c.read(onboardingCompleteProvider.future), isTrue);
  });

  test('existing session -> guard marks done (true) and persists', () async {
    final c = _container();
    await c.read(sessionRepositoryProvider).insertSession(_record());
    expect(await c.read(onboardingCompleteProvider.future), isTrue);
    expect(
      await c
          .read(settingsRepositoryProvider)
          .getBool(SettingsKeys.onboardingComplete, defaultValue: false),
      isTrue,
    );
  });

  test('existing profile name -> guard marks done (true)', () async {
    final c = _container();
    await c.read(profileRepositoryProvider).update(name: 'Maya');
    expect(await c.read(onboardingCompleteProvider.future), isTrue);
  });
}
