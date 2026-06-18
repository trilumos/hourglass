# Onboarding, Brand Rename & Package Switch — Build Spec (Sustain)

> **Status:** Design LOCKED by founder 2026-06-18 (brainstormed from the 2026-06-16
> research synthesis below — refined, not restarted). This is the build spec for
> **V1 roadmap item #3 (Onboarding)**, which also folds in the **Hourglass → Sustain**
> rename, the **Flow Block → Flow** rename, and the **package-id switch to
> `com.trilumos.sustain`**. Implementation follows via the writing-plans pass.
>
> The original research (strategy/flow + UI/motion, offline no-account v1, "Warm
> Precision") is preserved verbatim under **Appendix A** as the rationale; the
> sections below are what we build.

---

## 1. What this build delivers

1. A **first-run onboarding** flow: 4 short, skippable teaching screens + 1 profile
   screen (name + optional photo), ending by dissolving into Home.
2. **Profile generation** — captures the user's name and (optional) photo into the
   existing profile, so the personalized greeting works from first launch and the
   "add your name" empty state never appears.
3. The **Hourglass → Sustain** rename across all user-facing strings.
4. The **Flow Block → Flow** rename across all user-facing strings.
5. The **package id switch** `com.trilumos.hourglass` → `com.trilumos.sustain`
   (pre-launch, the only clean window).
6. The guide page retitled **"How it works"**.
7. The **store-listing copy** captured for Play Console (§7) — not shipped in-app.

Honesty constraint (brand rule): no fabricated stats, no misattributed quotes.
Onboarding copy describes only what V1 actually ships (e.g. the Focus Score as a
0–100 current-ability number — **no** level-up/collectible language, which is V2).

---

## 2. Brand placement (store vs in-app)

The "name + Focus/Flow phrase" lives **only in the store listing**. Inside the app
the wordmark is the clean **Sustain**; the tagline is the positioning line.

| Where | Text |
|---|---|
| **Store listing title** (Play Console / App Store — *not* in-app) | **Sustain: Find Your Flow** |
| **Store short description** | leads with **"Train your focus like an athlete."** |
| **In-app launcher name + wordmark** | **Sustain** |
| **In-app tagline** (Home caption + onboarding screen 1) | **Train your focus like an athlete.** |

---

## 3. The onboarding flow (5 screens)

First-run only; skippable; fully offline; outcome-framed, honest copy.

A single persistent `HourglassView` hero is mounted **above** a horizontal
`PageView` — it does **not** swipe away; only the text + dots page. Its `progress`
lerps between each slide's target (`medium 400ms`, `calm` curve). The hero uses the
existing `kHourglassHeroTag`, so the final **Begin** flies it continuously into
Home's hero (no jarring cut).

| # | Concept | Headline | Subcopy |
|---|---|---|---|
| 1 | Philosophy | **Train your focus like an athlete.** | "Focus is a skill you can build — with real training, and real recovery." |
| 2 | Flow + struggle + flow state | **Find your flow.** | "In Flow, the first minutes feel hard — that's the struggle. Stay with it and focus takes over: effortless, absorbed." |
| 3 | Recovery (the twist) | **Rest without your phone.** | "Then a short, boring break lets focus recover — no scrolling. Struggle, flow, recover: one full block." |
| 4 | Focus Score + modes + guide pointer | **Watch your focus grow.** | "Your Focus Score (0–100) tracks your focus ability as you train. Pomodoro and Custom are training wheels — Flow is the real method. The full guide is in Settings → How it works." |
| 5 | Profile (generation) | **What should we call you?** | Name field + optional "Add a photo" → CTA **Begin** (Home then greets by name) |

- The **Sustain** wordmark sits quietly atop screen 1 (the brand's first impression).
- **Skip** (top-right, low-contrast `textMuted`, ≥48dp, "Skip") on screens 1–4 jumps
  straight to the **Profile** step (5) — we still want the profile; we never force
  the teaching. Never trap the user.
- Hero `progress` targets: screen 1 ≈ 0.0 (at rest), 2 ≈ 0.4 (falling), 3 ≈ 0.8
  (settling), 4 ≈ at-rest, 5 = at-rest (Home hero).
- Screen 4 carries three linked ideas; if it reads heavy on device, split the
  modes/guide pointer into its own 6th screen (kept as a fast follow, not v1 default).

### Per-screen layout (Warm Precision, four-band)
- **Headline:** Geist 30–34 / w500 / -0.5 tracking / `textPrimary`, left-aligned.
- **Subcopy:** Geist 16–17 / w400 / `textSecondary`, ≤2 lines.
- **Hero:** the single persistent `HourglassView` on a warm radial gradient
  (`surface` → `background`), centered. Not a glow blob.
- **Progress dots:** 4 dots above the CTA; inactive = small `hairline` dots, active
  = a wider `accent` capsule-dot; width-morph + crossfade (`fast 200ms`). Accessible
  "Step N of 5".
- **CTA:** one sand pill (`accent`/`onAccent`), ≥56dp, bottom thumb zone, ≥16dp
  above the safe inset. Screens 1–4 CTA = "Continue"; screen 5 CTA = "Begin".

### Motion / accessibility
- **Stagger** first paint: hero → headline → subcopy → CTA (~60–80ms).
- **Parallax:** text at page speed, hero drifts ~0.3–0.5×.
- **Reduce Motion:** snap hero fill per slide, no parallax, freeze ambient sand,
  instant/fade entrances — no information lost.
- Larger-text safe: copy wraps; nothing clips at `textScaler` up to ~1.5.

---

## 4. Profile capture (screen 5) — reuses existing code

- **Name:** a single Geist text field. **Optional + skippable** — a quiet "Skip for
  now" proceeds with no name (the greeting then uses the name-less variant,
  "Welcome back"). Trim whitespace before saving.
- **Photo:** optional. A tappable avatar ring opens the **existing** pick + crop
  flow (`crop_avatar_screen.dart`, `image_storage_service.dart`); the fallback is
  the default `ProfileAvatar`. No new image plumbing.
- Persisted via the existing `ProfileRepository.update(name:, imagePath:)`.

---

## 5. Persistence & the first-run gate

- New settings key **`onboardingComplete`** (bool, default `false`) added to
  `SettingsKeys`; a `onboardingCompleteProvider` (FutureProvider<bool>) reads it via
  `SettingsRepository.getBool`.
- **Gate:** `app.dart` `home:` points at a small gate widget that watches
  `onboardingCompleteProvider`:
  - `false` → `OnboardingScreen`
  - `true` → `HomeScreen`
  - loading → a brief calm placeholder (offline read is near-instant).
- **On finish** (Begin on screen 5, or after skipping to it): write the profile
  (if any), `settings.setBool(onboardingComplete, true)`, invalidate
  `profileProvider` + `onboardingCompleteProvider`, then route to Home.
- **Migration guard (existing-data users never see onboarding):** during the gate's
  first read, if `onboardingComplete` is unset **and** the DB already has any
  recorded sessions **or** a non-empty profile name, silently set
  `onboardingComplete = true` and go straight to Home. This protects users who
  update the app (within the same package) from seeing onboarding again.
- First-run **defaults** already come from provider defaults (Boring Break on, etc.)
  — no extra writes needed at onboarding.

### Data lifecycle note
v1 is offline / no-account: all data is **device-local**. Uninstalling deletes the
private sandbox (`hourglass.sqlite` + the flag), so a reinstall is a clean slate
(fresh data, onboarding shows again) — correct behavior once
`android:allowBackup="false"` is set (a separate launch-checklist P0). Cross-device
/ reinstall persistence is **V2** (optional Google Sign-In + cloud backup/sync).

---

## 6. Renames folded into this build

### 6a. Hourglass → Sustain (user-facing strings only)
Change: `android:label` (`"hourglass"` → `"Sustain"`), `MaterialApp.title`, Home
wordmark `HOURGLASS` → `SUSTAIN`, Settings version string `Hourglass 1.0.0` →
`Sustain 1.0.0`, `showLicensePage` `applicationName`, the guide/settings/profile
"How Hourglass works" entries (retitled — see 6c), and the guide body copy
("Hourglass is focus training…", "Hourglass works fully offline…").

**Keep unchanged** (migration/visual safety): the `lib/hourglass/` painter +
all class names (`HourglassView`, `HourglassPainter`, `HourglassApp`, …), the
`hourglass.sqlite` DB filename, and the `kHourglassHeroTag`. "Hourglass" survives
as the **visual/icon motif**, not the name.

### 6b. Flow Block → Flow (user-facing strings only)
Mapping (a literal find-replace would read awkwardly, so):
- **Mode selector chip:** `"Flow"` (reads cleanly beside Pomodoro · Custom).
- **The method, in prose** (onboarding, guide, settings): `"Flow"` /
  `"Flow sessions"` for the session noun.
- **The unit:** keep `"block"` lowercase ("your first block", "Keep going" drains
  the block).
- **Focus Score copy:** "average of your last 10 **Flow sessions**" (was "Flow
  Blocks").
- **Code identifiers** (`SessionMode.flowBlock`, `SessionPlan.flowBlock`, etc.):
  **unchanged** — internal only.

Surfaces to update: `mode_selector.dart`, `setup_screen.dart`, `session_format.dart`,
`settings_screen.dart`, `focus_score_screen.dart`, `guide_screen.dart`,
`session_summary_screen.dart`, `insights_copy.dart` (+ doc comments as encountered).

### 6c. Guide title
`"How Hourglass works"` → **`"How it works"`** (the wordmark/context already says
Sustain; "How Sustain works" reads awkwardly because *sustain* is a verb).
Onboarding screen 4 points here: "Settings → How it works".

---

## 7. Package id switch — `com.trilumos.hourglass` → `com.trilumos.sustain`

Done **now** because the app is pre-launch (debug-signed); the applicationId is
permanent after the first Play publish. Founder accepts that the test device's data
won't migrate (it was test-only).

**Surface area (verified):**
1. `android/app/build.gradle.kts` — `namespace` + `applicationId` → `com.trilumos.sustain`.
2. `android/app/src/main/kotlin/com/trilumos/hourglass/MainActivity.kt` — move to
   `.../com/trilumos/sustain/MainActivity.kt`, update its `package` line, delete the
   empty old folder.
3. `ios/Runner.xcodeproj/project.pbxproj` — `PRODUCT_BUNDLE_IDENTIFIER` (6 entries)
   → sustain, for consistency when iOS work begins (not blocking on Windows now).

**Problems & fixes (complete list — no hidden gotchas):**

| Problem | Fix |
|---|---|
| Two app icons on the test device (old + new) | `adb uninstall com.trilumos.hourglass` once |
| Test data won't carry over (new sandbox) | Accepted — new app starts clean |
| `am start -n …/.MainActivity` could break if id ≠ namespace | Change **both** namespace + MainActivity package so they stay aligned |
| Docs/deploy commands reference old package | Update project-context, handoff, launch checklist, run/launch commands → `com.trilumos.sustain/.MainActivity` |
| Must precede first publish | ✓ pre-launch |

Confirmed **not** affected: no Firebase / `google-services.json`, no custom deep-link
scheme, no Dart code references the applicationId.

---

## 8. Store-listing copy (Play Console — kept here, not shipped in-app)
- **Title:** `Sustain: Find Your Flow`
- **Short description:** opens with `Train your focus like an athlete.`
- (Full long description, screenshots, feature graphic: drafted at store-submission
  time against the launch checklist.)

---

## 9. Testing
- `onboardingCompleteProvider` read/default; gate routing (false → onboarding, true
  → home).
- Migration guard: existing sessions OR a profile name ⇒ onboarding skipped + flag
  set; empty DB ⇒ onboarding shown.
- Profile persistence from screen 5 (name set; name skipped ⇒ empty; photo set via
  the crop flow).
- Skip paths (screens 1–4 → profile; profile "Skip for now" → Home).
- Widget tests for `OnboardingScreen` (paging, dots semantics "Step N of 5", CTA
  labels, Reduce-Motion fallback).
- Rename smoke: no remaining user-facing "Hourglass"/"Flow Block" strings (grep gate).
- Run serial: `flutter test --concurrency=1`; `flutter analyze` clean.

---

## 10. Open / deferred
- Screen 4 may split into two (modes/guide as a 6th screen) if it reads heavy on
  device — decide on-device.
- Splash screen (branded "Sustain" + forming hourglass) remains a separate small
  item; not required for this build.
- Cross-device / reinstall data persistence → **V2** (optional sign-in + sync).
- A pre-V2 local export/import stopgap — not planned (passed on for v1).

---
---

# Appendix A — Original research synthesis (2026-06-16, preserved)

> The strategy + UI/motion research that this spec was refined from. Some calls
> below were later overridden by the founder (notably: **name is now captured in
> onboarding**, reversing the "defer name" recommendation; **block-length is not
> asked** in onboarding; **teaching is expanded** because Sustain's method is novel
> enough that explaining it is value-first, not conversion scaffolding). Kept for
> rationale.

## The core reframe
Almost every "great onboarding" benchmark (Headspace, Calm, Opal, Noom) is
engineered to drive **signup + trial-to-paid conversion**. Our v1 has **neither
account nor paywall**. So we keep the one thing those flows get right — **fast
time-to-value** — and drop all the monetization scaffolding (long quizzes,
shock-stat reports, gated value). Our flow is **shorter, calmer, and ends in a
focus block, not a paywall**. Independent guidance converges on **3–5 screens,
skippable, <60s to first meaningful action**; tutorial walls get skipped, so ours
MUST be skippable and short.

## Aha moment & value-first
- **Onboarding aha (emotional):** *"This app expects the hard part — it warned me the
  Struggle was coming, and it actually passed."* Naming the Struggle is our unique,
  honest, differentiating promise.
- **Activation (hands-on):** completing one full Flow (ending in the phone-free
  Boring Break). First-session completion predicts retention best.
- **Drive to the block, not through more screens.** Value-first: intro screens are
  skippable and the final screen's action *is* starting; pre-arm a short, winnable
  first block even if they skip everything.

## Personalization (original recommendation — partly overridden)
- Original: ask exactly ONE optional question (target block length); DEFER name to
  Settings. **Override (2026-06-18):** onboarding *is* profile generation — it
  captures **name + optional photo**, and does **not** ask block length (the app
  already suggests a starter length and the per-session Setup picks duration).
- DON'T ask goal / "what are you working on" globally → fold into the per-session
  "Set intention" phase, where it's actually used.

## UI / layout (Warm Precision) — as adopted in §3
Four-band layout; persistent single `HourglassView` above a `PageView`; warm radial
gradient; Geist type; accent-as-punctuation dots; one sand pill CTA in the thumb
zone; value-first horizontal paging (not a feature carousel, not heavy interactive);
parallax + stagger + Reduce-Motion fallback; the only illustration is the hourglass.

## Honesty
Avoid the "4% beyond skill" and "500%/4x productivity" figures (pop-science,
unverifiable). Be inspiring with defensible qualitative truths: focus is trainable;
the first minutes feel effortful before they settle (struggle = loading, not
failure); recovery matters. Naming the Struggle is itself the most honest and most
differentiating move.

## Deferred to later phases
- **P2 paywall/trial** → only AFTER the first completed block; never in the intro.
- **P3/V2 optional sign-in** → "back up your streak & Focus Stamina," from Settings
  + at a milestone, never first-run. App stays fully usable signed-out.
- **Permissions** → none in v1.

## Sources
Strategy: NN/g mobile-app onboarding & tutorials-vs-contextual & skip; Userpilot;
Appcues; weareaffective; UXCam; Headspace/Finch/Fabulous/Opal/Endel/Sunsama
teardowns (App Fuel, Screensdesign, Mobbin, Figma community, Bootcamp); ProductLed;
UserGuiding; Toptal; Neurosity; PositivePsychology. UI/motion: Material onboarding;
NN/g; DesignerUp 200-flows; Mobbin page-control; Lollypop/Eleken steppers;
Raw.Studio Headspace; Spiel/Advids animation; Tubik.
