// check-timer.js — asserts the pure timer logic in timer.js. CommonJS, like the
// other check-*.js. Loads the browser ES module by stripping `export` and
// running it in a vm sandbox; top-level `function` declarations attach to the
// sandbox global, so we read them straight off it (undefined ones just come back
// undefined — lets this file grow task-by-task without a fragile export list).
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

const src = fs.readFileSync(__dirname + '/timer.js', 'utf8').replace(/\bexport\s+/g, '');
const ctx = { module: { exports: {} }, Math, Number, Error, Date, console };
vm.runInNewContext(src, ctx);
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

console.log(`OK — ${n} timer assertions passed.`);
