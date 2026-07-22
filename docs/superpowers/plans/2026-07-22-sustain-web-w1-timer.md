# Sustain Web W1 — Phase 1a: The Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** turn the locked living-painting scene in `web-prototype/hybrid.html` into a real focus timer — a wall-clock ticker driving `S.prog`, four modes, a minimal session UI, the `[min]·🏺·[secs]` fade view, completion and a local "focused today" counter.

**Architecture:** the pure timer logic (segment plans + wall-clock elapsed + progress) lives in a new, DOM-free ES module `web-prototype/timer.js`, unit-tested in Node by `web-prototype/check-timer.js`. `hybrid.html` imports it, samples it once per animation frame, and writes the result to `S.prog` — which the existing locked sand renderer already turns into falling sand. Session state lives entirely in the timer module, **never in `S`** (so the `S`↔HTML slider contract that `check-wiring.py` enforces is untouched).

**Tech Stack:** vanilla ES modules, Canvas 2D + Three.js (existing), Node for tests (CommonJS, matching the repo's other `check-*.js`). No new dependencies. No framework — Astro migration is Phase 1b, a separate plan.

## Global Constraints

- **Keep all scene check scripts green** after every change to `hybrid.html`: `python check-wiring.py`, `node check-schedule.js`, `python check-glow.py`, `node check-bed.js`, `python check-stream.py`, `node check-pile.js`, plus `node --check` on the extracted module. Do not weaken a check to make a change pass (handoff rule).
- **No new `S` keys.** All session state lives in the `timer.js` module. The only `S` field the timer touches is the existing `S.prog` (already defined at `hybrid.html:703` and read at `hybrid.html:1472`).
- **Elapsed is always derived from wall-clock timestamps** (`Date.now()` minus paused time), never from accumulated animation frames — so a backgrounded/throttled tab stays accurate.
- **Do not change any locked scene value** (glass nodes, sand physics, sun/moon, day cycle). This phase only *drives* `S.prog` and adds UI; it does not retune the scene.
- **`web-prototype/` has no `package.json` and its Node checks are CommonJS** (`require`). Do **not** add `{"type":"module"}` — it would break `check-bed.js` / `check-pile.js` / `check-schedule.js`. `timer.js` is a browser ES module; `check-timer.js` loads it via `vm` after stripping `export`.
- **Serve + judge on a GPU browser:** `cd web-prototype && python -m http.server 8899 --bind 127.0.0.1`, open `http://localhost:8899/hybrid.html`. Headless cannot judge the scene; visual steps are founder-verified on GPU.
- **Commit messages** end with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: `timer.js` — the plan builder (`buildPlan`)

**Files:**
- Create: `web-prototype/timer.js`
- Create: `web-prototype/check-timer.js`

**Interfaces:**
- Produces: `MODES: string[]`; `buildPlan(mode: string, opts?: {workMin?, breakMin?, longBreakMin?, rounds?}): Segment[]` where `Segment = {kind: 'focus'|'rest', dur: number /* seconds */}`; `planDuration(plan): number`.

- [ ] **Step 1: Write the failing test** — create `web-prototype/check-timer.js`:

```js
// check-timer.js — asserts the pure timer logic in timer.js. CommonJS, like the
// other check-*.js. Loads the browser ES module by stripping `export` and
// evaluating it in a vm sandbox (the repo's extract-and-check convention).
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

const src = fs.readFileSync(__dirname + '/timer.js', 'utf8').replace(/\bexport\s+/g, '');
const ctx = { module: { exports: {} }, Math, Number, Error, Date, console };
vm.runInNewContext(src, ctx);
// top-level `function` declarations attach to the sandbox global; ones not yet
// added in this task just read back as undefined instead of throwing.
const { buildPlan, planDuration, progressAt, elapsedSeconds, createSession } = ctx;

let n = 0;
const ok = (c, m) => { assert.ok(c, m); n++; };

// buildPlan — Flow is one focus block
{
  const p = buildPlan('flow', { workMin: 25 });
  ok(p.length === 1 && p[0].kind === 'focus' && p[0].dur === 1500, 'flow = one 25m focus');
}
// buildPlan — Pomodoro 4 rounds: F R F R F R F, ends on focus, 3 short breaks
{
  const p = buildPlan('pomodoro', { workMin: 25, breakMin: 5, longBreakMin: 15, rounds: 4 });
  ok(p.length === 7, 'pomodoro 4 rounds = 7 segments');
  ok(p.filter(s => s.kind === 'focus').length === 4, '4 focus blocks');
  ok(p.filter(s => s.kind === 'rest').every(s => s.dur === 300), 'all 3 breaks short');
  ok(p[p.length - 1].kind === 'focus', 'ends on focus');
}
// buildPlan — Pomodoro long break lands on the 4th break (rounds 5)
{
  const rests = buildPlan('pomodoro', { rounds: 5 }).filter(s => s.kind === 'rest');
  ok(rests.length === 4 && rests[3].dur === 900, '4th break is the long break');
}
// buildPlan — Custom uses user values, no long-break rule
{
  const p = buildPlan('custom', { workMin: 50, breakMin: 10, rounds: 3 });
  ok(p.filter(s => s.kind === 'focus').every(s => s.dur === 3000), 'custom focus = 50m');
  ok(p.filter(s => s.kind === 'rest').every(s => s.dur === 600), 'custom breaks = 10m, none long');
}
// planDuration sums every segment
{
  ok(planDuration(buildPlan('pomodoro', { workMin: 25, breakMin: 5, rounds: 2 })) === 1500 + 300 + 1500,
     'planDuration sums segments');
}

console.log(`OK — ${n} timer assertions passed.`);
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd web-prototype && node check-timer.js`
Expected: FAIL — `ENOENT ... timer.js` (the module doesn't exist yet).

- [ ] **Step 3: Write the minimal implementation** — create `web-prototype/timer.js`:

```js
// timer.js — pure focus-timer logic for the Sustain web hourglass.
//
// A session is a list of focus/rest segments advanced by a WALL-CLOCK ticker.
// No DOM, no globals, no rendering — so it runs identically in the browser
// (imported by hybrid.html) and in Node (tested by check-timer.js). Elapsed is
// always derived from timestamps, never from accumulated frames, so a
// backgrounded/throttled tab stays accurate.

export const MODES = ['flow', 'pomodoro', 'custom', 'endless'];

const MIN = 60;
const clampMin = v => Math.max(1, Math.round(Number(v) || 0));

// Build the segment list for a mode. Durations are in SECONDS. Ends on focus
// (no trailing rest). opts: { workMin, breakMin, longBreakMin, rounds }.
export function buildPlan(mode, opts = {}) {
  const work = clampMin(opts.workMin ?? 25) * MIN;
  const brk = clampMin(opts.breakMin ?? 5) * MIN;
  const longBrk = clampMin(opts.longBreakMin ?? 15) * MIN;
  const rounds = clampMin(opts.rounds ?? 4);
  const F = dur => ({ kind: 'focus', dur });
  const R = dur => ({ kind: 'rest', dur });
  const cycle = longEvery => {
    const segs = [];
    for (let i = 0; i < rounds; i++) {
      segs.push(F(work));
      if (i < rounds - 1) segs.push(R(longEvery && (i + 1) % longEvery === 0 ? longBrk : brk));
    }
    return segs;
  };
  switch (mode) {
    case 'flow': return [F(work)];
    case 'pomodoro': return cycle(4);
    case 'custom': return cycle(0);      // user values, no long-break rule
    case 'endless': return [F(work)];    // single open block; the controller wraps it
    default: throw new Error('unknown mode: ' + mode);
  }
}

export function planDuration(plan) {
  return plan.reduce((a, s) => a + s.dur, 0);
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd web-prototype && node check-timer.js`
Expected: PASS — `OK — 9 timer assertions passed.`

- [ ] **Step 5: Commit**

```bash
git add web-prototype/timer.js web-prototype/check-timer.js
git commit -m "feat(web): timer.js buildPlan — 4 modes as segment lists

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: `timer.js` — progress + wall-clock elapsed

**Files:**
- Modify: `web-prototype/timer.js`
- Modify: `web-prototype/check-timer.js`

**Interfaces:**
- Consumes: `buildPlan`, `Segment` (Task 1).
- Produces: `progressAt(plan, elapsedSec): {index, kind, segProg, segRemainingSec, done}`; `elapsedSeconds(st, nowMs): number` where `st = {startedAt, pausedAt, pausedAccumMs}` (ms; `null` when unset).

- [ ] **Step 1: Write the failing tests** — append inside `check-timer.js`, before the final `console.log`:

```js
// progressAt — halfway through a single Flow block
{
  const r = progressAt(buildPlan('flow', { workMin: 10 }), 300); // 600s block
  ok(Math.abs(r.segProg - 0.5) < 1e-9 && r.kind === 'focus' && !r.done, 'flow half → segProg 0.5');
}
// progressAt — inside the rest segment resolves to that rest
{
  const p = buildPlan('pomodoro', { workMin: 25, breakMin: 5, rounds: 2 }); // F1500 R300 F1500
  const r = progressAt(p, 1500 + 150);
  ok(r.index === 1 && r.kind === 'rest' && Math.abs(r.segProg - 0.5) < 1e-9, 'mid-break → rest seg');
}
// progressAt — past the end → done, glass fully drained
{
  const r = progressAt(buildPlan('flow', { workMin: 1 }), 120); // 60s block, 120s in
  ok(r.done === true && Math.abs(r.segProg - 1) < 1e-9, 'past end → done, segProg 1');
}
// elapsedSeconds — wall-clock, correct across a background gap with zero ticks
{
  const st = { startedAt: 1000, pausedAt: null, pausedAccumMs: 0 };
  ok(Math.abs(elapsedSeconds(st, 1000 + 90000) - 90) < 1e-9, '90s wall-clock, no frames');
}
// elapsedSeconds — paused clock is frozen
{
  const st = { startedAt: 0, pausedAt: 30000, pausedAccumMs: 0 };
  ok(Math.abs(elapsedSeconds(st, 999999) - 30) < 1e-9, 'paused at 30s stays 30s');
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd web-prototype && node check-timer.js`
Expected: FAIL — `progressAt is not a function` (or `undefined`).

- [ ] **Step 3: Write the implementation** — append to `web-prototype/timer.js`:

```js
// Where a plan is at `elapsedSec`. Past the end of the last segment → done.
// Returns { index, kind, segProg (0..1), segRemainingSec, done }.
export function progressAt(plan, elapsedSec) {
  let acc = 0;
  for (let i = 0; i < plan.length; i++) {
    const seg = plan[i];
    if (elapsedSec < acc + seg.dur || i === plan.length - 1) {
      const into = Math.min(Math.max(elapsedSec - acc, 0), seg.dur);
      const done = i === plan.length - 1 && elapsedSec >= acc + seg.dur;
      return {
        index: i,
        kind: seg.kind,
        segProg: seg.dur ? into / seg.dur : 1,
        segRemainingSec: Math.max(seg.dur - into, 0),
        done,
      };
    }
    acc += seg.dur;
  }
  return { index: 0, kind: 'focus', segProg: 1, segRemainingSec: 0, done: true };
}

// Wall-clock elapsed for a running/paused session, in seconds. `st` carries the
// start timestamp, the pause timestamp (or null), and total paused ms.
export function elapsedSeconds(st, nowMs) {
  if (st.startedAt == null) return 0;
  const ref = st.pausedAt != null ? st.pausedAt : nowMs;
  return Math.max(0, (ref - st.startedAt - st.pausedAccumMs) / 1000);
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd web-prototype && node check-timer.js`
Expected: PASS — `OK — 14 timer assertions passed.`

- [ ] **Step 5: Commit**

```bash
git add web-prototype/timer.js web-prototype/check-timer.js
git commit -m "feat(web): timer.js progressAt + wall-clock elapsedSeconds

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: `timer.js` — the `createSession` controller

**Files:**
- Modify: `web-prototype/timer.js`
- Modify: `web-prototype/check-timer.js`

**Interfaces:**
- Consumes: `buildPlan`, `progressAt`, `elapsedSeconds` (Tasks 1–2).
- Produces: `createSession(now = Date.now)` → controller with `configure(mode, opts)`, `start()`, `pause()`, `resume()`, `reset()`, `sample()`. `sample()` returns `{prog, kind: 'idle'|'focus'|'rest'|'done', remainingSec, totalFocusSec, done, endless}`. `prog` is what `hybrid.html` writes to `S.prog`: the focus segment's drain fraction (0→1), `0` during rest/idle, and a wrapping fraction in Endless.

- [ ] **Step 1: Write the failing tests** — append inside `check-timer.js`, before the final `console.log`:

```js
// createSession — start/pause/resume with an injected clock; pause is not counted
{
  let t = 0; const s = createSession(() => t);
  s.configure('flow', { workMin: 10 });
  ok(s.sample().kind === 'idle' && s.sample().prog === 0, 'idle before start: glass full');
  t = 0; s.start();
  t = 20000; ok(Math.abs(s.sample().totalFocusSec - 20) < 1e-9, '20s in');
  s.pause(); t = 120000; ok(Math.abs(s.sample().totalFocusSec - 20) < 1e-9, 'paused: still 20s');
  s.resume(); t = 125000; ok(Math.abs(s.sample().totalFocusSec - 25) < 1e-9, 'resumed: 25s, pause skipped');
}
// createSession — rest segment shows a full glass (prog 0)
{
  let t = 0; const s = createSession(() => t);
  s.configure('pomodoro', { workMin: 25, breakMin: 5, rounds: 2 });
  t = 0; s.start(); t = (1500 + 150) * 1000; // 150s into the break
  const r = s.sample();
  ok(r.kind === 'rest' && r.prog === 0, 'during rest: glass full');
}
// createSession — Endless wraps (refills) and never finishes
{
  let t = 0; const s = createSession(() => t);
  s.configure('endless', { workMin: 1 }); // 60s block
  t = 0; s.start(); t = 90000; // 1.5 blocks
  const r = s.sample();
  ok(!r.done && r.endless && Math.abs(r.prog - 0.5) < 1e-6, 'endless wraps to 0.5, not done');
  ok(Math.abs(r.totalFocusSec - 90) < 1e-9, 'endless counts total focus');
}
// createSession — a finished plan reports done and a drained glass
{
  let t = 0; const s = createSession(() => t);
  s.configure('flow', { workMin: 1 }); t = 0; s.start(); t = 120000;
  const r = s.sample();
  ok(r.done && r.kind === 'done' && Math.abs(r.prog - 1) < 1e-9, 'flow finished: done, drained');
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd web-prototype && node check-timer.js`
Expected: FAIL — `createSession is not a function`.

- [ ] **Step 3: Write the implementation** — append to `web-prototype/timer.js`:

```js
function planFocus(plan) {
  return plan.filter(s => s.kind === 'focus').reduce((a, s) => a + s.dur, 0);
}

// Stateful controller. `now` is injectable for tests (defaults to Date.now).
export function createSession(now = Date.now) {
  const st = {
    mode: 'flow', opts: {}, plan: buildPlan('flow'),
    startedAt: null, pausedAt: null, pausedAccumMs: 0, running: false,
  };
  return {
    get state() { return st; },
    get mode() { return st.mode; },
    configure(mode, opts = {}) {
      st.mode = mode; st.opts = opts; st.plan = buildPlan(mode, opts);
      st.startedAt = null; st.pausedAt = null; st.pausedAccumMs = 0; st.running = false;
    },
    start() { st.startedAt = now(); st.pausedAt = null; st.pausedAccumMs = 0; st.running = true; },
    pause() { if (st.running && st.pausedAt == null) { st.pausedAt = now(); st.running = false; } },
    resume() {
      if (!st.running && st.pausedAt != null) {
        st.pausedAccumMs += now() - st.pausedAt; st.pausedAt = null; st.running = true;
      }
    },
    reset() { st.startedAt = null; st.pausedAt = null; st.pausedAccumMs = 0; st.running = false; },
    sample() {
      if (st.startedAt == null) {
        return { prog: 0, kind: 'idle', remainingSec: planFocus(st.plan), totalFocusSec: 0, done: false, endless: st.mode === 'endless' };
      }
      const elapsed = elapsedSeconds(st, now());
      if (st.mode === 'endless') {
        const block = st.plan[0].dur;
        return { prog: (elapsed % block) / block, kind: 'focus', remainingSec: block - (elapsed % block), totalFocusSec: elapsed, done: false, endless: true };
      }
      const p = progressAt(st.plan, elapsed);
      if (p.done) st.running = false;
      return {
        prog: p.kind === 'focus' ? p.segProg : 0,   // rest → full glass
        kind: p.done ? 'done' : p.kind,
        remainingSec: p.segRemainingSec,
        totalFocusSec: elapsed,
        done: p.done,
        endless: false,
      };
    },
  };
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `cd web-prototype && node check-timer.js`
Expected: PASS — `OK — 22 timer assertions passed.`

- [ ] **Step 5: Commit**

```bash
git add web-prototype/timer.js web-prototype/check-timer.js
git commit -m "feat(web): timer.js createSession controller (start/pause/resume/sample)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Drive `S.prog` from the session in the render loop

**Files:**
- Modify: `web-prototype/hybrid.html` (import at :613; `session` decl after the `S` literal ~:725; `updateSession()` + loop call ~:2185; move the `prog` slider markup :56–57 into the lock group at :62)

**Interfaces:**
- Consumes: `createSession` (Task 3).
- Produces: a module-scope `const session = createSession();` and a hoisted `function updateSession()` that writes `S.prog` each frame when a session is active.

- [ ] **Step 1: Add the import** — in `hybrid.html`, immediately after line 613 (`import * as THREE from 'three';`):

```js
import { createSession, MODES } from './timer.js';
```

- [ ] **Step 2: Create the controller** — in `hybrid.html`, immediately after the `S = { ... };` literal closes (around line 725, the line after `moonGlowCol` / the S object's closing `};`):

```js
// ── The focus timer. Session state lives here, never in S (which is the
// slider-bound render-param object). The loop samples this and writes S.prog.
const session = createSession();
```

- [ ] **Step 3: Add `updateSession` and call it in the loop** — in `hybrid.html`, change the loop body (currently lines 2185–2196). Add the function just above `function loop(now){`:

```js
function updateSession(){
  const r = session.sample();
  if (r.kind !== 'idle') S.prog = r.prog;   // idle leaves the debug slider in control
  if (typeof updateSessionUI === 'function') updateSessionUI(r);   // wired in Tasks 5–7
}
```

Then insert the call inside `loop`, right after `updateDayCycle();`:

```js
function loop(now){ tSec+=(now-t0)/1000; t0=now;
  updateDayCycle();
  updateSession();
  U.uTime.value=tSec; renderer.render(scene,cam);
```

- [ ] **Step 4: Move the manual `prog` slider into the debug lock group** — in `hybrid.html`, delete these two lines from the `Session` panel (currently 56–57):

```html
  <label>Progress <b id="vProg">0.35</b></label>
  <input type="range" id="prog" min="0" max="1" step="0.0005" value="0.35">
```

and paste them back in immediately after the `<div class="lockgrp hid">` line (currently 62), so `prog` becomes a hidden debug control. Leave `bind('prog','vProg','prog',v=>v.toFixed(2));` (line 1870) exactly as-is — it stays wired (so `check-wiring.py` passes), and it now only takes effect when no session is running.

- [ ] **Step 5: Run the scene checks + timer test**

Run:
```bash
cd web-prototype
node check-timer.js
python check-wiring.py
node check-schedule.js && python check-glow.py && node check-bed.js && python check-stream.py && node check-pile.js
```
Expected: every one prints its `OK` line and exits 0. `check-wiring.py` in particular must still print `OK - every S key has a default and every bind is wired.` (the `prog` slider moved but is still bound).

- [ ] **Step 6: Extract-and-syntax-check the module**

Run (from `web-prototype`):
```bash
python -c "import re,io;s=io.open('hybrid.html',encoding='utf-8').read();m=re.search(r'<script type=\"module\">(.*?)</script>',s,re.S).group(1);io.open('_mod.mjs','w',encoding='utf-8').write(m)" && node --check _mod.mjs && rm _mod.mjs
```
Expected: no output, exit 0 (the module parses; catches a stray-backtick/brace truncation).

- [ ] **Step 7: Manual GPU verification** *(founder, on the GPU browser)*

Serve and open `hybrid.html`. In DevTools console run `session.configure('flow',{workMin:1}); session.start();` and confirm the sand drains smoothly from full to empty over ~1 minute, the day cycle keeps running independently, and no red error banner appears. Then `session.reset();` — the debug `prog` slider (under the lock) drives the sand again.

- [ ] **Step 8: Commit**

```bash
git add web-prototype/hybrid.html
git commit -m "feat(web): drive S.prog from the focus session each frame

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: The session setup UI (modes + duration + Begin/Pause/Reset)

**Files:**
- Modify: `web-prototype/hybrid.html` (new `#session-ui` overlay in the `<body>`; its CSS in the `<style>`; its wiring at the end of the module script, before the render loop)

**Interfaces:**
- Consumes: `session` (Task 4), `MODES` (Task 3).
- Produces: `cfg` (the live `{workMin, breakMin, longBreakMin, rounds}` from the inputs); `startSession()`, `togglePause()`, `resetSession()` wired to the buttons; enters setup with `S.prog = 0` (full glass).

- [ ] **Step 1: Add the overlay markup** — in `hybrid.html`, immediately after `<div id="err"></div>` (line 50):

```html
<div id="session-ui">
  <div class="modes">
    <button class="mode on" data-mode="flow">Flow</button>
    <button class="mode" data-mode="pomodoro">Pomodoro</button>
    <button class="mode" data-mode="custom">Custom</button>
    <button class="mode" data-mode="endless">Endless</button>
  </div>
  <div class="durs">
    <label id="wWrap">Focus <input type="number" id="workMin" min="1" max="180" value="25"> min</label>
    <label id="bWrap">Break <input type="number" id="breakMin" min="1" max="60" value="5"> min</label>
    <label id="rWrap">Rounds <input type="number" id="rounds" min="1" max="12" value="4"></label>
  </div>
  <div class="ctrls">
    <button id="beginBtn">Begin</button>
    <button id="pauseBtn" hidden>Pause</button>
    <button id="resetBtn" hidden>Reset</button>
  </div>
</div>
```

- [ ] **Step 2: Add the styles** — in the `<style>` block (before `</style>`, line 41). Prototype styling only (Phase 1b builds the polished version):

```css
  #session-ui { position:fixed; left:50%; bottom:5%; transform:translateX(-50%);
                z-index:15; display:flex; flex-direction:column; gap:10px; align-items:center;
                font-size:13px; color:#e6ebf2; text-align:center; }
  #session-ui .modes { display:flex; gap:6px; }
  #session-ui .mode { width:auto; margin:0; padding:6px 12px; background:rgba(8,10,16,.6);
                      color:#aab3c2; border:1px solid rgba(255,255,255,.14); font-weight:600; }
  #session-ui .mode.on { background:#EACA78; color:#141414; border-color:#EACA78; }
  #session-ui .durs { display:flex; gap:14px; align-items:center; }
  #session-ui .durs label { display:inline-flex; gap:6px; align-items:center; color:#c3ccda; }
  #session-ui .durs input { width:52px; background:rgba(8,10,16,.6); color:#fff;
                            border:1px solid rgba(255,255,255,.16); border-radius:5px; padding:4px 6px;
                            font:inherit; text-align:center; }
  #session-ui .ctrls { display:flex; gap:8px; }
  #session-ui .ctrls button { width:auto; margin:0; padding:8px 22px; }
  #session-ui.running .durs, #session-ui.running .modes { display:none; }
```

- [ ] **Step 3: Wire it up** — in `hybrid.html`, near the end of the module script (before `fit();` on line 2179), add:

```js
// ── Session setup UI ────────────────────────────────────────────────────────
const cfg = { workMin:25, breakMin:5, longBreakMin:15, rounds:4 };
const sUI = $('session-ui');
function syncDurFields(mode){
  // Flow/Endless: focus only. Pomodoro/Custom: focus + break + rounds.
  const many = (mode === 'pomodoro' || mode === 'custom');
  $('bWrap').style.display = many ? '' : 'none';
  $('rWrap').style.display = many ? '' : 'none';
  $('wWrap').firstChild.textContent = mode === 'endless' ? 'Block ' : 'Focus ';
}
let curMode = 'flow';
sUI.querySelectorAll('.mode').forEach(btn => btn.addEventListener('click', () => {
  sUI.querySelectorAll('.mode').forEach(b => b.classList.remove('on'));
  btn.classList.add('on');
  curMode = btn.dataset.mode;
  syncDurFields(curMode);
}));
$('workMin').addEventListener('input', e => { cfg.workMin = +e.target.value || 1; });
$('breakMin').addEventListener('input', e => { cfg.breakMin = +e.target.value || 1; });
$('rounds').addEventListener('input', e => { cfg.rounds = +e.target.value || 1; });

function startSession(){
  session.configure(curMode, cfg);
  session.start();
  sUI.classList.add('running');
  $('beginBtn').hidden = true; $('pauseBtn').hidden = false; $('resetBtn').hidden = false;
  $('pauseBtn').textContent = 'Pause';
}
function togglePause(){
  const st = session.state;
  if (st.running) { session.pause(); $('pauseBtn').textContent = 'Resume'; }
  else { session.resume(); $('pauseBtn').textContent = 'Pause'; }
}
function resetSession(){
  session.reset(); S.prog = 0;
  sUI.classList.remove('running');
  $('beginBtn').hidden = false; $('pauseBtn').hidden = true; $('resetBtn').hidden = true;
}
$('beginBtn').addEventListener('click', startSession);
$('pauseBtn').addEventListener('click', togglePause);
$('resetBtn').addEventListener('click', resetSession);
syncDurFields('flow');
S.prog = 0;   // idle = full glass, ready to begin
```

- [ ] **Step 4: Run all checks**

Run (from `web-prototype`): `node check-timer.js && python check-wiring.py && node check-schedule.js && python check-glow.py && node check-bed.js && python check-stream.py && node check-pile.js`
Expected: all `OK`. `check-wiring.py` must still pass — the three new number `<input>`s (`workMin`, `breakMin`, `rounds`) each have an `addEventListener('input')`, which the input-scan accepts.

- [ ] **Step 5: Extract-and-syntax-check** (same command as Task 4 Step 6). Expected: exit 0.

- [ ] **Step 6: Manual GPU verification** *(founder)*

Reload. Pick each mode; confirm the duration fields show/hide correctly (Flow/Endless → focus only; Pomodoro/Custom → focus+break+rounds). Begin a 1-minute Flow: the sand drains, `Pause`/`Reset` appear. Pause holds the sand; Resume continues; Reset returns to a full glass + setup. No error banner.

- [ ] **Step 7: Commit**

```bash
git add web-prototype/hybrid.html
git commit -m "feat(web): session setup UI — modes, durations, Begin/Pause/Reset

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: The `[min]·🏺·[secs]` fade session view + visibility setting

**Files:**
- Modify: `web-prototype/hybrid.html` (number overlay markup + CSS; `updateSessionUI` + visibility wiring in the module script)

**Interfaces:**
- Consumes: the `r` sample object passed by `updateSession()` (Task 4).
- Produces: a global `updateSessionUI(r)` (picked up by the `typeof` guard added in Task 4) that writes the flanking minute/second readouts; a `timerVis` setting (`'hover' | 'always' | 'flash'`, default `'hover'`).

- [ ] **Step 1: Add the number overlay** — in `hybrid.html`, inside `<div id="frame">` (line 45–48), after the two canvases:

```html
    <span id="mm" class="clocknum">25</span>
    <span id="ss" class="clocknum">00</span>
```

- [ ] **Step 2: Add styles** — in `<style>`:

```css
  .clocknum { position:absolute; top:50%; transform:translateY(-50%); z-index:14;
              font-size:clamp(28px,5vw,64px); font-weight:200; color:#f2f5fa;
              font-variant-numeric:tabular-nums; letter-spacing:.02em; pointer-events:none;
              text-shadow:0 2px 18px rgba(0,0,0,.45); opacity:0; transition:opacity .6s ease; }
  #mm { right:calc(50% + 90px); }   /* flank the hourglass */
  #ss { left:calc(50% + 90px); }
  #frame.show-nums .clocknum { opacity:.92; }
```

- [ ] **Step 3: Add `updateSessionUI` + visibility wiring** — in the module script, after the Task 5 block (before `fit();`):

```js
// ── The [min] · hourglass · [secs] readout (hidden, fades in on move) ────────
const frameEl = $('frame');
let timerVis = 'hover', hideTimer = 0;
const pad = n => String(Math.max(0, n | 0)).padStart(2, '0');
function updateSessionUI(r){
  const secs = (r.endless ? r.totalFocusSec : r.remainingSec) | 0;
  $('mm').textContent = pad(secs / 60 | 0);
  $('ss').textContent = pad(secs % 60);
  if (r.done) revealNums();   // always show the final 00 · drained glass
}
function revealNums(){
  frameEl.classList.add('show-nums');
  if (timerVis === 'hover') {
    clearTimeout(hideTimer);
    hideTimer = setTimeout(() => frameEl.classList.remove('show-nums'), 1600);
  }
}
window.addEventListener('mousemove', () => { if (timerVis === 'hover') revealNums(); });
function applyVis(){
  if (timerVis === 'always') { clearTimeout(hideTimer); frameEl.classList.add('show-nums'); }
  else if (timerVis === 'hover') frameEl.classList.remove('show-nums');
  else /* flash */ { frameEl.classList.remove('show-nums'); }
}
// flash: reveal briefly once a minute
setInterval(() => { if (timerVis === 'flash' && session.state.running) { revealNums(); setTimeout(() => frameEl.classList.remove('show-nums'), 1600); } }, 60000);
```

- [ ] **Step 4: Add a visibility toggle to the setup UI** — in the `#session-ui` markup (Task 5 Step 1), add after the `.ctrls` div:

```html
  <div class="vis">
    <button class="visbtn on" data-vis="hover">Show on hover</button>
    <button class="visbtn" data-vis="always">Always</button>
    <button class="visbtn" data-vis="flash">Flash / min</button>
  </div>
```

and its wiring, in the Task 5 JS block (after the button listeners):

```js
sUI.querySelectorAll('.visbtn').forEach(btn => btn.addEventListener('click', () => {
  sUI.querySelectorAll('.visbtn').forEach(b => b.classList.remove('on'));
  btn.classList.add('on'); timerVis = btn.dataset.vis; applyVis();
}));
```

with matching CSS (in `<style>`):

```css
  #session-ui .vis { display:flex; gap:6px; }
  #session-ui .visbtn { width:auto; margin:0; padding:4px 10px; font-size:11px; font-weight:600;
                        background:rgba(8,10,16,.5); color:#8b95a6; border:1px solid rgba(255,255,255,.12); }
  #session-ui .visbtn.on { color:#EACA78; border-color:rgba(234,202,120,.5); }
```

- [ ] **Step 5: Run all checks** (same set as Task 5 Step 4). Expected: all `OK`. `.visbtn`/`.mode` are `<button>`s, not `<input>`s, so `check-wiring.py`'s input scan is unaffected.

- [ ] **Step 6: Extract-and-syntax-check** (Task 4 Step 6 command). Expected: exit 0.

- [ ] **Step 7: Manual GPU verification** *(founder)*

Begin a Flow session with "Show on hover": numbers are hidden, fade in on mouse move, fade out after ~1.6s. Switch to "Always": numbers stay. The minute/second values flank the hourglass and count down. No error banner.

- [ ] **Step 8: Commit**

```bash
git add web-prototype/hybrid.html
git commit -m "feat(web): [min] hourglass [secs] fade view + visibility setting

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: Completion, "focused today", and the Endless refill

**Files:**
- Modify: `web-prototype/hybrid.html` (completion handling in `updateSessionUI`; a `#focused-today` readout; the Endless sand-refill transition)

**Interfaces:**
- Consumes: the `r` sample (Task 4), `frameEl`/`sUI` (Tasks 5–6).
- Produces: `bumpFocusedToday(sec)` (localStorage, resets daily); a completion state; a wrap-detecting refill on the `#sand` canvas.

- [ ] **Step 1: Add the "focused today" readout** — in the `#session-ui` markup, as the first child (before `.modes`):

```html
  <div id="focused-today"></div>
```

with CSS:

```css
  #focused-today { font-size:12px; color:#9fb0c8; min-height:14px; }
  #sand.refill { transition:opacity .45s ease; opacity:0; }
```

- [ ] **Step 2: Add the counter + completion + refill logic** — in the module script, after the Task 6 block:

```js
// ── "Focused today" — localStorage only, resets on date change ───────────────
function focusedTodayKey(){ return 'sustain.focusedToday.' + new Date().toDateString(); }
function bumpFocusedToday(sec){
  const k = focusedTodayKey();
  const v = (+localStorage.getItem(k) || 0) + Math.round(sec);
  localStorage.setItem(k, v); renderFocusedToday();
}
function renderFocusedToday(){
  const v = +localStorage.getItem(focusedTodayKey()) || 0;
  $('focused-today').textContent = v >= 60 ? `Focused today · ${Math.round(v/60)} min` : '';
}
renderFocusedToday();

// ── Completion + Endless refill, both detected from the per-frame sample ─────
let wasDone = false, lastProg = 0, sandEl = $('sand');
function onSampleExtras(r){
  // Endless refill: prog just wrapped high→low → a brief fade so it reads as a flip.
  if (r.endless && r.prog < lastProg - 0.5) {
    sandEl.classList.add('refill');
    setTimeout(() => sandEl.classList.remove('refill'), 460);
  }
  lastProg = r.prog;
  // Completion: fires once on the done edge.
  if (r.done && !wasDone) {
    wasDone = true;
    bumpFocusedToday(r.totalFocusSec);
    sUI.classList.remove('running');
    $('pauseBtn').hidden = true; $('resetBtn').hidden = true;
    $('beginBtn').hidden = false; $('beginBtn').textContent = 'Begin again';
    $('focused-today').textContent = 'Done. ' + ($('focused-today').textContent || 'Nice session.');
  }
  if (!r.done) wasDone = false;
}
```

- [ ] **Step 3: Call it from `updateSessionUI`** — add one line at the end of `updateSessionUI(r)` (Task 6 Step 3):

```js
  onSampleExtras(r);
```

Also reset the `Begin` label in `resetSession()` (Task 5 Step 3) — add after `S.prog = 0;`:

```js
  $('beginBtn').textContent = 'Begin'; wasDone = false;
```

*(Note: `resetSession` references `wasDone`, declared in the Task 7 block above it in source order — since `resetSession` is only ever called from a click handler at runtime, this is safe; but to satisfy `check-wiring.py`'s top-level TDZ scan, ensure the `let wasDone` line sits ABOVE the `resetSession` function in the file. If Task 5's block is earlier, move the `let wasDone = false, lastProg = 0, sandEl = $('sand');` line up to just under the Task 5 `cfg` declaration.)*

- [ ] **Step 4: Run all checks** (Task 5 Step 4 set). Expected: all `OK`, including `check-wiring.py` (no new `S` keys, no unbound inputs, no TDZ).

- [ ] **Step 5: Extract-and-syntax-check** (Task 4 Step 6 command). Expected: exit 0.

- [ ] **Step 6: Manual GPU verification** *(founder)*

- Run a 1-minute Flow to completion: at 00:00 the glass is drained, "Done." + "Focused today · 1 min" shows, and the button reads "Begin again". Reload and confirm "Focused today" persists for today.
- Run Endless with a 1-minute block: at each minute the sand briefly fades and refills (the flip stand-in) while the total keeps counting; it never reports done. (True grab-and-flip animation is deferred polish.)

- [ ] **Step 7: Commit**

```bash
git add web-prototype/hybrid.html
git commit -m "feat(web): session completion, focused-today counter, endless refill

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage (against `2026-07-22-sustain-web-w1-first-push-design.md` §4):**
- §4.2 segment-based engine, 4 modes → Tasks 1, 3. ✅
- §4.2 Endless = drain→refill (flip deferred) → Task 3 (`sample` wrap) + Task 7 (visual refill). ✅
- §4.2 wall-clock accuracy (not tick accumulation) → Task 2 `elapsedSeconds` + its tests. ✅
- §4.2 `S.prog` wiring; manual slider → debug → Task 4. ✅
- §4.2 day cycle keeps running independently → unchanged; verified in Task 4 Step 7. ✅
- §4.2 completion + "focused today"; breaks auto-advance; Endless user-triggered → Task 7; auto-advance is implicit (the plan runs rest segments inline, no stop) — Endless breaks are user-driven since Endless is a single open block. ✅
- §4.2 Begin (flip-to-start deferred) → Task 5 `beginBtn`. ✅
- §4.3 `[min]·🏺·[secs]` fade view + 3 visibility modes → Task 6. ✅
- §4.3 "focused today" localStorage → Task 7. ✅
- §5 verification: keep 6 scene checks + a timer check → every integration task runs all of them; the timer check is `check-timer.js` (Tasks 1–3). ✅
- **Out of this phase (correct):** `/stage` (§4.4), the Astro site/landing (§4.1 1b), theming config (§3) — all Phase 1b or later, not here.

**Placeholder scan:** none — every step has the exact command or full code.

**Type consistency:** `sample()` returns `{prog, kind, remainingSec, totalFocusSec, done, endless}` — consumed identically in Tasks 4, 6, 7. `buildPlan`/`progressAt`/`elapsedSeconds`/`createSession` names match across `timer.js` and `check-timer.js`. `cfg` keys (`workMin/breakMin/longBreakMin/rounds`) match `buildPlan`'s `opts`. ✅

---

*Next after 1a is founder-approved on GPU: Phase 1b — the Astro site (port scene+timer into an island, scroll landing with the persistent hourglass, `/stage`, SEO, deploy). Its own plan.*
