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
  recent-10 average. Range 0–100. **100 = level up** → collectible + share card +
  theme unlock + reset (see Collectibles & Levels; next milestone).
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

## Collectibles & Levels — REVISED 2026-06-16 (supersedes per-session collectible)
**Founder correction (confirmed, supersedes the locked "1 per completed block"):**
collectibles are **milestone** rewards, not per-session.
- A Flow Block session **does NOT** grant a collectible. Each session only earns
  **points** that move the overall Focus Score.
- When the **overall Focus Score reaches 100** → **level up**: grant **one hourglass
  collectible + a share card**, **unlock the next app theme**, and **reset the score
  to 0**. The next level is **harder** (progressive difficulty). Locked themes behind
  levels give a "veteran/experienced" progression.
- Completion screen (this build) therefore shows the **Focus Score (count-up) + the
  points earned this session** — NOT "hourglass collected." The level-up celebration
  (collect + share + theme unlock) is the **Level/Progression milestone** below.

**OPEN math question for the Level milestone (do NOT assume):** a literal "reset to 0"
does not sit naturally on a rolling average of the last 10 — a strong user's average
would climb straight back to ~100. Resolve when building Levels (options: reset the
score window after level-up; or treat 100 as a *progress bar* that fills from the
average and the bar resets while the underlying ability number persists; or apply
harder per-level scaling so the same performance yields fewer points). Confirm with
founder before implementing.

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

## Hourglass Lottery / gacha (founder, 2026-06-16 — FUTURE VERSION, recorded)
On each **level completion** the user gets a **wrapped** hourglass. **Unwrapping** it
(a reward-opening moment) reveals a **random themed hourglass** — each future theme has
its own hourglass design, so a collectible *represents the theme it unlocks*.
- Builds **anticipation** (you don't know which you'll get) and drives repeated use:
  unique themes — including **festival/seasonal themes** (Christmas, Halloween, etc.) —
  give people reasons to keep coming back.
- **Rarity tiers, RPG-style:** some themes are **very luck-based / hard to get** (like
  rare gun/clothing skins). A drop-rate/rarity table governs the gacha.
- Open design questions for that version: does the unwrapped theme = the one "unlocked,"
  or is the theme unlocked separately and the wrapped hourglass purely cosmetic-random?
  Duplicate handling (dupe protection / shards?), pity timer for rare drops, whether
  rarity is purely luck or partly effort-gated. Ethics: keep it free/earned (no paid
  loot-box mechanics) to stay on-brand and avoid dark patterns. Confirm before building.

## Roadmap (recorded; NOT this build)
1. **Level / Progression system (next milestone):** score→100 = level up → grant
   **hourglass collectible + share card**, **unlock a new app theme** (some themes
   locked behind levels), **reset score to 0**, raise difficulty. Resolve the
   rolling-average-vs-reset math (see Collectibles & Levels above). Needs the **theme
   system** in place. Numbered levels → "veteran" identity.
2. **Progressive difficulty:** higher levels average more blocks with **decaying
   weights** / harder scaling, so leveling takes more sustained focus.
3. **Share card:** shareable image of the milestone (level reached / hourglass).
4. **Streak effects:** at higher levels (~L3+), broken streaks pull the score down.
5. **Honesty / anti-idle checks.**
6. **PC / web versions** with **site/app/application blocking + activity monitoring**
   — the real work-verification.
7. **Profile screen:** displays the collected hourglasses + level history.

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
