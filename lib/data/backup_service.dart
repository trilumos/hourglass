import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/session_mode.dart';
import 'app_database.dart';
import 'image_storage_service.dart';

/// Exports/imports ALL on-device user data as one portable, versioned JSON map,
/// so a user never loses their focus history when they switch phones. This is
/// the manual v1 safety net; full cloud sync + auth is V2. Captures: every
/// session (with its uuid, so restore MERGES instead of overwriting), the
/// Settings table (stamina, prefs, onboarding flag), the profile (+ avatar as
/// base64), and SharedPreferences (theme id + mode). Entitlements (Pro) are NOT
/// here — those restore from Google Play.
class BackupService {
  final AppDatabase _db;
  final SharedPreferences _prefs;
  final ImageStorageService _images;
  final String Function() _uuidGen;
  final DateTime Function() _now;

  BackupService(
    this._db,
    this._prefs,
    this._images, {
    String Function()? uuidGen,
    DateTime Function()? clock,
  })  : _uuidGen = uuidGen ?? (() => const Uuid().v4()),
        _now = clock ?? DateTime.now;

  static const formatTag = 'sustain-backup';
  static const formatVersion = 1;

  /// Builds the full backup map (the caller JSON-encodes + writes/shares it).
  Future<Map<String, dynamic>> exportData() async {
    final sessions = await _db.select(_db.sessions).get();
    final settings = await _db.select(_db.settings).get();
    final profileRow = await (_db.select(_db.profile)
          ..orderBy([(t) => OrderingTerm(expression: t.id)])
          ..limit(1))
        .getSingleOrNull();

    String? imageB64;
    final imgPath = profileRow?.imagePath;
    if (imgPath != null) {
      try {
        final f = await _images.resolve(imgPath);
        if (await f.exists()) imageB64 = base64Encode(await f.readAsBytes());
      } catch (_) {/* avatar unreadable — back up the rest */}
    }

    return {
      'format': formatTag,
      'version': formatVersion,
      'exportedAt': _now().toIso8601String(),
      'sessions': [for (final s in sessions) _sessionToJson(s)],
      'settings': {for (final s in settings) s.key: s.value},
      'profile': profileRow == null
          ? null
          : {
              'uuid': profileRow.uuid,
              'name': profileRow.name,
              'createdAt': profileRow.createdAt.toIso8601String(),
              'updatedAt': profileRow.updatedAt.toIso8601String(),
              'image': imageB64,
            },
      'prefs': _prefsToJson(),
    };
  }

  Map<String, dynamic> _sessionToJson(Session s) => {
        'startedAt': s.startedAt.toIso8601String(),
        'mode': s.mode.index,
        'intention': s.intention,
        'plannedSeconds': s.plannedSeconds,
        'recordedSeconds': s.recordedSeconds,
        'completed': s.completed,
        'abandoned': s.abandoned,
        'autoContinue': s.autoContinue,
        'soundscape': s.soundscape,
        'skinId': s.skinId,
        'uuid': s.uuid ?? _uuidGen(),
        'updatedAt': (s.updatedAt ?? s.startedAt).toIso8601String(),
        'planJson': s.planJson,
      };

  List<Map<String, dynamic>> _prefsToJson() {
    final out = <Map<String, dynamic>>[];
    for (final key in _prefs.getKeys()) {
      final v = _prefs.get(key);
      final String type;
      if (v is bool) {
        type = 'bool';
      } else if (v is int) {
        type = 'int';
      } else if (v is double) {
        type = 'double';
      } else if (v is String) {
        type = 'string';
      } else if (v is List<String>) {
        type = 'stringList';
      } else {
        continue;
      }
      out.add({'key': key, 'type': type, 'value': v});
    }
    return out;
  }

  /// Restores from [data]. Sessions MERGE by uuid (existing data is never
  /// deleted, duplicates are skipped); profile + settings + prefs overwrite.
  /// Returns the number of NEW sessions added. Throws [BackupException] on a
  /// file that isn't a Sustain backup.
  Future<int> importData(Map<String, dynamic> data) async {
    if (data['format'] != formatTag) {
      throw const BackupException('That file is not a Sustain backup.');
    }

    final existing = (await _db.select(_db.sessions).get())
        .map((s) => s.uuid)
        .whereType<String>()
        .toSet();
    final incoming = (data['sessions'] as List?) ?? const [];
    var added = 0;
    await _db.batch((b) {
      for (final raw in incoming) {
        final m = raw as Map<String, dynamic>;
        final uuid = m['uuid'] as String?;
        if (uuid != null && existing.contains(uuid)) continue;
        final started = DateTime.parse(m['startedAt'] as String);
        b.insert(
          _db.sessions,
          SessionsCompanion.insert(
            startedAt: started,
            mode: SessionMode.values[(m['mode'] as num).toInt()],
            intention: Value(m['intention'] as String? ?? ''),
            plannedSeconds: (m['plannedSeconds'] as num).toInt(),
            recordedSeconds: (m['recordedSeconds'] as num).toInt(),
            completed: Value(m['completed'] as bool? ?? false),
            abandoned: Value(m['abandoned'] as bool? ?? false),
            autoContinue: Value(m['autoContinue'] as bool? ?? false),
            soundscape: Value(m['soundscape'] as String? ?? 'sand'),
            skinId: Value(m['skinId'] as String? ?? 'classic'),
            planJson: Value(m['planJson'] as String?),
            uuid: Value(uuid ?? _uuidGen()),
            updatedAt: Value(m['updatedAt'] != null
                ? DateTime.parse(m['updatedAt'] as String)
                : started),
          ),
        );
        added++;
      }
    });

    final settings = (data['settings'] as Map?) ?? const {};
    for (final entry in settings.entries) {
      await _db.into(_db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(
                key: entry.key as String, value: entry.value as String),
          );
    }

    final profile = data['profile'] as Map?;
    if (profile != null) {
      String? imagePath;
      final imgB64 = profile['image'] as String?;
      if (imgB64 != null) {
        try {
          imagePath = await _images.saveAvatarBytes(base64Decode(imgB64));
        } catch (_) {/* keep the rest of the profile */}
      }
      final row = await (_db.select(_db.profile)..limit(1)).getSingleOrNull();
      if (row == null) {
        await _db.into(_db.profile).insert(
              ProfileCompanion.insert(
                uuid: profile['uuid'] as String? ?? _uuidGen(),
                name: Value(profile['name'] as String? ?? ''),
                imagePath: Value(imagePath),
                createdAt:
                    DateTime.tryParse(profile['createdAt'] as String? ?? '') ??
                        _now(),
                updatedAt: _now(),
              ),
            );
      } else {
        await (_db.update(_db.profile)..where((t) => t.id.equals(row.id)))
            .write(ProfileCompanion(
          name: Value(profile['name'] as String? ?? row.name),
          imagePath: imagePath != null ? Value(imagePath) : const Value.absent(),
          updatedAt: Value(_now()),
        ));
      }
    }

    final prefs = (data['prefs'] as List?) ?? const [];
    for (final raw in prefs) {
      final m = raw as Map<String, dynamic>;
      final key = m['key'] as String;
      final value = m['value'];
      switch (m['type']) {
        case 'bool':
          await _prefs.setBool(key, value as bool);
        case 'int':
          await _prefs.setInt(key, (value as num).toInt());
        case 'double':
          await _prefs.setDouble(key, (value as num).toDouble());
        case 'string':
          await _prefs.setString(key, value as String);
        case 'stringList':
          await _prefs.setStringList(key, (value as List).cast<String>());
      }
    }
    return added;
  }
}

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
  @override
  String toString() => message;
}
