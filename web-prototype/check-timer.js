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

console.log(`OK — ${n} timer assertions passed.`);
