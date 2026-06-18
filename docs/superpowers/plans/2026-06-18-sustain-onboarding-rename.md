# Sustain Onboarding & Rename — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a first-run onboarding flow (4 teaching screens + a name/photo profile screen) gated by an `onboardingComplete` flag, and fold in the Hourglass→Sustain and Flow Block→"Flow" user-facing renames plus the Android/iOS package-id switch to `com.trilumos.sustain`.

**Architecture:** A `RootGate` widget replaces `HomeScreen` as the app's `home:`; it watches an `onboardingCompleteProvider` (which has a migration guard that auto-marks existing-data installs as done) and shows either `OnboardingScreen` or `HomeScreen`. `OnboardingScreen` is a single `StatefulWidget`: a persistent `HourglassView` hero above a 5-page `PageView` (4 teach pages + 1 profile page), finishing by saving the profile, setting the flag, and `pushReplacement`-ing to `HomeScreen` (the shared `kHourglassHeroTag` flies the hero across).

**Tech Stack:** Flutter, Riverpod 3.x, Drift (SQLite), existing `ProfileRepository` / `SettingsRepository` / `ImageStorageService` / crop flow. No new dependencies (`image_picker` already present).

## Global Constraints

- Flutter SDK at `D:\Dev\tools\flutter`. Run tests **serial**: `flutter test --concurrency=1` (parallel OOMs this machine; ~25s for the suite). `flutter analyze` must stay clean after every task.
- Riverpod 3.x: use `Notifier`/`NotifierProvider` (not legacy `StateProvider`). Colors: `.withValues(alpha:)`, never `.withOpacity`.
- Tokens-first: all styling via `context.hg.<token>`, `HgSpacing`, `HgRadius`, `HgSize`, `HgMotion`, `HgFont` — never hardcode colors/sizes. See `docs/design-language.md`.
- **Keep these internal names UNCHANGED** (renaming them is churn or breaks data): the Dart package name `hourglass` in `pubspec.yaml` and every `package:hourglass/...` import; `lib/hourglass/` files and classes (`HourglassView`, `HourglassPainter`, `HourglassApp`); the enum `SessionMode.flowBlock` and `SessionPlan.flowBlock`; the DB filename `hourglass.sqlite`; the hero tag constant `kHourglassHeroTag`.
- Copy is honest (brand rule): no fabricated stats, no level-up/collectible language (that's V2). Use the onboarding copy **verbatim** from `docs/superpowers/specs/2026-06-16-onboarding-screen-design.md` §3.
- **Device verification is the founder's job.** Each task ends at: code written + `flutter analyze` clean + `flutter test --concurrency=1` green + commit. Do **not** drive the app over adb to "verify".
- Work on `master`; commit after each task (founder works directly on master).

---

### Task 1: Rename "Flow Block" → "Flow" (user-facing strings only)

**Files:**
- Modify: `lib/ui/widgets/mode_selector.dart:20`
- Modify: `lib/ui/session_format.dart:11`
- Modify: `lib/ui/setup_screen.dart:82`
- Modify: `lib/ui/settings_screen.dart:110-114, 131`
- Modify: `lib/ui/focus_score_screen.dart:18-23`
- Modify: `lib/ui/guide_screen.dart:17, 74, 94-96`
- Modify: `lib/ui/session_summary_screen.dart:124`
- Modify: `lib/ui/insights_copy.dart:85`
- Test (update): `test/ui/home_screen_test.dart:56`
- Test (update): `test/ui/insights_copy_test.dart:62`

**Interfaces:**
- Consumes: nothing new.
- Produces: no API change — only display text. The enum `SessionMode.flowBlock` is untouched.

Mapping rule: the **mode label** becomes `Flow`; the **session noun** becomes `Flow session(s)`; the **unit** stays lowercase `block`.

- [ ] **Step 1: Update the mode-label maps to "Flow"**

In `lib/ui/widgets/mode_selector.dart:20` change:
```dart
    SessionMode.flowBlock: 'Flow',
```
In `lib/ui/session_format.dart:11` change:
```dart
      SessionMode.flowBlock => 'Flow',
```
In `lib/ui/setup_screen.dart:82` change:
```dart
    SessionMode.flowBlock: 'Flow',
```

- [ ] **Step 2: Update Settings copy**

In `lib/ui/settings_screen.dart`, the switch row (around lines 110-114):
```dart
                  title: 'Run Flow sessions until I end them',
                  subtitle:
                      "When on, a Flow session never stops on its own — it keeps "
                      "running until you tap End. When off, it stops at its set "
                      "length (with a “keep going” option near the end).",
```
And the guide row subtitle (line 131):
```dart
                  subtitle: 'Modes, the Flow method, and your numbers',
```

- [ ] **Step 3: Update Focus Score copy**

In `lib/ui/focus_score_screen.dart:18-23` replace the three paragraphs' "Flow Blocks" references:
```dart
    'Your Focus Score is the average of your last 10 Flow sessions, on a scale of '
        '0 to 100. It reflects your recent focus ability, not your whole history.',
    "It builds up over your first several Flow sessions. One great session won't "
        'jump you to 100 — focus is trained, not flipped.',
    'Completing a block, and pushing a little past it, raises your score. '
        'Giving up early lowers it. Only Flow sessions of at least 2 minutes count.',
```

- [ ] **Step 4: Update Guide copy**

In `lib/ui/guide_screen.dart`:
- Mode card name (line 17): `'Flow',`
- Heading (line 74): `_Heading('THE FLOW METHOD'),`
- Focus Score body (lines 94-96): change `'average of your last 10 Flow Blocks. It builds up over your '` → `'average of your last 10 Flow sessions. It builds up over your '` and `'first several blocks, and it rewards finishing what you '` stays (already "blocks"), and `'start. Only Flow Blocks count toward it. Open the Focus Score '` → `'start. Only Flow sessions count toward it. Open the Focus Score '`.
- Doc comment (line 9-10) "the Flow Block method" → "the Flow method" (cosmetic).

- [ ] **Step 5: Update Session Summary + Insights copy**

In `lib/ui/session_summary_screen.dart:124`:
```dart
                            'Not scored — Flow sessions under 2 minutes don’t count.',
```
In `lib/ui/insights_copy.dart:85` (and the doc comment line 75):
```dart
      SessionMode.flowBlock => "You're a Flow person.",
```

- [ ] **Step 6: Update the two tests that assert the old strings**

In `test/ui/home_screen_test.dart:56`:
```dart
    expect(find.text('Flow'), findsOneWidget);
```
In `test/ui/insights_copy_test.dart:62`:
```dart
      expect(InsightsCopy.modeInsight(slices), "You're a Flow person.");
```

- [ ] **Step 7: Verify no user-facing "Flow Block" remains**

Run: `git grep -n "Flow Block" -- lib`
Expected: only doc-comment hits (acceptable) — no string literals shown to users. Fix any remaining literal.

- [ ] **Step 8: Analyze + test**

Run: `flutter analyze`
Expected: No issues found.
Run: `flutter test --concurrency=1`
Expected: All tests pass.

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "rename(ui): Flow Block -> \"Flow\" in all user-facing strings"
```

---

### Task 2: Rename "Hourglass" → "Sustain" (user-facing) + guide title "How it works"

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml:3`
- Modify: `lib/app/app.dart:17`
- Modify: `lib/ui/home_screen.dart:82`
- Modify: `lib/ui/settings_screen.dart:130, 141, 162`
- Modify: `lib/ui/profile_screen.dart:162`
- Modify: `lib/ui/guide_screen.dart:9, 53, 69, 105`

**Interfaces:**
- Consumes: nothing.
- Produces: no API change — display text + the Android launcher label only. `HourglassApp` class name stays.

- [ ] **Step 1: Android launcher label**

In `android/app/src/main/AndroidManifest.xml:3`:
```xml
        android:label="Sustain"
```

- [ ] **Step 2: MaterialApp title + Home wordmark**

In `lib/app/app.dart:17`:
```dart
      title: 'Sustain',
```
In `lib/ui/home_screen.dart:82`:
```dart
                          'SUSTAIN',
```

- [ ] **Step 3: Settings strings**

In `lib/ui/settings_screen.dart`:
- Line 130: `title: 'How it works',`
- Line 141: `applicationName: 'Sustain',`
- Line 162: `'Sustain 1.0.0',`

- [ ] **Step 4: Profile guide row**

In `lib/ui/profile_screen.dart:162`:
```dart
                  title: 'How it works',
```

- [ ] **Step 5: Guide screen title + body**

In `lib/ui/guide_screen.dart`:
- Header (line 53): `const ScreenHeader(title: 'How it works'),`
- Body (line 69): `'Sustain is focus training, not just a timer. You build the '`
- Privacy body (line 105): `'Sustain works fully offline. Your sessions, stats, and '`
- Doc comment (line 9): "How Hourglass works" → "How it works" (cosmetic).

- [ ] **Step 6: Verify no user-facing "Hourglass" remains**

Run: `git grep -n "Hourglass" -- lib android/app/src`
Expected: only the intentional internals — `HourglassApp`, `HourglassView`/`HourglassPainter`/`kHourglassHeroTag`, `lib/hourglass/` imports, and `hourglass.sqlite`. No user-visible string literals.

- [ ] **Step 7: Analyze + test**

Run: `flutter analyze` → No issues found.
Run: `flutter test --concurrency=1` → All tests pass. (`test/widget_test.dart` references the `HourglassApp` class, which is unchanged.)

- [ ] **Step 8: Commit**

```bash
git add lib android
git commit -m "rename(brand): Hourglass -> Sustain in user-facing strings; guide -> \"How it works\""
```

---

### Task 3: Switch Android/iOS package id to `com.trilumos.sustain`

**Files:**
- Modify: `android/app/build.gradle.kts:8, 19`
- Move + modify: `android/app/src/main/kotlin/com/trilumos/hourglass/MainActivity.kt` → `android/app/src/main/kotlin/com/trilumos/sustain/MainActivity.kt`
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (6 `PRODUCT_BUNDLE_IDENTIFIER` entries)
- Modify (docs): `docs/project-context.md`, `docs/v1-launch-checklist.md` (any `com.trilumos.hourglass/.MainActivity` run/launch commands)

**Interfaces:**
- Consumes: nothing.
- Produces: new applicationId `com.trilumos.sustain`. **Does NOT** change the Dart package name `hourglass` or any `package:hourglass/` import — those are internal and stay.

- [ ] **Step 1: Gradle namespace + applicationId**

In `android/app/build.gradle.kts`:
```kotlin
    namespace = "com.trilumos.sustain"
```
```kotlin
        applicationId = "com.trilumos.sustain"
```

- [ ] **Step 2: Move MainActivity into the new package**

Create `android/app/src/main/kotlin/com/trilumos/sustain/MainActivity.kt` with:
```kotlin
package com.trilumos.sustain

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```
Then delete the old file + empty dir:
```bash
git rm android/app/src/main/kotlin/com/trilumos/hourglass/MainActivity.kt
```
(`AndroidManifest.xml` uses `android:name=".MainActivity"`, which now resolves against the new namespace — no manifest change needed.)

- [ ] **Step 3: iOS bundle ids**

In `ios/Runner.xcodeproj/project.pbxproj`, change every `PRODUCT_BUNDLE_IDENTIFIER = com.trilumos.hourglass;` → `= com.trilumos.sustain;` and the test target `…hourglass.RunnerTests;` → `…sustain.RunnerTests;` (6 occurrences total). Not built on Windows now, but kept consistent.

- [ ] **Step 4: Update docs/run commands**

In `docs/project-context.md` and `docs/v1-launch-checklist.md`, replace `com.trilumos.hourglass/.MainActivity` launch references with `com.trilumos.sustain/.MainActivity`, and note the old app should be uninstalled from the test device (`adb uninstall com.trilumos.hourglass`).

- [ ] **Step 5: Verify**

Run: `git grep -n "com.trilumos.hourglass"`
Expected: no hits except historical/handoff notes you intentionally leave. `android/`, `ios/`, and run commands should all read `sustain`.
Run: `flutter analyze`
Expected: No issues found. (Dart code is unaffected by the Android id.)
Run: `flutter test --concurrency=1`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add android ios docs
git commit -m "build: switch package id to com.trilumos.sustain (pre-launch); keep Dart pkg + DB file"
```

---

### Task 4: `onboardingComplete` setting + `onboardingCompleteProvider` (migration guard)

**Files:**
- Modify: `lib/app/providers.dart` (add key to `SettingsKeys`; add provider near the other settings providers)
- Test: `test/app/onboarding_gate_test.dart` (new)

**Interfaces:**
- Consumes: `settingsRepositoryProvider`, `sessionRepositoryProvider`, `profileRepositoryProvider` (all existing).
- Produces:
  - `SettingsKeys.onboardingComplete` → `'onboardingComplete'` (String const).
  - `final onboardingCompleteProvider = FutureProvider<bool>(...)` → resolves `true` when onboarding should be skipped (stored true, or existing data triggers the guard) and `false` when onboarding should run.

- [ ] **Step 1: Write the failing test**

Create `test/app/onboarding_gate_test.dart`:
```dart
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

void main() {
  test('fresh install (no data, flag unset) -> show onboarding (false)', () async {
    final c = _container();
    expect(await c.read(onboardingCompleteProvider.future), isFalse);
  });

  test('flag stored true -> skip onboarding (true)', () async {
    final c = _container();
    await c.read(settingsRepositoryProvider)
        .setBool(SettingsKeys.onboardingComplete, true);
    expect(await c.read(onboardingCompleteProvider.future), isTrue);
  });

  test('existing session -> guard marks done (true) and persists', () async {
    final c = _container();
    await c.read(sessionRepositoryProvider).save(SessionRecord(
          mode: SessionMode.flowBlock,
          plannedDuration: const Duration(minutes: 25),
          recordedFocus: const Duration(minutes: 25),
          startedAt: DateTime(2026, 1, 1),
          completed: true,
          abandoned: false,
        ));
    expect(await c.read(onboardingCompleteProvider.future), isTrue);
    // persisted, so a re-read without the session reasoning still returns true
    expect(
      await c.read(settingsRepositoryProvider)
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
```
(Confirm `SessionRecord`'s constructor field names against `lib/domain/session_record.dart` and `SessionRepository.save(...)` against `lib/data/session_repository.dart`; adjust the literal if the existing test `test/data/session_repository_test.dart` uses a different shape.)

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test --concurrency=1 test/app/onboarding_gate_test.dart`
Expected: FAIL — `onboardingCompleteProvider`/`SettingsKeys.onboardingComplete` undefined.

- [ ] **Step 3: Add the key**

In `lib/app/providers.dart`, inside `class SettingsKeys`, add:
```dart
  /// Whether first-run onboarding has been completed. Default: false (show it).
  static const onboardingComplete = 'onboardingComplete';
```

- [ ] **Step 4: Add the provider**

In `lib/app/providers.dart`, after `flowRunUntilEndedProvider`:
```dart
/// True when first-run onboarding should be SKIPPED — either it was completed,
/// or the migration guard found existing data (so an updating user is never
/// shown onboarding again).
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  if (await settings.getBool(SettingsKeys.onboardingComplete,
      defaultValue: false)) {
    return true;
  }
  // Migration guard: any prior sessions or a saved profile name = existing user.
  final sessions = await ref.watch(sessionRepositoryProvider).allSessions();
  final profile = await ref.watch(profileRepositoryProvider).load();
  if (sessions.isNotEmpty || profile.name.trim().isNotEmpty) {
    await settings.setBool(SettingsKeys.onboardingComplete, true);
    return true;
  }
  return false;
});
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test --concurrency=1 test/app/onboarding_gate_test.dart`
Expected: PASS (all 4).

- [ ] **Step 6: Analyze + full suite + commit**

Run: `flutter analyze` → No issues found.
Run: `flutter test --concurrency=1` → all pass.
```bash
git add lib/app/providers.dart test/app/onboarding_gate_test.dart
git commit -m "feat(onboarding): add onboardingComplete flag + gate provider w/ migration guard"
```

---

### Task 5: `OnboardingScreen` (persistent hero + 4 teach pages + profile page + finish)

**Files:**
- Create: `lib/ui/onboarding_screen.dart`
- Test: `test/ui/onboarding_screen_test.dart` (new)

**Interfaces:**
- Consumes: `kHourglassHeroTag`, `HourglassView` (`lib/hourglass/hourglass_view.dart`); `PrimaryButton`; `ScreenBackground`; `profileRepositoryProvider`, `imageStorageProvider`, `settingsRepositoryProvider`, `profileProvider`, `onboardingCompleteProvider`, `SettingsKeys` (`lib/app/providers.dart`); `CropAvatarScreen` (`lib/ui/crop_avatar_screen.dart`); `HomeScreen` (`lib/ui/home_screen.dart`).
- Produces: `class OnboardingScreen extends ConsumerStatefulWidget` (const constructor) — used by `RootGate` in Task 6.

- [ ] **Step 1: Create the screen**

Create `lib/ui/onboarding_screen.dart`:
```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../data/image_storage_service.dart';
import '../hourglass/hourglass_view.dart';
import 'crop_avatar_screen.dart';
import 'home_screen.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// First-run onboarding: a persistent hourglass hero above a 5-page PageView
/// (4 teaching beats + a name/photo profile page). Skippable; finishing saves
/// the profile, marks onboarding done, and flies the hero into Home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _TeachPage {
  final String headline;
  final String subcopy;
  final double heroProgress;
  const _TeachPage(this.headline, this.subcopy, this.heroProgress);
}

const _teach = <_TeachPage>[
  _TeachPage(
    'Train your focus like an athlete.',
    'Focus is a skill you can build — with real training, and real recovery.',
    0.0,
  ),
  _TeachPage(
    'Find your flow.',
    "In Flow, the first minutes feel hard — that's the struggle. Stay with it "
        'and focus takes over: effortless, absorbed.',
    0.4,
  ),
  _TeachPage(
    'Rest without your phone.',
    'Then a short, boring break lets focus recover — no scrolling. Struggle, '
        'flow, recover: one full block.',
    0.8,
  ),
  _TeachPage(
    'Watch your focus grow.',
    'Your Focus Score (0–100) tracks your focus ability as you train. Pomodoro '
        'and Custom are training wheels — Flow is the real method. The full '
        'guide is in Settings → How it works.',
    0.0,
  ),
];

const _profileIndex = 4; // 0..3 teach, 4 profile
const _pageCount = 5;

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  int _index = 0;
  String? _pendingPath;
  File? _pendingFile;
  bool _saving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  double get _heroProgress =>
      _index < _teach.length ? _teach[_index].heroProgress : 0.0;

  void _onCta() {
    if (_index < _profileIndex) {
      _pageCtrl.nextPage(duration: HgMotion.medium, curve: HgMotion.calm);
    } else {
      _finish(save: true);
    }
  }

  void _onSkip() {
    if (_index < _profileIndex) {
      _pageCtrl.animateToPage(_profileIndex,
          duration: HgMotion.medium, curve: HgMotion.calm);
    } else {
      _finish(save: false);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (picked == null || !mounted) return;
    final bytes = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        builder: (_) => CropAvatarScreen(source: File(picked.path)),
      ),
    );
    if (bytes == null || !mounted) return;
    try {
      final storage = ref.read(imageStorageProvider);
      final rel = await storage.saveAvatarBytes(bytes);
      final file = await storage.resolve(rel);
      await FileImage(file).evict();
      if (!mounted) return;
      setState(() {
        _pendingPath = rel;
        _pendingFile = file;
      });
    } on ImageStorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _finish({required bool save}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final name = _nameCtrl.text.trim();
    if (save && (name.isNotEmpty || _pendingPath != null)) {
      await ref.read(profileRepositoryProvider).update(
            name: name.isEmpty ? null : name,
            imagePath: _pendingPath,
          );
    }
    await ref
        .read(settingsRepositoryProvider)
        .setBool(SettingsKeys.onboardingComplete, true);
    ref.invalidate(profileProvider);
    ref.invalidate(onboardingCompleteProvider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              children: [
                // Chrome: Skip top-right.
                SizedBox(
                  height: HgSize.touchMin,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saving ? null : _onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 14,
                          color: hg.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                // Persistent hero (does not page).
                Expanded(
                  flex: 5,
                  child: Center(
                    child: HourglassView(
                      progress: _heroProgress,
                      heroTag: kHourglassHeroTag,
                    ),
                  ),
                ),
                // Paged content.
                Expanded(
                  flex: 6,
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      for (final p in _teach) _TeachView(page: p),
                      _ProfileView(
                        controller: _nameCtrl,
                        pendingFile: _pendingFile,
                        onPickPhoto: _saving ? null : _pickPhoto,
                      ),
                    ],
                  ),
                ),
                // Dots.
                Semantics(
                  label: 'Step ${_index + 1} of $_pageCount',
                  child: _Dots(count: _pageCount, index: _index),
                ),
                const SizedBox(height: HgSpacing.lg),
                PrimaryButton(
                  label: _index < _profileIndex ? 'Continue' : 'Begin',
                  onPressed: _saving ? null : _onCta,
                ),
                const SizedBox(height: HgSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeachView extends StatelessWidget {
  final _TeachPage page;
  const _TeachView({required this.page});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          page.headline,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 30,
            fontWeight: FontWeight.w500,
            height: 1.15,
            letterSpacing: -0.5,
            color: hg.textPrimary,
          ),
        ),
        const SizedBox(height: HgSpacing.md),
        Text(
          page.subcopy,
          style: TextStyle(
            fontFamily: HgFont.sans,
            fontSize: 16,
            height: 1.5,
            color: hg.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  final TextEditingController controller;
  final File? pendingFile;
  final VoidCallback? onPickPhoto;
  const _ProfileView({
    required this.controller,
    required this.pendingFile,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: HgSpacing.md),
          Text(
            'What should we call you?',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 30,
              fontWeight: FontWeight.w500,
              height: 1.15,
              letterSpacing: -0.5,
              color: hg.textPrimary,
            ),
          ),
          const SizedBox(height: HgSpacing.lg),
          GestureDetector(
            onTap: onPickPhoto,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _AvatarRing(file: pendingFile),
                const SizedBox(width: HgSpacing.md),
                Text(
                  pendingFile == null ? 'Add a photo' : 'Change photo',
                  style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 15,
                    color: hg.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HgSpacing.lg),
          TextField(
            controller: controller,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 16,
              color: hg.textPrimary,
            ),
            buildCounter: (_,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: hg.textMuted),
              filled: true,
              fillColor: hg.surfaceRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HgRadius.sm),
                borderSide: BorderSide(color: hg.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HgRadius.sm),
                borderSide: BorderSide(color: hg.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HgRadius.sm),
                borderSide: BorderSide(color: hg.accent),
              ),
            ),
          ),
          const SizedBox(height: HgSpacing.sm),
          Text(
            'Optional — you can add or change this later in your profile.',
            style: TextStyle(
              fontFamily: HgFont.sans,
              fontSize: 13,
              height: 1.4,
              color: hg.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  final File? file;
  const _AvatarRing({required this.file});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    const size = 56.0;
    if (file == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hg.surfaceRaised,
          shape: BoxShape.circle,
          border: Border.all(color: hg.hairline),
        ),
        child: Icon(Icons.add_a_photo_outlined,
            size: size * 0.42, color: hg.textMuted),
      );
    }
    return ClipOval(
      child: Image.file(file!,
          width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: HgMotion.fast,
            curve: HgMotion.calm,
            margin: const EdgeInsets.symmetric(horizontal: HgSpacing.xs),
            height: 6,
            width: i == index ? 20 : 6,
            decoration: BoxDecoration(
              color: i == index ? hg.accent : hg.hairline,
              borderRadius: BorderRadius.circular(HgRadius.pill),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Write widget tests**

Create `test/ui/onboarding_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/home_screen.dart';
import 'package:hourglass/ui/onboarding_screen.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    databaseProvider.overrideWith((ref) {
      final db = AppDatabase.memory();
      ref.onDispose(db.close);
      return db;
    }),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('opens on the first teach page with Continue + Skip + dots',
      (tester) async {
    await _pump(tester);
    expect(find.text('Train your focus like an athlete.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 5'), findsOneWidget);
  });

  testWidgets('Skip jumps to the profile page (name field + Begin)',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.widgetWithText(TextField, '').hitTestable(), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });

  testWidgets('Begin with a name saves the profile + marks onboarding done',
      (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Maya');
    await tester.tap(find.text('Begin'));
    await tester.pumpAndSettle();

    final profile = await container.read(profileRepositoryProvider).load();
    expect(profile.name, 'Maya');
    expect(
      await container
          .read(settingsRepositoryProvider)
          .getBool(SettingsKeys.onboardingComplete, defaultValue: false),
      isTrue,
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
```
(If `find.bySemanticsLabel` needs the semantics tree, the `Semantics` wrapper provides it. If `pushReplacement` to `HomeScreen` makes the last assertion flaky due to async stats providers, assert `find.byType(OnboardingScreen)` is gone instead.)

- [ ] **Step 4: Run the tests**

Run: `flutter test --concurrency=1 test/ui/onboarding_screen_test.dart`
Expected: PASS (all 3). Fix the screen/test if the profile-page or navigation assertions need adjusting per the notes above.

- [ ] **Step 5: Analyze + full suite + commit**

Run: `flutter analyze` → No issues found.
Run: `flutter test --concurrency=1` → all pass.
```bash
git add lib/ui/onboarding_screen.dart test/ui/onboarding_screen_test.dart
git commit -m "feat(onboarding): add OnboardingScreen (teach pages + name/photo + finish)"
```

---

### Task 6: Wire `RootGate` into the app

**Files:**
- Create: `lib/app/root_gate.dart`
- Modify: `lib/app/app.dart:4, 23` (import + `home:`)
- Modify: `test/widget_test.dart` (add an in-memory db override so the gate's first read is safe)
- Test: `test/app/root_gate_test.dart` (new)

**Interfaces:**
- Consumes: `onboardingCompleteProvider`; `HomeScreen`; `OnboardingScreen`; `ScreenBackground`.
- Produces: `class RootGate extends ConsumerWidget` (const constructor).

- [ ] **Step 1: Create the gate**

Create `lib/app/root_gate.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/home_screen.dart';
import '../ui/onboarding_screen.dart';
import '../ui/widgets/screen_background.dart';
import 'providers.dart';

/// Decides the app's first screen: onboarding for fresh installs, Home otherwise.
/// Fails open to Home on any read error (never trap the user out of the app).
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(onboardingCompleteProvider).when(
          data: (done) => done ? const HomeScreen() : const OnboardingScreen(),
          loading: () => const Scaffold(body: ScreenBackground(child: SizedBox.expand())),
          error: (_, __) => const HomeScreen(),
        );
  }
}
```

- [ ] **Step 2: Point the app at the gate**

In `lib/app/app.dart`, replace the `home:` line (and its import):
```dart
import 'root_gate.dart';
```
```dart
      home: const RootGate(),
```
(Remove the now-unused `import '../ui/home_screen.dart';` if analyze flags it.)

- [ ] **Step 3: Write the gate test**

Create `test/app/root_gate_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/root_gate.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/home_screen.dart';
import 'package:hourglass/ui/onboarding_screen.dart';

Future<void> _pump(WidgetTester tester, {required bool complete}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
        onboardingCompleteProvider.overrideWith((ref) async => complete),
      ],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const RootGate(),
      ),
    ),
  );
  await tester.pump(); // resolve the future
}

void main() {
  testWidgets('complete -> HomeScreen', (tester) async {
    await _pump(tester, complete: true);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('not complete -> OnboardingScreen', (tester) async {
    await _pump(tester, complete: false);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
```

- [ ] **Step 4: Harden `test/widget_test.dart`**

Replace its body so the gate's first read uses an in-memory DB (avoids touching real path_provider):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hourglass/app/app.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots to a screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith((ref) {
            final db = AppDatabase.memory();
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: const HourglassApp(),
      ),
    );
    expect(find.byType(HourglassApp), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run the gate tests**

Run: `flutter test --concurrency=1 test/app/root_gate_test.dart test/widget_test.dart`
Expected: PASS.

- [ ] **Step 6: Analyze + full suite + commit**

Run: `flutter analyze` → No issues found.
Run: `flutter test --concurrency=1` → all pass.
```bash
git add lib/app test/app/root_gate_test.dart test/widget_test.dart
git commit -m "feat(onboarding): gate app entry with RootGate (onboarding vs home)"
```

---

## Self-Review

**Spec coverage:**
- §2 Brand placement — in-app wordmark "SUSTAIN" (Task 2 Step 2), tagline already in `TypewriterTagline` (unchanged); store-listing copy is doc-only (§8 of spec, no code task — correct).
- §3 Flow (5 screens, copy, dots, skip, hero) — Task 5.
- §4 Profile capture (name optional/skippable, photo via crop, `ProfileRepository.update`) — Task 5.
- §5 Persistence + gate + migration guard — Tasks 4 (provider/guard) + 6 (gate). Data-lifecycle note is informational, no code.
- §6a Hourglass→Sustain — Task 2. §6b Flow Block→Flow — Task 1. §6c Guide title — Task 2.
- §7 Package id (gradle + MainActivity + iOS + docs) — Task 3.
- §9 Testing — each task ends with analyze + serial tests; new tests in Tasks 4/5/6.

**Placeholder scan:** No TBD/TODO; all code blocks are complete; copy is verbatim from the spec.

**Type consistency:** `onboardingCompleteProvider` (FutureProvider<bool>) and `SettingsKeys.onboardingComplete` defined in Task 4 and consumed identically in Tasks 5/6. `OnboardingScreen`/`RootGate` const constructors match their usages. Reuses verified existing APIs: `ProfileRepository.update({name, imagePath, clearImage})`, `ImageStorageService.saveAvatarBytes`/`resolve`, `imageStorageProvider`, `CropAvatarScreen({source})` returning `Uint8List?`, `HourglassView({progress, heroTag})`, `kHourglassHeroTag`.

**Known follow-ups (left to on-device polish, per spec §10):** optional parallax/stagger motion; possible split of teach screen 4 into two; branded splash. None block this plan.
