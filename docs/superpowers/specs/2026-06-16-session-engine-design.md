# Session Engine — Multi-Segment Design

> Date: 2026-06-16. Replaces the single-block session model with a multi-segment
> engine so a session is a sequence of Focus/Rest segments. Powers proper
> Pomodoro cycles, Custom interval sessions, and (later) the task-list sprint.
> Built test-first. Scope = engine + Setup wiring; the mid-session **rest UI**
> is part of the Session screen (Task 8, next).

## Why
Founder wants: Pomodoro that fills a total duration with auto work/break cycles;
Custom sessions like "4 hours of work with 3 breaks". The current
`SessionController` runs a single `plannedDuration` — it cannot express cycles or
mid-session breaks. This engine generalizes to N segments.

## Core model (`lib/session/session_plan.dart`, pure Dart)
```
enum SegmentKind { focus, rest }

class SessionSegment {
  final SegmentKind kind;
  final Duration duration;
}

class SessionPlan {
  final List<SessionSegment> segments;
  Duration get totalFocus;     // sum of focus segment durations
  Duration get totalDuration;  // sum of all segments
  int get focusCount;          // number of focus segments
  bool get isSingleFocus;      // exactly one focus, no rest (Flow / Custom-no-breaks)
}
```

### Pure builders (tested) — both modes are FULL implementations

**Flow Block**
- **`SessionPlan.flowBlock(Duration work)`** → `[focus(work)]`. One unbroken block;
  recovery happens after (separate, Plan 3). No mid-breaks.

**Pomodoro — proper, two entry paths that both feed one builder.**
- Builder: **`SessionPlan.pomodoro({Duration work, Duration shortBreak,
  Duration longBreak, int blocks, int longEvery = 4})`** → `blocks` focus segments;
  between consecutive focus blocks insert a rest — every `longEvery`-th break is
  `longBreak`, else `shortBreak`. **Ends on a focus block** (no trailing rest).
  e.g. blocks=6, 25/5, long 15: `f25 r5 f25 r5 f25 r5 f25 r15 f25 r5 f25`.
- Ratio presets (work/shortBreak): **25/5, 50/10, 52/17, 90/15** (longBreak per
  preset, e.g. 25/5→15, 50/10→20; `longEvery = 4`).
- **Entry A — By blocks:** user picks a ratio preset + **block count** (stepper);
  total is computed & shown.
- **Entry B — By duration:** user enters a **target total work** → for each ratio
  preset compute `blocks = (target / work).round()` (≥1) and its resulting total;
  present those as options ("25/5 ×6 = 2h 25m", "50/10 ×3 = 2h 50m", …) → user
  picks → same builder. (Suggest only presets whose resulting total is reasonably
  near the target.)

**Custom — full autonomy. The chosen time is TOTAL WORK; breaks add on top.**
- **`SessionPlan.customByCount({Duration totalWork, int breaks,
  Duration breakDuration})`** → if `breaks <= 0`: `[focus(totalWork)]`; else
  `breaks+1` focus chunks of `totalWork ~/ (breaks+1)` (**last chunk absorbs the
  remainder** so focus sums exactly to `totalWork`), `rest(breakDuration)` between.
  Even spacing; the implied interval is shown.
- **`SessionPlan.customByInterval({Duration totalWork, Duration intervalWork,
  Duration breakDuration})`** → focus chunks of `intervalWork` with
  `rest(breakDuration)` between, repeated until `totalWork` is consumed (**final
  chunk = remainder**, no trailing rest). e.g. 120 work, every 30, break 10 →
  `f30 r10 f30 r10 f30 r10 f30`.

`longBreak`/`shortBreak` defaults for Pomodoro are per-preset constants in the
Setup layer; Custom break length is user-chosen.

## `SessionConfig` change (`lib/session/session_config.dart`)
Replace `plannedDuration` with `SessionPlan plan`. Keep `mode`, `intention`,
`autoContinue`, `soundscape`, `skinId`. `autoContinue` (endless) is only honored
when `plan.isSingleFocus` (Flow / Custom-no-breaks); ignored for multi-segment.

## `SessionController` rewrite (`lib/session/session_controller.dart`)
Runs a plan via the injectable `Ticker` (still fully unit-testable, no real time).

State (`SessionState`):
- `status` (idle/running/paused/finished)
- `segmentIndex`, `currentKind` (focus/rest), `segmentElapsed`, `segmentRemaining`
- `elapsed` (whole session), `recordedFocus` (focus time done so far)
- `phase` (Struggle/Release/Flow) — from `PhaseEngine.forBlock(currentFocusDuration)`
  applied within **focus** segments; rest segments report no phase
- `goalReached` (plan's planned end passed)
- overall `progress` 0..1 = elapsed / totalDuration (clamped)

Behavior:
- On each tick, add delta to `segmentElapsed`/`elapsed`; when a segment completes,
  carry remainder into the next segment and emit a transition (focus↔rest). When
  the **last** segment completes → `finished`, `goalReached = true`, ticker stops.
- `recordedFocus` accrues only during focus segments.
- **Endless** (`autoContinue` + `isSingleFocus`): at the single focus end, set
  `goalReached` but keep running (overflow counts as focus) until the user ends.
- `pause`/`resume`/`end`/`abandon` as today.
- `finalize()` → `SessionRecord` with `recordedFocus = state.recordedFocus`
  (completed) or `Duration.zero` (abandoned before goal); `plannedDuration` on the
  record = `plan.totalFocus` (so stats/stamina see focus time, not rest).

## Finalizer / stats (`lib/session/session_finalizer.dart`)
Unchanged contract: persists the record; updates Focus Stamina **only** for a
completed, non-abandoned **Flow Block** (single focus). Uses the record's focus
duration. Multi-segment Pomodoro/Custom persist but don't move stamina.

## Setup wiring (`lib/ui/setup_screen.dart`)
Each mode produces a `SessionPlan`; always show a live **preview** of the schedule
(e.g. "4 × 60m focus · 3 × 10m break · 4h 30m total").
- **Flow Block** — length presets/+5 (as now) → `flowBlock`. Endless toggle.
- **Pomodoro** — a sub-toggle **Blocks / Duration**:
  - *Blocks*: ratio chips (25/5, 50/10, 52/17, 90/15) + a **block-count** stepper →
    `pomodoro(...)`. Preview shows total.
  - *Duration*: a target-total stepper → computed **ratio options** as chips
    ("25/5 ×6 · 2h 25m", …) → pick → `pomodoro(...)`.
  - No endless toggle for Pomodoro.
- **Custom** — total-**work** stepper, a **By count / By interval** sub-toggle
  (count → `customByCount`; interval "break every X" → `customByInterval`), and a
  **break-length** stepper. Preview shows chunks/breaks/total. Endless toggle only
  when there are no breaks.

## Testing (TDD, the heart)
- **Builders:** segment sequences + math for each builder, incl. remainder
  absorption, breaks=0, long-break placement, plan ending on focus, totalFocus.
- **Controller (fake ticker):** advance through a multi-segment plan — focus→rest→
  focus transitions at the right marks; `recordedFocus` counts focus only; finish
  after last segment; endless keeps running for single-focus; pause/resume; abandon
  → zero recorded. Update the existing single-block controller tests to the plan.
- **Finalizer:** completed flow block updates stamina; multi-segment Pomodoro/Custom
  persist without changing stamina; abandoned persists uncounted.
- Widget tests for Setup previews per mode.

## Out of scope (deferred)
- Mid-session **rest UI** + visuals → Session screen (Task 8).
- Manual per-segment editor; saving plans/routines as templates → with the
  FlowStack-style task list later.
- Soundscape selection (audio task).

## Migration note
This rewrites `SessionConfig`/`SessionController`/`SessionState` and their tests
(currently single-block). `PhaseEngine`, `computeRecordedFocus`,
`StaminaCalculator`, repositories are reused. `computeRecordedFocus` may be
retired in favor of the controller's per-segment focus accrual (decide during
implementation; keep if it still serves the single-focus overflow rule).
