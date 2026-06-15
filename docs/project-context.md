# Hourglass — Project Context & Memory

> Durable context for this project. Kept **in the project folder** (per founder preference — never in the C-drive `.claude` user folder).

## Founder / working preferences
- Solo founder, hopes Hourglass becomes a real company and full-time income ("big break").
- Self-describes as **non-technical** — wants me to lead with expertise and recommend a clear default rather than hand over abstract option lists. Present concrete, pre-filtered choices.
- Develops on **Windows**; Android dev/build works there. iOS deferred until a Mac + Apple dev account are affordable from revenue.
- Bootstrapping — prefers **free tools** until there's traction. Values honesty/integrity (no overclaiming) as part of the brand.
- **Save all project context/memory inside this project folder**, not in `C:\Users\...\.claude\...`.

## Design mandate (founder, standing) — premium / buttery-smooth / no-friction
Every screen must feel **premium, minimal, flow-state, and buttery-smooth** — no nonsense, no friction, no clutter. Motion is a feature: soft transitions, ~60fps verified on device, isolated repaints. The founder expects to **iterate the UI heavily** (color palette, button shapes, positions) — so ALL styling must flow from **centralized design tokens** (one theme file: colors, typography, spacing, shape, motion) and never be hardcoded per-screen, making restyles cheap. When building UI, lean on the `frontend-design` / `impeccable` skills for quality. **Why:** the aesthetic-study audience shares beautiful tools; craft IS the moat. **How to apply:** tokens-first, reusable restyleable widgets, verify smoothness on a real device, default to calm/minimal over feature-dense.

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
- **Hourglass visual = prototyping step** at the start of P2 (try fluid-to-particle styles, pick default). Keep it lightweight (no grain physics in v1).
