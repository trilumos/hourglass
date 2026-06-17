# Profile / Account + DB (Foundation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Hourglass a local, sync-ready user profile plus the Profile / History / Focus-Score surfaces, and remove the hardcoded greeting name.

**Architecture:** Additive Drift migration (schemaVersion 1→2) adds a self-creating `Profile` table and `uuid`+`updatedAt` sync metadata to `Sessions`, preserving all existing data. A `ProfileRepository` + `ImageStorageService` back five new screens (Profile hub, Edit Profile, Session History, Per-session summary, Focus Score), wired through Riverpod `FutureProvider`s exactly like the existing providers. Aggregates stay derived from the sessions list.

**Tech Stack:** Flutter, Riverpod 3, Drift (SQLite, `storeDateTimeAsText`), `image_picker`, `image`, `uuid`. Design tokens in `lib/app/tokens.dart` + `context.hg` theme extension. Source of truth for look/feel: `docs/design-language.md`. Spec: `docs/superpowers/specs/2026-06-17-hourglass-profile-account-db-design.md`.

**UI code-completeness note:** Data/domain/service/provider tasks below give complete code and TDD tests. The five screens are design-heavy and iterated on-device; their tasks give a compilable structure + the non-obvious logic (validation, async image, routing) + behavior tests, and must be built to the existing token patterns (mirror `lib/ui/settings_screen.dart`). No hardcoded colors/spacing — use `context.hg` + `HgSpacing`/`HgFont`/`HgRadius`. Honor `MediaQuery.textScaler` (scrollable, no fixed-height clips).

**Naming note:** The Drift table class is `Profile` (generated row class `ProfileData`, companion `ProfileCompanion`). The **domain model is `UserProfile`** (`lib/domain/user_profile.dart`) to avoid a name clash with the Drift `Profile` table class.

---

## File structure

**Create:**
- `lib/domain/user_profile.dart` — domain profile model.
- `lib/data/profile_repository.dart` — self-creating singleton profile repo.
- `lib/data/image_storage_service.dart` — pick→crop→resize→save avatar to app-private dir.
- `lib/ui/profile_screen.dart` — Profile hub.
- `lib/ui/edit_profile_screen.dart` — edit name + photo.
- `lib/ui/session_history_screen.dart` — history list.
- `lib/ui/session_summary_screen.dart` — per-session detail.
- `lib/ui/focus_score_screen.dart` — Focus Score hero + explanation.
- `lib/ui/widgets/profile_avatar.dart` — reusable circular avatar (image or default).
- Tests: `test/domain/user_profile_test.dart`, `test/data/profile_repository_test.dart`, `test/data/migration_test.dart`, `test/data/image_storage_service_test.dart`, `test/ui/edit_profile_screen_test.dart`, `test/ui/profile_screen_test.dart`, `test/ui/session_history_screen_test.dart`.

**Modify:**
- `pubspec.yaml` — add deps.
- `lib/data/app_database.dart` — Profile table, Sessions sync columns, schemaVersion 2, migration.
- `lib/data/session_repository.dart` — set `uuid`+`updatedAt` on insert, bump `updatedAt` on revise.
- `lib/domain/stats_calculator.dart` — add `totalFocus`.
- `lib/app/providers.dart` — profile/image/history/profileStats providers.
- `lib/ui/home_screen.dart` — avatar (left) + tappable Focus stat.
- `lib/ui/settings_screen.dart` — Profile row.
- `lib/ui/widgets/greeting_line.dart` — read profile name, drop "Deep".
- Existing tests touched by new columns: `test/data/session_repository_test.dart`, `test/domain/stats_calculator_test.dart` (additions only).

---

## Phase A — DB foundation & sync-ready schema

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the packages**

Run (resolves compatible versions automatically):

```bash
flutter pub add uuid image image_picker
flutter pub add dev:sqlite3
```

Expected: `pubspec.yaml` gains `uuid`, `image`, `image_picker` under dependencies and `sqlite3` under dev_dependencies; `flutter pub get` runs clean.

- [ ] **Step 2: Verify analyze still clean**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: add uuid, image, image_picker (+ dev sqlite3) for profile feature"
```

---

### Task 2: Profile table + Sessions sync columns + migration

**Files:**
- Modify: `lib/data/app_database.dart`
- Regenerate: `lib/data/app_database.g.dart`

- [ ] **Step 1: Edit `app_database.dart`**

Add the `uuid` import at the top:

```dart
import 'package:uuid/uuid.dart';
```

Add two columns to the `Sessions` table (after `skinId`):

```dart
  TextColumn get uuid => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
```

Add the new table (after the `Settings` table):

```dart
class Profile extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

Register the table and bump the version + add the migration. Replace the `@DriftDatabase(...)` annotation and the `schemaVersion`/`options` members:

```dart
@DriftDatabase(tables: [Sessions, Settings, Profile])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.open() {
    return AppDatabase(LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'hourglass.sqlite'));
      return NativeDatabase.createInBackground(file);
    }));
  }

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
            await m.addColumn(sessions, sessions.uuid);
            await m.addColumn(sessions, sessions.updatedAt);
            await m.createTable(profile);
            // Back-fill sync metadata for existing sessions (non-destructive).
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
```

- [ ] **Step 2: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/data/app_database.g.dart` regenerates with the `Profile` table classes (`ProfileData`, `ProfileCompanion`) and the new `Sessions` columns. No errors.

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze`
Expected: No issues (existing `SessionRepository` still compiles — new columns are optional on the companion).

- [ ] **Step 4: Commit**

```bash
git add lib/data/app_database.dart lib/data/app_database.g.dart
git commit -m "feat(db): Profile table + Sessions uuid/updatedAt + v1->v2 migration"
```

---

### Task 3: Migration test (v1 → v2 preserves data + back-fills)

**Files:**
- Test: `test/data/migration_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tmp;
  late String dbPath;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hg_mig');
    dbPath = p.join(tmp.path, 'hourglass.sqlite');

    // Build a v1-shaped database with two existing sessions, no sync columns.
    final raw = sqlite3.open(dbPath);
    raw.execute('''
      CREATE TABLE sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        mode INTEGER NOT NULL,
        intention TEXT NOT NULL DEFAULT '',
        planned_seconds INTEGER NOT NULL,
        recorded_seconds INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        abandoned INTEGER NOT NULL DEFAULT 0,
        auto_continue INTEGER NOT NULL DEFAULT 0,
        soundscape TEXT NOT NULL DEFAULT 'sand',
        skin_id TEXT NOT NULL DEFAULT 'classic'
      );
    ''');
    raw.execute('''
      CREATE TABLE settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    raw.execute(
      "INSERT INTO sessions (started_at, mode, planned_seconds, recorded_seconds, completed) "
      "VALUES ('2026-06-11T09:00:00.000Z', 0, 1500, 1500, 1);",
    );
    raw.execute(
      "INSERT INTO sessions (started_at, mode, planned_seconds, recorded_seconds, completed) "
      "VALUES ('2026-06-12T09:00:00.000Z', 0, 1500, 600, 0);",
    );
    raw.execute('PRAGMA user_version = 1;');
    raw.dispose();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('v1->v2 upgrade preserves sessions and back-fills uuid/updatedAt', () async {
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    // Reading triggers the migration.
    final rows = await db.select(db.sessions).get();
    expect(rows, hasLength(2), reason: 'existing rows preserved');

    expect(rows.map((r) => r.recordedSeconds).toList(), [1500, 600]);

    for (final r in rows) {
      expect(r.uuid, isNotNull);
      expect(r.uuid!.isNotEmpty, isTrue);
      expect(r.updatedAt, r.startedAt, reason: 'updatedAt back-filled to startedAt');
    }
    expect(rows[0].uuid, isNot(rows[1].uuid), reason: 'uuids unique');

    // Profile table now exists and is empty (created lazily, not by migration).
    final profiles = await db.select(db.profile).get();
    expect(profiles, isEmpty);
  });
}
```

- [ ] **Step 2: Run it**

Run: `flutter test test/data/migration_test.dart`
Expected: PASS. (If `sqlite3` import fails to resolve, confirm Task 1 Step 1 added `dev:sqlite3`.)

- [ ] **Step 3: Commit**

```bash
git add test/data/migration_test.dart
git commit -m "test(db): v1->v2 migration preserves data and back-fills sync fields"
```

---

### Task 4: `UserProfile` model + `ProfileRepository`

**Files:**
- Create: `lib/domain/user_profile.dart`
- Create: `lib/data/profile_repository.dart`
- Test: `test/domain/user_profile_test.dart`, `test/data/profile_repository_test.dart`

- [ ] **Step 1: Write `lib/domain/user_profile.dart`**

```dart
/// The single on-device user profile, as the app sees it (ORM-independent).
class UserProfile {
  final int id;
  final String uuid;
  final String name;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.uuid,
    required this.name,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasName => name.trim().isNotEmpty;
  bool get hasImage => imagePath != null;

  /// Whether the user has configured their profile (drives the "set up" nudge).
  bool get isSetUp => hasName;
}
```

- [ ] **Step 2: Write the model test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/user_profile.dart';

UserProfile _p({String name = '', String? imagePath}) => UserProfile(
      id: 1,
      uuid: 'u',
      name: name,
      imagePath: imagePath,
      createdAt: DateTime(2026, 6, 17),
      updatedAt: DateTime(2026, 6, 17),
    );

void main() {
  test('isSetUp is false for blank/whitespace name', () {
    expect(_p(name: '').isSetUp, isFalse);
    expect(_p(name: '   ').isSetUp, isFalse);
    expect(_p(name: 'Deep').isSetUp, isTrue);
  });

  test('hasImage reflects imagePath', () {
    expect(_p().hasImage, isFalse);
    expect(_p(imagePath: 'profile/avatar.jpg').hasImage, isTrue);
  });
}
```

- [ ] **Step 3: Run it (fails — repository not used yet, but model test should pass)**

Run: `flutter test test/domain/user_profile_test.dart`
Expected: PASS.

- [ ] **Step 4: Write `lib/data/profile_repository.dart`**

```dart
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
    final existing =
        await (_db.select(_db.profile)..limit(1)).getSingleOrNull();
    if (existing != null) return _toDomain(existing);
    final now = _now();
    final id = await _db.into(_db.profile).insert(
          ProfileCompanion.insert(
            uuid: _uuidGen(),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final row =
        await (_db.select(_db.profile)..where((t) => t.id.equals(id)))
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
```

- [ ] **Step 5: Write the repository test**

```dart
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

    final updated = await repo.update(name: 'Deep', imagePath: 'profile/avatar.jpg');
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
```

- [ ] **Step 6: Run the tests**

Run: `flutter test test/domain/user_profile_test.dart test/data/profile_repository_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/domain/user_profile.dart lib/data/profile_repository.dart test/domain/user_profile_test.dart test/data/profile_repository_test.dart
git commit -m "feat(profile): UserProfile model + self-creating ProfileRepository"
```

---

### Task 5: Session sync metadata on insert/revise

**Files:**
- Modify: `lib/data/session_repository.dart`
- Test: `test/data/session_repository_test.dart` (add cases)

- [ ] **Step 1: Edit `session_repository.dart`**

Add imports + injected generators, and set the columns. Replace the class header + the two write methods:

```dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';
import '../domain/session_record.dart';

/// Persists and loads [SessionRecord]s, mapping to/from Drift rows.
class SessionRepository {
  final AppDatabase _db;
  final String Function() _uuidGen;
  final DateTime Function() _now;

  SessionRepository(
    this._db, {
    String Function()? uuidGen,
    DateTime Function()? clock,
  })  : _uuidGen = uuidGen ?? (() => const Uuid().v4()),
        _now = clock ?? DateTime.now;

  Future<int> insertSession(SessionRecord r) async {
    return _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            startedAt: r.startedAt,
            mode: r.mode,
            intention: Value(r.intention),
            plannedSeconds: r.plannedDuration.inSeconds,
            recordedSeconds: r.recordedFocus.inSeconds,
            completed: Value(r.completed),
            abandoned: Value(r.abandoned),
            autoContinue: Value(r.autoContinue),
            soundscape: Value(r.soundscape),
            skinId: Value(r.skinId),
            uuid: Value(_uuidGen()),
            updatedAt: Value(_now()),
          ),
        );
  }

  Future<void> updateRecordedFocus(
    int id, {
    required Duration recorded,
    required bool completed,
    required bool abandoned,
  }) async {
    await (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        recordedSeconds: Value(recorded.inSeconds),
        completed: Value(completed),
        abandoned: Value(abandoned),
        updatedAt: Value(_now()),
      ),
    );
  }
```

(Leave `allSessions` and `_toRecord` unchanged — `SessionRecord` does not surface `uuid`/`updatedAt`.)

- [ ] **Step 2: Add tests to `test/data/session_repository_test.dart`**

Add inside `main()` (these read the raw row to assert the DB-level sync fields):

```dart
  test('insertSession stamps a uuid and updatedAt', () async {
    final repo2 = SessionRepository(db,
        uuidGen: () => 'sess-uuid', clock: () => DateTime(2026, 6, 17, 12));
    await repo2.insertSession(_draft(DateTime(2026, 6, 11)));
    final row = await (db.select(db.sessions)).getSingle();
    expect(row.uuid, 'sess-uuid');
    expect(row.updatedAt, DateTime(2026, 6, 17, 12));
  });

  test('updateRecordedFocus bumps updatedAt', () async {
    var t = DateTime(2026, 6, 17, 12);
    final repo2 = SessionRepository(db, clock: () => t);
    final id = await repo2.insertSession(_draft(DateTime(2026, 6, 11)));
    t = DateTime(2026, 6, 17, 13);
    await repo2.updateRecordedFocus(id,
        recorded: const Duration(minutes: 40), completed: true, abandoned: false);
    final row = await (db.select(db.sessions)..where((s) => s.id.equals(id)))
        .getSingle();
    expect(row.updatedAt, DateTime(2026, 6, 17, 13));
    expect(row.recordedSeconds, 40 * 60);
  });
```

Add the Drift import at the top of the test file if not present: `import 'package:drift/drift.dart';` is NOT needed (queries use the db API), but the `db.select(db.sessions)` calls are already valid via the existing imports.

- [ ] **Step 3: Run the tests**

Run: `flutter test test/data/session_repository_test.dart`
Expected: PASS (existing 2 tests + 2 new).

- [ ] **Step 4: Commit**

```bash
git add lib/data/session_repository.dart test/data/session_repository_test.dart
git commit -m "feat(db): stamp uuid + updatedAt on session insert/revise"
```

---

## Phase B — Stats & providers

### Task 6: `StatsCalculator.totalFocus`

**Files:**
- Modify: `lib/domain/stats_calculator.dart`
- Test: `test/domain/stats_calculator_test.dart` (add cases)

- [ ] **Step 1: Add the method** (after `focusInWeekEnding`)

```dart
  /// Lifetime total focus across every session that recorded real focus.
  Duration totalFocus(List<SessionRecord> sessions) => sessions
      .where((s) => s.recordedFocus > Duration.zero)
      .fold(Duration.zero, (sum, s) => sum + s.recordedFocus);
```

- [ ] **Step 2: Add tests**

```dart
  test('totalFocus sums all recorded focus, ignoring zero-focus sessions', () {
    final sessions = [
      _session(startedAt: DateTime(2026, 6, 11)),                 // 25m
      _session(startedAt: DateTime(2026, 6, 10), recorded: const Duration(minutes: 5)),
      _session(startedAt: DateTime(2026, 6, 9), recorded: Duration.zero, completed: false, abandoned: true),
    ];
    expect(calc.totalFocus(sessions), const Duration(minutes: 30));
  });

  test('totalFocus is zero for no sessions', () {
    expect(calc.totalFocus(const []), Duration.zero);
  });
```

- [ ] **Step 3: Run**

Run: `flutter test test/domain/stats_calculator_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/domain/stats_calculator.dart test/domain/stats_calculator_test.dart
git commit -m "feat(stats): lifetime totalFocus"
```

---

### Task 7: Providers (profile, image, history, profile stats)

**Files:**
- Modify: `lib/app/providers.dart`
- Test: `test/app/providers_test.dart` (add a case)

- [ ] **Step 1: Add imports** (top of `providers.dart`)

```dart
import '../data/profile_repository.dart';
import '../data/image_storage_service.dart';
import '../domain/session_record.dart';
import '../domain/user_profile.dart';
```

- [ ] **Step 2: Add providers** (after `homeStatsProvider`)

```dart
/// The single on-device profile (self-creating). Invalidate after an edit.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

final imageStorageProvider =
    Provider<ImageStorageService>((ref) => ImageStorageService());

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).load(),
);

/// All sessions that recorded real focus, newest first (for the history list).
final sessionHistoryProvider = FutureProvider<List<SessionRecord>>((ref) async {
  final all = await ref.watch(sessionRepositoryProvider).allSessions();
  return all
      .where((s) => s.recordedFocus > Duration.zero)
      .toList()
      .reversed
      .toList();
});

/// Lifetime stats shown on the Profile hub.
class ProfileStats {
  final Duration totalFocus;
  final int streak;
  final int sessionsCompleted;
  const ProfileStats({
    required this.totalFocus,
    required this.streak,
    required this.sessionsCompleted,
  });
  static const empty =
      ProfileStats(totalFocus: Duration.zero, streak: 0, sessionsCompleted: 0);
}

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final now = ref.watch(clockProvider)();
  const stats = StatsCalculator();
  return ProfileStats(
    totalFocus: stats.totalFocus(sessions),
    streak: stats.currentStreak(now, sessions),
    sessionsCompleted: stats.sessionsCompleted(sessions),
  );
});
```

- [ ] **Step 3: Add a provider test**

```dart
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
```

- [ ] **Step 4: Run**

Run: `flutter test test/app/providers_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/providers.dart test/app/providers_test.dart
git commit -m "feat(providers): profile, image storage, session history, profile stats"
```

---

## Phase C — Image storage

### Task 8: `ImageStorageService`

**Files:**
- Create: `lib/data/image_storage_service.dart`
- Test: `test/data/image_storage_service_test.dart`

- [ ] **Step 1: Write the service**

```dart
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Saves the user's avatar into app-private storage as a 512² JPEG and returns a
/// **relative** path (e.g. `profile/avatar.jpg`) to store in the profile row.
class ImageStorageService {
  final Future<Directory> Function() _baseDir;
  ImageStorageService({Future<Directory> Function()? baseDirOverride})
      : _baseDir = baseDirOverride ?? getApplicationDocumentsDirectory;

  static const _relDir = 'profile';
  static const _avatarName = 'avatar.jpg';
  static const _size = 512;

  Future<String> saveAvatar(File picked) async {
    final decoded = img.decodeImage(await picked.readAsBytes());
    if (decoded == null) {
      throw const ImageStorageException('Could not read that image.');
    }
    final square = _centerSquare(decoded);
    final resized = img.copyResize(square, width: _size, height: _size);
    final jpg = img.encodeJpg(resized, quality: 85);

    final dir = Directory(p.join((await _baseDir()).path, _relDir));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, _avatarName));
    await file.writeAsBytes(jpg, flush: true);
    return p.join(_relDir, _avatarName);
  }

  Future<void> deleteAvatar(String relativePath) async {
    final file = File(p.join((await _baseDir()).path, relativePath));
    if (await file.exists()) await file.delete();
  }

  Future<File> resolve(String relativePath) async =>
      File(p.join((await _baseDir()).path, relativePath));

  img.Image _centerSquare(img.Image src) {
    final side = src.width < src.height ? src.width : src.height;
    final x = (src.width - side) ~/ 2;
    final y = (src.height - side) ~/ 2;
    return img.copyCrop(src, x: x, y: y, width: side, height: side);
  }
}

class ImageStorageException implements Exception {
  final String message;
  const ImageStorageException(this.message);
  @override
  String toString() => message;
}
```

- [ ] **Step 2: Write the test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/data/image_storage_service.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late ImageStorageService service;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hg_img');
    service = ImageStorageService(baseDirOverride: () async => tmp);
  });
  tearDown(() async => tmp.delete(recursive: true));

  File _writePng(int w, int h) {
    final file = File(p.join(tmp.path, 'src.png'));
    file.writeAsBytesSync(img.encodePng(img.Image(width: w, height: h)));
    return file;
  }

  test('saveAvatar writes a 512x512 jpg and returns the relative path', () async {
    final rel = await service.saveAvatar(_writePng(200, 120));
    expect(rel, p.join('profile', 'avatar.jpg'));

    final saved = await service.resolve(rel);
    expect(await saved.exists(), isTrue);
    final decoded = img.decodeImage(await saved.readAsBytes())!;
    expect(decoded.width, 512);
    expect(decoded.height, 512);
  });

  test('deleteAvatar removes the file', () async {
    final rel = await service.saveAvatar(_writePng(64, 64));
    await service.deleteAvatar(rel);
    expect(await (await service.resolve(rel)).exists(), isFalse);
  });

  test('saveAvatar throws on undecodable bytes', () async {
    final bad = File(p.join(tmp.path, 'bad.png'))..writeAsBytesSync([1, 2, 3]);
    expect(() => service.saveAvatar(bad), throwsA(isA<ImageStorageException>()));
  });
}
```

- [ ] **Step 3: Run**

Run: `flutter test test/data/image_storage_service_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/data/image_storage_service.dart test/data/image_storage_service_test.dart
git commit -m "feat(profile): ImageStorageService (square 512 jpg in app-private dir)"
```

---

## Phase D — Screens

> Build to the token system; mirror `lib/ui/settings_screen.dart` for the calm header + row patterns. Each screen is a `ConsumerWidget`/`ConsumerStatefulWidget` inside `Scaffold(body: ScreenBackground(child: SafeArea(...)))`.

### Task 9: `ProfileAvatar` widget

**Files:**
- Create: `lib/ui/widgets/profile_avatar.dart`

- [ ] **Step 1: Write the widget**

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

/// Circular avatar: the profile image if set, else a calm default glyph.
class ProfileAvatar extends ConsumerWidget {
  final double size;
  const ProfileAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final profile = ref.watch(profileProvider).asData?.value;
    final path = profile?.imagePath;

    Widget fallback() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: hg.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(color: hg.hairline),
          ),
          child: Icon(Icons.person_outline_rounded,
              size: size * 0.55, color: hg.textMuted),
        );

    if (path == null) return fallback();

    return FutureBuilder<File>(
      future: ref.watch(imageStorageProvider).resolve(path),
      builder: (context, snap) {
        final file = snap.data;
        if (file == null) return fallback();
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          ),
        );
      },
    );
  }
}
```

Note: if `hg.surfaceMuted` does not exist in the theme extension, use the nearest existing token (check `lib/app/theme.dart` — e.g. a card/surface color) rather than inventing one.

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze`
Expected: No issues (resolve any token-name mismatch against `lib/app/theme.dart`).

- [ ] **Step 3: Commit**

```bash
git add lib/ui/widgets/profile_avatar.dart
git commit -m "feat(ui): reusable circular ProfileAvatar (image or default)"
```

---

### Task 10: Focus Score page

**Files:**
- Create: `lib/ui/focus_score_screen.dart`

- [ ] **Step 1: Write the screen**

Hero number (count-up like Home's `_Stat`) + plain-language explanation. Structure:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/screen_background.dart';

/// The Focus Score, hero-sized, with an honest explanation of how it's computed.
class FocusScoreScreen extends ConsumerWidget {
  const FocusScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hg = context.hg;
    final score = ref.watch(focusScoreProvider).asData?.value ?? 0;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                // Back arrow + title row (mirror settings_screen.dart).
                _Header(),
                const SizedBox(height: HgSpacing.xl),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: score.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: HgMotion.calm,
                    builder: (_, v, _) => Text(
                      '${v.round()}',
                      style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 96,
                        fontWeight: FontWeight.w600,
                        color: hg.accent,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text('FOCUS SCORE',
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 11,
                          letterSpacing: 2,
                          color: hg.textMuted)),
                ),
                const SizedBox(height: HgSpacing.xl),
                _Explanation(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

`_Explanation` is calm body copy (use `hg.textSecondary`, ~15px, height 1.5). **Exact copy to ship** (honesty-compliant — no FRC claims, no "level up" line):

> Your Focus Score reflects your **recent** focus ability — the average of your last 10 Flow Blocks, on a scale of 0 to 100.
>
> It builds up over your first several Flow Blocks. One great session won't jump you to 100 — focus is trained, not flipped.
>
> Completing a block, and pushing a little past it, raises your score. Giving up early lowers it. Only Flow Blocks of at least 2 minutes count.

`_Header` = the back-arrow + "Focus Score" title Row copied from `settings_screen.dart` (extract the same pattern). Build it to match.

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/focus_score_screen.dart
git commit -m "feat(ui): Focus Score page (hero number + honest explanation)"
```

---

### Task 11: Session History + Per-session summary

**Files:**
- Create: `lib/ui/session_history_screen.dart`, `lib/ui/session_summary_screen.dart`
- Test: `test/ui/session_history_screen_test.dart`

- [ ] **Step 1: Write `session_summary_screen.dart`**

Takes a `SessionRecord`; shows date/time, mode, intention, planned-vs-focused, outcome, and (Flow Block ≥2 min) the per-session score via `FocusScoreCalculator().sessionScore(chosen:, actual:)`.

```dart
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import '../domain/focus_score_calculator.dart';
import '../domain/session_mode.dart';
import '../domain/session_record.dart';
import 'widgets/screen_background.dart';

class SessionSummaryScreen extends StatelessWidget {
  final SessionRecord session;
  const SessionSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final isFlow = session.mode == SessionMode.flowBlock;
    final scored = isFlow && session.recordedFocus.inSeconds >= 120;
    final score = scored
        ? const FocusScoreCalculator().sessionScore(
            chosen: session.plannedDuration, actual: session.recordedFocus)
        : null;
    // ... calm detail rows built from tokens (mirror settings rows) ...
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(/* header + detail rows + score line */),
      ),
    );
  }
}
```

Outcome label logic: `session.abandoned ? 'Ended early' : (session.recordedFocus > session.plannedDuration ? 'Extended' : 'Completed')`. Score line when `score != null`: "This session scored **$score** / 100 toward your Focus Score." Else: "Not scored."

- [ ] **Step 2: Write `session_history_screen.dart`**

Reads `sessionHistoryProvider` (already newest-first). Group by calendar day with headers **Today / Yesterday / `<d MMM yyyy>`** (compute from `ref.watch(clockProvider)()`). Each row → mode label + focused duration + intention + a quiet ✓/early mark; `onTap` pushes `SessionSummaryScreen(session: s)`. Empty state text: *"Your focused time will appear here."* Use `ListView` (data sets are small) or `ListView.builder`.

Day-key helper:

```dart
String dayLabel(DateTime d, DateTime now) {
  DateTime only(DateTime x) => DateTime(x.year, x.month, x.day);
  final diff = only(now).difference(only(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${d.day} ${_month(d.month)} ${d.year}';
}
```

(`_month` = a `const ['Jan',...]` lookup.)

- [ ] **Step 3: Write the history behavior test (empty state)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/session_history_screen.dart';

void main() {
  testWidgets('history shows the empty state with no sessions', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const MaterialApp(home: SessionHistoryScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('appear here'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run + analyze**

Run: `flutter test test/ui/session_history_screen_test.dart` then `flutter analyze`
Expected: PASS / no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/session_history_screen.dart lib/ui/session_summary_screen.dart test/ui/session_history_screen_test.dart
git commit -m "feat(ui): Session History list + per-session summary"
```

---

### Task 12: Profile hub + Edit Profile

**Files:**
- Create: `lib/ui/profile_screen.dart`, `lib/ui/edit_profile_screen.dart`
- Test: `test/ui/profile_screen_test.dart`, `test/ui/edit_profile_screen_test.dart`

- [ ] **Step 1: Write `edit_profile_screen.dart`**

`ConsumerStatefulWidget`. A `TextEditingController` seeded from the current profile name; a `_pendingImagePath` (nullable) seeded from the current `imagePath`. **Save is disabled until `controller.text.trim().isNotEmpty`.**

Key logic:

```dart
bool get _canSave => _controller.text.trim().isNotEmpty;

Future<void> _pickPhoto() async {
  final picked = await ImagePicker()
      .pickImage(source: ImageSource.gallery, maxWidth: 1024);
  if (picked == null) return; // cancelled
  try {
    final rel = await ref.read(imageStorageProvider).saveAvatar(File(picked.path));
    setState(() => _pendingImagePath = rel);
  } on ImageStorageException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

Future<void> _save() async {
  await ref.read(profileRepositoryProvider).update(
        name: _controller.text.trim(),
        imagePath: _pendingImagePath,
      );
  ref.invalidate(profileProvider);
  if (mounted) Navigator.of(context).pop();
}

Future<void> _removePhoto() async {
  final path = _pendingImagePath;
  if (path != null) await ref.read(imageStorageProvider).deleteAvatar(path);
  setState(() => _pendingImagePath = null);
}
```

Imports needed: `dart:io`, `package:image_picker/image_picker.dart`, providers, `image_storage_service.dart` (for `ImageStorageException`). Avatar preview uses `_pendingImagePath` (resolve via `imageStorageProvider`) or the default glyph. The **Save** button passes `onPressed: _canSave ? _save : null`.

- [ ] **Step 2: Write the Edit Profile behavior test (Save gating)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/edit_profile_screen.dart';

void main() {
  testWidgets('Save is disabled until a non-empty name is entered',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const MaterialApp(home: EditProfileScreen()),
    ));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(ElevatedButton, 'Save');
    expect(tester.widget<ElevatedButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Deep  ');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(save).onPressed, isNotNull);
  });
}
```

(If the Save control is not an `ElevatedButton` — e.g. the project's `PrimaryButton` — adjust the finder to that widget and assert its disabled state accordingly.)

- [ ] **Step 3: Write `profile_screen.dart`**

`ConsumerWidget`. Header: large `ProfileAvatar(size: 88)` → name (or *"Add your name"*) → an **Edit profile** button **directly below the name** → push `EditProfileScreen`. If `!profile.isSetUp`, show a quiet *"Set up your profile"* line under the header.

Headline stats row (4): **Focus Score** (`focusScoreProvider`, tappable → `FocusScoreScreen`), **Total focus** (`profileStatsProvider.totalFocus`), **Streak**, **Sessions**. Reuse the Home `_Stat` look (small reusable stat cell).

Nav rows (mirror settings rows): *Session history* → `SessionHistoryScreen`; *Focus Score* → `FocusScoreScreen`; *Analytics* — disabled, trailing **Soon** chip. **No Level, no Collection** (V2).

- [ ] **Step 4: Write the Profile hub test (nudge when empty)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/profile_screen.dart';

void main() {
  testWidgets('profile hub nudges setup when no name is set', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Set up your profile'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run + analyze**

Run: `flutter test test/ui/edit_profile_screen_test.dart test/ui/profile_screen_test.dart` then `flutter analyze`
Expected: PASS / no issues.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/profile_screen.dart lib/ui/edit_profile_screen.dart test/ui/profile_screen_test.dart test/ui/edit_profile_screen_test.dart
git commit -m "feat(ui): Profile hub + Edit Profile (name required, photo optional)"
```

---

## Phase E — Wire existing screens

### Task 13: Home top bar (avatar) + tappable Focus stat

**Files:**
- Modify: `lib/ui/home_screen.dart`

- [ ] **Step 1: Add imports**

```dart
import 'profile_screen.dart';
import 'focus_score_screen.dart';
import 'widgets/profile_avatar.dart';
```

- [ ] **Step 2: Replace the top Row** (the wordmark + gear `Row`) with avatar (left) · wordmark (center) · gear (right)

```dart
Row(
  children: [
    GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      behavior: HitTestBehavior.opaque,
      child: const ProfileAvatar(size: 36),
    ),
    Expanded(
      child: Center(
        child: Text(
          'HOURGLASS',
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 14,
            letterSpacing: 3.5,
            color: hg.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
    IconButton(
      onPressed: _openSettings,
      iconSize: HgSize.iconMd,
      color: hg.textSecondary,
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Settings',
      visualDensity: VisualDensity.compact,
    ),
  ],
),
```

- [ ] **Step 3: Make the Focus stat tappable**

In `_StatRow`, wrap the Focus `_Stat` in a tap target that pushes `FocusScoreScreen`. Pass a callback down (e.g. add `onTap` to the Focus `_Stat`), or wrap it:

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const FocusScoreScreen()),
  ),
  child: _Stat(label: 'Focus', value: '${focusScore ?? 0}', animatedNumber: focusScore ?? 0, accent: true),
),
```

(`_StatRow` will need a `BuildContext`; it already builds with one. If `_StatRow` lacks navigation context, convert the Focus cell wrapping into the `build` method where `context` is available.)

- [ ] **Step 4: Run the existing home test + analyze**

Run: `flutter test test/ui/home_screen_test.dart` then `flutter analyze`
Expected: PASS / no issues. (Update the home test if it asserts the old top-bar structure.)

- [ ] **Step 5: Commit**

```bash
git add lib/ui/home_screen.dart test/ui/home_screen_test.dart
git commit -m "feat(ui): Home avatar entry + tappable Focus stat"
```

---

### Task 14: Settings → Profile row

**Files:**
- Modify: `lib/ui/settings_screen.dart`

- [ ] **Step 1: Add a Profile section at the top of the `ListView`** (above DISPLAY), navigating to `ProfileScreen`

```dart
// after the title row + SizedBox(height: HgSpacing.lg)
_SectionLabel('PROFILE'),
const SizedBox(height: HgSpacing.sm),
_ChoiceRow(
  title: 'Profile',
  selected: false,
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ProfileScreen()),
  ),
),
const SizedBox(height: HgSpacing.xl),
```

Add `import 'profile_screen.dart';`. (`_ChoiceRow` shows a check when selected; passing `selected: false` reuses it as a nav row. If a trailing chevron reads better, add an optional trailing icon to `_ChoiceRow` — small, local change.)

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/settings_screen.dart
git commit -m "feat(ui): Settings → Profile entry"
```

---

### Task 15: Greeting reads the profile (remove "Deep")

**Files:**
- Modify: `lib/ui/widgets/greeting_line.dart`

- [ ] **Step 1: Replace the hardcoded name with the profile name**

Delete the `_name` constant + its `TODO(Plan 3)` comment. In `build`, read the profile and build the greeting with or without the name span:

```dart
final profileName =
    ref.watch(profileProvider).asData?.value.name.trim() ?? '';
```

Then the `Text.rich` children become conditional:

```dart
children: [
  if (profileName.isEmpty)
    TextSpan(text: '$greeting${greetingPunctuation(greeting)}')
  else ...[
    TextSpan(text: '$greeting, '),
    TextSpan(
      text: profileName,
      style: TextStyle(color: hg.accent, fontWeight: FontWeight.w500),
    ),
    TextSpan(text: greetingPunctuation(greeting)),
  ],
],
```

- [ ] **Step 2: Analyze + run any greeting/home tests**

Run: `flutter analyze` then `flutter test test/ui/home_screen_test.dart`
Expected: No issues / PASS. (No test should still assert "Deep".)

- [ ] **Step 3: Commit**

```bash
git add lib/ui/widgets/greeting_line.dart
git commit -m "feat(ui): greeting reads profile name; remove hardcoded 'Deep'"
```

---

## Phase F — Full verification on device

### Task 16: Analyze, test, build, deploy, review

- [ ] **Step 1: Full analyze + test**

Run: `flutter analyze` then `flutter test`
Expected: No analyzer issues; **all tests green** (94 prior + the new ones).

- [ ] **Step 2: Build the app APK** (full app entrypoint, not the hourglass preview)

```bash
export PATH="/d/Dev/tools/flutter/bin:$PATH"; export JAVA_HOME="/c/Program Files/Java/jdk-21"; export MSYS_NO_PATHCONV=1
flutter build apk --debug
```

Expected: APK at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 3: Install + launch on the V2521**

```bash
ADB="/c/Users/morni/AppData/Local/Android/Sdk/platform-tools/adb.exe"
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk
"$ADB" shell am start -n com.trilumos.hourglass/.MainActivity
```

Expected: app launches. The founder's existing session data migrates (v1→v2) with the streak/score intact.

- [ ] **Step 4: Founder review checklist** (the founder tests on device — they can only confirm visually)

Verify together: avatar (left) opens Profile; gear (right) opens Settings; Settings has Profile; tapping Focus opens the Focus Score page; Profile shows 4 stats + setup nudge; Edit Profile won't Save with a blank name; picking a photo works (no permission prompt) and shows round; History lists past sessions, tap → summary; greeting no longer says "Deep" (neutral until a name is set, then the chosen name).

- [ ] **Step 5: On founder lock — push** (standing rule)

```bash
git push origin master
```

---

## Self-review (completed during planning)

- **Spec coverage:** Profile table + Sessions `uuid`/`updatedAt` + migration (T2–T3), derived aggregates incl. `totalFocus` (T6), image storage (T8), providers (T7), Profile hub / Edit / History / Per-session / Focus Score (T9–T12), Home avatar + Focus tap (T13), Settings Profile row (T14), greeting / "Deep" removal (T15), name-required + photo-optional (T12), hide Level + Collection (T12), no "level up" line (T10), device verification + push-on-lock (T16). All spec sections map to a task.
- **Placeholders:** none — copy for the Focus Score page and the empty/nudge strings are given; logic steps include code.
- **Type consistency:** domain model is `UserProfile` throughout (Drift table `Profile`/`ProfileData`/`ProfileCompanion`); `ProfileRepository.load()/update()`, `ImageStorageService.saveAvatar/deleteAvatar/resolve`, `StatsCalculator.totalFocus`, providers (`profileProvider`, `sessionHistoryProvider`, `profileStatsProvider`, `imageStorageProvider`) are referenced consistently.
- **Open risk flagged to executor:** token names used in widgets (`hg.surfaceMuted`) must be checked against `lib/app/theme.dart` and swapped for the real token if absent (noted in T9).
```
