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

### Pure builders (tested)
- **`SessionPlan.flowBlock(Duration work)`** → `[focus(work)]`. One unbroken block;
  recovery happens after (separate, Plan 3). No mid-breaks.
- **`SessionPlan.custom({Duration totalWork, int breaks, Duration breakDuration})`**
  → if `breaks <= 0`: `[focus(totalWork)]`. Else split `totalWork` into
  `breaks + 1` focus chunks of `totalWork ~/ (breaks+1)` (the **last chunk absorbs
  any remainder** so focus sums exactly to `totalWork`), separated by
  `rest(breakDuration)`. Example: 240 min, 3 breaks, 10 → `60·r10·60·r10·60·r10·60`.
- **`SessionPlan.pomodoroSingle({Duration work, Duration breakDuration})`** →
  `[focus(work), rest(breakDuration)]` (one classic pomodoro).
- **`SessionPlan.pomodoroSession({Duration totalWork, Duration work,
  Duration shortBreak, Duration longBreak, int longEvery = 4})`** → repeat
  `focus(work)`; after each focus, if accumulated focus `>= totalWork` **stop (no
  trailing rest)**, else append a break — every `longEvery`-th break is `longBreak`,
  otherwise `shortBreak`. So breaks only sit *between* focus blocks; the plan ends
  on a focus block.

Break auto-derivation for Pomodoro work length: `shortBreak ≈ round(work/5)`
(min 5), `longBreak ≈ 3 × shortBreak` (classic ~15 for 25/5). Computed in the
Setup layer and passed to the builder.

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
Each mode produces a `SessionPlan`; show a live **preview** of the generated plan.
- **Flow Block** — length presets/+5 (as now) → `flowBlock`. Endless toggle.
- **Pomodoro** — a sub-toggle **Single / Full session**:
  - *Single*: work-length stepper → `pomodoroSingle`. Preview "25 min work · 5 min break".
  - *Full session*: total stepper + work-length (25/50) → `pomodoroSession`.
    Preview e.g. "≈4 focus blocks · 3 short + 1 long break · 2h 5m total".
  - No endless toggle for Pomodoro.
- **Custom** — total-work stepper + **# breaks** stepper + **break-length** stepper
  → `custom`. Preview e.g. "4 × 60 min focus · 3 × 10 min break". Endless toggle
  only when breaks = 0.

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
