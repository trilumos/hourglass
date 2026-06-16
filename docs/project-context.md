# Hourglass — Project Context & Memory

> Durable context for this project. Kept **in the project folder** (per founder preference — never in the C-drive `.claude` user folder).

## Founder / working preferences
- Solo founder, hopes Hourglass becomes a real company and full-time income ("big break").
- Self-describes as **non-technical** — wants me to lead with expertise and recommend a clear default rather than hand over abstract option lists. Present concrete, pre-filtered choices.
- Develops on **Windows**; Android dev/build works there. iOS deferred until a Mac + Apple dev account are affordable from revenue.
- Bootstrapping — prefers **free tools** until there's traction. Values honesty/integrity (no overclaiming) as part of the brand.
- **Save all project context/memory inside this project folder**, not in `C:\Users\...\.claude\...`.

## Repo & git workflow (founder, standing)
- **GitHub remote:** `origin` → `https://github.com/trilumos/hourglass.git` (branch `master`). Auth via Git Credential Manager (already authenticated on this machine).
- **STANDING RULE: whenever something is "locked" / approved by the founder, commit it and `git push origin master`.** Keep the remote current with locked work. (Founder requested this 2026-06-15 after locking the hourglass visual.)

## Design mandate (founder, standing) — premium / buttery-smooth / no-friction
Every screen must feel **premium, minimal, flow-state, and buttery-smooth** — no nonsense, no friction, no clutter. Motion is a feature: soft transitions, ~60fps verified on device, isolated repaints. The founder expects to **iterate the UI heavily** (color palette, button shapes, positions) — so ALL styling must flow from **centralized design tokens** (one theme file: colors, typography, spacing, shape, motion) and never be hardcoded per-screen, making restyles cheap. When building UI, lean on the `frontend-design` / `impeccable` skills for quality. **Why:** the aesthetic-study audience shares beautiful tools; craft IS the moat. **How to apply:** tokens-first, reusable restyleable widgets, verify smoothness on a real device, default to calm/minimal over feature-dense.

## What Hourglass is
A study/focus app positioned as **focus training** ("Train your focus like an athlete, recover like one too"), NOT "a prettier timer." Core invented method: **The Flow Block**, grounded in Flow Research Collective science (Rian Doris / Steven Kotler).

A session runs **Set intention → Flip → Struggle → Flow → Recovery**. Signature differentiators: surfacing the **Struggle phase** as expected/temporary, and a **phone-free "Boring Break"** (active recovery). **Focus Stamina** grows the user's sustainable block length toward the ~90-min ideal. Pomodoro/custom timers are on-ramps.

## Locked decisions
- **Flutter + Dart**; **Android first** (Play Store, founder has Google dev account); iOS later, revenue-funded.
- Stack: Riverpod, Drift (SQLite), just_audio, Firebase Analytics/Crashlytics. Pre-chosen for later: RevenueCat (P2), Firebase Auth/Firestore (P3).
- Royalty-free soundscapes for now. Brand name still **TBD** (working title "Hourglass" is generic/hard to trademark — brainstorm before launch).
- **Technique name = "Flow Block" (LOCKED 2026-06-15).** Founder briefly considered renaming it "Flowmodoro"; I validated and advised against. "Flowmodoro" is an existing generic term (nickname for the Flowtime Technique, invented by Zoe Read-Bivens, 2016), already used by live competing apps (**Flowmo: Flowmodoro Timer** on App Store + Google Play, **Flowcycle**, etc.), effectively un-trademarkable, and tethers the brand to Pomodoro — all of which clash with the "we invented this method / focus training, not a prettier timer" positioning. "Flow Block" is ownable, distinct, and on-narrative. Do not rename without re-checking this.
- Hourglass visual = fluid-to-fine-particle spray, minimalist/premium, lightweight (no grain physics in v1); exact style prototyped during build.

## Honesty constraints (baked into the product)
- Don't claim Doris/Kotler attack Pomodoro by name (no such quote). The "4% rule" and "500% productivity" figures are heuristics, not lab constants. The beginner stamina ramp is our approach, not an FRC claim.

## Key documents
- **Design Language (LOOK/FEEL SOURCE OF TRUTH): `docs/design-language.md`** — our own branded style ("Warm Precision"): semantic color tokens (Sand light+dark), themes×modes model, Fraunces+Inter type system, spacing/radius/motion, voice & greeting personality, anti-patterns, and the Flutter token architecture (ThemeExtension). All screens build to this. Synthesized 2026-06-15 from category + Vercel/Geist + theming research.
- Design spec: `docs/superpowers/specs/2026-06-11-hourglass-flow-block-app-design.md`
- Plan 1 (Foundation & Core Domain): `docs/superpowers/plans/2026-06-11-hourglass-v1-foundation.md`
- Roadmap: v1 "The Ritual" (P1) → P2 money/skins/stats → P3 ecosystem (sync/widgets/mixer) → P4 best-in-class (social, physics-grade sand).

## Status (2026-06-15)
Design approved. v1 split into 3 plans: **P1 Foundation — DONE & reviewed SHIP-READY** (30 tests pass); **P2 Session UI & Hourglass — IN PROGRESS** (foundation tasks done; hourglass visual DONE & LOCKED; screens not yet built); P3 Stickiness & Share. See "Continuation" section at the bottom for exactly where to pick up.

Foundation built (subagent-driven, two-stage reviews): pure-Dart domain (`lib/domain/`: enums, PhaseEngine, computeRecordedFocus, SessionRecord, StaminaCalculator, StatsCalculator) + Drift data layer (`lib/data/`: AppDatabase with Sessions/Settings tables using `storeDateTimeAsText: true`, SessionRepository, SettingsRepository). Engineering mandate from founder: act as senior engineer, leave no bugs or security/privacy/legal holes; security work scales by phase (real rigor lands at P2 payments / P3 sync).

## Accounts decision (2026-06-13) — LOCKED
v1 is **offline-first, no accounts, no cloud**. All data on-device. Rationale: fastest to ship, zero backend cost, and — per founder's data-leak/legal concern — the best way to never leak user data is to never collect it (no privacy policy / GDPR / breach liability burden for a solo non-technical founder). **Optional Google Sign-In + cloud backup/sync is the HEADLINE of Plan 3 (P3)** — offered as an opt-in benefit ("sign in to back up & sync across devices"), never a gate. Architecture already supports this (clean local repos; Firestore pre-chosen). Founder chose this over "accounts now" and "offline + local export."

## First-open user flow (offline v1) — the canonical UX
1. **Splash** (1–2s, branded — hourglass forms/sand settles). *(Plan 3)*
2. **Onboarding — 3 calm skippable screens, first run only** *(Plan 3)*: the promise ("Train your focus like an athlete"), the method (Struggle→Flow→Recovery, "focus grows over time"), the twist (phone-free Boring Break). Ends "Begin your first block." No email/account/permission nags.
3. First-run **defaults set locally**: dark/AMOLED, Boring Break on, protect-the-block on, auto-continue off, classic skin, sand soundscape.
4. **Home** (every open): hourglass at rest, single "Begin", today 0m, streak 0, mode selector; one-time hint "Flip to start your first Flow Block."
5. **Set intention** → starter suggestion 25 min (no history yet) → pick soundscape.
6. **Flip** → full/quiet → **Struggle** line → fades → **Flow** (sand+sound; protect-the-block if they leave).
7. **Completion**: chime → "25 minutes focused" → streak→1, session logged, next suggestion 30 min.
8. *(Plan 3)* **Boring Break/Recovery** → then another block or done; *(Plan 3)* optional **share card**.
9. **Return**: opens skip onboarding → Home shows totals/streak, suggests slightly longer block; over time streak + suggested length grow (hourglass "grows" with them). All on-device, instant, no login until P3 opt-in.

Note: v1 needs **no special permissions** (sessions run foreground; protect-the-block requires foreground anyway). Keeps the privacy story clean.

## Carry-forward into Plan 2 (from final review — DO NOT lose these)
- **Android release signing:** `android/app/build.gradle.kts` still signs release with the DEBUG keystore (scaffold default). Must create a real keystore + `android/key.properties` (gitignored) before any Play release.
- **`android:allowBackup="false"`** (or backup rules) in AndroidManifest — the focus-history SQLite is privacy data; default auto-backup should be disabled for a privacy-first app.
- **DB lifecycle:** wire `AppDatabase.open()` to a Riverpod provider that calls `db.close()` on dispose.
- **Android toolchain setup needed before building APK:** accept licenses (`flutter doctor --android-licenses`), set up an emulator/device. (Flutter SDK lives at `D:\Dev\tools\flutter`.)
- Already handled defensively in P1: stats ignore `abandoned` even if `completed` (guard test added); `.gitignore` excludes keystores/`google-services.json`/`GoogleService-Info.plist`/`.env`/etc.; `getInt` hardened against malformed values.
- **Hourglass visual = prototyping step** at the start of P2 (try fluid-to-particle styles, pick default). Keep it lightweight (no grain physics in v1). — ✅ DONE & LOCKED (see below).

---

## Open follow-ups (don't lose)
- **Full RESPONSIVENESS audit across every screen (founder, 2026-06-16).** Test on many mobile sizes (small → large/tablet), and across OS **font-size settings** (extra-small → extra-large / bold text) and **display zoom / large display-size** settings. Users run XL fonts + zoomed screens; nothing may overflow, clip, or break. Approach: prefer scrollable/flexible layouts, honor `MediaQuery.textScaler` (don't hard-cap unless needed), test with `textScaleFactor` 0.85–1.5+ and small viewports, fix RenderFlex overflows (already hit several on Setup). Do a dedicated pass after the core screens exist.
- **Brainstorm a daily TASK LIST feature AFTER core screens** (founder, 2026-06-16), inspired by **FlowStack** (apps.apple.com/us/app/flowstack-focus-task-timer/id6739469633): users build a daily task list and do tasks one-by-one in focus/flow blocks; "smash multiple tasks in one focus sprint"; save tasks/routines as **templates** (a Library); per-task flexible timer + "flow state" continue; completion summary ("Session Complete! 7 tasks, 170 min"); stats (tasks completed today, time today, streak). Likely adds a Library/templates screen + task context into Setup/Session; revisit/edit screens after the ritual is built. Fits our Flow Block methodology (tasks → blocks).
- **Review `github.com/ever-works/awesome-time-tracking` AFTER the core screens are built** (founder, 2026-06-16). It lists many time-management practices/techniques + tools; check which match or complement our Flow Block methodology (could inform modes, features, or positioning). Deferred until Setup/Session screens are done.
- **Hardcoded greeting name "Deep"** in `lib/ui/widgets/greeting_line.dart` (`_name`). Placeholder until Plan 3 onboarding captures the user's real name into settings; then read it from there. (Founder asked to note this 2026-06-15.)
- **Home top-right gear → full Settings page (future).** Currently the gear opens a small light/dark/system bottom sheet (interim). Plan: point it at a proper **Settings page** that hosts theme switching, **Profile access**, and more. The **Profile** then holds analytics/stats and other things. Other pages (stats dashboard, recovery, etc.) need entry points too — **brainstorm placement/accessibility when we build them** (don't just bolt on buttons). (Founder asked to note this 2026-06-15.)

## CONTINUATION — pick up here in a new session (updated 2026-06-15)

### What's DONE and committed (branch `master`)
- **P1 Foundation** — `lib/domain/` + `lib/data/`, fully tested (30 tests green). Reviewed ship-ready.
- **P2 logic** — `lib/app/` (Riverpod providers, theme, app shell — `home:` is a placeholder Scaffold), `lib/session/` (`SessionConfig`, `Ticker`, `SessionState`, `SessionController`, `SessionFinalizer`). All tested (38 tests green at last count).
- **P2 hourglass visual — LOCKED** (commit `8fbfaa9`): `lib/hourglass/` (`hourglass_skin.dart`, `hourglass_painter.dart`, `hourglass_view.dart`, `hourglass_preview.dart`) + `lib/hourglass_preview_main.dart` (standalone preview entrypoint with a drain slider). The founder approved and **locked** this look after long on-device iteration — do NOT change it without being asked. Key choices already settled: andyfitz 2-layer parallax liquid top (light back / base front, ~1.4× speed apart, Catmull-Rom rendered); thin hole-width gravity sand-fall (~30 fine matte grains, phase² acceleration, no glow); two-phase pile; reduced fill so top/bottom never merge; wave fades flat near empty.

### Dev environment (all set up, don't redo)
- **Flutter 3.44.2** at `D:\Dev\tools\flutter` (on PATH). Dev on Windows; build via `flutter build apk` / preview on device.
- **Android licenses accepted** (had to run the SDK's `sdkmanager --licenses` directly with `SKIP_JDK_VERSION_CHECK=1` + JDK 21 — `flutter doctor --android-licenses` mis-detects Java 21).
- **Low-memory Gradle fix is committed** (`android/gradle.properties`: `-Xmx1536m`, kotlin in-process, no parallel) — the template's `-Xmx8G` crashed the daemon on this ~16GB/<5GB-free machine. Don't revert it.
- **Real Android phone** used for preview: Vivo **V2521**, Android 16, id `10MG18FQQG0008L`. `adb` at `C:\Users\morni\AppData\Local\Android\Sdk\platform-tools\adb.exe`.

### How to preview the hourglass on the phone (the loop used all session)
```
export PATH="/d/Dev/tools/flutter/bin:$PATH"; export JAVA_HOME="/c/Program Files/Java/jdk-21"; export MSYS_NO_PATHCONV=1
ADB="/c/Users/morni/AppData/Local/Android/Sdk/platform-tools/adb.exe"
flutter build apk --debug -t lib/hourglass_preview_main.dart
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk
"$ADB" shell am start -n com.trilumos.hourglass/.MainActivity
# screenshot (note MSYS path quirk): screencap to /sdcard then pull to a C:/ path
"$ADB" shell screencap -p /sdcard/s.png; "$ADB" pull /sdcard/s.png "C:/Users/morni/AppData/Local/Temp/s.png"
```
(`adb shell input tap 300 1518` taps the drain slider; screen stays awake via `svc power stayon usb`.)

### NEXT (Plan 2 remaining) — see `docs/superpowers/plans/2026-06-13-hourglass-v1-session-ui.md`
Build the screens that USE the locked `HourglassView` + the `SessionController`:
1. **Home screen** (Task 6): calm landing, `HourglassView(progress:0)` at rest, Begin, mode selector, today/streak from a stats provider. Then point `lib/app/app.dart` `home:` at it (replace the placeholder).
2. **Setup/Intention screen** (Task 7): intention + duration (stamina-suggested) + soundscape → builds a `SessionConfig`.
3. **Session screen** (Task 8): wires `SessionController` (real `PeriodicTicker`) to `HourglassView(progress: elapsed/planned)`, surfaces the Struggle line, pause, protect-the-block (lifecycle), completion.
4. **Audio** (Task 4): `just_audio` soundscapes — needs sourcing royalty-free CC0 loops + a CREDITS.md (deferred; signature "sand" sound is the hard one).
5. **Wire `SessionFinalizer`** into the session-complete + abandon paths (Task 9 step 5).
6. **Verify on device** (Task 10), then Plan 3 (Recovery/Boring-Break screen, stats dashboard, settings, share cards, optional sign-in/cloud-sync) + the release-security carry-forward items above.
