// plan.js — Sustain session plan math.
// Faithful, DOM-free port of lib/session/session_plan.dart (via web-prototype/gen_setup.py).
// A plan is a list of {kind:'focus'|'rest', min}. The big readout and cadence subline are both
// computed from a real plan, exactly like the app. Reused by home/session later.
// Node self-test:  node js/plan.js --test
(function (root) {
  'use strict';

  var F = function (m) { return { kind: 'focus', min: m }; };
  var R = function (m) { return { kind: 'rest', min: m }; };

  // Defaults + ranges copied from the app.
  var RATIOS = [{ w: 25, s: 5, l: 15 }, { w: 50, s: 10, l: 20 }, { w: 52, s: 17, l: 25 }, { w: 90, s: 15, l: 30 }];
  var SOFT_CAP = 90, LONG_EVERY = 4, MIN_CHUNK = 5;
  var STEPS = {
    flowMin:        { d: 5,  min: 5,  max: 240 },
    pomoTarget:     { d: 15, min: 30, max: 360 },
    durBlocks:      { d: 1,  min: 1,  max: 12 },
    blocks:         { d: 1,  min: 1,  max: 16 },
    pomoFocus:      { d: 5,  min: 5,  max: 120 },
    pomoBreak:      { d: 1,  min: 1,  max: 60 },
    customWork:     { d: 15, min: 15, max: 480 },
    customBreaks:   { d: 1,  min: 0,  max: 12 },
    customInterval: { d: 5,  min: 10, max: 120 },
    customBreakLen: { d: 1,  min: 1,  max: 30 }
  };
  var DESC = {
    flow: 'One unbroken block of deep focus — recovery comes after.',
    pomodoro: 'Focus in cycles with short breaks between.',
    custom: 'Design your own focus-and-break schedule.',
    endless: 'Focus with no set end — you decide when to stop.'
  };

  // ── Plan builders ─────────────────────────────────────────────────────────
  function flowBlock(m) { return [F(m)]; }

  function pomodoroPlan(work, shortB, longB, blocks, longEvery) {
    longEvery = longEvery || LONG_EVERY;
    var s = [];
    for (var i = 0; i < blocks; i++) {
      s.push(F(work));
      if (i !== blocks - 1) {
        var n = i + 1;
        s.push(R(longEvery > 0 && n % longEvery === 0 ? longB : shortB));
      }
    }
    return s;
  }

  function flowmodoro(totalMin, blocks) {
    var base = blocks <= 0 ? 0 : Math.floor(totalMin / blocks);
    if (blocks <= 1 || base <= 0) return [F(totalMin)];
    var rem = totalMin - base * blocks;
    var rest = Math.min(60, Math.max(1, Math.round(base / 5)));
    var s = [];
    for (var i = 0; i < blocks; i++) {
      var last = i === blocks - 1;
      s.push(F(last ? base + rem : base));
      if (!last) s.push(R(rest));
    }
    return s;
  }

  function customByCount(totalMin, breaks, breakLen) {
    var chunks = breaks + 1, base = Math.floor(totalMin / chunks);
    if (breaks <= 0 || base <= 0) return [F(totalMin)];
    var rem = totalMin - base * chunks, s = [];
    for (var i = 0; i < chunks; i++) {
      var last = i === chunks - 1;
      s.push(F(last ? base + rem : base));
      if (!last) s.push(R(breakLen));
    }
    return s;
  }

  function customByInterval(totalMin, interval, breakLen) {
    if (interval <= 0 || totalMin <= interval) return [F(totalMin)];
    var s = [], left = totalMin;
    while (left > 0) {
      var take = Math.min(left, interval);
      s.push(F(take)); left -= take;
      if (left > 0) s.push(R(breakLen));
    }
    return s;
  }

  // ── Derived readers ───────────────────────────────────────────────────────
  var focusOf = function (p) { return p.filter(function (s) { return s.kind === 'focus'; }); };
  var restsOf = function (p) { return p.filter(function (s) { return s.kind === 'rest'; }); };
  var totalMinOf = function (p) { return p.reduce(function (a, s) { return a + s.min; }, 0); };
  var totalFocusOf = function (p) { return focusOf(p).reduce(function (a, s) { return a + s.min; }, 0); };
  var isSingleFocus = function (p) { return p.length === 1 && p[0].kind === 'focus'; };
  function fmt(m) {
    var h = Math.floor(m / 60), mm = m % 60;
    return h === 0 ? mm + 'm' : (mm === 0 ? h + 'h' : h + 'h ' + mm + 'm');
  }

  // ── Build the plan for a setup state ──────────────────────────────────────
  function buildPlan(st) {
    if (st.mode === 'flow') return flowBlock(st.flowMin);
    if (st.mode === 'endless') return [F(0)]; // open-ended; no total
    // Pomodoro: ONE view, three settings — Focus, Break, Blocks. No duration/blocks duality.
    // Independently adjustable — never locked to a fixed 25/5 ratio (NN/g + category research).
    // The long break derives at 3× the short break, so it needs no extra field.
    if (st.mode === 'pomodoro')
      return pomodoroPlan(st.pomoFocus, st.pomoBreak, st.pomoBreak * 3, st.blocks, LONG_EVERY);
    // Custom: breaks spread evenly by COUNT, or one break every INTERVAL of focus.
    // Two genuinely different needs — both kept.
    return st.customMode === 'interval'
      ? customByInterval(st.customWork, st.customInterval, st.customBreakLen)
      : customByCount(st.customWork, st.customBreaks, st.customBreakLen);
  }

  // ── Cadence subline (app's _subline), returns {t, warn} ───────────────────
  function subline(st, plan) {
    if (st.mode === 'endless') return { t: 'Open focus · break whenever you say', warn: false };
    if (st.mode === 'flow') {
      return st.flowMin > SOFT_CAP
        ? { t: 'Past ~90 min, focus tends to fade. A fresh block after a break often serves you better.', warn: true }
        : { t: 'One unbroken block — recovery comes after.', warn: false };
    }
    var f = focusOf(plan), r = restsOf(plan);
    if (st.mode === 'pomodoro') {
      if (!r.length) return { t: 'One ' + fmt(totalFocusOf(plan)) + ' block · no breaks', warn: false };
      var t = f.length + ' × ' + st.pomoFocus + 'm focus · ' + st.pomoBreak + 'm break';
      if (f.length > LONG_EVERY) t += '<br>' + (st.pomoBreak * 3) + 'm long break every ' + LONG_EVERY + 'th';
      return { t: t, warn: false };
    }
    // custom
    if (!r.length) return { t: 'One ' + fmt(totalFocusOf(plan)) + ' block · no breaks', warn: false };
    var allEq = f.every(function (s) { return s.min === f[0].min; });
    var cavg = Math.round(totalFocusOf(plan) / f.length);
    return {
      t: (allEq ? f.length + ' × ' + f[0].min + 'm focus' : f.length + ' × ~' + cavg + 'm focus')
        + ' · ' + r.length + ' × ' + r[0].min + 'm break',
      warn: false
    };
  }

  // Guard ported from the app: a break may never squeeze focus below 5 min per chunk.
  // Returns true if adding one more break is allowed.
  function canAddBreak(st) {
    return Math.floor(st.customWork / (st.customBreaks + 2)) >= MIN_CHUNK;
  }

  var Plan = {
    F: F, R: R, RATIOS: RATIOS, SOFT_CAP: SOFT_CAP, LONG_EVERY: LONG_EVERY, STEPS: STEPS, DESC: DESC,
    flowBlock: flowBlock, pomodoroPlan: pomodoroPlan, flowmodoro: flowmodoro,
    customByCount: customByCount, customByInterval: customByInterval,
    focusOf: focusOf, restsOf: restsOf, totalMinOf: totalMinOf, totalFocusOf: totalFocusOf,
    isSingleFocus: isSingleFocus, fmt: fmt, buildPlan: buildPlan, subline: subline, canAddBreak: canAddBreak
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = Plan;
  else root.Plan = Plan;

  // ── Self-test ─────────────────────────────────────────────────────────────
  if (typeof process !== 'undefined' && process.argv && process.argv.indexOf('--test') !== -1) {
    var n = 0;
    function ok(cond, msg) { n++; if (!cond) { console.error('FAIL: ' + msg); process.exit(1); } }

    // Flow
    var flow = buildPlan({ mode: 'flow', flowMin: 25 });
    ok(totalMinOf(flow) === 25 && isSingleFocus(flow), 'flow 25 → single 25m block');
    ok(subline({ mode: 'flow', flowMin: 120 }, null).warn === true, 'flow >90 warns');
    ok(subline({ mode: 'flow', flowMin: 45 }, null).warn === false, 'flow ≤90 calm');

    // flowmodoro stays part of the app-parity model even though the UI no longer exposes it
    var fm = flowmodoro(120, 4);
    ok(totalFocusOf(fm) === 120 && focusOf(fm).length === 4, 'flowmodoro splits 120 into 4 blocks');

    // Pomodoro: ONE view — 25 focus / 5 break × 4 → 4×25 + 3×5 = 115
    var pbSt = { mode: 'pomodoro', pomoFocus: 25, pomoBreak: 5, blocks: 4 };
    var pb = buildPlan(pbSt);
    ok(totalMinOf(pb) === 115, 'pomo·blocks 25/5 ×4 = 115');
    ok(restsOf(pb).every(function (s) { return s.min === 5; }), 'pomo·blocks all short breaks at 4');

    // Long break = 3× the short break, appearing at the 4th boundary
    var pb6 = buildPlan({ mode: 'pomodoro', pomoEntry: 'blocks', pomoFocus: 25, pomoBreak: 5, blocks: 6 });
    ok(restsOf(pb6).some(function (s) { return s.min === 15; }), 'pomo·blocks ×6 long break = 3× short');

    // Fields are NOT locked to a ratio: any focus/break combination builds correctly
    var pbFree = buildPlan({ mode: 'pomodoro', pomoFocus: 40, pomoBreak: 7, blocks: 3 });
    ok(totalFocusOf(pbFree) === 120, 'pomo 40m ×3 = 120 focus (unlocked ratio)');
    ok(totalMinOf(pbFree) === 134, 'pomo 40/7 ×3 total = 134');

    // Custom: 120 / 3 breaks → 4×30 focus + 3×10 break = 150
    var cc = buildPlan({ mode: 'custom', customWork: 120, customBreaks: 3, customBreakLen: 10 });
    ok(totalMinOf(cc) === 150 && totalFocusOf(cc) === 120, 'custom 120/3 → 150 total');
    ok(focusOf(cc).length === 4, 'custom 3 breaks → 4 focus chunks');

    // Custom by interval: a break every 30m of focus → 4×30 + 3×10 = 150
    var ci = buildPlan({ mode: 'custom', customMode: 'interval', customWork: 120, customInterval: 30, customBreakLen: 10 });
    ok(totalMinOf(ci) === 150, 'custom·interval 120 every 30 → 150 total');
    ok(focusOf(ci).every(function (s) { return s.min === 30; }), 'custom·interval every chunk is 30m');

    // Break-squeeze guard: 20m work, 3 breaks (→ chunks would be 5 → 4m < 5m) is refused
    ok(canAddBreak({ customWork: 20, customBreaks: 3 }) === false, 'guard: 20m/5chunks refused');
    ok(canAddBreak({ customWork: 60, customBreaks: 3 }) === true, 'guard: 60m/5chunks allowed');

    console.log('plan.js: ' + n + ' assertions passed');
  }
})(typeof window !== 'undefined' ? window : this);
