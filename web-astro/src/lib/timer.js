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

function planFocus(plan) {
  return plan.filter(s => s.kind === 'focus').reduce((a, s) => a + s.dur, 0);
}

// Focus seconds actually elapsed so far (rest segments excluded). This is what
// "focused today" credits — never break time.
export function focusDone(plan, elapsedSec) {
  let acc = 0, focus = 0;
  for (const seg of plan) {
    if (elapsedSec <= acc) break;
    if (seg.kind === 'focus') focus += Math.min(elapsedSec - acc, seg.dur);
    acc += seg.dur;
  }
  return focus;
}

// Stateful controller. `now` is injectable for tests (defaults to Date.now).
export function createSession(now = Date.now) {
  const st = {
    mode: 'flow', opts: {}, plan: buildPlan('flow'),
    startedAt: null, pausedAt: null, pausedAccumMs: 0, running: false,
    flipBase: 0,   // endless-only: sand-block origin (seconds). Flip resets it so the glass refills, elapsed unaffected.
  };
  return {
    get state() { return st; },
    get mode() { return st.mode; },
    configure(mode, opts = {}) {
      st.mode = mode; st.opts = opts; st.plan = buildPlan(mode, opts);
      st.startedAt = null; st.pausedAt = null; st.pausedAccumMs = 0; st.running = false;
    },
    // Run an externally-built plan verbatim (Setup builds richer plans with plan.js). `plan` is
    // [{kind:'focus'|'rest', dur}] in SECONDS. mode is kept only so sample() knows 'endless'.
    setPlan(plan, mode = 'custom') {
      st.mode = mode; st.opts = {}; st.plan = plan;
      st.startedAt = null; st.pausedAt = null; st.pausedAccumMs = 0; st.running = false;
    },
    start() { st.startedAt = now(); st.pausedAt = null; st.pausedAccumMs = 0; st.running = true; st.flipBase = 0; },
    // Endless only: refill the glass now (reset the sand block) WITHOUT resetting the elapsed timer.
    flip() { if (st.mode === 'endless' && st.startedAt != null) st.flipBase = elapsedSeconds(st, now()); },
    // Jump the ENDLESS loop position forward to `target` seconds within the current block, without mutating the
    // plan (the block must keep looping at its chosen length). Only ever moves forward within one iteration.
    _endlessJumpTo(loopE, target) {
      const j = (target - loopE) * 1000;
      if (j <= 0) return false;
      st.startedAt -= j; if (st.pausedAt != null) st.pausedAt -= j;
      return true;
    },
    // Take your next break early. Endless: jump the loop to the block's rest (no mutation). Pomodoro/Custom: end
    // the CURRENT focus now by truncating it to the focus actually done (honest credit) so the rest begins now.
    skipToBreak() {
      if (st.startedAt == null) return false;
      const elapsed = elapsedSeconds(st, now());
      if (st.mode === 'endless') {
        const total = planDuration(st.plan) || 1, loopE = elapsed % total;
        let acc = 0;
        for (const seg of st.plan) { if (seg.kind === 'rest' && acc > loopE + 0.001) return this._endlessJumpTo(loopE, acc); acc += seg.dur; }
        return false;
      }
      let acc = 0;
      for (let i = 0; i < st.plan.length; i++) {
        const seg = st.plan[i];
        if (elapsed < acc + seg.dur || i === st.plan.length - 1) {
          if (seg.kind === 'focus' && i + 1 < st.plan.length && st.plan[i + 1].kind === 'rest') { seg.dur = Math.max(1, Math.floor(elapsed - acc)); return true; }
          return false;
        }
        acc += seg.dur;
      }
      return false;
    },
    // End the current rest early → focus resumes now. Endless: jump the loop to the rest's end (no mutation).
    skipBreak() {
      if (st.startedAt == null) return false;
      const elapsed = elapsedSeconds(st, now());
      const endless = st.mode === 'endless';
      const total = endless ? (planDuration(st.plan) || 1) : 0, ref = endless ? elapsed % total : elapsed;
      let acc = 0;
      for (let i = 0; i < st.plan.length; i++) {
        const seg = st.plan[i];
        if (ref < acc + seg.dur || (!endless && i === st.plan.length - 1)) {
          if (seg.kind !== 'rest') return false;
          if (endless) return this._endlessJumpTo(ref, acc + seg.dur);
          seg.dur = Math.max(1, Math.floor(elapsed - acc)); return true;
        }
        acc += seg.dur;
      }
      return false;
    },
    pause() { if (st.running && st.pausedAt == null) { st.pausedAt = now(); st.running = false; } },
    resume() {
      if (!st.running && st.pausedAt != null) {
        st.pausedAccumMs += now() - st.pausedAt; st.pausedAt = null; st.running = true;
      }
    },
    reset() { st.startedAt = null; st.pausedAt = null; st.pausedAccumMs = 0; st.running = false; },
    sample() {
      if (st.startedAt == null) {
        return { prog: 0, kind: 'idle', remainingSec: planFocus(st.plan), totalFocusSec: 0, focusSec: 0, done: false, endless: st.mode === 'endless' };
      }
      const elapsed = elapsedSeconds(st, now());
      if (st.mode === 'endless') {
        // Loop the chosen block [focus(, rest)] forever; count DOWN within the current segment; never "done".
        const total = planDuration(st.plan) || 1;
        const loopE = elapsed % total;
        const p = progressAt(st.plan, loopE);
        return {
          prog: p.kind === 'focus' ? p.segProg : 0,   // rest → full glass
          kind: p.kind,                                // 'focus' or 'rest' — breaks loop too
          remainingSec: p.segRemainingSec,             // counts down within the segment
          totalFocusSec: elapsed, focusSec: elapsed, done: false, endless: true,
        };
      }
      const p = progressAt(st.plan, elapsed);
      if (p.done) st.running = false;
      return {
        prog: p.kind === 'focus' ? p.segProg : 0,   // rest → full glass
        kind: p.done ? 'done' : p.kind,
        remainingSec: p.segRemainingSec,
        totalFocusSec: elapsed,
        focusSec: focusDone(st.plan, elapsed),
        done: p.done,
        endless: false,
      };
    },
  };
}
