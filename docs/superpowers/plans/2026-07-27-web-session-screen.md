# Session Screen (v1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `site/session.html` — the running-focus screen reached from Setup's *Begin* — with a wall-clock timer engine, Pause/Resume/End controls, and an in-session ⚙ settings panel.

**Architecture:** A self-contained static page (inline CSS/JS, no build step) mirroring `site/setup.html`. The **critical logic — the wall-clock timer engine — is extracted to a DOM-free, node-tested module `site/js/session-timer.js`** (same pattern as `site/js/plan.js`). The page reuses `plan.js` (segments), `session-timer.js` (the clock), and ports the number treatment (from `web-prototype/number-lab.html`) and the audio engine (from `site/setup.html`). Visual/feel is founder-verified on-device (Iron Rule); the timer math is machine-tested.

**Tech Stack:** Plain HTML/CSS/JS (ES2019, no framework), Web Audio API, CSS Masks, self-hosted woff2 fonts. Node for the two `--test` self-checks.

## Global Constraints

- **No build step, no new runtime dependency.** Self-contained page + `<script src>` includes only. (Astro migration is later.)
- **Ponytail:** laziest-that-works; reuse `plan.js`/setup audio/number-lab treatment verbatim where possible; shortest working diff.
- **LOCKED site-wide plate rule** (identical to Home/Setup): the plate fills the viewport, `object-fit:cover; object-position:50% 50%`, no transform/zoom. Never deviate.
- **Wall-clock rule:** elapsed = `now() - startTs - pausedMs`. NEVER accumulate rAF ticks (must survive tab-backgrounding). `now` is injectable for tests.
- **Locked number geometry** comes from `web-prototype/timer-modes.json` (verbatim): horizon `{size:20,gap:3cqw,weight:550,stretch:1,xPct:-30,yPct:-4.2}`, middle `{25,15cqw,550,1,x0,y4.84}`, top `{25,3cqw,550,1,x0,y-2.59}`, ledge `{25,15cqw,550,1,x0,y11.96}`. Top/Middle/Ledge X-locked to hourglass axis `--hg-cx:49.79%`.
- **Per-mode separator rule:** Middle & Ledge = `none`; Top & Horizon = `colon|dot`.
- **Visual consistency with Setup (non-negotiable):** Session must feel like the same product as `site/setup.html` — same frost material (`.frost` tokens, blur, borders, shadows), same type (MUJI/Jost UI + Newsreader/Jost numerals), same spacing scale, same control language (chips, sheets, buttons), same accent (`#EACA78`). Reuse Setup's CSS tokens/classes verbatim; do not invent a new visual style. When a component exists in Setup (sheet, chip row, frost button, sound mixer), copy it, don't re-style it.
- **git/GitHub = trilumos account.** Commit after each task. Serve for founder review: `python -m http.server 8000` from `site/` → `http://localhost:8000/session.html`.

---

## File structure

- **Create** `site/js/session-timer.js` — DOM-free timer engine over a plan's segment list; wall-clock elapsed, pause/resume, current-segment/remaining, done. Node `--test`. (~120 lines)
- **Create** `site/session.html` — the page: plate scene, ported number treatment, controls, done-state, ⚙ settings panel, ported audio. Uses `plan.js` + `session-timer.js`. (self-contained)
- **Modify** `site/setup.html` — persist config to `localStorage['sustain.session']` on Begin; replace the old *Above/On-glass/Below* position control with the 4-mode number-look picker.
- **Move** `web-prototype/assets/fonts/*.woff2` and `web-prototype/assets/{hourglass,skyline}-matte.png` → `site/assets/…` (one canonical copy both pages reference).

---

### Task 1: Move shared assets into `site/assets/`

**Files:**
- Move: `web-prototype/assets/fonts/*.woff2` → `site/assets/fonts/`
- Move: `web-prototype/assets/hourglass-matte.png`, `web-prototype/assets/skyline-matte.png` → `site/assets/`

- [ ] **Step 1: Copy the assets**

```bash
cd d:/Dev/Trilumos/hourglass
mkdir -p site/assets/fonts
cp web-prototype/assets/fonts/*.woff2 site/assets/fonts/
cp web-prototype/assets/hourglass-matte.png web-prototype/assets/skyline-matte.png site/assets/
```

- [ ] **Step 2: Verify they exist**

Run: `ls site/assets/fonts/ && ls site/assets/hourglass-matte.png site/assets/skyline-matte.png`
Expected: 10 woff2 files + the 2 mattes listed.

- [ ] **Step 3: Commit**

```bash
git add site/assets/fonts site/assets/hourglass-matte.png site/assets/skyline-matte.png
git commit -m "chore(web): move number-treatment fonts + mattes into site/assets"
```

---

### Task 2: Timer engine `site/js/session-timer.js` (DOM-free, node-tested)

**Files:**
- Create: `site/js/session-timer.js`
- Test: same file's `--test` block (pattern: `site/js/plan.js` lines ~158-181).

**Interfaces:**
- Consumes: a segment list from `Plan.buildPlan(st)` — `[{kind:'focus'|'rest', min:Number}, …]`.
- Produces: `SessionTimer.create(segments, opts)` → engine with methods below. `opts = { now?:()=>ms, endless?:bool }` (`now` defaults to `Date.now`; injectable for tests).
  - `start()` — records `startTs = now()`.
  - `pause()` / `resume()` — freeze/continue; `resume` accumulates paused time.
  - `elapsedMs()` — `now() - startTs - pausedMs - (paused ? now()-pauseStart : 0)`; `0` before start.
  - `progress()` — `{ done:Boolean, segIndex:Int, kind:'focus'|'rest', remainingMs:Int, elapsedMs:Int }`. Endless: always `{done:false, segIndex:0, kind:'focus', elapsedMs, remainingMs:0}`. Timed: maps `elapsedMs` onto segment durations; `done:true` when past the last segment.
  - `totalMs()` — sum of segment durations (0 for endless).

- [ ] **Step 1: Write the failing test block**

Create `site/js/session-timer.js` with ONLY the test block first (module body added in Step 3):

```javascript
// (place at bottom of file, after the module — written first for TDD)
if (typeof require !== 'undefined' && require.main === module) {
  var T = module.exports, n = 0, clock = 0, now = function () { return clock; };
  function ok(c, m) { n++; if (!c) { console.error('FAIL: ' + m); process.exit(1); } }
  var segs = [{kind:'focus',min:25},{kind:'rest',min:5},{kind:'focus',min:25}]; // 25+5+25 = 55 min

  // wall-clock accuracy across a backgrounded gap (no rAF drift)
  clock = 0; var e = T.create(segs, {now:now}); e.start();
  clock = 90000;                                  // jump 90s (as if tab was backgrounded)
  ok(e.elapsedMs() === 90000, 'elapsed tracks wall clock across a gap');

  // pause/resume math
  clock = 0; e = T.create(segs, {now:now}); e.start();
  clock = 10000; e.pause(); clock = 25000; e.resume(); // paused 15s
  clock = 30000;
  ok(e.elapsedMs() === 15000, 'pause/resume subtracts paused time (30s - 15s paused = 15s)');

  // segment mapping
  clock = 0; e = T.create(segs, {now:now}); e.start();
  clock = 24*60000; var p = e.progress();
  ok(p.segIndex===0 && p.kind==='focus' && p.remainingMs===60000, 'at 24m: focus seg0, 1m left');
  clock = 26*60000; p = e.progress();
  ok(p.segIndex===1 && p.kind==='rest', 'at 26m: rest seg1');
  clock = 31*60000; p = e.progress();
  ok(p.segIndex===2 && p.kind==='focus', 'at 31m: focus seg2');
  clock = 56*60000; p = e.progress();
  ok(p.done === true, 'at 56m: done');

  // endless counts up, never done
  clock = 0; e = T.create([{kind:'focus',min:0}], {now:now, endless:true}); e.start();
  clock = 999*60000; p = e.progress();
  ok(p.done===false && p.kind==='focus' && p.elapsedMs===999*60000, 'endless counts up, never done');

  console.log('session-timer: ' + n + ' checks passed');
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node site/js/session-timer.js --test`
Expected: FAIL — `TypeError: Cannot read properties of undefined (reading 'create')` (module not written yet).

- [ ] **Step 3: Write the minimal engine (module body, above the test block)**

```javascript
(function (root) {
  function create(segments, opts) {
    opts = opts || {};
    var now = opts.now || function () { return Date.now(); };
    var endless = !!opts.endless;
    var startTs = null, pausedMs = 0, pauseStart = null;
    function elapsedMs() {
      if (startTs == null) return 0;
      var live = pauseStart != null ? (now() - pauseStart) : 0;
      return now() - startTs - pausedMs - live;
    }
    function totalMs() {
      if (endless) return 0;
      return segments.reduce(function (a, s) { return a + s.min * 60000; }, 0);
    }
    function progress() {
      var e = elapsedMs();
      if (endless) return { done:false, segIndex:0, kind:'focus', remainingMs:0, elapsedMs:e };
      var acc = 0;
      for (var i = 0; i < segments.length; i++) {
        var segMs = segments[i].min * 60000;
        if (e < acc + segMs) return { done:false, segIndex:i, kind:segments[i].kind, remainingMs:(acc+segMs)-e, elapsedMs:e };
        acc += segMs;
      }
      return { done:true, segIndex:segments.length-1, kind:(segments[segments.length-1]||{}).kind, remainingMs:0, elapsedMs:e };
    }
    return {
      start:  function () { if (startTs == null) startTs = now(); },
      pause:  function () { if (pauseStart == null) pauseStart = now(); },
      resume: function () { if (pauseStart != null) { pausedMs += now() - pauseStart; pauseStart = null; } },
      elapsedMs: elapsedMs, totalMs: totalMs, progress: progress,
      isPaused: function () { return pauseStart != null; }
    };
  }
  var API = { create: create };
  if (typeof module !== 'undefined' && module.exports) module.exports = API;
  root.SessionTimer = API;
})(typeof window !== 'undefined' ? window : this);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `node site/js/session-timer.js --test`
Expected: `session-timer: 8 checks passed`

- [ ] **Step 5: Commit**

```bash
git add site/js/session-timer.js
git commit -m "feat(web): DOM-free wall-clock session-timer engine + node self-tests"
```

---

### Task 3: Session page skeleton — plate + config + plan + engine + 1 Hz tick

**Files:**
- Create: `site/session.html`
- Reference (read, don't modify): `site/setup.html` (head/frost/plate rule), `web-prototype/number-lab.html` (plate + `:root` tokens).

**Interfaces:**
- Consumes: `Plan.buildPlan(st)`, `SessionTimer.create(segments,{endless})`.
- Produces: a running page that reads `localStorage['sustain.session']` (or a default), builds a plan, starts the engine, and renders `mm:ss` updating every second.

- [ ] **Step 1: Scaffold `site/session.html`**

Create the file with: `<head>` copying Setup's meta + the **self-hosted @font-face block** for Jost/Newsreader (copy verbatim from `web-prototype/number-lab.html` `<style>` top, but change `url('assets/fonts/…')` → `url('assets/fonts/…')` — already correct under `site/`). Body:

```html
<div id="stage"><div id="scene">
  <div class="layer bg"></div>
  <div id="nums"><span class="tb">
    <span class="num" id="mm">25</span><span class="num" id="sep"></span><span class="num" id="ss">00</span>
  </span></div>
  <div class="layer fg fg-glass"></div>
  <div class="layer fg fg-ledge"></div>
  <div class="layer fg fg-horizon"></div>
</div></div>
<script src="js/plan.js"></script>
<script src="js/session-timer.js"></script>
<script> /* IIFE below */ </script>
```

Copy the **plate + scene + `.layer`/`.bg`/`.fg-*` CSS** and the number-treatment CSS (`:root` tokens, `.num`, fills, separators, `--hg-cx` placements, `--num-eff`) **verbatim** from `web-prototype/number-lab.html`. Copy the mask paths `assets/hourglass-matte.png` / `assets/skyline-matte.png` (correct under `site/`).

- [ ] **Step 2: Config load + plan + engine (page IIFE)**

```javascript
(function () {
  var S = document.getElementById('scene'), mm = document.getElementById('mm'), ss = document.getElementById('ss');
  var cfg = JSON.parse(localStorage.getItem('sustain.session') || 'null')
         || { mode:'flow', flowMin:25, place:'middle', phase:2, sounds:[], vol:100, sep:'none', font:"'Newsreader',serif", color:'#ffffff', vis:'always', followDay:true, autoContrast:true };
  var plan = Plan.buildPlan(cfg);
  var timer = SessionTimer.create(plan, { endless: cfg.mode === 'endless' });
  timer.start();
  var fmt2 = function (n) { return String(n).padStart(2,'0'); };
  function tick() {
    var p = timer.progress();
    var totalSec = cfg.mode === 'endless' ? Math.floor(p.elapsedMs/1000) : Math.ceil(p.remainingMs/1000);
    mm.textContent = fmt2(Math.floor(totalSec/60) % 100);
    ss.textContent = fmt2(totalSec % 60);
  }
  tick(); setInterval(tick, 250);   // 250ms so the seconds flip crisply; engine is wall-clock, not tick-accumulated
  // apply the static plate for cfg.phase (see Task 4 for setPlate); default midday for now:
  document.documentElement.style.setProperty('--plate', 'url("assets/plates/midday.jpg")');
})();
```

- [ ] **Step 3: Serve and founder-verify**

Run: `cd site && python -m http.server 8000` → open `http://localhost:8000/session.html`.
Expected: the midday plate fills the viewport; `25:00` counts down once per second. (Founder confirms visual.)

- [ ] **Step 4: Commit**

```bash
git add site/session.html
git commit -m "feat(web): session page skeleton — plate + plan + engine + 1Hz countdown"
```

---

### Task 4: Port the number treatment (4 modes, auto-contrast, phases, look-from-config)

**Files:**
- Modify: `site/session.html`
- Reference: `web-prototype/number-lab.html` (the treatment source).

**Interfaces:**
- Consumes: `cfg.{place,font,color,sep,vis,phase,followDay,autoContrast}`.
- Produces: `applyLook(cfg)` (sets mode/font/colour/sep + per-mode geometry from the locked table), `setPlate()` (phase → plate url + `sampleBg`), `sampleBg()`+`setTone()` (auto-contrast), `applySepForMode(mode)`, and `refreshFG()` (occluders per mode).

- [ ] **Step 1: Port the treatment JS**

From `web-prototype/number-lab.html` port **verbatim** (adapting `S`/`phase`/`hourglass` which already exist): the `PHASES`/`withHG` plate helpers, `refreshFG()`, `rgbOf`/`setTone`/`sampleBg` (auto-contrast, overall-luminance version), `applySepForMode`, and the **locked per-mode geometry** application. Add an `applyLook(cfg)` that sets `S.dataset.place=cfg.place; S.dataset.sep=cfg.sep; --num-font/--num-color`, then applies the locked `{size,gap,weight,stretch,--hg-cx,--tb-top,dx,dy}` for `cfg.place` from the `timer-modes.json` table (inline the table as a `const LOCKED = {…}` — copy the 4 objects verbatim). Wire `S.dataset.vis = cfg.vis`.

- [ ] **Step 2: Wire phase (Follow-my-day)**

```javascript
// map local clock hour -> phase index when cfg.followDay
function phaseFromClock(){ var h=new Date().getHours();
  return h<5?0 : h<8?1 : h<16?2 : h<19?3 : h<21?4 : 5; }   // predawn,sunrise,midday,sunset,twilight,midnight
var phase = cfg.followDay ? phaseFromClock() : (cfg.phase|0);
```
Call `setPlate()` (which sets `--plate` for `phase` and calls `sampleBg`) and `applyLook(cfg)` + `refreshFG()` + `applySepForMode(cfg.place)` at startup.

- [ ] **Step 3: Serve and founder-verify each mode/phase**

Manually set `localStorage['sustain.session']` in DevTools to each `place` (horizon/middle/ledge/top) and `phase`, reload. Expected: numbers sit at the locked positions, occluders correct per mode, auto-contrast lifts black on dark phases. (Founder confirms.)

- [ ] **Step 4: Commit**

```bash
git add site/session.html
git commit -m "feat(web): port number treatment (4 modes, auto-contrast, phases) into session"
```

---

### Task 5: Controls — Pause/Resume + End, fade-when-idle, done-state, focusedToday

**Files:**
- Modify: `site/session.html`

**Interfaces:**
- Consumes: `timer.pause/resume/isPaused`, `timer.progress().done`.
- Produces: `#controls` (Pause⇄Resume, End), `#done` overlay (Again/End), `bumpFocusedToday(min)`.

- [ ] **Step 1: Markup + frost CSS**

Add (frost class copied from Setup): bottom-centre `#controls` with `<button id="pause">Pause</button><button id="end">End</button>`; top-right `<button id="gear">⚙</button>` (panel wired in Task 7); a hidden `#done` overlay with total + `<button id="again">Again</button><button id="doneEnd">End</button>`. Chrome fades: `#controls,#gear{opacity:0;transition:opacity .4s}` and `body.active #controls, body.active #gear{opacity:1}`; a pointer-move handler adds `active` for 3s then removes.

- [ ] **Step 2: Wire controls**

```javascript
var pauseBtn = document.getElementById('pause');
pauseBtn.addEventListener('click', function () {
  if (timer.isPaused()) { timer.resume(); pauseBtn.textContent='Pause'; }
  else { timer.pause(); pauseBtn.textContent='Resume'; }
});
document.getElementById('end').addEventListener('click', endSession);
function endSession(){ location.href = 'setup.html'; }         // End -> Setup (state persists in localStorage)
```

- [ ] **Step 3: Done-state + focusedToday**

```javascript
function bumpFocusedToday(min){
  var k='sustain.focusedToday', today=new Date().toDateString();
  var o=JSON.parse(localStorage.getItem(k)||'null'); if(!o||o.date!==today) o={date:today,min:0};
  o.min += min; localStorage.setItem(k, JSON.stringify(o));
}
// in tick(): if timer.progress().done && !shownDone -> shownDone=true; bumpFocusedToday(Plan.totalFocusOf ? ... : plan focus min); show #done overlay.
```
Use `Plan`’s focus total: compute `var focusMin = plan.filter(function(s){return s.kind==='focus';}).reduce(function(a,s){return a+s.min;},0);` at start; call `bumpFocusedToday(focusMin)` once on done. `#again` restarts (`timer = SessionTimer.create(plan,…); timer.start(); shownDone=false; hide overlay`). `#doneEnd` → `endSession()`.

- [ ] **Step 4: Serve and founder-verify**

Verify pause freezes the countdown and resume continues; End returns to setup; a short Flow (set `flowMin:1`) reaches the done overlay and `sustain.focusedToday` increments. (Founder confirms.)

- [ ] **Step 5: Commit**

```bash
git add site/session.html
git commit -m "feat(web): session controls (pause/resume/end), done-state, focusedToday"
```

---

### Task 6: Segment auto-advance + soft cue + Endless fade-flip

**Files:**
- Modify: `site/session.html`

**Interfaces:**
- Consumes: `timer.progress().segIndex/kind`.
- Produces: segment-transition detection in `tick()`, `softCue(kind)`, `fadeFlip(cb)`.

- [ ] **Step 1: Segment transition + soft cue**

In `tick()`, track `lastSegIndex`; when `p.segIndex !== lastSegIndex` (and not done), call `softCue(p.kind)` and briefly show a label (`Break · 5 min` / `Focus`). `softCue` plays a gentle tone via the audio context (a short sine blip) — reuse the audio context created in Task 7; if audio not yet started, no-op.

- [ ] **Step 2: Endless fade-flip**

```javascript
// full-screen black overlay #flip { position:fixed; inset:0; background:#000; opacity:0; pointer-events:none; transition:opacity .5s }
function fadeFlip(reset){
  var f=document.getElementById('flip'); f.style.opacity='1';
  setTimeout(function(){ reset(); f.style.opacity='0'; }, 500);
}
```
For Endless: expose a "flip / new cycle" affordance (a tap on the scene, or an on-screen "Flip" control). On flip → `fadeFlip(function(){ timer = SessionTimer.create(plan,{endless:true}); timer.start(); })`. (v1 Endless is open focus; the flip resets the count with the fade-through-black — no sand animation.)

- [ ] **Step 3: Serve and founder-verify**

Pomodoro plan (`flowMin` small, e.g. 1-min focus / 1-min break, 2 blocks): confirm the label + soft cue at each focus↔rest boundary. Endless: confirm the fade-to-black → reset → fade-in on flip. (Founder confirms.)

- [ ] **Step 4: Commit**

```bash
git add site/session.html
git commit -m "feat(web): segment auto-advance + soft cue + Endless fade-flip"
```

---

### Task 7: ⚙ Settings panel (sound engine port + visibility + number-look + scene/auto-contrast)

**Files:**
- Modify: `site/session.html`
- Reference: `site/setup.html` (audio engine + frost sheet), `web-prototype/number-lab.html` (number-look controls).

**Interfaces:**
- Consumes: everything above.
- Produces: a frosted `#settings` sheet toggled by `#gear`, with the four sections; every change applies live and persists to `localStorage['sustain.session']` via `saveCfg()`.

- [ ] **Step 1: Port the audio engine**

Copy the Web-Audio engine **verbatim** from `site/setup.html` (the sound tokens, master volume, per-sound mixer, crossfade-stacking loop, ducking, limiter — the block the setup build spec calls the audio engine). Initialise it on first user gesture (browser autoplay policy). Feed it `cfg.sounds`/`cfg.vol`.

- [ ] **Step 2: Build the frost sheet + 4 sections**

Copy Setup's frosted-sheet CSS. Sections: **Sound** (toggles + volume + mixer — bound to the ported engine); **Timer visibility** (Always/On hover/Hidden → `S.dataset.vis`); **Number look** (Mode/Font/Colour picker/Separator — reuse the lab's chip handlers + `applyLook`/`applySepForMode`); **Scene** (Follow-my-day vs pick phase → `setPlate`; Auto-contrast toggle → `autoContrast` + `setTone`).

- [ ] **Step 3: Persist + live-apply**

```javascript
function saveCfg(){ localStorage.setItem('sustain.session', JSON.stringify(cfg)); }
// each control updates cfg.<field>, calls its apply fn, then saveCfg().
```

- [ ] **Step 4: Serve and founder-verify**

Open ⚙ mid-session: toggle sounds/volume (audible), flip visibility, change mode/font/colour/separator (numbers restyle live), switch phase + auto-contrast. Reload → settings persisted. (Founder confirms.)

- [ ] **Step 5: Commit**

```bash
git add site/session.html
git commit -m "feat(web): in-session settings panel (sound/visibility/number-look/scene)"
```

---

### Task 8: Setup edits — persist config on Begin + 4-mode number-look picker

**Files:**
- Modify: `site/setup.html`

**Interfaces:**
- Produces: on Begin, writes `localStorage['sustain.session']` from Setup's state (shape matching `cfg` in Task 3) and navigates to `session.html`; a Number-look picker replacing the old position control.

- [ ] **Step 1: Persist on Begin**

Find the Begin handler (`#begin`, currently a nav stub). On click: assemble `cfg` from Setup's internal state — `{mode, flowMin, pomo*, custom* (whatever plan.js consumes), sounds:[selected ids], vol, phase/followDay (from Themes), vis (from timer-display), place, font, color, sep (from the new number-look picker)}` — `localStorage.setItem('sustain.session', JSON.stringify(cfg))`, then `location.href='session.html'`.

- [ ] **Step 2: Replace the position control with the number-look picker**

In the Themes panel timer-display area (where *Above / On-the-glass / Below* lives — `grep 'On the glass' site/setup.html`), **remove** those three buttons and add a **Mode** picker (Horizon/Middle/Ledge/Top) + Font (Serif/Jost) + Colour (picker) + Separator (colon/dot/none, per-mode rule). Store into the Setup state that Step 1 serialises. (A small live preview is optional — the session is where it's seen.)

- [ ] **Step 3: Serve and founder-verify the round-trip**

Setup → choose mode/font/colour/sounds/timer → Begin → session opens with exactly those; End → back to Setup with selections intact. (Founder confirms.)

- [ ] **Step 4: Commit**

```bash
git add site/setup.html
git commit -m "feat(web): setup persists session config + 4-mode number-look picker (replaces position control)"
```

---

## Self-Review

**Spec coverage:** §2 approach → Tasks 1-4,7. §3 layout/chrome → Tasks 3,5. §4 engine → Task 2 (+ tick in 3, advance in 6). §5 done-state → Task 5. §6 data flow → Tasks 3,7,8. §7 fade-flip → Task 6. §8 settings → Task 7. §9 setup edits → Task 8. §11 testing → Task 2 (`session-timer --test`) + `plan.js --test` (unchanged). All covered.

**Placeholders:** none — engine + glue code is complete; ports name the exact source file + block to copy (actionable, not "similar to").

**Type consistency:** `SessionTimer.create(segments,opts)` → `progress()` shape `{done,segIndex,kind,remainingMs,elapsedMs}` used identically in Tasks 3/5/6. `cfg` shape defined in Task 3 and produced by Task 8. `applyLook/setPlate/setTone/sampleBg/applySepForMode/refreshFG` defined in Task 4 and consumed in Task 7. Consistent.

## Notes for the implementer

- The ports (Tasks 4, 7) copy large blocks from `web-prototype/number-lab.html` and `site/setup.html`. Copy them **verbatim first, then adapt paths/vars** — do not re-derive. Run the page after each port and diff behaviour against the source page.
- Visual correctness is **founder-verified** (Iron Rule): each task ends with a serve-and-confirm step, not an automated visual assert. The only machine tests are `node site/js/session-timer.js --test` and `node site/js/plan.js --test` (must stay green).
