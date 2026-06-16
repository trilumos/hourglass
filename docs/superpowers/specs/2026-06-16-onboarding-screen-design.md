# Onboarding — Design Research & Spec Input (Hourglass v1)

> Date: 2026-06-16. Deep research synthesis (strategy/flow + UI/layout/motion),
> scoped to our **offline, no-account, no-paywall** v1 and the "Warm Precision"
> design language. This is design INPUT for the onboarding build (slated for
> **Plan 3**); it does not change the Plan 2 order (Home ✓ → Setup → Session).
> Informed by a founder-provided 1,000-flow analysis + cited web research.

## The core reframe
Almost every "great onboarding" benchmark (Headspace, Calm, Opal, Noom) is
engineered to drive **signup + trial-to-paid conversion**. Hourglass v1 has
**neither account nor paywall**. So we keep the one thing those flows get right —
**fast time-to-value** — and drop all the monetization scaffolding (long quizzes,
shock-stat reports, gated value). Our flow is **shorter, calmer, and ends in a
focus block, not a paywall**.

Reject the "~25 screens average / Duolingo 60+" benchmark — that's conversion-funnel
scaffolding. Independent guidance converges on **3–5 screens, skippable, <60s to
first meaningful action**. (Tutorial walls get skipped by most users → ours MUST
be skippable and short.)

## Aha moment & value-first
- **Onboarding aha (emotional):** *"This app expects the hard part — it warned me the
  Struggle was coming, and it actually passed."* Naming the Struggle is our unique,
  honest, differentiating promise.
- **Activation (hands-on):** **completing one full Flow Block** (ending in the
  phone-free Boring Break). First-session completion predicts retention best.
- **Drive to the block, not through more screens.** Value-first: the 3 intro
  screens are skippable and the final screen's action *is* starting the block — no
  setup wall. Pre-arm a **short, winnable first block (~15 min)** even if they skip
  everything.

## Personalization: ask exactly ONE optional question
Without an account, every question is pure friction unless it visibly changes the
user's next 20 minutes.
- **ASK (the one question): target block length** — "How long can you focus right
  now, honestly?" 15 / 25 / 40, plus "Not sure → start me at 15." → seeds the first
  suggested block **and** the Focus-Stamina baseline. About the task, not the person.
- **DEFER name** → optional in Settings later (a name prompt at first run reads as a
  soft signup; against the no-account/calm ethos). The greeting's "Deep" placeholder
  gets replaced from there.
- **DON'T ask goal / "what are you working on"** globally → fold into the per-session
  **"Set intention"** phase, where it's actually used.

## Recommended flow (3 teach screens + handoff)
First-run only (persist `onboardingComplete` via `SettingsRepository`); skippable;
offline; no fields. Outcome-framed copy (a feeling/result per headline; mechanism is
at most a subordinate clause). Honest — **no fabricated stats**.

| # | Beat | One job | Headline (draft) | Subcopy (draft, honest) | Hero `progress` | CTA |
|---|---|---|---|---|---|---|
| 0 | Open animation | Set calm/premium tone | (hourglass fills, wordless) | — | auto | — |
| 1 | The promise | Focus is **trainable** | "Train your focus." | "Build focus like an athlete — and recover like one too." | ~0.0 | Continue |
| 2 | The method | Struggle is expected & survivable (the aha) | "Struggle, then flow." | "The hard first minutes are normal. Stay with it and focus takes over." | ~0.4 falling | Continue |
| 3 | The twist | Rest without guilt | "Rest without your phone." | "A short Boring Break lets focus recover — no scrolling." | ~0.8 settling | Continue |
| 4 | Handoff | Convert intent → block | "Begin your first block." | (one warm line / none) | reset to at-rest = Home hero | **Begin** |

(The one optional length question can live on the handoff or as a 3.5 step.)

**Handoff dissolves into Home** — same hourglass hero (continuous motion, no jarring
cut), first block pre-armed; the block's own "Set intention" continues the
conversation. "The best onboarding doesn't feel like onboarding."

## UI / layout (in our design language)
Four-band layout per screen (System / Chrome / Content / Action):
- **Skip:** persistent top-right, low-contrast (`textMuted`), text "Skip", ≥48dp,
  jumps to handoff/Home (sets defaults). Never trap the user.
- **Hero:** the **single persistent `HourglassView`** mounted above a `PageView` —
  it does NOT swipe away; only text + dots page. Its `progress` lerps between each
  slide's target (`medium 400ms`, `calm` curve). On a warm radial gradient
  (`surface`→`background`), not a glow blob. **One living hero is the teaching.**
- **Headline:** Geist 30–34 / w500 / -0.5 tracking / `textPrimary`, left-aligned.
- **Subcopy:** Geist 16–17 / w400 / `textSecondary`, ≤2 lines (no wall of text).
- **Progress:** 3 dots above the CTA; inactive = small `hairline` dots, active = a
  wider `accent` capsule-dot (accent as punctuation); width-morph + crossfade,
  `fast 200ms`. Accessible "Step N of 3".
- **CTA:** one sand pill per screen (`accent`/`onAccent`), ≥56dp, bottom thumb zone,
  ≥16dp above safe inset.

**Format:** value-first, **horizontal `PageView`** (signals "a few chapters with an
end"). NOT a generic feature carousel (~1% engage) and NOT heavy interactive.
**Parallax:** text at page speed, hero drifts ~0.3–0.5×. **Stagger** first paint:
hero → headline → subcopy → CTA (~60–80ms). **Reduce Motion:** snap hero fill per
slide, no parallax, freeze ambient sand, instant/fade entrances — no info lost.

**Visual restraint (anti-AI-slop):** the only illustration is the hourglass; sand
accent appears ONLY on hero sand + active dot + CTA. No 3D blobs, glassmorphism,
gradient text, purple→cyan, emoji icons, stock doodles, hero-swap-per-slide, bounce.

## Defer to P2 / P3 (and where they slot)
- **P2 paywall/trial** → only AFTER the first completed block (e.g., post-Recovery
  summary). Never in the 3-screen intro.
- **P3 optional sign-in** → "back up your streak & Focus Stamina," offered from
  Settings + at a milestone, never first-run. App stays fully usable signed-out.
- **Permissions** → none in v1. If notification nudges added later, pre-prompt
  (explain value first) AFTER the first completed block.

## Honesty
Avoid the "4% beyond skill" and "500%/4x productivity" flow figures (pop-science,
unverifiable — exactly what the brand rule forbids). Be inspiring with defensible
qualitative truths: focus is trainable; the first minutes feel effortful before they
settle (struggle = loading, not failure); recovery matters. Naming the Struggle is
itself the most honest and most differentiating move.

## Open decisions for the founder (when we build this in Plan 3)
- Confirm the one optional question (target length) vs zero questions.
- Final copy pass on the 3 headlines/sublines.
- Whether the handoff has a secondary "Maybe later" or just Begin.

## Sources
Strategy: NN/g mobile-app onboarding & tutorials-vs-contextual & skip; Userpilot
(aha, carousels, onboarding UX); Appcues (aha, mobile onboarding); weareaffective
(signup-before-explore); UXCam (great onboarding); Headspace/Finch/Fabulous/Opal/
Endel/Sunsama teardowns (App Fuel, Screensdesign, Mobbin, Figma community, Bootcamp);
ProductLed; UserGuiding; Toptal; Neurosity; PositivePsychology.
UI/motion: Material onboarding; NN/g; DesignerUp 200-flows; Mobbin page-control;
Lollypop/Eleken steppers; Raw.Studio Headspace; Spiel/Advids animation; Tubik.
(Full URLs captured in the research run.)
