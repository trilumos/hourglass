# Flow Block — Focus Score & Collectibles (Design)

> Date: 2026-06-16. Makes **Flow Block the standout/default mode** via one honest
> mechanic: a personal **Focus Score** you grow only through Flow Block, with a
> **give-up** option as the willpower engine and **collectible hourglasses** as the
> reward. v1 here; Levels/blocking are a recorded roadmap. Builds with the Session
> screen (Task 8). Honesty rule applies (no fabricated science).

## Why this makes Flow Block the default
Pomodoro/Custom are static timers. Flow Block is the only mode that **trains you
and grows with you**, and the Focus Score is built **only** by Flow Block — so the
way to grow your number is to choose Flow Block. The give-up option turns each
session into a willpower test ("meet or beat your average"); the collectible adds a
satisfying, tangible payoff.

## Focus Score (the core) — a weighted points game

**Per-session points** (computed when a Flow Block ends, only if focused ≥ 2 min):
```
points = round( base(chosen) × completion²  +  overflow × overflowRate )

base(L)       = L + L²/D          // depth bonus: longer = more per minute   (D = 100)
completion    = min(actual/chosen, 1)        // squared → partial completion costs a lot
overflow      = max(0, actual − chosen)      // minutes past the chosen length
overflowRate  = (1 + chosen/D) × M           // grit reward for pushing past  (M = 1.5)
```
Worked: 25 done → 31 · 50 done → 75 · 50 quit@25 → 19 · 25 pushed→40 → 59.
Constants (D=100, completion exponent 2, M=1.5) are tunable.

**Normalize each session to 0–100:**
```
sessionScore = clamp(round(rawPoints / perfectPoints × 100), 0, 100)
perfectPoints = base(PERFECT)   // PERFECT = 60 min (the "100" anchor, tunable)
```
So 25 done ≈ 33, 50 done ≈ 78, 60 done = 100, give-up scores low, push adds toward 100.

- **Focus Score = round( sum(last 10 sessionScores) ÷ 10 )** — note the divisor is
  ALWAYS 10. This builds a **ramp**: one perfect early session only yields ~10 (not
  100); it can reach 100 only after ~10 strong sessions, then becomes a true rolling
  recent-10 average. Range 0–100. **100 = hourglass full → level up** (roadmap).
  Flow-Block-only. Reflects current ability: strong sessions raise it, give-ups lower it.
- **All ends are scored:** completed, given-up, or app-left all produce points from
  their actual focused length (≥ 2 min); sub-2-min ends are ignored.
- **Shown on Home** as the headline stat. Separate from the **suggested next Flow
  length** (which stays a simple recent-completed-length estimate, default 25).
- This replaces the user-facing "Focus Stamina" with the points-average score.

## Give up (willpower)
- In the Session screen, a clear but not-too-easy **"Give up"** affordance (a quiet
  secondary action, possibly with a one-tap confirm) ends the block now and records
  the actual focused length.
- Optional willpower cue (nice-to-have): show the user's current Focus Score during
  the block as a benchmark ("you usually focus 28 min") so they feel when they're
  below/above it. Keep it subtle; off by default if it adds clutter.

## Recording rule (CHANGES the locked "abandoned = 0")
For **Flow Block**, every end records the **actual focused length if ≥ 2 min**, else
uncounted:
- Completed the planned length → records that length (or the overflow in endless).
- Gave up early → records the focused length so far.
- Left app / protect-the-block → block ends; records the focused length so far.
This feeds the Focus Score, the Today total, and the streak (a day with any
qualifying Flow Block counts). **Pomodoro/Custom keep their prior behavior** (the
score is Flow-only); their partial-credit question stays a separate open follow-up.

`SessionController.finalize()` / the recording path is updated: for Flow Block,
`recordedFocus = actual focused time` (not zeroed on early end); `completed` still
reflects whether the planned goal was reached (for messaging/celebration), but does
not zero the recorded length.

## Collectible hourglasses
- Completing a Flow Block plays the **drain → flip → empty** animation and
  **collects one hourglass** — a running count (e.g. "12 hourglasses"). **Same art,
  no new design.**
- The count is **derivable** (number of completed Flow Blocks) — no new storage
  needed; or store a simple counter. Displayed in the **Profile** (future screen);
  for v1 it may surface as a small Home/completion indicator. (Founder said "in your
  profile" — Profile is a later screen, so v1 tracks it and shows it where it fits.)

## Data / engine
- New pure `FocusScoreCalculator`:
  - `sessionPoints(chosen, actual)` → the weighted formula above (0 if actual < 2m).
  - `score(recentSessions)` → average of `sessionPoints` over the last 10 Flow Block
    sessions (chosen = stored `plannedSeconds`, actual = `recordedSeconds`); 0 when
    none. Unit-tested.
- A Riverpod `focusScoreProvider` (FutureProvider) loads Flow Block sessions via
  `SessionRepository` and computes the score. `suggestedFlowLengthProvider` stays a
  separate recent-completed-length estimate (unchanged), default 25.
- **No schema change:** points are derived from stored `plannedSeconds` (chosen) +
  `recordedSeconds` (actual) + `mode`. The only data change is that Flow Block ends
  now store the actual focused length (we stop zeroing them).

## Home
- The **Focus Score** is the headline stat (your focus capacity). Today/Streak stay
  as quiet secondary stats. (Exact placement tuned on-device.)

## Honesty (v1 reality)
On phone-only v1 we can't verify real work. Defenses: **protect-the-block** (leaving
the app ends the block) and the score being a **private, self-only number** (no
social/leaderboard to fake for — gaming it only cheats yourself). True
work-verification arrives with the roadmap's PC/web blocking + monitoring.

## Roadmap (recorded; NOT v1)
1. **Focus Levels:** the score fills the hourglass → flip → upgrades to a **new
   hourglass design** (collectible skins) → numbered levels.
2. **Progressive difficulty:** higher levels average more blocks with **decaying
   weights**, so leveling takes more sustained focus.
3. **Streak effects:** at higher levels (~L3+), broken streaks pull the score down.
4. **Honesty / anti-idle checks.**
5. **PC / web versions** with **site/app/application blocking + activity monitoring**
   — the real work-verification.

## Testing
- `FocusScoreCalculator.sessionPoints`: depth bonus (50 > 2×25), completion² penalty
  (50 quit@25 ≈ 19), overflow bonus (25→40 ≈ 59), 0 when < 2 min. Worked-example
  values locked.
- `FocusScoreCalculator.score`: recent-10 window, ignores non-Flow, 0 when empty;
  a give-up lowers the average, a strong session raises it.
- Recording: a given-up Flow Block records its actual length (not 0); a < 2 min end
  is uncounted; Pomodoro/Custom unaffected.
- Widget: Home shows the Focus Score; Session screen shows a give-up action.
- Session-controller tests updated for the Flow Block recording change.

## Out of scope (v1)
Levels & new hourglass art, progressive difficulty, streak penalties, anti-idle,
PC/web + blocking, the dedicated Profile screen (collection display lands there).
