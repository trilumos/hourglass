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
