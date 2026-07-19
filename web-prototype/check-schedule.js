// Pulls the real schedule + glow code out of hybrid.html and tabulates it, so the
// timings are checked against the shipping source rather than a copy.
const fs = require('fs');
const s = fs.readFileSync('d:/Dev/Trilumos/hourglass/web-prototype/hybrid.html', 'utf8');

const grab = (from, to) => {
  const i = s.indexOf(from), j = s.indexOf(to, i);
  if (i < 0 || j < 0) throw new Error('not found: ' + from);
  return s.slice(i, j);
};

const clamp = (v,a,b)=>v<a?a:v>b?b:v;
const lerp  = (a,b,t)=>a+(b-a)*t;
const smooth= t=>{ t=clamp(t,0,1); return t*t*(3-2*t); };

// indirect eval + const/let→var so the declarations land in global scope
const run = src => (0,eval)(src.replace(/\b(const|let) /g, 'var '));
globalThis.clamp = clamp; globalThis.lerp = lerp; globalThis.smooth = smooth;
globalThis.S = { hor: 0.4475, hazeAmt: 0.50 };
run(grab('const SEG =', 'function phaseAt'));
run(grab('function phaseAt', 'const SUN_POS'));
run(grab('const SUN_POS', 'function updateDayCycle'));

const NAME = ['pre-dawn','sunrise','midday','sunset','twilight','midnight'];
const hhmm = t => String(Math.floor(t)).padStart(2,'0')+':'+String(Math.round((t%1)*60)).padStart(2,'0');

console.log('time  | plate              | sun amt alt | moon amt');
for (let t = 0; t < 24; t += 0.25) {
  const p = phaseAt(t), su = trackSun(t), mo = trackMoon(t);
    const plate = p.blend > 0.001
    ? `${NAME[p.a]}→${NAME[p.b]} ${p.blend.toFixed(2)}` : NAME[p.a];
  console.log(
    `${hhmm(t)} | ${plate.padEnd(18)} | ${su.amt.toFixed(2)} ${su.alt.toFixed(2).padStart(5)}` +
    ` | ${mo.amt.toFixed(2)}`);
}

// The hard invariants the founder stated, asserted rather than eyeballed.
const fail = [];
const sunOn  = t => trackSun(t).amt  > 0.02;
const moonOn = t => trackMoon(t).amt > 0.02;
for (let t = 0; t < 24; t += 1/60) {
  if (sunOn(t) && moonOn(t)) fail.push(`sun AND moon both up at ${hhmm(t)}`);
}
if (sunOn(5.9))  fail.push('sun glowing before 06:00 sunrise');
if (!sunOn(6.2)) fail.push('sun not up at 06:12');
if (!sunOn(18.4))fail.push('sun gone before 18:30 sunset');
if (sunOn(20.6)) fail.push('sun glow still alive after 20:30');
if (!sunOn(20.0))fail.push('sun afterglow died before 20:00 — founder wants it to ~20:25');
if (moonOn(21.6))fail.push('moon rose before 21:45');
if (!moonOn(22.3))fail.push('moon not up by 22:18');
// must be GONE before the sunrise glow begins at 06:00
if (moonOn(5.9))  fail.push('moon still up when the sunrise glow starts');
if (moonOn(6))    fail.push('moon still up at sunrise');


// plate windows the founder specified in this round
const plateAt = t => { const p = phaseAt(t); return p.blend > 0.5 ? p.b : p.a; };
if (phaseAt(6.5).blend > 0.001) fail.push('sunrise not pure at 06:30');
if (plateAt(8.2) !== 2)  fail.push('not midday by 08:12');
if (phaseAt(8.05).blend > 0.001) fail.push('still crossfading after 08:00');

// NO transition may be fast enough to read as two images dissolving. smoothstep
// peaks at 1.5/T, so this caps every crossfade at T >= 1.25h.
let worst = 0, worstAt = 0;
for (let t = 0; t < 24; t += 1/240) {
  const a = phaseAt(t), b = phaseAt(t + 1/240);
  if (a.a === b.a && a.b === b.b) {
    const rate = Math.abs(b.blend - a.blend) * 240;
    if (rate > worst) { worst = rate; worstAt = t; }
  }
}
if (worst > 1.25) fail.push(`plate crossfade too fast: ${worst.toFixed(2)}/h at ${hhmm(worstAt)} (want <1.25)`);
console.log(`\nfastest plate crossfade: ${worst.toFixed(2)}/h at ${hhmm(worstAt)}`);
if (plateAt(19.2) !== 3) fail.push('not fully sunset by 19:12');
if (plateAt(19.8) !== 3) fail.push('sunset plate gone before 19:48');

// The founder's core complaint: the sunset must EASE in while the sun descends,
// not snap over once it is already at the water.
const sset = phaseAt(17.2);
if (!(sset.b === 3 && sset.blend > 0.05 && sset.blend < 0.5))
  fail.push(`sunset not gently easing in at 17:12 (b=${sset.b} blend=${sset.blend.toFixed(2)})`);
if (phaseAt(18.45).blend < 0.9) fail.push('sunset not essentially complete as the sun reaches the horizon');

// Sun must still be HIGH through the afternoon, not near the horizon at 16:00.
const altAtT = t => trackSun(t).alt;
if (!(altAtT(16.0) > 0.75)) fail.push(`sun too low at 16:00 (alt ${altAtT(16.0).toFixed(2)})`);
if (!(altAtT(17.0) > 0.55)) fail.push(`sun too low at 17:00 (alt ${altAtT(17.0).toFixed(2)})`);
if (!(altAtT(12.0) > 0.95)) fail.push('sun not at peak around noon');
if (!(Math.abs(altAtT(18.5)) < 0.09)) fail.push('sun not at the horizon at 18:30');
// The RISE must be gradual: the disc starts fully submerged and slides up, rather
// than half-popping into view the instant the window opens.
if (!(altAtT(6.0) < -0.3))  fail.push('sun does not start below the horizon — it will pop in');
for (let t = 6.0; t < 6.8; t += 1/60)
  if (altAtT(t+1/60) < altAtT(t) - 1e-9) { fail.push(`sun dips while rising at ${hhmm(t)}`); break; }
if (!(altAtT(6.5) > -0.06 && altAtT(6.5) < 0.20)) fail.push('sun not mid-emergence at 06:30');
// and the descent must be monotonic through the sunset window (no bobbing)
for (let t = 14; t < 18.5; t += 0.1)
  if (altAtT(t+0.1) > altAtT(t) + 1e-9) { fail.push(`sun rises again at ${hhmm(t)}`); break; }

console.log(fail.length ? '\nFAIL:\n  ' + fail.join('\n  ') : '\nOK — all schedule invariants hold.');
process.exit(fail.length ? 1 : 0);
