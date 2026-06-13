# Hourglass v1 — Plan 2: Session UI & Hourglass

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the *playable focus ritual* end-to-end — from the calm home screen, through setting an intention and flipping the hourglass, into a running session that surfaces the flow phases over a beautiful falling-sand hourglass with looping sound, protected against leaving, all the way to a satisfying completion that logs the session and grows Focus Stamina.

**Architecture:** Riverpod is the composition root: providers expose the Plan-1 database/repositories and a `SessionController` that owns the live session state. The session runtime is split into **pure, test-driven logic** (`SessionController` + an injectable `Ticker`/clock — no Flutter, fully unit-tested) and **a thin presentation layer** (screens + the `HourglassPainter`) that simply renders controller state and forwards user intent. The hourglass visual is isolated behind one widget so it can be prototyped and swapped without touching session logic. Completion writes through the Plan-1 `SessionRepository`/`SettingsRepository`.

**Tech Stack:** Flutter, Riverpod (flutter_riverpod), just_audio + audio_session, the existing Drift data layer, Flutter `CustomPainter`/`AnimationController` for the hourglass.

**This is Plan 2 of 3 for v1.** Plan 1 (Foundation) is complete. Plan 3 (Stickiness & Share) adds the Recovery/Boring-Break screen, the stats dashboard, the settings screen, and share cards. Design spec: `docs/superpowers/specs/2026-06-11-hourglass-flow-block-app-design.md`. Project context & carry-forward security items: `docs/project-context.md`.

**Three task types in this plan (read this):**
- **[TDD]** — strict test-first with exact code (logic tasks). Same discipline as Plan 1.
- **[UI]** — build the widget with provided structure, add widget tests where meaningful, then a **manual run-on-device verification** step. Visual polish is expected to be iterated live during execution (the `impeccable` / `frontend-design` skills may assist).
- **[PROTOTYPE]** — the hourglass visual: build candidate styles, compare them on-device, and record a chosen default. Exact pixels are decided here, not pre-specified.

---

## Carry-forward from Plan 1 review (must be handled in this plan)
- **DB lifecycle:** the `AppDatabase` provider must `close()` the database on dispose (Task 1).
- **Android release security** (Task 0 records them; real fix lands at Plan 3/release): replace debug signing with a real keystore + `android/key.properties`; set `android:allowBackup="false"`.
- `.gitignore` already excludes keystores/service-config/`.env` (done in Plan 1).

---

## File Structure (created/modified in this plan)

```
lib/
  app/
    app.dart                     # MaterialApp, theme, routing/home
    providers.dart               # Riverpod providers: database, repositories, controllers
    theme.dart                   # design tokens: colors (AMOLED dark-first), typography, spacing
  session/
    session_config.dart          # SessionConfig value object (mode, duration, autoContinue, intention, soundscape, skinId)
    ticker.dart                  # Ticker abstraction (real periodic ticker + injectable interface)
    session_controller.dart      # SessionController: live session state machine (pure logic, Flutter-free except ChangeNotifier-equivalent)
    session_state.dart           # immutable SessionState (status, elapsed, phase, goalReached)
  audio/
    audio_service.dart           # just_audio wrapper: looping soundscapes
    soundscapes.dart             # catalog of bundled royalty-free loops + the signature sand
  hourglass/
    hourglass_skin.dart          # data-driven skin (glass shape params, sand color, palette)
    hourglass_painter.dart       # the chosen CustomPainter (set in Task 5)
    hourglass_view.dart          # widget wrapping painter + AnimationController, driven by progress
    _prototypes/                 # candidate painters explored in Task 5 (kept for reference or removed)
  ui/
    home_screen.dart             # calm home: hourglass at rest, Begin, mode selector, today/streak
    setup_screen.dart            # intention + duration/preset + soundscape selection
    session_screen.dart          # the running ritual: hourglass + phase surfacing + pause + protect-block
    widgets/                     # small shared widgets (primary button, stat chip, etc.)
test/
  session/
    session_controller_test.dart # [TDD] the heart
    session_config_test.dart
  app/
    providers_test.dart          # providers construct & dispose cleanly
  ui/
    home_screen_test.dart        # widget tests
    setup_screen_test.dart
    session_screen_test.dart
  audio/
    audio_service_test.dart      # interface-level (playback verified manually)
assets/
  audio/                         # royalty-free loops (sand, rain, cafe, brown noise)
```

`assets/audio/` must be declared in `pubspec.yaml`.

---

## Task 0: Android toolchain ready to run on a device [setup]

**Files:** none (environment + a verification screenshot).

- [ ] **Step 1: Accept Android SDK licenses**

Run (PowerShell; Flutter is at `D:\Dev\tools\flutter\bin`, on PATH):
```
flutter doctor --android-licenses
```
Accept all (answer `y`). Then:
```
flutter doctor
```
Expected: the **Android toolchain** line shows `[√]` (no "license status unknown").

- [ ] **Step 2: Ensure a device or emulator is available**

```
flutter devices
```
If a physical Android phone is connected with USB debugging, it appears here. Otherwise create/launch an emulator:
```
flutter emulators
flutter emulators --launch <emulator_id>
```
(If no emulator exists, create one via Android Studio's Device Manager, or `flutter emulators --create`.) Expected: at least one Android device/emulator listed.

- [ ] **Step 3: Verify the scaffold app runs**

```
flutter run -d <android_device_id>
```
Expected: the default counter app launches on the device. Confirm it builds and runs (this proves the full Android build pipeline works), then stop it (`q`).

- [ ] **Step 4: Record completion** — no commit (nothing changed). If the Android build fails, STOP and report the exact error; do not proceed (every later UI task needs `flutter run`).

---

## Task 1: Composition root — providers, theme, app shell [UI/TDD]

Replace the counter scaffold with the real app shell, and wire Riverpod providers for the Plan-1 database and repositories with correct disposal.

**Files:**
- Create: `lib/app/providers.dart`, `lib/app/theme.dart`, `lib/app/app.dart`
- Modify: `lib/main.dart`
- Test: `test/app/providers_test.dart`
- Modify: `test/widget_test.dart` (the default smoke test references the counter app — update it to the new app shell or remove it)

- [ ] **Step 1: Write the failing provider test**

`test/app/providers_test.dart`:
```dart
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
    // smoke: a query works against the overridden in-memory db
    final sessions = await container.read(sessionRepositoryProvider).allSessions();
    expect(sessions, isEmpty);
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (`providers.dart` not found).

Run: `flutter test test/app/providers_test.dart`

- [ ] **Step 3: Implement providers**

`lib/app/providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/session_repository.dart';
import '../data/settings_repository.dart';

/// The on-device database. Closed automatically when the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);
```

- [ ] **Step 4: Run it — expect PASS.**

- [ ] **Step 5: Implement theme tokens**

`lib/app/theme.dart` — a dark-first, AMOLED-true theme. Provide a `ThemeData hourglassDarkTheme()` with: true-black scaffold background (`Color(0xFF000000)`), a calm warm sand accent (e.g. `Color(0xFFE8C9A0)`), low-emphasis text colors, generous spacing, and a quiet typography scale (use the default font for now; a custom font is a Plan-3 polish item). Keep it small and centralized so all screens read from `Theme.of(context)`.
```dart
import 'package:flutter/material.dart';

class HgColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF101010);
  static const sand = Color(0xFFE8C9A0);
  static const textHigh = Color(0xFFF2EDE4);
  static const textLow = Color(0xFF8A8378);
}

ThemeData hourglassDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: HgColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: HgColors.surface,
      primary: HgColors.sand,
      onPrimary: Colors.black,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: HgColors.textHigh,
      displayColor: HgColors.textHigh,
    ),
  );
}
```

- [ ] **Step 6: Implement the app shell and main**

`lib/app/app.dart`:
```dart
import 'package:flutter/material.dart';
import '../ui/home_screen.dart';
import 'theme.dart';

class HourglassApp extends StatelessWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hourglass',
      debugShowCheckedModeBanner: false,
      theme: hourglassDarkTheme(),
      home: const HomeScreen(),
    );
  }
}
```
`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() {
  runApp(const ProviderScope(child: HourglassApp()));
}
```
(`HomeScreen` is created in Task 6; until then, temporarily point `home:` at a `Scaffold(body: Center(child: Text('Hourglass')))` placeholder so the app compiles, and switch it to `HomeScreen` in Task 6.)

- [ ] **Step 7: Replace the default widget smoke test**

The scaffold's `test/widget_test.dart` references the removed counter app and will fail to compile. Replace it with:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hourglass/app/app.dart';

void main() {
  testWidgets('app boots to a screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HourglassApp()));
    expect(find.byType(HourglassApp), findsOneWidget);
  });
}
```

- [ ] **Step 8: Verify** — `flutter test` (all green), `flutter analyze` (clean).

- [ ] **Step 9: Commit** — `feat: app composition root, theme, and DB providers`

---

## Task 2: SessionConfig value object [TDD]

**Files:** Create `lib/session/session_config.dart`; Test `test/session/session_config_test.dart`

- [ ] **Step 1: Failing test**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';

void main() {
  test('holds the configuration for a planned session', () {
    const config = SessionConfig(
      mode: SessionMode.flowBlock,
      plannedDuration: Duration(minutes: 50),
      autoContinue: true,
      intention: 'Read chapter 4',
      soundscape: 'sand',
      skinId: 'classic',
    );
    expect(config.plannedDuration, const Duration(minutes: 50));
    expect(config.autoContinue, isTrue);
    expect(config.intention, 'Read chapter 4');
  });
}
```
- [ ] **Step 2: Run — FAIL.**
- [ ] **Step 3: Implement**
```dart
import '../domain/session_mode.dart';

/// Immutable configuration chosen on the setup screen before a session starts.
class SessionConfig {
  final SessionMode mode;
  final Duration plannedDuration;
  final bool autoContinue;
  final String intention;
  final String soundscape;
  final String skinId;

  const SessionConfig({
    required this.mode,
    required this.plannedDuration,
    required this.autoContinue,
    required this.intention,
    required this.soundscape,
    required this.skinId,
  });
}
```
- [ ] **Step 4: Run — PASS.**
- [ ] **Step 5: Commit** — `feat: add SessionConfig value object`

---

## Task 3: SessionState + SessionController [TDD] — the heart

This is the live session state machine: it tracks elapsed time via an injectable ticker, derives the current phase from the Plan-1 `PhaseEngine`, fires a "goal reached" signal at the planned mark, honors auto-continue (keep running) vs fixed (auto-finish), and on finish produces a `SessionRecord` using the Plan-1 `computeRecordedFocus` rule. It must be **Flutter-free logic** wrapped in a `ChangeNotifier` for the UI to listen to. Tests drive a fake ticker — no real time.

**Files:**
- Create: `lib/session/ticker.dart`, `lib/session/session_state.dart`, `lib/session/session_controller.dart`
- Test: `test/session/session_controller_test.dart`

- [ ] **Step 1: Failing test (drives a fake ticker through a full session)**

`test/session/session_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/focus_phase.dart';
import 'package:hourglass/domain/session_mode.dart';
import 'package:hourglass/session/session_config.dart';
import 'package:hourglass/session/session_controller.dart';
import 'package:hourglass/session/session_state.dart';
import 'package:hourglass/session/ticker.dart';

/// A ticker we advance manually in tests.
class FakeTicker implements Ticker {
  void Function(Duration delta)? _cb;
  bool running = false;
  @override
  void start(void Function(Duration delta) onTick) { _cb = onTick; running = true; }
  @override
  void stop() { running = false; }
  void advance(Duration delta) { if (running) _cb!(delta); }
}

SessionController _controller(FakeTicker ticker, {required bool autoContinue}) {
  return SessionController(
    config: SessionConfig(
      mode: SessionMode.flowBlock,
      plannedDuration: const Duration(minutes: 25),
      autoContinue: autoContinue,
      intention: 'x',
      soundscape: 'sand',
      skinId: 'classic',
    ),
    ticker: ticker,
    now: () => DateTime(2026, 6, 12, 9),
  );
}

void main() {
  test('starts in struggle and tracks elapsed as the ticker advances', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    expect(c.state.status, SessionStatus.running);
    expect(c.state.phase, FocusPhase.struggle);
    ticker.advance(const Duration(minutes: 15));
    expect(c.state.elapsed, const Duration(minutes: 15));
    expect(c.state.phase, FocusPhase.flow); // struggle(6:15)+release(45s) passed
  });

  test('fixed mode auto-finishes exactly at the planned mark', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    ticker.advance(const Duration(minutes: 25));
    expect(c.state.status, SessionStatus.finished);
    expect(ticker.running, isFalse);
    final record = c.finalize();
    expect(record.completed, isTrue);
    expect(record.abandoned, isFalse);
    expect(record.recordedFocus, const Duration(minutes: 25));
  });

  test('endless mode signals goal reached but keeps running past planned', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: true);
    c.start();
    ticker.advance(const Duration(minutes: 25));
    expect(c.state.goalReached, isTrue);
    expect(c.state.status, SessionStatus.running); // did NOT stop
    ticker.advance(const Duration(minutes: 12));
    expect(c.state.elapsed, const Duration(minutes: 37));
    c.end(); // user chooses to stop
    expect(c.state.status, SessionStatus.finished);
    final record = c.finalize();
    expect(record.completed, isTrue);
    expect(record.recordedFocus, const Duration(minutes: 37)); // overflow counts
  });

  test('ending before the goal records an abandoned, uncounted session', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    ticker.advance(const Duration(minutes: 10));
    c.abandon(); // e.g. user left the app (protect-the-block)
    expect(c.state.status, SessionStatus.finished);
    final record = c.finalize();
    expect(record.completed, isFalse);
    expect(record.abandoned, isTrue);
    expect(record.recordedFocus, Duration.zero);
  });

  test('pause stops accumulating; resume continues', () {
    final ticker = FakeTicker();
    final c = _controller(ticker, autoContinue: false);
    c.start();
    ticker.advance(const Duration(minutes: 5));
    c.pause();
    expect(ticker.running, isFalse);
    c.resume();
    ticker.advance(const Duration(minutes: 5));
    expect(c.state.elapsed, const Duration(minutes: 10));
  });
}
```

- [ ] **Step 2: Run — FAIL** (types not found).

- [ ] **Step 3: Implement the ticker interface**

`lib/session/ticker.dart`:
```dart
import 'dart:async';

/// Abstraction over a periodic clock so the controller can be unit-tested
/// with a fake ticker (no real time) and run with a real one in the app.
abstract class Ticker {
  void start(void Function(Duration delta) onTick);
  void stop();
}

/// Real ticker firing every [interval] (default 1s), reporting the delta.
class PeriodicTicker implements Ticker {
  final Duration interval;
  Timer? _timer;
  PeriodicTicker({this.interval = const Duration(seconds: 1)});

  @override
  void start(void Function(Duration delta) onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => onTick(interval));
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
```

- [ ] **Step 4: Implement the state**

`lib/session/session_state.dart`:
```dart
import '../domain/focus_phase.dart';

enum SessionStatus { idle, running, paused, finished }

/// Immutable snapshot of the live session, consumed by the UI.
class SessionState {
  final SessionStatus status;
  final Duration elapsed;
  final FocusPhase phase;
  final bool goalReached; // planned mark passed (chime fired)

  const SessionState({
    required this.status,
    required this.elapsed,
    required this.phase,
    required this.goalReached,
  });

  factory SessionState.initial() => const SessionState(
        status: SessionStatus.idle,
        elapsed: Duration.zero,
        phase: FocusPhase.struggle,
        goalReached: false,
      );

  SessionState copyWith({
    SessionStatus? status,
    Duration? elapsed,
    FocusPhase? phase,
    bool? goalReached,
  }) =>
      SessionState(
        status: status ?? this.status,
        elapsed: elapsed ?? this.elapsed,
        phase: phase ?? this.phase,
        goalReached: goalReached ?? this.goalReached,
      );
}
```

- [ ] **Step 5: Implement the controller**

`lib/session/session_controller.dart`:
```dart
import 'package:flutter/foundation.dart';

import '../domain/focus_phase.dart';
import '../domain/phase_engine.dart';
import '../domain/recorded_focus.dart';
import '../domain/session_record.dart';
import 'session_config.dart';
import 'session_state.dart';
import 'ticker.dart';

/// Owns the live session: elapsed time, phase, goal/auto-continue handling,
/// and finalization into a [SessionRecord]. UI listens via [ChangeNotifier].
class SessionController extends ChangeNotifier {
  final SessionConfig config;
  final Ticker ticker;
  final DateTime Function() now;
  final PhaseEngine _engine;

  SessionState _state = SessionState.initial();
  late final DateTime _startedAt;

  SessionController({
    required this.config,
    required this.ticker,
    required this.now,
  }) : _engine = PhaseEngine.forBlock(config.plannedDuration);

  SessionState get state => _state;

  void start() {
    _startedAt = now();
    _set(_state.copyWith(status: SessionStatus.running));
    ticker.start(_onTick);
  }

  void _onTick(Duration delta) {
    final elapsed = _state.elapsed + delta;
    final reachedGoal = elapsed >= config.plannedDuration;

    if (reachedGoal && !config.autoContinue) {
      // Fixed mode: stop exactly at the planned mark.
      ticker.stop();
      _set(_state.copyWith(
        elapsed: config.plannedDuration,
        phase: _engine.phaseAt(config.plannedDuration),
        goalReached: true,
        status: SessionStatus.finished,
      ));
      return;
    }

    _set(_state.copyWith(
      elapsed: elapsed,
      phase: _engine.phaseAt(elapsed),
      goalReached: _state.goalReached || reachedGoal,
    ));
  }

  void pause() {
    if (_state.status != SessionStatus.running) return;
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.paused));
  }

  void resume() {
    if (_state.status != SessionStatus.paused) return;
    _set(_state.copyWith(status: SessionStatus.running));
    ticker.start(_onTick);
  }

  /// User ends an endless session that has reached its goal.
  void end() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
  }

  /// Session abandoned before the goal (e.g. left the app, protect-the-block).
  void abandon() {
    ticker.stop();
    _set(_state.copyWith(status: SessionStatus.finished));
  }

  /// Builds the record to persist. completed iff the goal was reached.
  SessionRecord finalize() {
    final completed = _state.goalReached;
    final recorded = completed
        ? computeRecordedFocus(
            plannedDuration: config.plannedDuration,
            elapsed: _state.elapsed,
            autoContinue: config.autoContinue,
          )
        : Duration.zero;
    return SessionRecord(
      id: 0,
      startedAt: _startedAt,
      mode: config.mode,
      intention: config.intention,
      plannedDuration: config.plannedDuration,
      recordedFocus: recorded,
      completed: completed,
      abandoned: !completed,
      autoContinue: config.autoContinue,
      soundscape: config.soundscape,
      skinId: config.skinId,
    );
  }

  void _set(SessionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    ticker.stop();
    super.dispose();
  }
}
```

- [ ] **Step 6: Run — PASS (all 5 tests).** Then `flutter analyze` clean.

- [ ] **Step 7: Commit** — `feat: add SessionController session state machine`

> Note: `_onTick`'s `elapsed >= plannedDuration` and `phaseAt` rely only on the Plan-1 engine; the controller adds no duplicate phase logic. The "finished" status is reused for fixed-auto-finish, user-end, and abandon — `finalize()` distinguishes completed vs abandoned via `goalReached`.

---

## Task 4: Soundscape catalog + AudioService [UI/TDD-light]

just_audio loops a chosen soundscape under the session. Playback itself is verified on-device; the catalog and service contract get a light test.

**Files:**
- Create: `lib/audio/soundscapes.dart`, `lib/audio/audio_service.dart`
- Add royalty-free loop assets under `assets/audio/` and declare them in `pubspec.yaml`
- Test: `test/audio/audio_service_test.dart`

- [ ] **Step 1: Source royalty-free loops.** Obtain 4 seamless loops licensed for commercial use with no attribution burden (e.g. CC0/public-domain from a reputable source): `sand.mp3` (the signature), `rain.mp3`, `cafe.mp3`, `brown_noise.mp3`. Place in `assets/audio/`. **Record each file's source URL and license in `assets/audio/CREDITS.md`** (legal hygiene — the founder cares about this). If a genuinely good signature sand loop can't be found royalty-free, use the best available placeholder and note it as a Plan-3 sourcing task; do not ship a poor signature sound silently.

- [ ] **Step 2: Declare assets** in `pubspec.yaml` under `flutter:` → `assets: [assets/audio/]`. Run `flutter pub get`.

- [ ] **Step 3: Catalog**

`lib/audio/soundscapes.dart`:
```dart
/// A selectable background loop.
class Soundscape {
  final String id;
  final String label;
  final String asset; // path under assets/
  const Soundscape({required this.id, required this.label, required this.asset});
}

const kSoundscapes = <Soundscape>[
  Soundscape(id: 'sand', label: 'Falling sand', asset: 'assets/audio/sand.mp3'),
  Soundscape(id: 'rain', label: 'Soft rain', asset: 'assets/audio/rain.mp3'),
  Soundscape(id: 'cafe', label: 'Café hum', asset: 'assets/audio/cafe.mp3'),
  Soundscape(id: 'brown', label: 'Brown noise', asset: 'assets/audio/brown_noise.mp3'),
];

Soundscape soundscapeById(String id) =>
    kSoundscapes.firstWhere((s) => s.id == id, orElse: () => kSoundscapes.first);
```

- [ ] **Step 4: Test the catalog lookup**

`test/audio/audio_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/audio/soundscapes.dart';

void main() {
  test('soundscapeById returns the matching soundscape', () {
    expect(soundscapeById('rain').label, 'Soft rain');
  });
  test('soundscapeById falls back to the first for an unknown id', () {
    expect(soundscapeById('does-not-exist').id, 'sand');
  });
}
```
Run — expect PASS.

- [ ] **Step 5: Implement the service**

`lib/audio/audio_service.dart` — wrap `just_audio`'s `AudioPlayer` with `setLoopMode(LoopMode.one)`, `play(soundscape)` (sets asset, loops, plays), `pause()`, `resume()`, `stop()`, and `dispose()`. Configure `audio_session` for playback. Keep the interface tiny; this is a thin adapter (no unit test of playback — verified on device in Task 8).
```dart
import 'package:just_audio/just_audio.dart';
import 'soundscapes.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(Soundscape soundscape) async {
    await _player.setLoopMode(LoopMode.one);
    await _player.setAsset(soundscape.asset);
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();
  Future<void> dispose() => _player.dispose();
}
```

- [ ] **Step 6: Add deps** — `flutter pub add just_audio audio_session`. `flutter analyze` clean.

- [ ] **Step 7: Commit** — `feat: add soundscape catalog and audio service`

---

## Task 5: The Hourglass visual [PROTOTYPE → chosen default]

Goal: a **minimalist, premium** hourglass where a fluid-like body in the top chamber falls as a fine spray of tiny particles into the bottom, with the sand level driven by session progress. We try a few styles, compare on-device, and lock a default. Keep it lightweight (no cellular-automata physics).

**Files:**
- Create: `lib/hourglass/hourglass_skin.dart`, `lib/hourglass/hourglass_view.dart`, `lib/hourglass/hourglass_painter.dart`, candidates under `lib/hourglass/_prototypes/`
- A throwaway dev gallery screen to compare candidates (removed or kept behind a debug flag after the decision)

- [ ] **Step 1: Skin data model**

`lib/hourglass/hourglass_skin.dart`:
```dart
import 'package:flutter/painting.dart';

/// Data-driven hourglass appearance so the Plan-2 default and the Plan-2+
/// collectible skins are just different values.
class HourglassSkin {
  final String id;
  final Color sandColor;
  final Color glassTint;
  final double neckWidth; // relative 0..1
  const HourglassSkin({
    required this.id,
    required this.sandColor,
    required this.glassTint,
    required this.neckWidth,
  });

  static const classic = HourglassSkin(
    id: 'classic',
    sandColor: Color(0xFFE8C9A0),
    glassTint: Color(0x22FFFFFF),
    neckWidth: 0.06,
  );
}
```

- [ ] **Step 2: Build 2–3 candidate painters** in `lib/hourglass/_prototypes/` (e.g. `painter_particles.dart`, `painter_fluid_stream.dart`, `painter_hybrid.dart`). Each is a `CustomPainter` taking `progress` (0..1), `HourglassSkin`, and an animation value. Each draws: the two glass chambers (vector outline with subtle tint/refraction highlight), the top sand body shrinking and bottom growing with `progress`, and a falling stream/spray in the neck animated by the animation value. Provide a concrete baseline for at least the particle approach (a few dozen small circles with randomized-but-seeded offsets along the neck, fading near the bottom).

- [ ] **Step 3: Dev gallery** — a temporary screen showing all candidates side by side animating at a fixed progress sweep, runnable via `flutter run`. Compare on a real device for smoothness and beauty.

- [ ] **Step 4: DECISION CHECKPOINT** — run on device, pick the default style. **Record the choice and rationale in `docs/project-context.md`** (so future sessions know why). Promote the chosen painter to `lib/hourglass/hourglass_painter.dart`.

- [ ] **Step 5: HourglassView widget** — `lib/hourglass/hourglass_view.dart` wraps the chosen painter with an `AnimationController` (repeating, for the falling motion) and exposes `progress` (0..1) and `skin` parameters. A `RepaintBoundary` around the painter to isolate repaints.

- [ ] **Step 6: Widget test** — pump `HourglassView(progress: 0.5, skin: HourglassSkin.classic)` and assert it builds and a `CustomPaint` is present. (Visual correctness is judged on-device, not by test.)

- [ ] **Step 7: Performance check** — on a mid-range device (or emulator with profiling), confirm the animation holds ~60fps via `flutter run --profile` and the performance overlay. If it stutters, reduce particle count. Record the result.

- [ ] **Step 8: Commit** — `feat: add hourglass visual (chosen default style)` (remove or debug-flag the gallery; keep `_prototypes/` only if useful).

---

## Task 6: Home screen [UI]

Calm landing: the hourglass at rest, a single "Begin", a mode selector, and today's focus time + streak read from the repositories via the Plan-1 `StatsCalculator`.

**Files:** Create `lib/ui/home_screen.dart`, small widgets under `lib/ui/widgets/`; Test `test/ui/home_screen_test.dart`; Modify `lib/app/app.dart` (point `home:` at `HomeScreen`).

- [ ] **Step 1: A stats provider** — add to `lib/app/providers.dart` a `FutureProvider` that loads `allSessions()` and derives today's focus + streak + sessions-completed via `StatsCalculator` and `now`. (Inject `DateTime.now()` through a small `clockProvider` so it's testable.)
- [ ] **Step 2: Widget test** — with an overridden in-memory DB seeded with a couple of completed sessions, pump `HomeScreen` in a `ProviderScope`, and assert the Begin control, mode selector, and a non-zero "today" stat render. Expect FAIL first.
- [ ] **Step 3: Build `HomeScreen`** — a `ConsumerWidget`: centered `HourglassView(progress: 0)` at rest, a prominent "Begin" button → navigates to `SetupScreen`, a segmented mode selector (Flow Block / Pomodoro / Custom), and a quiet stat row (today's focus, streak) from the stats provider with a graceful loading/empty state. Use theme tokens; minimal chrome.
- [ ] **Step 4: Run widget test — PASS.** Point `app.dart` `home:` at `HomeScreen`.
- [ ] **Step 5: Manual verify** — `flutter run`; confirm the home screen looks calm and the hourglass renders at rest.
- [ ] **Step 6: Commit** — `feat: add calm home screen with stats`

---

## Task 7: Setup / Intention screen [UI]

Capture the one clear goal, the length, and the soundscape, then hand a `SessionConfig` to the session screen.

**Files:** Create `lib/ui/setup_screen.dart`; Test `test/ui/setup_screen_test.dart`

- [ ] **Step 1: Widget test** — pump `SetupScreen(mode: SessionMode.flowBlock)`; enter an intention; for Flow Block, assert a suggested length appears (from `StaminaCalculator.suggestedNextLength` over the stored stamina); toggle auto-continue; tap Start and assert it navigates with a `SessionConfig` carrying the entered values. Expect FAIL first.
- [ ] **Step 2: Build `SetupScreen`** — a `ConsumerStatefulWidget`: an intention `TextField` ("What's this block for?"), a duration control (Flow Block pre-fills the stamina-based suggestion; Pomodoro shows presets 25/5, 50/10; Custom shows a picker), a soundscape chooser from `kSoundscapes`, and an **auto-continue (endless flow)** toggle. "Flip to begin" builds a `SessionConfig` and pushes `SessionScreen`. Read defaults from `SettingsRepository` (auto-continue default, last soundscape).
- [ ] **Step 3: Run widget test — PASS.**
- [ ] **Step 4: Manual verify** on device.
- [ ] **Step 5: Commit** — `feat: add intention/setup screen`

---

## Task 8: Session screen — the running ritual [UI]

Wire `SessionController` to the hourglass, surface the phases, handle pause and protect-the-block, play sound, and route to completion.

**Files:** Create `lib/ui/session_screen.dart`; add a `sessionControllerProvider` family in `lib/app/providers.dart`; Test `test/ui/session_screen_test.dart`

- [ ] **Step 1: Controller provider** — a `ChangeNotifierProvider.family<SessionController, SessionConfig>` that builds a `SessionController` with a real `PeriodicTicker` and `DateTime.now`. Dispose stops the ticker (the controller's `dispose` does this).
- [ ] **Step 2: Widget test (with a fake ticker override)** — pump `SessionScreen` for a config; assert: the Struggle reframe line shows early then the screen quiets; the `HourglassView` progress advances as the (injected fake) ticker advances; a pause control toggles; reaching the goal in fixed mode routes to a completion state. (Inject the ticker via an override so the test controls time.) Expect FAIL first.
- [ ] **Step 3: Build `SessionScreen`** — a `ConsumerStatefulWidget` that:
  - On first build, calls `controller.start()` and `AudioService.play(soundscape)`.
  - Renders `HourglassView(progress: elapsed/planned clamped to 1)` full-screen, true-black background.
  - **Surfaces the Struggle phase**: while `phase == struggle`, show a single soft line ("The first few minutes are the hard part — stay with it."), fading out as Release/Flow begin. No countdown numbers by default; a tap faintly reveals remaining/elapsed.
  - A minimal pause control (pauses ticker + audio).
  - **Protect-the-block:** use `WidgetsBindingObserver`; on `AppLifecycleState.paused`/`inactive` while running and `protectBlock` setting is on, call `controller.abandon()` and show the gentle "block broke" state (sand spills) on return. Toggleable via the stored setting.
  - On `goalReached` fires a soft chime; in endless mode shows an unobtrusive "End session" affordance (auto-continues otherwise); in fixed mode the controller finishes and we route to completion.
  - On finish, calls `AudioService.stop()` and shows a completion state ("50 minutes focused"), then triggers persistence (Task 9).
- [ ] **Step 4: Run widget test — PASS.**
- [ ] **Step 5: Manual verify on device** — run a short custom session end-to-end (set a 1-minute custom block for testing): flip → struggle line → quiet → chime → completion. Background the app mid-session and confirm protect-the-block behaves. Confirm audio loops seamlessly.
- [ ] **Step 6: Commit** — `feat: add running session screen with phases and protect-the-block`

---

## Task 9: Persist completion + grow stamina [TDD/integration]

On a completed session, write the `SessionRecord` and update the stored Focus Stamina; abandoned sessions are recorded as abandoned (uncounted), not silently dropped.

**Files:** Create `lib/session/session_finalizer.dart`; Test `test/session/session_finalizer_test.dart`

- [ ] **Step 1: Failing test (integration with in-memory DB)** — build a `SessionFinalizer(sessionRepo, settingsRepo, staminaCalculator)`. Given a completed `SessionRecord`, assert: it's persisted (appears in `allSessions()`), and the stored `staminaSeconds` setting updates toward the new sustainable length (re-derive expected via `StaminaCalculator.currentStamina` over recent completed flow blocks). Given an abandoned record, assert it's persisted with `abandoned: true` and stamina is unchanged.
- [ ] **Step 2: Run — FAIL.**
- [ ] **Step 3: Implement `SessionFinalizer`** — `persist(SessionRecord)`: insert via `SessionRepository`; if `completed && !abandoned && mode == flowBlock`, recompute stamina from recent completed flow-block durations and `setInt('staminaSeconds', ...)` via `SettingsRepository`. Pure orchestration over Plan-1 pieces.
- [ ] **Step 4: Run — PASS.**
- [ ] **Step 5: Wire** the finalizer into `SessionScreen`'s finish handler (and the abandon path) via a provider. Manual verify: complete a real short session, return home, confirm today's focus + streak updated and the next suggested length nudged up.
- [ ] **Step 6: Commit** — `feat: persist completed sessions and update Focus Stamina`

---

## Task 10: Full verification [setup]

- [ ] **Step 1:** `flutter test` → ALL green (Plan-1 + Plan-2 tests). Report count.
- [ ] **Step 2:** `flutter analyze` → "No issues found!".
- [ ] **Step 3: End-to-end on device** — fresh launch → set intention → flip → run a short block to completion (both fixed and endless) → confirm session logged, streak/stamina updated, audio looped, protect-the-block worked. Capture a screenshot of the running hourglass.
- [ ] **Step 4: Commit** any cleanup — `chore: session UI complete — playable ritual end to end`.

---

## Done criteria for Plan 2
- A user can launch the app, set an intention, flip the hourglass, focus through the surfaced flow phases over a beautiful falling-sand hourglass with looping sound, be protected against leaving, and complete a session that's logged and grows their Focus Stamina — in both fixed and endless modes.
- Session runtime logic is fully unit-tested with a fake ticker; screens have widget tests; the whole suite + analyze are green; the experience is verified on a real Android device.

**Next:** Plan 3 — Stickiness & Share (Recovery/Boring-Break screen, stats dashboard, settings screen, share cards) + the release-security items (real signing key, `allowBackup=false`).
```
