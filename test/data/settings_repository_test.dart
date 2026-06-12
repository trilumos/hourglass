import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = SettingsRepository(db);
  });

  tearDown(() async => db.close());

  test('returns the provided default when a key is unset', () async {
    expect(await repo.getBool('boringBreak', defaultValue: true), isTrue);
  });

  test('round-trips a bool', () async {
    await repo.setBool('protectBlock', false);
    expect(await repo.getBool('protectBlock', defaultValue: true), isFalse);
  });

  test('round-trips an int', () async {
    await repo.setInt('staminaSeconds', 1500);
    expect(await repo.getInt('staminaSeconds', defaultValue: 0), 1500);
  });

  test('getInt returns the default when the stored value is not an int', () async {
    await repo.setBool('weird', false); // stores the string 'false', not a number
    expect(await repo.getInt('weird', defaultValue: 7), 7);
  });
}
