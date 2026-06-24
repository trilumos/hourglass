# Sustain — App-Wide Pre-Launch Audit Plan

**Created:** 2026-06-24 · **To run:** next chat, after the current release build is verified on V2521.
**Goal:** Find everything that could break, mislead, frustrate, or embarrass before launch — workflows, edge cases, failing logic, inconsistencies, dead code, store-readiness — and fix it. This file is the checklist; nothing here is executed yet.

## Smoothness & performance track (added 2026-06-24, founder-requested "SMOOTH")

Do this **measured**, not by guessing — speculative animation rewrites risk breaking locked work (the hourglass physics, transitions).

1. **Profile-mode capture (the right tool).** Build `flutter run --profile` on V2521, open DevTools Performance/Timeline, and exercise every screen + transition. Record: jank frames (>16ms / >8ms at 120Hz), the worst build/layout/paint phases, and shader-compilation jank. Fix only what the trace flags.
2. **Startup.** First launch after a *fresh install* is slow (one-time ART/dexopt of the R8-minified APK — black native splash). Confirm warm start is fast (measured ~275ms on V2521 — good). If first-start matters, evaluate Play's baseline profiles (`flutter build appbundle` ships a baseline profile that speeds first run on devices that use it).
3. **Known/likely candidates to verify against the trace:**
   - `ProfileAvatar` is a `FutureBuilder` that re-`resolve()`s the path on every rebuild → can flash the fallback glyph. Consider resolving once (the docs dir is stable) or holding the `File` to kill avatar flicker.
   - Hourglass `Ticker` does `setState` per frame; it's `RepaintBoundary`-isolated and `TickerMode`-gated (verified) — confirm it actually mutes under pushed routes so it isn't burning frames behind other screens.
   - Image decode sizes: `ProfileAvatar` sets `cacheWidth/Height` (good); the edit-profile 112px preview does not — size it.
   - Page transitions use default platform route; if any feel sluggish, evaluate a lighter custom transition.
   - Check for any `setState` on a parent that rebuilds a large subtree each animation frame.
4. **RESOLVED this session:** avatar didn't update until app restart — root cause was a **fixed avatar filename** (`avatar.jpg`) colliding with Flutter's path+size-keyed `ImageCache` across all display sizes; `evict()` couldn't clear the sized variants. Fixed by writing a **unique filename per save** (`avatar_<ts>.jpg`) + cleaning old ones, so every cached variant is invalidated at once. ([image_storage_service.dart](../../../lib/data/image_storage_service.dart))

## How we'll run it

Work area-by-area in the order below. For each area: (1) read the code path end-to-end, (2) walk every workflow + the edge cases listed, (3) note findings in a running list with severity (P0 blocker / P1 should-fix / P2 polish), (4) fix P0/P1 in batches with `flutter analyze` + targeted tests after each, (5) re-verify on device. Keep one todo per area. Prefer a subagent per independent area when the lists get long (dispatch in parallel where there's no shared state).

Tooling each pass:
- `flutter analyze` (must stay clean) and `dart format` check.
- `flutter test` after each fix batch; add tests for any logic bug found (TDD for the fix).
- Grep sweeps for the cross-cutting patterns listed in §2.
- On-device smoke of the specific workflow after fixes (V2521, release build for billing/notifications/FGS paths).

---

## 1. Workflows to walk end-to-end (use-case pass)

For each: happy path, cancel/back at every step, re-entry, and the edge cases in §3.

1. **First run / onboarding** → profile create (name + photo crop) → land on Home. Verify the RootGate ↔ onboarding transition (was a past bug), `onboardingComplete` flag, profile persistence, avatar file write.
2. **Begin a session** (each mode): Home → mode select → Setup (duration-first, all 3 modes incl. Pomodoro by-blocks/by-duration, Custom by-count/by-interval) → Session → Summary → back to Home. Verify intention capture, flip animation, sound cues, milestone rewards.
3. **Session in-flight controls:** pause (free 3×3min / Pro ∞×10min), pause-cap 15s grace, leave-app 30s grace + return-resume, skip break, break auto-advance vs tap-to-continue, Keep going (Flow overflow), Endless flow, Pomodoro/Custom keep-going (Pro), end-early cost, sub-2-min no-record.
4. **Force-kill / backgrounding mid-session:** FGS live timer, grace pushes, orphaned-FGS cleanup on next Home, notification cancellation. Verify `sessionGuardProvider.stop()` + `cancelGraceAlerts()` on Home init.
5. **Insights:** free band (Records + heatmap), Pro depth band (over-time charts, when-you-focus, by-mode, follow-through, stamina, bests), Week/Month/All toggle, empty/low-data teaching lines.
6. **Exports:** PDF report (Pro, Insights) and CSV (free, History). Verify file names, share sheet, content correctness, the new 40pt margins render well across page breaks.
7. **Monetization:** paywall features→pricing→buy (each plan), success screen, restore, Pro management (status card, manage subscription, change plan, lifetime-aware tiles), à-la-carte theme buy, theme preview (capped, records nothing).
8. **Themes:** browse, preview (whole-app), apply (owned), buy, Aurora flagship position/badge, light/dark/system independent of theme, lapse→Sand→renew restores look.
9. **Profile/account:** view, edit (name + new photo sheet: view/edit/change/remove), photo viewer, session history, stats correctness.
10. **Settings:** every row, theme mode, session toggles (sounds, auto-advance, run-until-ended), notifications screen (opt-in, permission denied→request again), backup/restore, clear-all-data (type-to-confirm → factory reset → re-onboard), licenses, version.
11. **Backup & restore:** export file, restore-merge by id (no dupes, count reported), profile/settings replaced, Pro/themes NOT in file (restore via Play).
12. **Notifications:** opt-in scheduling, daily quote, streak nudge + grace, reconcile on Home, permission flows, retry banner.

---

## 2. Cross-cutting sweeps (grep-driven, whole codebase)

- **`async` + `BuildContext`:** every `await` followed by `context`/`Navigator`/`ScaffoldMessenger` must be guarded by `if (!mounted) return` / `if (context.mounted)`. Grep `await` in `lib/ui`. (Several screens already do this — verify none missed, esp. new edit-profile sheet + crop flow.)
- **`ref` after await in widgets:** same mounted discipline for Riverpod reads/invalidates.
- **`dispose()` completeness:** controllers, streams, listeners, page controllers, animation controllers. Grep `StreamController`, `…Controller(`, `addListener`, `addCustomerInfoUpdateListener`.
- **Provider invalidation correctness:** after mutations (profile, sessions, settings, theme) the right providers are invalidated; no stale Home/Insights. Cross-check `clearAll`, save flows, purchase/restore.
- **Null/empty/zero handling:** `0` durations, empty session lists, null avatar, null stamina, null focusScore, missing offering/products (offline/key-less).
- **Number/date formatting:** durations (`0m`/`1h 2m`), streak pluralization, dates (PDF `_months`, StatusCard `_fmt`, history), currency (paywall `_perMonthLabel` symbol extraction — test prefix ₹/$/€/£ AND suffix "199 kr" locales; verify the per-month rounding reads sensibly).
- **Theming tokens:** no hardcoded colors where `context.hg` should be used; accent usage consistent; `onAccent` contrast on every theme; scrim/hairline usage. Grep `Color(0x`, `Colors.` in `lib/ui`.
- **Spacing tokens:** `HgSpacing`/`HgRadius`/`HgSize` used instead of magic numbers (some intentional exceptions in painters/PDF).
- **Strings/copy:** one voice; verify every user-facing claim against code (we found CSV/PDF drift — sweep for any other "Pro" claims, pause numbers, grace seconds, theme count "9", "last 10", "2 minutes", "90 minutes reference").
- **Debug-only branches:** `kDebugMode` (dev Pro unlock, dev theme products) provably compiled out of release; no debug UI leaks.
- **Key-less / offline degradation:** billing null offering, `themeProducts` empty → "In Pro", `proStatus` null → graceful StatusCard fallback; nothing blocks the free experience.
- **TODO/FIXME/HACK + dead code:** grep `TODO|FIXME|HACK|XXX`; unused widgets/methods/imports; `tools/gen_guide.py` references a temp JSON that no longer exists (guide is now hand-edited — decide: re-root the generator or delete it to avoid a misleading "do not hand-edit" header).

---

## 3. Edge cases & failure modes (per-area)

**Session engine (highest risk — most logic):**
- Clock changes / DST / timezone: streak boundaries, "today" since midnight, heatmap day buckets, grace timers using wall-clock vs monotonic.
- Very long sessions, Endless running for hours, overflow math, `extendNow` repeated keep-going, last-segment detection.
- Rapid tapping (double-begin, double-end, pause-spam), backgrounding exactly at a transition, break↔focus boundary.
- Sub-2-min false start records nothing across ALL entry points; preview mode records nothing.
- Pause cap reaching exactly at session end; out-of-pauses locking only the button.

**Stats / score / stamina:**
- First-ever session (baseline set), fewer than 10 Flow sessions (ramp), all-early-ends, mixed modes, division-by-zero guards, `averageSession` over all modes.
- Heatmap with 15 weeks, future days blank, single-day grace exactly at 2 missed days.

**Images / avatar:**
- Huge image, tiny image (smaller than crop ring — does `_minScale` cover hold?), non-square, corrupt/unreadable file, EXIF rotation, HEIC, cancel at picker vs cancel at cropper.
- Edit-current-photo re-crop limitation (only the already-cropped 512² square is available, can't zoom out past it) — confirm acceptable or store original.
- Avatar file eviction/caching with fixed filename; remove-then-cancel leaves saved photo intact; delete orphan on save.

**Billing:**
- Offering missing one plan, products partially configured, purchase pending/cancelled/error/alreadyOwned, restore nothing/error, entitlement push after app restart, refund/expiry mid-session, plan mapping when product ids differ from `pro.monthly/yearly/lifetime` (the `_planOf` substring heuristic — verify against real RevenueCat product/base-plan ids), lifetime `expirationDate == null` path, cancelled-but-active (`willRenew=false`, future expiry) StatusCard wording.

**Insights / PDF:**
- Zero/low data (each section's teaching-line fallback, no fabricated lines), exactly-threshold counts (`>=2 months`, `>=3 sessions`, `>=5 follow-through sample`), page breaks splitting a block awkwardly, long names/intentions overflowing, non-ASCII in name (`_ascii` coverage), very large totals.

**Notifications / FGS:**
- Permission denied / later granted, exact-alarm permission on Android 14+, reboot rescheduling, doze, multiple grace pushes, notification taps routing to live session, channel config, Android 16 (API 36) behavior on the test device.

**Data / persistence:**
- Backup of empty app, restore of malformed/old-schema file, restore merge with overlapping ids, clear-all mid-session, settings migration/missing keys default sanely.

---

## 4. Consistency & UX-frustration pass

- Back/close affordances consistent (in-body header vs AppBar; some screens use `ScreenHeader`, others a manual Row — standardize).
- Loading/disabled/busy states everywhere an async action exists (double-submit guards — paywall has `_busy`; verify others).
- Empty states have a calm, branded message (no raw "Nothing here").
- Error messages are human ("That did not go through…") and never expose internals.
- Snackbars vs dialogs used consistently; no silent failures.
- Haptics consistent on selection/confirm.
- Tap targets ≥ 44px; the new pencil badge + avatar tap; stat taps→Insights/Focus.
- Scroll/overflow on small screens + large font sizes (FittedBox on stats — check other rows).
- No guilt/dark-patterns (matches the brand promise); paywall not nagging.
- Icon semantics correct; accent-ring removal from profile is consistent with other avatars.

---

## 5. Release / store readiness

- AndroidManifest: only necessary permissions (notifications, FGS special-use, boot, exact-alarm) — justify each for Play Data Safety; confirm no leftover storage/media/camera.
- `allowBackup=false`, signing config, R8/minify rules don't strip needed classes (RevenueCat, image, pdf, share_plus), shrinkResources.
- Version code/name (`1.0.0`) consistent (settings shows it, pubspec, manifest).
- App icon/splash all densities; adaptive icon.
- Open-source licenses screen accurate (Geist OFL registered); legal links (privacy/ToS) resolve.
- `.aab` builds, installs, cold-starts; first-run with no data; deep-link/notification cold-start into session.
- Locale/RTL sanity (at least no layout breakage); large-text accessibility.

---

## 6. Test-coverage gaps to close

- Billing `proStatus` mapping (each plan, lifetime, cancelled-active, null) — add unit tests via FakeBillingService `proStatusValue`.
- `_perMonthLabel` currency formatting (prefix/suffix/edge) — extract to a testable pure fn if needed.
- Stats/score/stamina edge cases listed in §3 (many likely already covered — measure, fill).
- Backup/restore merge-by-id and counts.
- Session grace/pause state machine transitions.
- Widget tests for paywall pages (features/pricing/management), themes grid (Aurora order/badge), edit-profile photo sheet.

---

## Suggested execution order (next chat)

1. **Cross-cutting sweeps (§2)** first — cheap, catches systemic issues, informs the rest.
2. **Session engine + stats edge cases (§3)** — highest logic risk.
3. **Billing + paywall (§3/§1.7)** — money path; verify `_planOf` against real product ids.
4. **Insights/PDF/exports (§1.5–1.6)**.
5. **Images/avatar, profile, settings, backup (§1.9–1.11)**.
6. **Notifications/FGS (§1.4, §1.12)** — needs device.
7. **Consistency/UX pass (§4)**.
8. **Release readiness (§5)** + **test gaps (§6)**, then a full on-device regression.

### Seed findings already noted (carry into the audit)
- `tools/gen_guide.py` source JSON is gone; guide is now hand-edited despite its "do not hand-edit" header — reconcile.
- Edit-current-photo only re-crops the 512² result (can't reframe wider) — decide whether to persist originals.
- `_planOf`/`proStatus` plan detection is a substring heuristic — validate against the live RevenueCat product/base-plan identifiers.
- `_perMonthLabel` symbol extraction assumes simple currency formatting — verify against locales seen in target markets.
