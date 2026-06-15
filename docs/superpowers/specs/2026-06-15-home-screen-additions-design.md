# Home Screen Redesign + Additions — Design Spec

> Date: 2026-06-15. The first home build felt "too plain, too empty." External
> design tools (Stitch/Claude) didn't produce anything the founder liked, so the
> redesign is delegated. This spec defines the home screen's **information
> architecture, dynamic content, and behavior**; exact pixels are tuned
> on-device (the founder's established iteration loop).

## Goal

A calm, premium home screen that no longer feels empty — warm and personal,
gently urging the user to begin a focus session — without becoming a busy,
text-heavy dashboard. The hourglass stays the hero.

## Decisions captured (and explicitly rejected ideas)

- **APPROVED — time-aware greeting + contextual encouragement** as the single
  dynamic, motivating text zone (Claude-new-chat style). It **absorbs** the
  earlier "rotating quote line" idea: the curated focus/flow + value-of-time
  teachings are delivered as the encouragement sub-line, segmented by time of
  day — one warm zone, not two competing rotating texts.
- **APPROVED — adaptive tagline** ("Train your focus like an athlete"):
  prominent for new users, recedes once the user has completed their first block.
- **DEFERRED — name personalization.** Greeting is **time-only now**
  ("Good evening"); the name ("Good evening, Maya") slots in when onboarding is
  built in Plan 3. The greeting is designed so a name drops in without rework.
- **REJECTED — hourglass as a live wall-clock that flips hourly.** Overloads the
  signature symbol with two meanings (session progress vs. time of day), kills
  the "*you* flip it to begin" ritual, and animates an idle screen for an event
  nobody witnesses. Do not revisit without re-reading this rationale.
- **REJECTED — on-screen current-time display.** Redundant with the OS status
  bar and works against the app's deliberate anti-clock-watching ethos.

---

## Home redesign direction (composition)

Replace the floating-center layout with an intentional three-zone vertical rhythm:

1. **Top — identity & welcome.** Wordmark, the adaptive tagline, and the
   time-aware greeting + encouragement line. This fills the previously-empty top
   with warmth and the reason to begin.
2. **Middle — the hero.** The locked hourglass at rest, sitting in a **soft warm
   ambient glow** (a subtle sand-toned radial vignette behind it) so it rests in
   a pool of light instead of pure void — adds depth and richness with zero
   clutter; edges stay AMOLED black.
3. **Bottom — the action cluster.** The quiet stats (Today / Streak), the mode
   selector, and the prominent Begin, grouped as one clear "ready to focus" unit.

Everything flows from the centralized theme tokens; the ambient glow is a token
too (so it can be tuned or removed in one place).

---

## Component A: Greeting + contextual encouragement (`GreetingLine`)

**Purpose:** A warm, present, time-aware line that welcomes the user and nudges
them to start — the home screen's soul and primary call to action (besides Begin).

**Content & honesty**
- **Greeting** by local time of day: morning / afternoon / evening / late-night
  (thresholds tuned during build). Time-only now; name appended later.
- **Encouragement sub-line:** a hand-curated bank of short teachings blending
  focus/flow + value-of-time, **segmented by time of day** (e.g. a late-night set
  can carry the "burn the midnight oil" energy; a morning set, fresh-start
  energy). ~30–50 lines total across segments.
- Mix of **correctly-attributed** real quotes (e.g. Seneca on time) and
  **original** Hourglass lines (no fabricated author).
- **Hard honesty rules (brand constraint):**
  - No fabricated statistics or fake flow-science ("4% rule", "500%", invented
    studies).
  - Every attributed quote verified to the correct author before shipping.
- Each line fits 1–2 lines on a phone; no scrolling/truncation.

**Behavior**
- Greeting reflects the current time of day on each Home appearance.
- The encouragement sub-line picks a fresh line (from the current time segment)
  on each Home appearance, and gently **cross-fades** to another from the same
  segment on a slow interval (~15s; calm, never sliding/flashy; theme motion
  tokens). Never repeats the same line twice in a row.

**Structure (isolation)**
- `FocusQuote` value object: `text` (required), `author` (nullable).
- A time-segmented catalog (`const`, bundled in-app, offline; growable in
  updates) + a `greetingFor(DateTime)` pure function and a
  `nextQuoteIndex(previous, count, rng)` pure selector.
- `GreetingLine` widget: self-contained; owns time read + selection + cross-fade.
- Injects the clock via the existing `clockProvider` so it's testable.

**Testing**
- Unit: `greetingFor` returns the right band at boundary times.
- Unit: `nextQuoteIndex` never returns `previous` (count ≥ 2); handles count == 1.
- Unit: every catalog entry has non-empty text; each time segment is non-empty.

---

## Component B: Adaptive tagline

**Purpose:** Surface the positioning promise to newcomers, then get out of the
way for regulars (so it never becomes redundant copy a daily user re-reads).

**Signal**
- Source: existing `homeStatsProvider` / `StatsCalculator.sessionsCompleted`.
- **New** = `sessionsCompleted == 0`; **Returning** = `>= 1`.
- Completing the first block is the "bought-in" moment; a lapsed returner still
  knows the brand, so it stays receded.

**Presentation**
- **New (prominent):** hero/emphasis treatment near the top, with the wordmark.
- **Returning (receded):** a small, low-emphasis sub-wordmark under "HOURGLASS".
- State changes across sessions (not an in-screen animation); per-state sizing
  tuned on-device.

**Testing**
- Widget: stats `== 0` → prominent form renders; `>= 1` → receded form renders
  (asserted via a test key, not pixels).

---

## Dependencies & sequencing

- Pure-Flutter + existing Riverpod stats + clock. No new packages, no network,
  no schema changes. Fully offline.
- Build order: redesign the home composition with `GreetingLine` + adaptive
  tagline baked in → deploy → tune on-device → founder locks → commit + push.

## Out of scope

- Name capture / onboarding (Plan 3) — greeting is built to accept a name later.
- Splash + onboarding placement of the tagline (Plan 3).
- Any clock/time-of-day hourglass behavior (rejected above).
