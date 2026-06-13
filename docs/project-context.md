# Hourglass — Project Context & Memory

> Durable context for this project. Kept **in the project folder** (per founder preference — never in the C-drive `.claude` user folder).

## Founder / working preferences
- Solo founder, hopes Hourglass becomes a real company and full-time income ("big break").
- Self-describes as **non-technical** — wants me to lead with expertise and recommend a clear default rather than hand over abstract option lists. Present concrete, pre-filtered choices.
- Develops on **Windows**; Android dev/build works there. iOS deferred until a Mac + Apple dev account are affordable from revenue.
- Bootstrapping — prefers **free tools** until there's traction. Values honesty/integrity (no overclaiming) as part of the brand.
- **Save all project context/memory inside this project folder**, not in `C:\Users\...\.claude\...`.

## What Hourglass is
A study/focus app positioned as **focus training** ("Train your focus like an athlete, recover like one too"), NOT "a prettier timer." Core invented method: **The Flow Block**, grounded in Flow Research Collective science (Rian Doris / Steven Kotler).

A session runs **Set intention → Flip → Struggle → Flow → Recovery**. Signature differentiators: surfacing the **Struggle phase** as expected/temporary, and a **phone-free "Boring Break"** (active recovery). **Focus Stamina** grows the user's sustainable block length toward the ~90-min ideal. Pomodoro/custom timers are on-ramps.

## Locked decisions
- **Flutter + Dart**; **Android first** (Play Store, founder has Google dev account); iOS later, revenue-funded.
- Stack: Riverpod, Drift (SQLite), just_audio, Firebase Analytics/Crashlytics. Pre-chosen for later: RevenueCat (P2), Firebase Auth/Firestore (P3).
- Royalty-free soundscapes for now. Brand name still **TBD** (working title "Hourglass" is generic/hard to trademark — brainstorm before launch).
- Hourglass visual = fluid-to-fine-particle spray, minimalist/premium, lightweight (no grain physics in v1); exact style prototyped during build.

## Honesty constraints (baked into the product)
- Don't claim Doris/Kotler attack Pomodoro by name (no such quote). The "4% rule" and "500% productivity" figures are heuristics, not lab constants. The beginner stamina ramp is our approach, not an FRC claim.

## Key documents
- Design spec: `docs/superpowers/specs/2026-06-11-hourglass-flow-block-app-design.md`
- Plan 1 (Foundation & Core Domain): `docs/superpowers/plans/2026-06-11-hourglass-v1-foundation.md`
- Roadmap: v1 "The Ritual" (P1) → P2 money/skins/stats → P3 ecosystem (sync/widgets/mixer) → P4 best-in-class (social, physics-grade sand).

## Status (2026-06-13)
Design approved. v1 split into 3 plans: **P1 Foundation — DONE & reviewed SHIP-READY** (30 tests pass, `flutter analyze` clean); P2 Session UI & Hourglass (next, plan not yet written); P3 Stickiness & Share.

Foundation built (subagent-driven, two-stage reviews): pure-Dart domain (`lib/domain/`: enums, PhaseEngine, computeRecordedFocus, SessionRecord, StaminaCalculator, StatsCalculator) + Drift data layer (`lib/data/`: AppDatabase with Sessions/Settings tables using `storeDateTimeAsText: true`, SessionRepository, SettingsRepository). Engineering mandate from founder: act as senior engineer, leave no bugs or security/privacy/legal holes; security work scales by phase (real rigor lands at P2 payments / P3 sync).

## Carry-forward into Plan 2 (from final review — DO NOT lose these)
- **Android release signing:** `android/app/build.gradle.kts` still signs release with the DEBUG keystore (scaffold default). Must create a real keystore + `android/key.properties` (gitignored) before any Play release.
- **`android:allowBackup="false"`** (or backup rules) in AndroidManifest — the focus-history SQLite is privacy data; default auto-backup should be disabled for a privacy-first app.
- **DB lifecycle:** wire `AppDatabase.open()` to a Riverpod provider that calls `db.close()` on dispose.
- **Android toolchain setup needed before building APK:** accept licenses (`flutter doctor --android-licenses`), set up an emulator/device. (Flutter SDK lives at `D:\Dev\tools\flutter`.)
- Already handled defensively in P1: stats ignore `abandoned` even if `completed` (guard test added); `.gitignore` excludes keystores/`google-services.json`/`GoogleService-Info.plist`/`.env`/etc.; `getInt` hardened against malformed values.
- **Hourglass visual = prototyping step** at the start of P2 (try fluid-to-particle styles, pick default). Keep it lightweight (no grain physics in v1).
