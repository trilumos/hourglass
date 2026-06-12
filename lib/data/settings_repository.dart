import 'app_database.dart';

/// Typed access to the key/value [Settings] table.
class SettingsRepository {
  final AppDatabase _db;
  SettingsRepository(this._db);

  Future<String?> _raw(String key) async {
    final row = await (_db.select(_db.settings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<bool> getBool(String key, {required bool defaultValue}) async {
    final v = await _raw(key);
    if (v == null) return defaultValue;
    return v == 'true';
  }

  Future<void> setBool(String key, bool value) =>
      _write(key, value ? 'true' : 'false');

  Future<int> getInt(String key, {required int defaultValue}) async {
    final v = await _raw(key);
    return v == null ? defaultValue : int.parse(v);
  }

  Future<void> setInt(String key, int value) => _write(key, '$value');
}
