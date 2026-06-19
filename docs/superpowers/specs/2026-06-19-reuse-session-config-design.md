# Reuse Session Config (v1 minimal) — Design Spec (Sustain)

> **Status:** scope LOCKED 2026-06-19 (founder: "minimal taste in v1"). v1 ships
> **config capture + "Start again"** (exact reuse) from the per-session History
> summary and the Completion screen, **as a Pro feature**. The **"save up to 3
> presets in Setup"** UI is deferred to **v1.2** (also Pro; pairs with the
> templates/Library direction). Small, self-contained.
>
> **Pro-gated, build-now / gate-later:** config *capture* (the schema + planJson)
> ships for everyone (it's just data); the **"Start again" action is Pro** — built
> visible now, wrapped in `ProGate` (with an upsell) when the entitlement engine
> lands, exactly like enhanced Insights. Capturing for all users means a user who
> upgrades later can reuse their *past* sessions too.

## 1. Why it's clean
A `SessionPlan` is a list of `SessionSegment`s (`kind` + `duration`) — the
**resolved segment list is the exact session**, whatever builder produced it
(Flow / Pomodoro by-blocks or by-duration / Custom by-count or by-interval). So
"reuse the exact config" = **store the plan's segments + a few flags**, then
rebuild a `SessionConfig` from them. No need to persist builder parameters.

## 2. Data capture
- **New pure codec** `lib/session/config_codec.dart`: `encodeConfig(SessionConfig)
  → String (JSON)` and `decodeConfig(String) → SessionConfig`. JSON shape:
  `{ "v":1, "mode":"flowBlock|pomodoro|custom", "segments":[{"k":"focus|rest",
  "s":<seconds>}...], "autoContinue":bool, "autoAdvanceBreaks":bool,
  "soundscape":"sand", "skinId":"classic" }`. **Intention is NOT in the codec**
  (it's per-session; carried separately from the record's existing `intention`).
- **Domain:** add `final String? planJson` to `SessionRecord`.
- **DB:** add a **nullable `planJson` TEXT** column to the `Sessions` table; bump
  `schemaVersion` 2 → 3; migration `m.addColumn(sessions, sessions.planJson)`.
  Old rows stay `null` (their "Start again" falls back — see §3).
- **Write path:** `SessionController.finalize()` already has `config` + `plan`; it
  serializes them via `encodeConfig` into the `SessionRecord.planJson`.
  `SessionRepository` maps the column on insert/load. (Revise path / "Keep going"
  doesn't change the plan, so planJson is set once at first persist.)

## 3. "Start again" (exact reuse)
- **Where:** the per-session **History summary** (`session_summary_screen.dart`)
  and the **Completion** screen (`_Completion` in `session_screen.dart`).
- **Behavior:** if `record.planJson != null` → button **"Start again"** →
  `decodeConfig(record.planJson)` → build a `SessionConfig` (carry the record's
  `intention` as the default; keep its soundscape/skin) → push the **Session
  screen** directly (it starts immediately, matching "reuse and start"). Current
  user prefs (autoAdvanceBreaks, run-until-ended) apply as today.
- **Fallback for old/null rows:** if `planJson == null` (sessions from before this
  ships), either hide "Start again" or offer a lossy "Repeat" that rebuilds a
  single focus block of `plannedDuration` (decide in build; hiding is simplest +
  honest). New sessions always have it.

## 4. Files
- Create `lib/session/config_codec.dart` (pure encode/decode).
- Modify `lib/domain/session_record.dart` (+`planJson`), `lib/data/app_database.dart`
  (Sessions column + schemaVersion + migration) + the generated `.g.dart` (rebuild),
  `lib/data/session_repository.dart` (map column).
- Modify `lib/session/session_controller.dart` (`finalize()` sets `planJson`).
- Modify `lib/ui/session_summary_screen.dart` + `lib/ui/session_screen.dart`
  (`_Completion`) — the "Start again" action + navigation.

## 5. Testing
- **Codec round-trip (pure, TDD):** encode→decode reproduces an identical plan
  (segments kind+seconds) + flags for Flow, Pomodoro (with long-break cadence),
  Custom by-count and by-interval; version field present; bad/empty JSON → null
  (graceful).
- **finalize():** produced `SessionRecord.planJson` decodes back to the original
  plan.
- **Migration:** v2→v3 adds `planJson` nullable; existing rows load with
  `planJson == null` and don't crash (extend `test/data/migration_test.dart`).
- **Repository:** insert with planJson → load returns it.
- **Widget:** "Start again" appears when planJson present, hidden/fallback when
  null; tapping navigates to the Session screen with the decoded config.
- Run serial: `flutter test --concurrency=1`; `flutter analyze` clean.

## 6. Deferred → v1.2
- **Save up to 3 presets** per mode in the Setup screens (a small presets store +
  setup UI), naming, and a presets picker — **Pro**, pairs with the
  templates/Library/todo work. The §2 codec is the shared enabler (presets store
  the same JSON).
