# Sustain Web — Session Screen (v1) — Design Spec

> Status: approved in brainstorm 2026-07-26. Next: implementation plan (writing-plans).
> Related: [`2026-07-25-web-session-handoff.md`](2026-07-25-web-session-handoff.md) (superseded where noted),
> the number-treatment lab `web-prototype/number-lab.html` (locked, commit `002332b`),
> `site/setup.html` (locked), `site/js/plan.js` (timer math, 15 tests).

---

## 1. Goal

Build the real **session screen** — the running-focus page reached from Setup's *Begin*. v1 assembles the
pieces already built (the number treatment, `plan.js`, Setup's frost UI + audio engine) plus the new parts:
a **wall-clock timer engine**, **Pause/Resume/End** controls, and an in-session **⚙ settings panel**.

The **live animated scene** (falling sand + moving sun/moon) is **deferred** — v1 uses the **static plate**
(phase-selectable), exactly as the lab does. This keeps v1 focused on the timer + controls + settings.

## 2. Approach

One **self-contained `site/session.html`** (inline CSS + JS, no build step), mirroring `setup.html`:
- **Reuse** `site/js/plan.js` verbatim for focus/rest segments (`Plan.buildPlan`, `Plan.fmt`).
- **Port** the number treatment from `web-prototype/number-lab.html` — the 4 modes (Horizon/Middle/Ledge/Top),
  the auto-contrast (`setTone` + `sampleBg`), separators, fonts (self-hosted overlap-removed woff2), fills,
  the locked per-mode geometry from `web-prototype/timer-modes.json`. Move `assets/fonts/*` and the mattes
  into `site/assets/` so the session (served under `site/`) can reach them.
- **Port** Setup's Web-Audio engine (crossfade-stacking loop, per-sound mixer, master volume, ducking, limiter).

Rejected: extracting shared JS modules now (premature — the Astro migration handles that later; the locked
pattern is self-contained pages).

## 3. Layout & chrome

Full-bleed **static plate** (site-wide LOCKED plate rule: `inset:0; cover; 50% 50%`, fills viewport — identical
to Home/Setup). The **number treatment is the hero**. Chrome is minimal and **fades when idle** (reveals on
pointer-move / tap), so the hourglass owns the frame:

- **Bottom-centre (frost):** **Pause** ⇄ **Resume**, and **End**.
- **Top-right:** **⚙** settings button (opens the panel — same frosted sheet language as Setup's Advanced).
- Numbers honour the **visibility** setting: *Always · On hover · Hidden*.

## 4. Timer engine (full, plan-driven)

- **Source:** the Setup config (see §6). `Plan.buildPlan(st)` → an ordered list of `{kind:'focus'|'rest', min}`
  segments (Flow / Pomodoro / Custom / Endless).
- **Clock:** wall-clock accurate — elapsed = `Date.now() - startTs - pausedTotalMs`. Never accumulate rAF ticks
  (must stay correct when the tab is backgrounded). A rAF loop only *reads* elapsed to paint; a 1 Hz update
  refreshes the mm:ss text.
- **Display:** timed modes count **down** the remaining time of the current segment; **Endless** counts **up**
  (open focus).
- **Segment advance:** on a segment's completion, **auto-advance** to the next (focus↔rest) with a **soft cue**
  (gentle sound + a brief label, e.g. "Break · 5 min"). Rest segments auto-advance; the final focus completion
  → **done-state** (§5).
- **Endless:** user triggers a break/continue. Each cycle reset uses the **fade-flip** (§7).
- **Controls:** **Pause** freezes elapsed (accumulates `pausedTotalMs`), **Resume** continues, **End** stops and
  navigates to Setup (§6). Pause/Resume are the same button toggling label.
- **On completion:** increment `localStorage.sustain.focusedToday` (`{date, min}`, daily reset) — the number
  the Setup "Focused today" line reads. Then a calm done-state with **Again** / **End**.

## 5. Done-state

When the plan finishes (or the user Ends): a calm overlay — total focused this session, **Again** (restart the
same plan) and **End** (→ Setup). Minimal, centered, frost. No confetti.

## 6. Data flow (Setup ↔ Session)

- **Setup persists** its full config to `localStorage['sustain.session']` on **Begin** — the timer state
  (`{mode, flowMin, pomo…, custom…}` as `plan.js` consumes), the selected **sounds** + volumes, the **theme/
  phase** choice (follow-my-day vs a fixed phase), **timer visibility**, and the **number look** (§8).
- **Session reads** it on load, `buildPlan`s, applies the look + phase + sounds, and starts (after a Begin tap
  if we want an explicit start; v1: auto-start on load, since Setup's Begin was the intent to start).
- **End → Setup** (`setup.html`), carrying state (Setup re-reads `sustain.session` so selections persist).
- Building/testing standalone: if `sustain.session` is absent, the session falls back to a **default**
  (`{mode:'flow', flowMin:25}`, all sounds off, Follow-my-day, Middle mode) so the page runs on its own.

## 7. Endless "flip" — fade-through-black

Static plates can't animate a sand flip, so the Endless cycle-reset is a **screen crossfade through black**:
hourglass "empties" → **fade the scene to black** (~500 ms ease) → reset the hourglass/segment → **fade back in**
(~500 ms). Smooth, calm, image-friendly. Implemented as a full-screen black overlay whose opacity animates
0→1→0 around the reset instant. (Same technique is available for any hard reset; scoped to Endless in v1.)

## 8. ⚙ Settings panel (live, mid-session)

Frosted sheet (Setup's language). Four sections, all live:
1. **Sound** — the seascape sounds (Sand/Ocean/Breeze/Seabirds) as toggles, **master Volume**, **per-sound mixer**
   (only for selected sounds) — the ported engine.
2. **Timer visibility** — *Always · On hover · Hidden*.
3. **Number look** — Mode (Horizon/Middle/Ledge/Top), Font (Serif/Jost), Colour (picker), Separator
   (colon/dot/none, per-mode rules: Middle/Ledge=none, Top/Horizon=colon|dot). Each mode snaps to its locked
   geometry (`timer-modes.json`).
4. **Scene** — **Follow my day** (auto phase from the local clock) vs **pick a phase** (pre-dawn…midnight);
   **Auto-contrast** on/off.

Changes apply immediately and persist back to `localStorage['sustain.session']`.

## 9. Setup changes (it's "locked" — these are the deltas)

1. **Persist config** to `localStorage['sustain.session']` on **Begin** (currently Begin is a nav stub).
2. **Add the Number-look control** to Setup (so the clock style can be chosen before starting) — Mode/Font/
   Colour/Separator, mirroring §8.3. This **supersedes** Setup's old *Above / On-the-glass / Below* timer-position
   control (our 4 modes now define position): **remove** that old control and put the 4-mode picker in its place
   (in the Themes panel's timer-display area, where the position control lives today).

## 10. Non-goals (deferred — still session, later)

Live animated scene (falling sand driven by `S.prog`, moving sun/moon on the real clock) · Home hero +
Home→Setup→Session transitions · `/stage` chrome-less fullscreen (+`?record=1`) · PiP · share links ·
flip-to-start ritual on entry (v1 auto-starts).

## 11. Testing / verification

- Keep `plan.js --test` green.
- **Timer-accuracy check** (the critical one): a headless check that elapsed-from-timestamps equals expected
  across a simulated background gap (advance a fake clock, assert remaining is correct — no rAF drift).
- Pause/Resume math: `pausedTotalMs` accounting leaves total elapsed correct.
- Segment advance: focus→rest→focus transitions fire at the right elapsed marks for a known Pomodoro plan.
- Founder verifies visuals/feel on-device (per the Iron Rule division of labour).

## 12. Files

- **New:** `site/session.html` (self-contained).
- **Move:** `web-prototype/assets/fonts/*`, `web-prototype/assets/{hourglass,skyline}-matte.png` → `site/assets/`
  (so both setup/session reference one copy). Update paths.
- **Edit:** `site/setup.html` (§9), `site/js/plan.js` (only if a helper is missing — reuse as-is otherwise).
