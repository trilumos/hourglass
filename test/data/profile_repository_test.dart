import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/data/profile_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() async => db.close());

  test('load creates exactly one profile and reuses it', () async {
    final repo = ProfileRepository(db, uuidGen: () => 'fixed-uuid');
    final a = await repo.load();
    final b = await repo.load();

    expect(a.id, b.id);
    expect(a.uuid, 'fixed-uuid');
    expect(a.name, '');
    expect(a.imagePath, isNull);

    final rows = await db.select(db.profile).get();
    expect(rows, hasLength(1));
  });

  test('update sets fields and bumps updatedAt', () async {
    var t = DateTime(2026, 6, 17, 10);
    final repo = ProfileRepository(db, clock: () => t);
    await repo.load(); // created at 10:00
    t = DateTime(2026, 6, 17, 11);

    final updated =
        await repo.update(name: 'Deep', imagePath: 'profile/avatar.jpg');
    expect(updated.name, 'Deep');
    expect(updated.imagePath, 'profile/avatar.jpg');
    expect(updated.updatedAt, DateTime(2026, 6, 17, 11));
  });

  test('clearImage nulls the avatar path', () async {
    final repo = ProfileRepository(db);
    await repo.update(name: 'Deep', imagePath: 'profile/avatar.jpg');
    final cleared = await repo.update(clearImage: true);
    expect(cleared.imagePath, isNull);
    expect(cleared.name, 'Deep'); // name preserved
  });
}
