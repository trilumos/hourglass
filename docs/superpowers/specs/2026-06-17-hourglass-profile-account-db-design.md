# Hourglass — Profile / Account + DB (Foundation) — Design Spec

> **Date:** 2026-06-17 · **Status:** Approved (brainstorm) → ready for implementation plan
> **Scope owner:** founder · **Builder:** senior-engineer mandate (no bugs / no privacy holes)
> Supersedes nothing. Implements the "Profile / Account + analytics + history" follow-up in
> `docs/project-context.md`. Charts/Analytics is intentionally a **separate, immediately-following spec.**

## 1. Summary

Give Hourglass a real **identity + history surface**: a single on-device user profile (name +
photo), a **Profile hub**, an **Edit Profile** page, a **Session History** list, a **per-session
summary**, and a dedicated **Focus Score** page. Add the **sync-ready** database foundation
(stable `uuid` + `updatedAt`) so a future cloud sync is a clean add-on, not a rewrite. The
hardcoded greeting name "Deep" is removed (the greeting reads the profile).

This spec is the **foundation slice** of the larger Profile cluster. It is complete and shippable
on its own.

## 2. Decisions locked during brainstorm (2026-06-17)

- **Account scope = "Local now, sync-ready."** Single on-device profile in the local Drift DB; no
  login/servers yet. Confirmed after a cost review (below).
- **Cloud sync cost review (so this isn't re-litigated):** Firebase **Auth** (Google/email) and
  **Firestore** are effectively **free at launch scale** — the Spark free tier allows ~50k
  reads/day, 20k writes/day, 1 GiB stored. A focus session is a tiny document; ~20k writes/day
  covers a few thousand daily-active users before any limit. Beyond that, Blaze pay-as-you-go is
  cheap (reads ≈ $0.06/100k, writes ≈ $0.18/100k). **Cost is therefore NOT the reason to defer
  cloud sync.** The reasons to defer are unchanged from the 2026-06-13 locked decision: (1) privacy
  / GDPR / breach **liability** for a solo non-technical founder ("never collect = never leak"),
  (2) auth + multi-device sync is a large, correctness-sensitive subsystem (conflict resolution,
  offline merge, security rules) that is risky to own solo, (3) it delays the product and taxes
  every later feature. **Plan: ship local now; add Google Sign-In + cloud backup/sync as the P3
  opt-in headline when there are users + revenue, on the same free tier.**
- **Navigation:** Home top bar becomes `[◯ avatar]  HOURGLASS  [⚙ gear]`. Avatar (left) → Profile
  hub. Gear (right, unchanged) → Settings. Tapping the **Focus** stat on Home → Focus Score page.
  Every destination is reachable more than one way (Profile also from Settings; Focus Score also
  from Profile).
- **First-run profile creation:** the profile **self-creates** (lazy singleton) on first read — no
  onboarding screen required for the data to exist. This spec ships **Edit Profile** to populate
  name/photo. The full **branded 3-screen onboarding stays a separate later spec (#3)** and writes
  into this same table.
- **Aggregates = derived, not stored** (matches current architecture — everything computes live
  from the sessions list).
- **Profile image = copied into app-private storage**, with only the relative filename in the DB.
- **Edit Profile entry point** lives **in the Profile header, directly below the name** (not as a
  nav row).
- **Analytics charts are a separate next spec.** Here, the Analytics entry is a disabled "Soon" row.
- **Name required to save; photo optional (2026-06-17).** A real user can't tap Save on a blank
  profile — Edit Profile requires a non-empty (trimmed) name. Photo stays optional (default avatar).
  The **transient empty state** (a brand-new self-created row before the user sets a name, or a future
  skipped onboarding) is handled by the neutral greeting + "set up your profile" nudge — that's the
  *initial* state, not a user-saved empty profile.
- **Roadmap (LOCKED 2026-06-17): V1 = Profile/DB → Analytics → Onboarding → some Themes → Monetization
  → ship to Play Store.** Then **V2** (built post-launch, shipped as traction grows): Level/Progression
  + themes, Cloud auth + sync, more monetization, widgets, and break-time activities (sudoku,
  meditation, exercise, breathing). **No Level system in V1.**
- **V1 Profile hides Level + Collection (2026-06-17).** Headline stats = Focus Score · Total focus ·
  Streak · Sessions (no inert "Level"). No collection placeholder. Focus Score page has no "level up"
  line. Cleanest + honest for launch; all of it returns with the V2 Levels system.

## 3. Scope

**In scope (this spec):**

1. DB foundation — new `Profile` table + additive `Sessions` migration (`uuid`, `updatedAt`),
   schemaVersion 1 → 2, **non-destructive** (existing sessions/streak/score preserved + back-filled).
2. Domain `Profile` model + `ProfileRepository` (self-creating singleton).
3. `ImageStorageService` (pick → downscale square → save to app-private dir → relative path).
4. Pages: **Profile hub**, **Edit Profile**, **Session History**, **Per-session summary**,
   **Focus Score**.
5. Existing-screen touches: Home avatar entry + tappable Focus stat; Settings "Profile" row;
   greeting reads the profile (remove "Deep").
6. `StatsCalculator.totalFocus` (lifetime) + providers for profile/history/lifetime stats.
7. Tests for the data + service layer; light widget tests for empty/nav states.

**Out of scope (named so they're not lost):**

- Analytics charts page → **next spec** (metrics + chart library decided there).
- Branded onboarding → spec #3.
- Cloud sync + auth → P3 opt-in (schema is made ready here).
- Session **delete/edit** UI + soft-delete tombstones → future (pairs with sync).
- Levels/collection → **V2** (Levels system). In V1 the Profile **hides** Level + Collection entirely
  (no inert "Level 1", no empty collection) — they appear when actually built.

## 4. Page map & navigation

```
Home ──(avatar, top-left)──────────────► Profile hub
 │                                          ├─(header, below name)─► Edit Profile
 ├──(⚙ gear, top-right)──► Settings         ├──────────────────────► Session History ─(row)─► Per-session summary
 │                           └─(Profile row)─► Profile hub           ├──────────────────────► Focus Score page
 └──(tap Focus stat)──────────────────────────────────────────────► Focus Score page
                                            └─ Analytics  [Soon, disabled]   (collection = placeholder)
```

All new screens follow the existing calm pattern (`SettingsScreen`-style: `ScreenBackground` +
`SafeArea` + scrollable list, back arrow + title header) and pull **all** styling from the design
tokens (`HgSpacing`, `HgFont`, `HgRadius`, `HgMotion`, `context.hg`). No hardcoded colors. Honor
`MediaQuery.textScaler` (scrollable, no fixed-height clips). See `docs/design-language.md`.

## 5. Data model

### 5.1 New `Profile` table (Drift) — single self-creating row

| column | type | purpose |
|---|---|---|
| `id` | `integer().autoIncrement()` | local PK (repository keeps exactly one row) |
| `uuid` | `text()` | stable global id — future sync identity (maps to a server user later) |
| `name` | `text().withDefault('')` | display name; empty → neutral greeting / "set up" nudge |
| `imagePath` | `text().nullable()` | **relative** avatar path (e.g. `profile/avatar.jpg`); null → default avatar |
| `createdAt` | `dateTime()` | first created |
| `updatedAt` | `dateTime()` | last edit — future last-write-wins sync key |

Singleton is enforced in the repository (never inserts a second row). DB stored as text dates
(`storeDateTimeAsText: true`, consistent with the existing DB).

### 5.2 `Sessions` table — additive columns (sync metadata)

Add to the existing [`Sessions`](../../../lib/data/app_database.dart) table:

| new column | type | meaning / back-fill |
|---|---|---|
| `uuid` | `text().nullable()` | stable global id. **Repo always sets it on insert**; migration back-fills existing rows with a fresh v4 uuid. Nullable in DB only to satisfy SQLite `ALTER` (no per-row default possible); treated as always-present in code. |
| `updatedAt` | `dateTime().nullable()` | last modification. Set on insert (= now) and bumped on `updateRecordedFocus`. Migration back-fills existing rows with `startedAt`. |

These are **DB-level sync metadata** and are **not** surfaced on the domain `SessionRecord` (the UI
doesn't need them; the future sync layer reads them straight from the DB). This keeps `SessionRecord`
unchanged and the blast radius tiny.

### 5.3 Migration (schemaVersion 1 → 2) — non-destructive

`AppDatabase.schemaVersion` → `2`. Implement `MigrationStrategy.onUpgrade`:

1. `m.addColumn(sessions, sessions.uuid)`
2. `m.addColumn(sessions, sessions.updatedAt)`
3. `m.createTable(profile)`
4. **Back-fill** existing sessions in a transaction: for every row, write `uuid = <generated v4>` and
   `updatedAt = startedAt`.

`onCreate` (fresh installs) creates everything at v2 directly. The profile row is **not** created in
the migration — it is created lazily by `ProfileRepository` on first read (so fresh and upgraded
installs behave identically). The founder's device currently holds v1 data; this upgrade preserves
all sessions, today's totals, streak, and Focus Score.

### 5.4 Why derived, not stored

Total focus / streak / sessions / Focus Score keep computing live from `allSessions()` (as today).
Single source of truth, no cached-aggregate drift, simplest future sync. At this scale (hundreds–
thousands of rows) recomputation is trivial.

## 6. Domain & data layer

- **`Profile` (domain model, ORM-independent)** — mirrors the table: `id, uuid, name, imagePath,
  createdAt, updatedAt`. Convenience: `bool get hasName => name.trim().isNotEmpty;`
  `bool get hasImage => imagePath != null;` `bool get isSetUp => hasName;` (used for the nudge).
- **`ProfileRepository(db, {uuidGen, clock})`** — injected `String Function()` uuid generator and
  `DateTime Function()` clock (default to real) for testability.
  - `Future<Profile> load()` — returns the single row; **creates a default** (fresh uuid, name `''`,
    null image, `createdAt = updatedAt = now`) if none exists, then returns it.
  - `Future<Profile> update({String? name, String? imagePath, bool clearImage = false})` — writes
    provided fields, sets `updatedAt = now`, returns the updated profile. `clearImage` nulls the path.
- **`SessionRepository`** — `insertSession` now also writes `uuid = uuidGen()` and
  `updatedAt = clock()`; `updateRecordedFocus` now also bumps `updatedAt = clock()`. Add the same
  injected `uuidGen` / `clock` (default real) so the change is testable. `_toRecord` is unchanged.
- **`StatsCalculator.totalFocus(List<SessionRecord>)`** — lifetime sum of `recordedFocus` over
  sessions with `recordedFocus > 0`. (Streak/today already exist.)

## 7. Image storage

- **Packages:** `image_picker` (gallery; on modern Android uses the **system Photo Picker → no
  runtime permission**, preserving the clean no-permissions privacy story), `image` (pure-Dart
  decode/crop/resize/encode), `uuid` (v4 ids). `path_provider` already present.
- **`ImageStorageService({baseDirOverride})`** (base dir injectable for tests):
  - `Future<String> saveAvatar(File picked)` — decode → **center-crop to a square** → resize to
    **512×512** → encode **JPEG (~quality 85)** → write to `<appDocs>/profile/avatar.jpg`
    (overwrite) → return the relative path `profile/avatar.jpg`.
  - `Future<void> deleteAvatar(String relativePath)` — delete the file if present.
  - `File resolve(String relativePath)` — `<appDocs>/<relativePath>` for display.
- **Display:** circular via `ClipOval` / `CircleAvatar` with `BoxFit.cover`. Default avatar (no
  image) = a token-styled monogram/placeholder glyph.
- **No interactive cropper in v1** (`image_cropper` is a heavier native dep) — center-crop + circular
  cover-fit is enough; an interactive crop can come later.
- **Privacy:** the image lives in **app-private** storage. Reinforces the carry-forward
  `android:allowBackup="false"` item (focus history + avatar are private). No network, no collection.

## 8. Providers (Riverpod)

Follow the existing `FutureProvider` + `ref.invalidate(...)` pattern in
[`providers.dart`](../../../lib/app/providers.dart).

- `profileRepositoryProvider` → `ProfileRepository`.
- `imageStorageProvider` → `ImageStorageService`.
- `profileProvider` (`FutureProvider<Profile>`) → `repo.load()`. Invalidated after an edit.
- `sessionHistoryProvider` (`FutureProvider<List<SessionRecord>>`) → all sessions with
  `recordedFocus > 0`, **newest first**.
- `profileStatsProvider` (`FutureProvider<ProfileStats>`) → bundles Focus Score (reuse
  `focusScoreProvider` logic), lifetime total focus, streak, sessions-completed, and a static
  `level = 1` placeholder. (Or compose existing `focusScoreProvider` + `homeStatsProvider` +
  `totalFocus`.)

## 9. Screens

> All screens: `ScreenBackground` + `SafeArea`, calm back-arrow + title header, token-driven,
> scroll-safe under large text scale.

### 9.1 Profile hub (`profile_screen.dart`)

- **Header:** large circular avatar (image via `ImageStorageService.resolve`, else default) →
  **name** beneath (or *"Add your name"* if empty) → **Edit profile** button directly **below the
  name**. If `!profile.isSetUp`, show a gentle *"Set up your profile"* nudge near the header.
- **Headline stats** (calm row/grid, token spacing): **Focus Score** (tap → Focus Score page),
  **Total focus** (lifetime), **Streak**, **Sessions** (completed count, same definition as Home).
  *(Level is hidden in V1 — it returns with the Levels system in V2.)*
- **Navigation rows** (Settings-style): *Session history* (subtitle = count) · *Focus Score*
  (subtitle "How it's calculated") · *Analytics* (**Soon**, disabled).
- **No Collection section in V1** — it arrives with the Levels system in V2 (see §3).

### 9.2 Edit Profile (`edit_profile_screen.dart`)

- Avatar with **Change photo** (Photo Picker → `saveAvatar` → preview updates) and **Remove photo**
  (→ `clearImage` + `deleteAvatar`, revert to default).
- **Name** `TextField` (trimmed; **1–40 chars; required**). **Save stays disabled until the name is
  non-empty after trimming** (quiet inline validation) — a user can **not** save a blank profile.
- **Photo is optional:** a styled **default avatar** shows when none is set. We do **not** force a
  photo upload (high friction; many users won't have one handy; the default looks intentional, not broken).
- **Save** → `repo.update(...)`, invalidate `profileProvider`, pop. (Avatar is saved to disk on pick;
  Save persists the path + name together.) Handle pick-cancelled and decode-failure gracefully (snack).

### 9.3 Session History (`session_history_screen.dart`)

- Reverse-chronological list (`ListView.builder`) grouped by day with headers **Today / Yesterday /
  <date>**.
- Row: time · mode label (Flow Block / Pomodoro / Custom) · intention (truncated) · **focused
  duration** · quiet completed ✓ / ended-early mark. Tap → per-session summary.
- Empty state: *"Your focused time will appear here."*

### 9.4 Per-session summary (`session_summary_screen.dart`)

- One session in full: date & time · mode · intention · **Planned vs Focused** ("Focused 18m of
  25m") · outcome (Completed / Ended early / Extended).
- **Flow Block ≥ 2 min:** show **this session's 0–100 score** (via the existing
  [`FocusScoreCalculator.sessionScore`](../../../lib/domain/focus_score_calculator.dart)) and a short
  plain-language note on how it nudged the Focus Score. Non-flow or < 2 min: *"Not scored."*
- Read-only in v1.

### 9.5 Focus Score page (`focus_score_screen.dart`)

- **Hero:** big 0–100 number on top with the count-up animation (reuse the `TweenAnimationBuilder`
  approach from Home's `_Stat`).
- **Explanation below** (honesty-compliant plain language): average of your **last 10 Flow Blocks**;
  it **ramps** over the first ~10 (one great session won't jump you to 100 — *focus is trained, not
  flipped*); completing & pushing past your block raises it, giving up early lowers it; only Flow
  Blocks ≥ 2 min count. *(No "level up" line in V1 — Levels is V2; don't overclaim an unbuilt
  feature.)* Optionally list the contributing last-10 sessions as plain rows (no chart; charts are the
  Analytics spec).

### 9.6 Existing-screen touches

- **Home** ([`home_screen.dart`](../../../lib/ui/home_screen.dart)): replace the top-left `HOURGLASS`
  wordmark layout with `[avatar]  HOURGLASS(center)  [gear]`; avatar → Profile hub. Wrap the **Focus**
  `_Stat` in a tap target → Focus Score page. Avatar shows a subtle "set up" hint until configured.
- **Settings** ([`settings_screen.dart`](../../../lib/ui/settings_screen.dart)): add a **Profile**
  row at the top → Profile hub.
- **Greeting** ([`greeting_line.dart`](../../../lib/ui/widgets/greeting_line.dart)): replace the
  hardcoded `_name = 'Deep'` (and its `TODO(Plan 3)`) with the **profile name** from `profileProvider`.
  When the name is empty, render the greeting **without** the name span (and without the leading
  comma) so it reads naturally (e.g. "Good morning." not "Good morning, ."). Remove the "Deep" TODO.

## 10. Testing

- **Migration v1 → v2:** build a v1-shaped DB with sample sessions, run the upgrade, assert: all
  session rows preserved; every `uuid` non-empty + unique; every `updatedAt == startedAt`; `profile`
  table exists and is empty. (Use Drift's migration testing or a manual before/after assertion.)
- **`ProfileRepository`:** `load()` creates exactly one row on first call and returns the same row on
  the second; `update()` writes fields and **bumps `updatedAt`**; never creates a second row;
  `clearImage` nulls the path.
- **`SessionRepository`:** `insertSession` persists a non-empty `uuid` + `updatedAt`;
  `updateRecordedFocus` bumps `updatedAt` (inject a fixed clock to assert).
- **`StatsCalculator.totalFocus`:** correct lifetime sum; ignores `recordedFocus == 0`.
- **`ImageStorageService`** (temp base dir): `saveAvatar` yields a 512×512 file + correct relative
  path; `deleteAvatar` removes it; `resolve` maps correctly; decode failure surfaces an error.
- **Per-session score:** reuse existing `FocusScoreCalculator` tests (no new math).
- **Light widget tests:** Profile hub renders headline stats + nudge when empty; History empty state;
  Focus stat tap routes to the Focus Score page.
- **Gate:** `flutter analyze` clean and `flutter test` green (currently 94 tests) before deploy/commit.

## 11. Dependencies to add

`image_picker`, `image`, `uuid` (add to `pubspec.yaml`). No native config beyond what these
packages require; on modern Android the Photo Picker needs no runtime permission. Verify the build on
the V2521 device.

## 12. Build & verify

Standard loop (see `docs/project-context.md` → "How to preview"): `flutter analyze` + `flutter test`
green → `flutter build apk --debug` → `adb install -r` → launch `com.trilumos.hourglass` on V2521 →
founder reviews on device. Per the standing rule, **commit + push** once the founder locks it.

## 13. Future hooks (made cheap by this foundation)

- **Cloud sync (V2):** `uuid` + `updatedAt` are the bridge; add soft-delete tombstones + a sync
  engine + Firebase Auth/Firestore then. No schema rewrite.
- **Levels (V2):** add progression columns to `Profile` (the migration pattern here makes it a
  non-event); wire the real Level + Collection.
- **Analytics (next spec):** the `sessionHistoryProvider` + derived stats already expose the data the
  charts will visualize.
```
