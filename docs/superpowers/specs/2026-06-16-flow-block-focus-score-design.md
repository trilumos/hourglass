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

## Focus Score (the core)
- **Definition:** the average focused length of your **most recent 10 Flow Block
  sessions** that lasted **≥ 2 minutes**. Flow-Block-only (Pomodoro/Custom never
  count).
- **Give-ups count:** a session's recorded length is the **actual minutes focused**,
  whether you completed the planned length, hit "give up", or left the app — as long
  as it's ≥ 2 min. Pushing longer raises the average; quitting early lowers it.
- **Drives the suggestion:** the suggested next Flow Block length = the Focus Score
  (a "meet or beat" target). New users with no history get a gentle starter
  (e.g. 25 min, the existing default).
- **Shown on Home** as the headline stat (your focus capacity), replacing the
  internal-only "Focus Stamina" as the user-facing number. (Stamina's recent-average
  idea is reused; window becomes 10 and give-up lengths are included.)

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
- New pure calculator `FocusScoreCalculator` (or extend `StaminaCalculator`): given
  recent Flow Block recorded lengths (oldest→newest), return the average of the last
  10 that are ≥ 2 min; default to the starter when empty. Unit-tested.
- A Riverpod `focusScoreProvider` (FutureProvider) loads Flow Block sessions via
  `SessionRepository` and computes the score; `suggestedFlowLengthProvider` becomes
  "= focus score" (with the starter fallback).
- `SessionRepository`/`AppDatabase` already store `recordedSeconds`, `mode`,
  `completed`, `abandoned` — sufficient. (No schema change; we just stop zeroing
  Flow Block lengths.)

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
- `FocusScoreCalculator`: recent-10 window, ignores < 2 min, ignores non-Flow,
  averages give-up + completed lengths, starter when empty.
- Recording: a given-up Flow Block records its actual length (not 0); a < 2 min end
  is uncounted; Pomodoro/Custom unaffected.
- Widget: Home shows the Focus Score; Session screen shows a give-up action.
- Session-controller tests updated for the Flow Block recording change.

## Out of scope (v1)
Levels & new hourglass art, progressive difficulty, streak penalties, anti-idle,
PC/web + blocking, the dedicated Profile screen (collection display lands there).
