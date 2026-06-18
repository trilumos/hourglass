import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import '../domain/user_profile.dart';

/// Loads and updates the single on-device [UserProfile]. The row self-creates
/// on first [load]; callers never have to seed it.
class ProfileRepository {
  final AppDatabase _db;
  final String Function() _uuidGen;
  final DateTime Function() _now;

  ProfileRepository(
    this._db, {
    String Function()? uuidGen,
    DateTime Function()? clock,
  })  : _uuidGen = uuidGen ?? (() => const Uuid().v4()),
        _now = clock ?? DateTime.now;

  /// Returns the single profile, creating a default one if none exists.
  Future<UserProfile> load() async {
    final existing = await (_db.select(_db.profile)
          ..orderBy([(t) => OrderingTerm(expression: t.id)])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return _toDomain(existing);
    final now = _now();
    final id = await _db.into(_db.profile).insert(
          ProfileCompanion.insert(
            uuid: _uuidGen(),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final row = await (_db.select(_db.profile)..where((t) => t.id.equals(id)))
        .getSingle();
    return _toDomain(row);
  }

  /// Updates name and/or image; always bumps [updatedAt]. Pass [clearImage]
  /// true to remove the avatar.
  Future<UserProfile> update({
    String? name,
    String? imagePath,
    bool clearImage = false,
  }) async {
    final current = await load();
    await (_db.update(_db.profile)..where((t) => t.id.equals(current.id)))
        .write(ProfileCompanion(
      name: name == null ? const Value.absent() : Value(name),
      imagePath: clearImage
          ? const Value(null)
          : (imagePath == null ? const Value.absent() : Value(imagePath)),
      updatedAt: Value(_now()),
    ));
    return load();
  }

  UserProfile _toDomain(ProfileData row) => UserProfile(
        id: row.id,
        uuid: row.uuid,
        name: row.name,
        imagePath: row.imagePath,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
