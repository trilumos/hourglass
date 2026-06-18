# Hourglass — V1 Launch Checklist (Play Store readiness)

> Created 2026-06-18. The complete pre-publish audit for a production app meant for thousands→millions of users. Grouped by area, each item tagged **P0** (hard blocker — cannot ship without), **P1** (do before launch), **P2** (fast-follow after launch). Status: ☐ todo · ◐ in progress · ☑ done · ❓ decision needed.
>
> This is the *plan for the audit*, not the audit itself. Several items (security pass, responsiveness pass, monetization brainstorm) are their own work sessions — run them against this list and check items off. Remaining V1 build scope still owed before most of this matters: **Analytics page → Onboarding → Themes → Monetization** (see the roadmap in `project-context.md`).

---

## 1. Release engineering & Play Store

- ☐ **P0 — Real release signing.** `android/app/build.gradle.kts` still signs release with the **debug keystore**. Generate a real upload keystore, store it + `android/key.properties` **gitignored**, wire `signingConfigs.release`. Enroll in **Play App Signing**. (Carry-forward from P1 review.)
- ☐ **P0 — App Bundle (.aab), not APK.** Play requires `flutter build appbundle --release`. Verify it builds, installs from an internal track, and launches.
- ☐ **P0 — Target SDK / compile SDK** meet Google's current minimum for new apps (Play raises this yearly). Confirm `targetSdk` is current; test on that API level.
- ☐ **P0 — Application id, versionCode, versionName** finalized (`com.trilumos.sustain`, start `1.0.0+1`). versionCode must increment every upload.
- ☐ **P1 — R8/ProGuard** shrink + obfuscate release; keep rules for Drift/sqlite3/Riverpod/reflection; verify the release build runs (not just debug).
- ☐ **P1 — App icon + adaptive icon + splash** (branded, all densities). Confirm no default Flutter icon ships.
- ☐ **P1 — Store listing:** title, short + full description, feature graphic, phone screenshots (premium ones — the app is the moat), category, contact email.
- ☐ **P1 — Pre-launch report** (Play Console auto-runs on real devices) reviewed; fix crashes/ANRs it surfaces.
- ☐ **P1 — Closed/internal testing track** before production (dogfood with a few users).

## 2. Security

- ☐ **P0 — `android:allowBackup="false"`** (or explicit backup rules) in AndroidManifest. The focus-history SQLite + profile are private; default auto-backup must be off for a privacy-first app. (Carry-forward.)
- ☐ **P1 — No secrets in the repo / app.** Confirm `.gitignore` covers keystores, `key.properties`, `google-services.json`, `GoogleService-Info.plist`, `.env`. (Already excluded — re-verify.)
- ☐ **P1 — Dependency audit.** `flutter pub outdated`; review transitive deps for known CVEs; pin/upgrade. New deps this cycle: `image`, `image_picker`, `uuid`.
- ☐ **P1 — Permissions minimal.** Confirm the manifest requests **no** runtime permissions (image_picker uses the system Photo Picker on modern Android = none). Any stray permission breaks the clean privacy story.
- ☐ **P1 — Input / file safety.** Avatar pick → decode is wrapped (corrupt images handled). Confirm no path traversal from stored relative paths; DB writes are parameterized (Drift handles).
- ☐ **P2 — Tamper/cheat surface** is intentionally minimal in v1 (focus is a private self-only number); real verification is the future PC/web monitoring. Note, don't fix now.

## 3. Legal, privacy & compliance

- ❓ **P0 — Privacy policy (hosted URL).** Required by Play even for offline apps. **Decision:** if v1 stays truly offline + no analytics, the policy is short and honest ("all data stays on your device; we collect nothing"). If Firebase Analytics/Crashlytics ships, the policy must disclose data collection + the SDKs.
- ❓ **P0 — Reconcile the analytics decision with the "no data collection" story.** `project-context` pre-chose Firebase Analytics/Crashlytics, but the locked account stance is "never collect = never leak." **Pick one for v1:** (a) ship with **zero** third-party SDKs → cleanest privacy + simplest policy (recommended for v1), or (b) ship Crashlytics/Analytics → must do the Data Safety form + consent + policy. Don't ship half-configured Firebase.
- ☐ **P0 — Play Data Safety form** filled accurately (what's collected, shared, why). Must match reality and the privacy policy.
- ☐ **P0 — Content rating** questionnaire (IARC). Hourglass → likely Everyone.
- ☐ **P1 — Terms of Service** (lightweight is fine for a free offline app; needed once accounts/payments land in V2).
- ☐ **P1 — Font license (Geist, OFL).** Ship `Geist-OFL.txt` + surface an in-app **licenses screen** (Flutter `showLicensePage` + register the font license). (Design-language obligation.)
- ☐ **P1 — Soundscape/audio licensing.** When audio ships: only CC0/royalty-free, with a `assets/audio/CREDITS.md` and in-app attribution if required.
- ☐ **P1 — Account deletion / data export** path. Offline v1: a "delete all my data" (clears the DB) is good practice and required once cloud/accounts arrive (V2).
- ☐ **P2 — GDPR/CCPA** posture documented (trivial while fully offline; becomes real with V2 cloud sync).

## 4. Data integrity & offline correctness

- ☑ **Migration safety.** v1→v2 migration is idempotent/non-destructive; tested; verified on-device (19 real sessions preserved). Re-verify on every future schema bump.
- ☐ **P1 — Schema migration test discipline.** Establish the pattern: every `schemaVersion` bump gets a migration test before release. Consider `drift_dev schema` snapshots for V2.
- ☐ **P1 — Date/time edge cases.** Streak + "today" are timezone/`DateTime.now()`-relative. Audit: day rollover at midnight, DST, device clock changes, travel across timezones. Confirm streak/today behave sanely (current: streak requires a session *today* — confirm that's the intended product rule, not a bug).
- ☐ **P1 — Checkpoint/force-kill persistence** still logs focus on every mode (the 8s checkpoint). Re-test after the session-screen changes.
- ☐ **P2 — DB corruption resilience** (rare): app should not hard-crash on a corrupt DB; consider a guarded open + recreate path.

## 5. UI/UX, states & copy

- ☐ **P1 — Six-states audit per screen** (empty / loading / error / success / first-use / offline) — design-language §13. New screens: History empty ✓; Profile/Edit loading; image-pick error (snackbar) ✓; **new-user must never see cold "0m / 0 days"** (warm framing).
- ☐ **P1 — Loading-flash sweep.** Fixed Home/Profile via `AsyncValue.value` (retains during refresh). Sweep the rest for the same blink-to-zero.
- ☐ **P1 — Copy pass.** Honest (no fake science / stats), no em dashes, no restated headings. Audit greeting pool, Focus Score page, errors.
- ☐ **P1 — Navigation consistency.** Back behavior, Android edge-back, no dead ends, session takeover always has a visible exit. Confirm every new screen pops correctly.
- ☐ **P1 — Design consistency.** One curvature family per screen; accent only as punctuation; no cards-in-cards; tokens-only (no hardcoded colors/spacing). Audit the new pages against design-language.md.
- ☐ **P2 — Onboarding (Plan 3)** — first-run name/photo capture + 3 calm intro screens. Needed before public launch so new users aren't dropped onto an empty hub.

## 6. Responsiveness, accessibility & compatibility

- ☐ **P0 — Full responsiveness audit** (founder's standing item). Test small→large/tablet, OS font-size XS→XL/bold, display-zoom/large-display. Honor `MediaQuery.textScaler`; no RenderFlex overflow/clipping anywhere. Use scrollable/flexible layouts. (The new bento + crop especially need the XL-font pass.)
- ☐ **P1 — Accessibility.** Contrast ≥ WCAG AA (tokens were tuned for it — verify on the new surfaces); semantic labels on icon-only buttons (avatar, gear, chevrons); min 48dp touch targets; respect **Reduce Motion** (ring/sand → fade/instant); screen-reader pass (TalkBack) on core flows.
- ☐ **P1 — Device matrix.** Test a low-end device + a tablet + the V2521, across Android versions (min SDK → latest). Watch jank on low-end.
- ☐ **P2 — Orientation** locked to portrait (intended) — confirm enforced app-wide.
- ☐ **P2 — Dark/light** both verified on every screen (Sand light + dark).

## 7. Performance & stability

- ☐ **P1 — 60fps on device** for the hourglass + transitions + the new ring animations (isolated repaints). Profile mode (`flutter run --profile`) on a real device; check the raster/UI threads.
- ☐ **P1 — Memory** under control (the low-RAM gradle fix is for the build host; check runtime memory on low-end). No leaks across many sessions (controllers/timers disposed — audit).
- ☐ **P1 — Cold start time** acceptable (first launch runs the migration — keep it snappy).
- ☐ **P1 — Crash-free** core loops: rapid nav, background/foreground mid-session, low battery, interruptions. (Crashlytics would catch field crashes — see §3 decision.)
- ☐ **P2 — Battery / wakelock**: wakelock only during a session; released on exit/background.

## 8. Code & pipeline hygiene (no redundancy / inconsistency)

- ☑ `flutter analyze` clean; **111 tests** green. Keep this gate green at every commit.
- ☐ **P1 — Dead/duplicate code sweep.** e.g. `ImageStorageService.saveAvatar(File)` is now only a fallback (crop path uses `saveAvatarBytes`) — keep or remove deliberately. Audit for unused widgets/providers after the restyle.
- ☐ **P1 — Consistency sweep.** Spacing token gaps (design uses 12/32/48/96; `HgSpacing` lacks some — either add them or stop using literals); duplicate stat-formatting (`home_screen._formatFocus` vs `session_format.formatFocusDuration` — unify); one icon weight per screen.
- ☐ **P1 — Test coverage gaps.** Add: migration *idempotency* (run twice), date-rollover streak, crop output, and a golden test for Home (Sand dark + light) per design-language.
- ☐ **P2 — CI.** A GitHub Action running `flutter analyze` + `flutter test` on every push would prevent regressions as scope grows.
- ☐ **P2 — `/code-review` ultra** pass on the full V1 branch before the release tag.

## 9. Monetization strategy (brainstorm — own session)

- ❓ **P1 — Decide the model** without feeling like a cheap money-grab (brand constraint). Run the brainstorming flow. Candidates to weigh:
  - Free core focus loop (always) vs **premium**: advanced analytics, extra themes/soundscapes, cloud sync (V2), the lottery/collectible **cosmetics** (earned-not-paid, ethical gacha), PC/web blocking (future).
  - **One-time unlock vs subscription** vs both; ethical seasonal/festival theme drops.
  - Pre-chosen tool: **RevenueCat** (P2/V2). No paywall in V1 unless deliberately decided.
- ☐ **P2 — Pricing + paywall placement** (only after the model is chosen; respect calm/no-dark-patterns).

## 10. Brand & assets

- ❓ **P0/P1 — App name / trademark.** Working title **"Hourglass" is generic and hard to trademark**, and competing apps exist. Decide the real brand name + check trademark/Play availability **before** the store listing is public (renaming later loses reviews/installs).
- ☐ **P1 — Visual identity** consistent: icon, wordmark, store art, the hourglass motif.
- ☐ **P2 — Domain / landing page / support channel** (even a one-pager + email).

## 11. V1 scope gate (what ships vs defers)

- **In V1:** Flow/Pomodoro/Custom sessions, Focus Score, Profile + History + Focus Score page, Analytics (next), Onboarding, a few Themes, basic Settings. Offline, no accounts.
- **Deferred to V2:** Levels/progression + collection, cloud auth + sync, widgets, break-time activities (sudoku/meditation/breathing), more monetization, PC/web blocking, anti-idle/honesty verification.
- ☐ **P1** — confirm nothing half-built ships (no dead "Soon" rows that look broken; either finish or clearly mark coming-soon).

## 12. Launch process

1. Finish remaining V1 features (Analytics → Onboarding → Themes).
2. Lock monetization + privacy/analytics decision (§3, §9).
3. Run the audits: security, responsiveness, a11y, performance, code-review.
4. Real keystore + `.aab` + obfuscated release build; smoke-test the release.
5. Internal test track → closed test (a few real users) → fix → production.
6. Privacy policy live, Data Safety + content rating submitted, store listing polished.
7. Ship to a **staged rollout** (e.g. 10% → 50% → 100%) watching crashes/reviews.

---

### Highest-leverage decisions to make now (unblock the rest)
1. **Analytics/Firebase in v1: yes or no?** (drives privacy policy, Data Safety, SDK work) — recommend **no** for the cleanest v1.
2. **Real brand name** (before any public listing).
3. **Monetization model** (drives whether a paywall/RevenueCat is in v1 at all).
