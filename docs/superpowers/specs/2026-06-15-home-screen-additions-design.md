# Home Screen Additions — Design Spec

> Date: 2026-06-15. Scope: content/behavior additions to the **home screen** that
> feed into the in-progress home redesign. The base layout/visual is being
> explored separately via external design tools (Google Stitch / Claude design);
> this spec defines the *elements and their behavior*, not pixel layout.

## Goal

Give the calm home screen a little soul and a gentle nudge to begin, without
turning it into a busy dashboard or an inspirational-poster app. Two additions:
a **rotating teaching line** and an **adaptive brand tagline**.

## Decisions captured (and explicitly rejected ideas)

- **APPROVED — rotating quote/teaching line.** One coherent tone: focus & flow
  wisdom fused with the value/finiteness of time, to create gentle urgency to
  start a session.
- **APPROVED — adaptive tagline** ("Train your focus like an athlete"):
  prominent for new users, recedes once the user has built history.
- **REJECTED — hourglass as a live wall-clock that flips hourly.** Overloads the
  single signature symbol with two meanings (session progress vs. time of day),
  destroys the "*you* flip it to begin" ritual, and burns battery animating an
  idle screen for an event nobody witnesses. Do not revisit without re-reading
  this rationale.
- **REJECTED — on-screen current-time display.** Redundant with the OS status
  bar and works against the app's deliberate anti-clock-watching ethos (the
  session screen hides the countdown on purpose).

---

## Component A: Rotating teaching line (`QuoteLine`)

**Purpose:** A single quiet line, visually subordinate to the hourglass, that
rotates through curated teachings to inspire and create urgency to focus.

**Content & honesty**
- A hand-curated bank of ~30–50 short lines, one coherent theme blending:
  attention/deep-work/flow + time-is-finite/time-is-a-gift/use-it-well.
- Mix of **correctly-attributed** real quotes (e.g. Seneca on time) and
  **original** Hourglass lines (no fabricated author).
- **Hard honesty rules (brand constraint):**
  - No fabricated statistics or fake flow-science (no "4% rule", no "500%
    productivity", no invented study claims).
  - Every attributed quote must be verified to the correct author before
    shipping — misattribution looks amateur and erodes trust.
- Each line short enough to render on 1–2 lines on a phone, no scrolling/truncation.

**Behavior**
- A fresh line is chosen each time Home appears.
- While the user lingers on Home, the line gently **cross-fades** to a new one on
  a slow interval (~15s; calm, never sliding/flashy; uses theme motion tokens).
- Selection is random but **never repeats the same line twice in a row**.

**Structure (isolation)**
- `FocusQuote` value object: `text` (required), `author` (nullable).
- `kFocusQuotes`: a `const` catalog bundled in-app (offline-first; no network).
  Can be grown in future app updates.
- `QuoteLine` widget: self-contained; owns selection + cross-fade timer; exposes
  no required config beyond optional styling. The redesigned home just drops it in.
- A small pure selector function (e.g. `nextQuoteIndex(previous, count, rng)`)
  so the no-immediate-repeat rule is unit-testable without timers.

**Placement** — intentionally flexible; fits whichever home layout is chosen
(likely beneath the hourglass or near the stats). Decided during the redesign.

**Testing**
- Unit: `nextQuoteIndex` never returns `previous` (for count ≥ 2); covers the
  count == 1 edge (returns the only index).
- Unit: catalog has no empty strings; every entry has non-empty text.
- The cross-fade is judged on-device, not asserted in tests.

---

## Component B: Adaptive tagline

**Purpose:** Surface the positioning promise to newcomers, then get out of the
way for regulars (so it never becomes redundant marketing copy a daily user
re-reads every open).

**The "new vs. returning" signal**
- Source: the existing `homeStatsProvider` / `StatsCalculator.sessionsCompleted`.
- **New** = `sessionsCompleted == 0` (the user has never completed a focus block).
- **Returning** = `sessionsCompleted >= 1`.
- Rationale: completing your first block is the moment you've "bought in"; a
  lapsed user who returns still knows the brand, so the tagline stays receded.

**Presentation**
- **New (prominent):** the tagline gets hero/emphasis treatment near the top
  (paired with the "HOURGLASS" wordmark) — it frames the product.
- **Returning (receded):** the tagline shrinks to a small, low-emphasis
  sub-wordmark under "HOURGLASS" (still part of identity, but subordinate to the
  user's own progress and the quote line).
- The transition between states happens naturally across sessions (it is not an
  in-screen animation); exact sizes/positions for each state are tuned on-device
  during the redesign.

**Testing**
- Widget: with stats overridden to `sessionsCompleted == 0`, the tagline renders
  in its prominent form; with `>= 1`, it renders in its receded form. (Form is
  asserted by a test-only marker/key, not by pixel size.)

---

## Dependencies & sequencing

- The base home **layout/visual** is pending external design examples
  (Stitch/Claude). These two components are layout-flexible by design and will be
  slotted into the chosen direction.
- Both components are pure-Flutter + the existing Riverpod stats; no new packages,
  no network, no schema changes. Fully offline.

## Out of scope

- The home layout redesign itself (separate, design-led).
- Splash + onboarding placement of the tagline (Plan 3).
- Any clock/time-of-day behavior (rejected above).
