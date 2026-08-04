// Generator for video-roadmap.md.  Run:  node docs/youtube/gen-roadmap.cjs
//
// Durations and chapters are computed from the SHIPPED plan.js, never from my own arithmetic — the real
// builder drops the trailing break AND inserts a long break every 4th block, so hand-derived numbers were
// wrong (a "4-Hour" 50/10 video is really 3h50m). Two tracks fall out of that:
//
//   ROUND-HOUR track  → Custom mode, which CAN hit 60/120/180… exactly. Chases "N hour timer" queries.
//   INTERVAL track    → Pomodoro mode, titled with its TRUE length. Chases "50/10 pomodoro" queries.
// Flip to true the day YouTube grants link posting (advanced features). Until then descriptions carry NO
// URL: an unverified channel cannot post them, and a stripped or blocked link is worse than none at all.
// The preset for each row is still printed underneath, so nothing is lost — just not pasted yet.
const LINKS_OK = false;
const fs = require('fs');
eval(fs.readFileSync(__dirname + '/../../web-astro/public/js/plan.js', 'utf8'));   // sets module.exports
const P = module.exports;

const LIGHT = {
  predawn:  { cap:'Pre-Dawn',      emo:'🌌', setup:'Time of day → Pre-dawn',  cols:['Ivory #f2ecdd','White #ffffff'] },
  sunrise:  { cap:'Sunrise',       emo:'🌅', setup:'Time of day → Sunrise',   cols:['Ivory #f2ecdd','Charcoal #20242e'] },
  midday:   { cap:'Midday',        emo:'☀️', setup:'Time of day → Midday',    cols:['Charcoal #20242e','White #ffffff'] },
  sunset:   { cap:'Sunset',        emo:'🌇', setup:'Time of day → Sunset',    cols:['Ivory #f2ecdd','White #ffffff'] },
  twilight: { cap:'Twilight',      emo:'🌆', setup:'Time of day → Twilight',  cols:['Gold #eaca78','Ivory #f2ecdd'] },
  midnight: { cap:'Midnight',      emo:'🌙', setup:'Time of day → Midnight',  cols:['Gold #eaca78','White #ffffff'] },
  intoday:  { cap:'Dawn to Day',   emo:'🌄', setup:'Cycle → Into the day',       cols:['Ivory #f2ecdd'] },
  intonight:{ cap:'Dusk to Night', emo:'🌃', setup:'Cycle → Into the night',     cols:['Ivory #f2ecdd','Gold #eaca78'] },
  wholeday: { cap:'Full Day',      emo:'🌍', setup:'Cycle → A whole day',        cols:['Ivory #f2ecdd'] },
};
const SNAME = { ocn:'Ocean', snd:'Sand', brz:'Shore breeze', brd:'Seabirds' };
const SOUND = {
  ocn:'Ocean Waves', snd:'Falling Sand', brz:'Shore Breeze', brd:'Seabirds',
  'ocn+brd':'Ocean & Seabirds','ocn+brz':'Ocean & Breeze','ocn+snd':'Ocean & Sand',
  'snd+brd':'Sand & Seabirds','brz+brd':'Breeze & Seabirds','snd+brz':'Sand & Breeze',
  'ocn+snd+brd':'Ocean, Sand & Seabirds','ocn+brz+brd':'Ocean, Breeze & Seabirds',
  'snd+brz+brd':'Sand, Breeze & Seabirds','ocn+snd+brz':'Ocean, Sand & Breeze',
  all4:'Full Shore Ambience', bell:'No Music, Bell Only',
};
const soundSetup = s => s==='bell' ? 'ALL sounds OFF — bell only'
  : (s==='all4' ? 'Sand + Ocean + Shore breeze + Seabirds' : s.split('+').map(k=>SNAME[k]).join(' + '));
const MIXV=[100,55,40,30], MASTER={1:100,2:100,3:90,4:85};
const audioCell = s => s==='bell' ? 'ALL sounds OFF — bell only'
  : (k=>`${k.map((x,i)=>`${SNAME[x]} ${MIXV[i]}`).join(' · ')} — master ${MASTER[k.length]}`)(s==='all4'?['ocn','snd','brz','brd']:s.split('+'));

// Kept for reference only: Custom configs that hit a round hour. Unused now that /stage's uniform
// Pomodoro does it natively — see the note in gen header.
const ROUND = {
  1:{work:50,breaks:1,len:10},  2:{work:110,breaks:1,len:10}, 3:{work:150,breaks:2,len:15},
  4:{work:200,breaks:4,len:10}, 5:{work:210,breaks:6,len:15}, 6:{work:300,breaks:4,len:15},
  8:{work:420,breaks:6,len:10}, 10:{work:550,breaks:10,len:5},
};
const stOf = r =>
    r.kind==='flow'   ? { mode:'flow', flowMin:r.mins }
  : r.kind==='custom' ? { mode:'custom', customMode:'count', customWork:r.work,
                          customBreaks:r.breaks, customBreakLen:r.len }
  :                     { mode:'pomodoro', pomoFocus:+r.iv.split('/')[0], pomoBreak:+r.iv.split('/')[1],
                          blocks:r.blocks, uniform:true };   // /stage: blocks x (focus+break) exactly

// Every downstream reader (slug, guard-rails, title, tags, table, description) used to re-derive the
// interval from r.iv, which only existed on Pomodoro rows. With three modes that is three ways to be
// wrong, so the shape is read ONCE off the real plan and everything else consumes this.
const totalOf = r => P.totalMinOf(P.buildPlan(stOf(r)));
const MIN_CHAPTER = 10;                        // seconds; YouTube rejects the whole list below this
const shapeOf = r => { const pl = P.buildPlan(stOf(r));
  const f = pl.filter(x=>x.kind==='focus'), b = pl.filter(x=>x.kind!=='focus');
  return { focus:f[0].min, brk:b.length?b[0].min:0, nFocus:f.length, nBreak:b.length,
           iv: b.length ? `${f[0].min}/${b[0].min}` : `${f[0].min}m` }; };

// ── Numerals: RULES, not permutations ────────────────────────────────────────────────────────────
// The old version cycled place/fill/font/separator/colour off the ROW index, which did two bad things:
// it made a bell twin differ from its own session (row 1 vs row 2 were different videos visually), and
// it emitted combinations that simply look wrong. A library of 30 videos that each look considered
// beats 30 videos that merely prove no permutation repeats.
//
// Locked for every YouTube video (founder, 2026-08-04):
//   visibility  Always, unless a row opts in to 5 min AND its title says so. Never and hover are both
//               banned — hover is Setup's DEFAULT and the most dangerous setting here: miss it and
//               the numbers fade out mid-recording.
//   separator   middle and ledge take NONE, ever. horizon and top take colon or dot.
//   fill        solid or glass only. Never outline.
//   colour      White #ffffff always legal. Charcoal #20242e ONLY on sun sessions (midday, sunrise,
//               sunset) — never on pre-dawn, twilight or midnight, which have no sun at all.
// Visibility is ALWAYS unless a session explicitly opts out. 5 min and Never break the pattern a
// viewer expects from a video titled "Pomodoro Timer", so they are only defensible when the title, the
// tags and the intro card all say so up front — and that needs a query to title against. There isn't
// one (vidIQ 2026-08-04): `hour glass timer` 0/mo, while `visual timer` 4,876 and `sand timer` 4,725
// both sit in a toddler/classroom cluster (visual timer for kids, toddler sand timer, egg timer,
// occupational therapy timer) — a different audience entirely, and the same mismatch that got the
// classroom tags pulled. `hourglass` 50,361 is the shape, not the timer.
// Never is therefore dropped outright. 5 min survives — the video is still visibly a timer — but is
// opt-in, never cycled: put vis:'5 min' on a UNIQUE row and write the title to match when you do.
// Only the six (placement, separator) pairs the rules actually permit. Nothing else can be generated.
const PLACE_SEP = [
  ['middle',  'none'],   ['horizon', 'colon'], ['ledge', 'none'],
  ['top',     'dot'],    ['horizon', 'dot'],   ['top',   'colon'],
];
const FILL = ['solid','glass'], FONT = ['Serif','Jost'];
// Charcoal is legal on the SUN sessions and nowhere else. The test is whether the sun is actually in
// the session, not whether the span brushes a dark window at its edge — sunrise and sunset inevitably
// graze pre-dawn and twilight (PH_SPAN, Session.astro:367: sunrise opens 5.0 inside pre-dawn's
// 3.5-6.1; sunset runs to 18.8 inside twilight's 18.2-19.6) but the sun is above the horizon for the
// bulk of both, so dark numerals read.
//   midday 8.2-16.5   full sun          -> charcoal OK
//   sunrise 5.0-8.2   sun rises ~6:00   -> charcoal OK
//   sunset 16.3-18.8  sun sets ~18:30   -> charcoal OK
//   pre-dawn / twilight / midnight      -> no sun at all, white only
// White reads on every sky, so it stays the default and charcoal is the exception.
const SUN = { midday:1, sunrise:1, sunset:1 };
const numColour = light => SUN[light] ? 'Charcoal #20242e' : 'White #ffffff';
// Driven by the SESSION index, never the row index — that is what makes a bell twin identical to the
// session it pairs with.
// The +floor(si/6) matters: fill has period 2 and PLACE_SEP period 6, so a plain si%2 keeps them in
// phase forever — every middle and ledge comes out solid, every top comes out glass. Flipping the fill
// phase each time the placement cycle wraps breaks that, so a placement is seen in both fills.
// Session 1 was recorded and published (IRTdF6rgjpQ, 2026-08-03) before these rules existed, so its
// config is pinned to what is actually on screen in that video rather than generated — otherwise its
// bell twin, which is day 2, would not be a twin at all. It happens to be legal under the rules:
// horizon takes a colon, glass is permitted, White is legal on every sky.
const PINNED = { 0: 'Always · horizon · glass · Serif · colon · White #ffffff' };
// The pin sits outside the cycle, so it can land on a config the cycle was going to produce anyway —
// it did: session 1's pinned horizon/glass/colon collided with session 2's generated one. Offsetting
// the placement lookup past the pinned sessions keeps every session visually distinct.
// Memoised per session: every look must be unique across the month, which needs memory of what has
// already been handed out. Skipping only the PINNED values was not enough — with 15 sessions against
// 24 shown-variants per colour, two collided on ledge/solid/Jost the moment visibility stopped
// separating them. Called more than once per session (JSON and markdown table), so the cache is also
// what keeps those two outputs in agreement.
const _look = new Map();
const numeralsOf = (r, si) => {
  if (_look.has(si)) return _look.get(si);
  const put = v => { _look.set(si, v); return v; };
  if (PINNED[si]) return put(PINNED[si]);
  const vis = r.vis || 'Always';
  const taken = new Set([...Object.values(PINNED), ..._look.values()]);
  for (let k = si; k < si + PLACE_SEP.length * 4; k++){
    const [place, sep] = PLACE_SEP[k % PLACE_SEP.length];
    const look = `${vis} · ${place} · ${FILL[(k + Math.floor(k/PLACE_SEP.length)) % 2]}`
               + ` · ${FONT[Math.floor(k/2) % 2]} · ${sep} · ${numColour(r.light)}`;
    if (!taken.has(look)) return put(look);
  }
  throw new Error(`no distinct look left for session ${si + 1} (${r.light}) — widen the look space`);
};


const rows=[];
const addC=(phase,hours,light,sound)=>rows.push({phase,kind:'custom',hours,light,sound});
const addP=(phase,iv,blocks,light,sound)=>rows.push({phase,kind:'pomo',iv,blocks,light,sound});
const addF=(phase,mins,light,sound)=>rows.push({phase,kind:'flow',mins,light,sound});
const addX=(phase,work,breaks,len,light,sound)=>rows.push({phase,kind:'custom',work,breaks,len,light,sound});

// The month runs from the FIRST upload to the last day of that calendar month, not for a flat 30
// days. August opened on the 3rd, so it holds 29 videos, not 30 — a list that overflows into
// September is a list you stop trusting by the third week.
// The repeat ledger keys off MONTH, so bump START when generating a new month, and change UNIQUE at
// the same time or the repeat check will (correctly) refuse to build.
const START = '2026-08-03';
const MONTH = START.slice(0, 7);
const MONTH_LABEL = new Date(START + 'T00:00:00Z')
  .toLocaleDateString('en-US', { month:'long', year:'numeric', timeZone:'UTC' });
const DAYS = (() => { const d = new Date(START + 'T00:00:00Z');
  const last = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  return last - d.getUTCDate() + 1; })();
const dayDate = n => { const d = new Date(START + 'T00:00:00Z');
  d.setUTCDate(d.getUTCDate() + n - 1); return d.toISOString().slice(0, 10); };

// ── THE MONTH — 15 unique sessions, each shot TWICE ──────────────────────────────────────────────
// Founder's schedule: every config is captured once with ocean and once bell-only, published on
// consecutive days. Day 1 config A with sound, day 2 config A silent, day 3 config B with sound, and so
// on. 15 x 2 = 30 videos a month, and only 15 sessions to think about.
//
// Two captures, never a re-export: /stage records what it is configured to record, and a silent version
// is a different file, not a trimmed one. `pomodoro timer no music` is 5,302/mo on its own, and
// `study with me no break no music` another 4,388 — the silent twin is chasing real queries, not padding.
//
// The 15 are chosen on search volume (vidIQ, 2026-08-03): study with me 2,533,520/mo · 2 hour timer
// 204,296 · study timer 103,138 · study with me pomodoro 47,568 · study with me 4 hours 44,753 ·
// 60 minute timer 33,037 · study with me late night 6,242 (midnight is a QUERY, not just our aesthetic).
// [interval, blocks, light, sound] — the sound is MATCHED TO THE LIGHT, not rotated blindly. Seabirds at
// midnight would be wrong, and a video that feels wrong is a video people leave. Dawn gets the birds,
// midday gets the bright full shore, the night hours get the quiet mixes. Variety here also widens the
// query surface: "ocean waves study", "brown noise"-adjacent sand, birdsong ambience are separate searches.
// Day 1 stays ocean because it is already published.
// Each entry is one SESSION; the generator adds its bell-only twin automatically.
// Durations weighted by real volume (vidIQ 2026-08-03) rather than by taste:
//   study with me 2,525,198/mo · deep focus 887,738 · deep work 654,229 · flow state 316,535
//   2 hour timer 204,296 · study with me 3 hours 125,629 · study timer 103,138
//   study with me pomodoro 44,753 · study with me 4 hours 44,753 · 60 minute timer 33,037
// 3 HOURS was missing entirely and is one of the biggest duration queries in the niche.
// FLOW mode earns its place on "deep work" and "flow state" — an unbroken block is literally what those
// searches want, and nobody else in this niche offers one. CUSTOM covers the long-block schedules
// (45/15, 60/20) that Pomodoro's fixed ratio cannot express.
// Sound is matched to the LIGHT: birds at dawn, the full shore at midday, quiet mixes at night.
const UNIQUE = [
  // ── Pomodoro 50/10 — the proven interval ───────────────────────────────────────────────────────
  { p:['50/10', 2], light:'sunset',   snd:'ocn'         },   // ← PUBLISHED 2026-08-03, do not change
  { p:['50/10', 3], light:'midnight', snd:'ocn+brz'     },   // 3h: 125,629/mo
  { p:['50/10', 4], light:'sunrise',  snd:'ocn+brd'     },
  { p:['50/10', 1], light:'twilight', snd:'snd+brz'     },   // 60 minute timer: 33,037/mo
  { p:['50/10', 3], light:'sunset',   snd:'ocn+snd+brd' },
  // ── Pomodoro 25/5 — the other searched interval ────────────────────────────────────────────────
  { p:['25/5',  4], light:'midnight', snd:'ocn'         },   // 2h
  { p:['25/5',  6], light:'sunset',   snd:'ocn+snd'     },   // 3h
  { p:['25/5',  8], light:'midday',   snd:'brz+brd'     },   // 4h
  // ── Flow — one unbroken block. Targets deep work / flow state, and no competitor ships it ───────
  { f:60,  light:'sunrise',  snd:'ocn+brd'     },
  { f:120, light:'midnight', snd:'snd'         },
  { f:180, light:'sunset',   snd:'ocn+brz'     },
  // ── Custom — long-block schedules Pomodoro's fixed ratio cannot express ────────────────────────
  { x:[150, 2, 15], light:'twilight', snd:'ocn'         },   // 3h -> 50/15
  { x:[200, 4, 10], light:'predawn',  snd:'snd+brz'     },   // 4h -> 40/10
  { x:[ 90, 2, 15], light:'midday',   snd:'all4'        },   // 2h -> 30/15
  { x:[240, 3, 20], light:'sunrise',  snd:'ocn+snd'     },   // 5h -> 60/20
];
// Interleaved so the silent twin follows its own session the very next day.
UNIQUE.forEach(u => {
  const add = (snd) => u.p ? addP('1', u.p[0], u.p[1], u.light, snd)
            : u.f     ? addF('1', u.f, u.light, snd)
            :           addX('1', u.x[0], u.x[1], u.x[2], u.light, snd);
  add(u.snd); add('bell');
});

const key = r => [r.kind, shapeOf(r).iv, totalOf(r), r.light, r.sound].join('|');
{ const seen=new Map();
  rows.forEach((r,i)=>{ const k=key(r);
    if(seen.has(k)) throw new Error(`DUPLICATE row ${i+1} (first at ${seen.get(k)+1}): ${k}`);
    seen.set(k,i); });
  console.log(`unique combinations: ${seen.size}/${rows.length} ✓`); }

// Minutes are ALWAYS two digits, so the first chapter reads 00:00 rather than 0:00. YouTube's chapter
// docs are explicit — "make sure that the first timestamp you list starts with 00:00" — and with 0:00 the
// timestamps still render as blue links (any timestamp does) while chapter validation silently fails and
// the progress bar never segments. One missing zero costs you the chapter markers entirely.
// ALWAYS full zero-padded HH:MM:SS. That `h ? ... : ...` was the bug that survived the 0:00 -> 00:00
// fix: it made the list CHANGE SHAPE partway down, `50:13` (MM:SS) followed by `1:00:13` (H:MM:SS, no
// leading zero). YouTube parsed neither, so the progress bar never segmented on video #1 — while the
// timestamps still rendered as blue links, which is why nothing looked broken.
// Verified against Timer Palette KNzl1LYrHtw, a 3-hour timer whose chapters DO render:
//   00:00:00 / 00:50:00 / 01:00:00 — one consistent zero-padded form the whole way down.
const ts = m => { const s = Math.round(m*60), p = n => String(n).padStart(2,'0');
  return `${p(Math.floor(s/3600))}:${p(Math.floor(s%3600/60))}:${p(s%60)}`; };
// ── Guard-rails, asserted not trusted ────────────────────────────────────────────────────────────
// A short block is a worse product: 15/5 means the viewer is interrupted every fifteen minutes, and a
// sub-30-minute timer is not something anyone leaves running. Both would also read as filler in a
// library, which is exactly what the inauthentic-content policy punishes. The generator refuses to emit
// them rather than relying on whoever edits UNIQUE next month to remember.

const MIN_FOCUS = 25, MIN_BREAK = 5, MIN_TOTAL = 30;
for (const r of rows){
  const sh = shapeOf(r), t = totalOf(r);
  if (sh.focus < MIN_FOCUS) throw new Error(`focus block too short: ${sh.iv} (min ${MIN_FOCUS})`);
  if (sh.nBreak && sh.brk < MIN_BREAK) throw new Error(`break too short: ${sh.iv} (min ${MIN_BREAK})`);
  if (t < MIN_TOTAL) throw new Error(`video too short: ${slug(r)} = ${t}min (min ${MIN_TOTAL})`);
}
console.log(`guard-rails: all ${rows.length} rows >= ${MIN_FOCUS}/${MIN_BREAK} and >= ${MIN_TOTAL}min ✓`);

const durTxt = m => { const h=Math.floor(m/60), mm=m%60;
  return h ? (mm ? `${h}h ${mm}m` : `${h}-Hour`) : `${mm}-Min`; };
const durPlain = m => { const h=Math.floor(m/60), mm=m%60;
  const hw = h===1 ? '1 hour' : `${h} hours`;
  return h ? (mm ? `${hw} ${mm} min` : hw) : `${mm} min`; };
// The deep link is built now, so descriptions carry the EXACT session, not just the domain.
const TOD = { predawn:'pre-dawn', sunrise:'sunrise', midday:'midday', sunset:'sunset',
              twilight:'twilight', midnight:'midnight' };
const SND_ID = { ocn:'ocean', snd:'sand', brz:'breeze', brd:'birds' };
const presetURL = r => {
  const q = ['mode=' + (r.kind==='pomo' ? 'pomodoro' : r.kind)];
  if (r.kind==='pomo') q.push('work='+shapeOf(r).focus, 'break='+shapeOf(r).brk, 'blocks='+r.blocks);
  if (r.kind==='flow') q.push('flow=' + r.mins);
  if (TOD[r.light]) q.push('phase=' + TOD[r.light]);
  q.push('sound=' + (r.sound==='bell' ? '' : r.sound.split('+').map(k=>SND_ID[k]).join(',')));
  return 'https://sustaintimer.com/?' + q.join('&');
};
// Chapters come straight off the real plan, so the long-break-every-4th rule is baked in.
// The VIDEO clock is not the SESSION clock. /stage records the intro card (INTRO_MS 10 s) and the 3-2-1
// countdown before the engine starts, so the first focus block begins 13 s into the file — every session
// timestamp has to shift by that much or the chapters point at the wrong moments all the way through.
// Keep in step with stage.astro: INTRO_MS/1000 + 3.
// The 3-2-1 countdown belongs to the SESSION, not the intro — the founder's call, and it is the right
// one: the viewer is already working by "3". So Focus 1 is stamped where the countdown starts, at
// INTRO_MS/1000 = 10 s, not at 13 s where the engine actually fires.
// That makes the Intro chapter exactly 10 s, which is precisely YouTube's per-chapter minimum. Legal,
// but with zero headroom — so MIN_CHAPTER below asserts it rather than trusting it. If stage.astro's
// INTRO_MS is ever shortened, the generator refuses to emit instead of silently killing chapters again.
const LEAD_IN = 10 / 60;                       // minutes, to match the plan's units
// No closing chapter for the thank-you card: recording stops 5 s into it (OUTRO_STOP_MS), and a chapter
// under 10 s is invalid and would silently kill the markers for the whole video. The last break absorbs it.
// Chapters start at 00:00:00 with Focus 1 — no "Intro" marker. Two reasons, one hard:
//   The intro card is 10 s and the countdown 3 s, so an Intro chapter leaves a 10 s first gap, sitting
//   exactly on YouTube's per-chapter minimum with zero headroom. Video #1 was rejected at that width.
//   Timer Palette KNzl1LYrHtw — a 3-hour timer whose chapters DO render — has no intro chapter either:
//   its first marker is FOCUS 1 at 00:00:00 and its smallest gap is ten MINUTES.
// Absorbing the 13 s of card + countdown into Focus 1 is off by 13 s at the head of a 50-minute
// chapter, which no one clicking "Focus 2" will ever notice. Working chapters beat exact ones.
const MIN_CHAPTERS = 3;                        // YouTube ignores the list below this
const chapters = r => {
  const plan=P.buildPlan(stOf(r)); const out=[]; let t=0,f=0,b=0;
  for (const seg of plan){ if(seg.kind==='focus'){ out.push(`${ts(t)} Focus ${++f}`); } else { out.push(`${ts(t)} Break ${++b}`); }
    t += seg.min; }
  return out.length >= MIN_CHAPTERS ? out : []; };
const nBreaks = r => P.buildPlan(stOf(r)).filter(s=>s.kind!=='focus').length;

// One human sentence: the shape of the session, then what the sky actually does. Both are read off the
// REAL plan and the light's drift window, so the description can never disagree with the video.
const DRIFT = {
  predawn:'begins in the dark hour before dawn and eases toward first light',
  sunrise:'begins at first light and warms into full morning',
  midday:'drifts from late morning into afternoon',
  sunset:'begins in late-afternoon light and sinks to the horizon',
  twilight:'deepens from the last light into dusk',
  midnight:'settles from dusk into the small hours',
  intoday:'warms from pre-dawn all the way into full daylight',
  intonight:'deepens from sunset into night',
  wholeday:'passes through a whole day, dawn through to midnight',
};
const sentence = r => {
  const p = P.buildPlan(stOf(r));
  const f = p.filter(x => x.kind === 'focus'), b = p.filter(x => x.kind !== 'focus');
  const shape = f.length > 1
    ? `${f.length} focus blocks of ${f[0].min} minutes` + (b.length ? `, a ${b[0].min}-minute break after each` : '') + ', and a soft bell on every change.'
    : `One ${f.length ? f[0].min + '-minute' : ''} block, with a soft bell to open and close it.`;
  return shape + ' The sky moves the whole way through — this session '
       + (DRIFT[r.light] || 'follows the day') + ' as you work.';
};
const slug = r => `${{pomo:'P',flow:'F',custom:'C'}[r.kind]}${shapeOf(r).iv.replace('/','-')}`
  + `x${Math.round(totalOf(r)/60*10)/10}h_${r.light}_${r.sound.replace(/\+/g,'-')}`;
// Video length = lead-in + session + the 5 s of outro that /stage records before it stops.
const videoSec = r => Math.round(LEAD_IN*60 + totalOf(r)*60 + 5);
for (const r of rows){
  const ch = chapters(r); if (!ch.length) continue;
  const at = ch.map(c => { const [h,m,sec] = c.split(' ')[0].split(':').map(Number); return h*3600+m*60+sec; });
  at.push(videoSec(r));
  for (let k = 0; k < at.length-1; k++){
    const gap = at[k+1] - at[k];
    if (gap < MIN_CHAPTER) throw new Error(`chapter ${k+1} of ${slug(r)} is ${gap}s (min ${MIN_CHAPTER}): ${ch[k]}`);
  }
}
// ── Title formula — ONE skeleton, four slots ───────────────────────────────────────────────────────
//
//   {N}-Hour Study With Me {e} {MODE PHRASE} for Deep Focus & ADHD | {Sound} & {Light}
//
// Only the emoji, the mode phrase, the sound and the light ever move. Everything else is fixed, on
// purpose: the channels that win this niche run a rigid skeleton and vary two words per upload.
// Measured 2026-08-03 on "3 hour study with me pomodoro timer":
//   Timer Palette  546,673 / 239,288 / 117,648 views — "50/10 Pomodoro Timer with Brown Noise 🎧
//                  3-Hour Study with Me for Deep Focus & ADHD ✨" — ONE variable word (Brown/Pink).
//   Countdown Time 687,672 / 472,688 / 436,770 — "{IV} Pomodoro Timer - 3 hour study || No music -
//                  Study for dreams - Deep focus - Study timer" — ONLY the interval changes.
//   iCanStudy   13,210,854 — "3-HOUR STUDY WITH ME | ... Pomodoro 50-10"
// Both openings are proven, so the opener is chosen on volume: "study with me" 2,525,198/mo beats
// "50/10 pomodoro" 47,568 by 53x and leads.
//
// Three fixes over the video-#1 wording, each worth real indexed volume:
//  1. "Pomodoro 50/10" -> "50/10 Pomodoro Timer". Word order is what exact-phrase matching sees: the
//     old order matched NEITHER "50/10 pomodoro" (47,568/mo) nor "pomodoro timer" (427,868/mo).
//     Four words now carry both. This was the single biggest hole in the old title.
//  2. "Focus & ADHD" -> "Deep Focus & ADHD" — "deep focus" is 887,738/mo on its own.
//  3. One emoji, tied to the sound rather than sprinkled. Every top performer here uses one or two
//     (Timer Palette 🎧✨, Sherry 🌅🌊, Sean Study 🌅, Mr Tiny ☕🌤). It is also the only glyph in a
//     wall of same-shaped titles, which is what earns the eye in a sidebar.
//
// Bell-only twins say "No Music" in the title, not the tail: Countdown Time's three biggest videos
// (687k/472k/436k) all lead on it, and "pomodoro no music" is 9,661/mo at competition 10.4 — the
// lowest-contested real term in the niche.
const MODE = { pomo:'Pomodoro', flow:'Flow', custom:'Custom' };
// What to actually tap into Setup before recording. Mode-shaped, because the three modes take
// genuinely different inputs — Pomodoro counts blocks, Custom counts breaks, Flow takes one number.
const setupOf = r => r.kind==='flow'
    ? `flow length **${r.mins}m**`
  : r.kind==='custom'
    ? `By count · work **${r.work}m** · breaks **${r.breaks}** · break length **${r.len}m**`
    : `focus **${shapeOf(r).focus}m** · break **${shapeOf(r).brk}m** · blocks **${r.blocks}**`;
// The head of the video description, emitted once here so the roadmap markdown and the directory page
// cannot drift apart — they both render THIS string.
const descHead = r => { const m=totalOf(r), ch=chapters(r);
  return `${durPlain(m)} Study With Me ${r.kind==='flow' ? 'deep work timer — one unbroken block'
            : MODE[r.kind].toLowerCase()+' timer — '+shapeOf(r).iv+' focus blocks'} with `
    + `${SOUND[r.sound].toLowerCase()} under a ${LIGHT[r.light].cap.toLowerCase()} sky.
`
    + `A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.

`
    + `${sentence(r)}
`
    + (ch.length ? `
⏱ Chapters
${ch.join('\n')}

` : ''); };
const EMOJI = r => r.sound==='bell' ? '🔔' : /ocn/.test(r.sound) ? '🌊' : '🍃';
const modePhrase = r => { const sh = shapeOf(r);
  if (r.kind==='flow')   return 'Deep Work Timer, No Breaks for Flow State & ADHD';
  if (r.sound==='bell')  return `${sh.iv} Pomodoro Timer, No Music for Deep Focus & ADHD`;
  return `${sh.iv} Pomodoro Timer for Deep Focus & ADHD`;
};
// A title YouTube truncates is a title nobody reads: 100 is the hard cap, ~70 is what Search shows.
// The head carries every keyword that matters, so when a long sound name pushes past the cap the TAIL
// gives way — the sound is already named in the description, the tags and the thumbnail.
// "Ocean & Seabirds & Sunrise" reads like a typo, so a multi-word sound meets the light on a comma.
const title = r => {
  const head = `${durTxt(totalOf(r))} Study With Me ${EMOJI(r)} ${modePhrase(r)}`;
  const L = LIGHT[r.light].cap, S = SOUND[r.sound];
  if (r.sound === 'bell') return `${head} | ${L}`;
  const full = `${head} | ${S}${/ & /.test(S) ? ',' : ' &'} ${L}`;
  return full.length <= 100 ? full : `${head} | ${L}`;
};
for (const r of rows) if (title(r).length > 100)
  throw new Error(`title still too long (${title(r).length}): ${title(r)}`);
// 500 is YouTube's hard cap on the whole tag field. The Upload-defaults block pre-fills 281 of it
// (the channel-wide set: pomodoro, pomodoro timer, study with me, deep focus, ...), so this is what
// is left for the per-video tags pasted after it. Re-measure if that default block is ever edited.
const TAG_BUDGET = 500-281;
const NONEN = ['ポモドーロタイマー','अध्ययन टाइमर','temporizador de estudio','مؤقت للدراسة',
               'temporizador de estudo','핑크 노이즈 공부','timer belajar','çalışma zamanlayıcısı'];
// Tags carry what the title could not fit, in measured-volume order. The title already owns
// "study with me", "{iv} pomodoro timer" and "deep focus", so these are the misses:
//   study with me {N} hours 125,629/mo · pomodoro technique 69,409 · 50/10 pomodoro 47,568
//   study pomodoro 24,362 · pomodoro adhd 15,990 · pomodoro no music 9,661 (competition 10.4)
//   deep work 654,229 · flow state 316,535 — flow rows only, where they are the actual promise
const tags = (r,i) => { const L=LIGHT[r.light], m=totalOf(r), h=Math.floor(m/60), sh=shapeOf(r), t=[];
  if (r.kind!=='flow') t.push(`${sh.iv} pomodoro`, `${sh.focus} minute pomodoro`, 'pomodoro technique');
  else t.push('deep work', 'flow state', 'deep work timer', 'study with me no break');
  if (m%60===0) t.push(`${h} hour timer`, `study with me ${h} hours`);   // 125,629/mo at h=3
  t.push(`${L.cap.toLowerCase()} ambience`, 'pomodoro adhd');
  if (r.sound==='bell') t.push('pomodoro no music','silent study timer');
  t.push(NONEN[i%NONEN.length]);
  while (t.join(', ').length>TAG_BUDGET) t.splice(-2,1);
  return t.join(', '); };

const PH = {
  '1':['MONTH 1 — chosen from search volume, not taste',
     'Every row is **Custom mode**, the only mode that lands on an exact round hour. Titles lead with **study with me** (2,533,520/mo — six times `pomodoro timer`) and carry the duration, because `2 hour timer` alone is **204,296/mo**. **Midnight earns its slots on data**, not vibes: `study with me late night` is 6,242/mo.'],
  '2':['MONTH 2+ — a HOLDING list, not a plan',
     '**Do not shoot these blind.** Month 1’s Analytics decide which axis actually earned its views — duration, light, or sound — and Month 2 gets rewritten from that. These rows exist so the shape of the next expansion is visible, nothing more. Re-cut them with the directory’s **Export next month** once the numbers are in.'],
};

const esc = s => s.replace(/\|/g,'\\|');

// ── Month plan as JSON ───────────────────────────────────────────────────────────────────────────
// The directory page renders THIS, not the 900M-combination space. One source of truth: the checklist
// you tick and the sheet you shoot from are generated together and cannot drift.
const monthPlan = rows.filter(r => r.phase === '1').slice(0, DAYS).map((r, i) => {
  const m = totalOf(r);
  return {
    day: i + 1, date: dayDate(i + 1),
    id: slug(r),
    // Rows are emitted interleaved (session, then its bell twin), so a twin's partner is simply the
    // row beside it. The old version hardcoded 'ocn' and pointed every silent row at a session that
    // does not exist the moment sand/breeze/birds sessions are in the list.
    pairId: slug(rows[r.sound==='bell' ? i-1 : i+1]),
    silent: r.sound === 'bell',
    mode: MODE[r.kind], interval: shapeOf(r).iv, blocks: shapeOf(r).nFocus,
    setup: setupOf(r).replace(/\*\*/g,''),
    minutes: m, duration: durPlain(m),
    light: LIGHT[r.light].cap, lightSetup: LIGHT[r.light].setup,
    sound: soundSetup(r.sound), audio: audioCell(r.sound),
    numerals: numeralsOf(r, Math.floor(i/2)),
    title: title(r), tags: tags(r, i+1), chapters: chapters(r), desc: descHead(r),
    preset: presetURL(r), sentence: sentence(r),
  };
});
// ── Never publish the same video twice ───────────────────────────────────────────────────────────
// This is the one failure that is genuinely unrecoverable: re-uploading a session already on the
// channel is exactly what the inauthentic-content policy exists to catch (see section 4), and no
// amount of good metadata undoes it. Human memory is not an adequate control across 30 videos a month
// for years, so the ledger is.
//
// published.json is the permanent record of every video actually RECORDED, committed to git. It is
// keyed on the slug, which encodes mode + interval + length + sky + sound — everything that makes a
// video that video. Numerals are deliberately NOT in the key: the same session under a different
// numeral colour is the same video to a viewer and to YouTube, and treating it as new is precisely the
// self-deception that gets channels struck.
//
// The month is part of each entry so this month's own recorded rows do not trip the check. Any id that
// reappears under a DIFFERENT month is a genuine repeat and throws.
{ const LEDGER = __dirname + '/published.json';
  const past = fs.existsSync(LEDGER) ? JSON.parse(fs.readFileSync(LEDGER, 'utf8')) : [];
  const elsewhere = new Map(past.filter(p => p.month !== MONTH).map(p => [p.id, p]));
  const repeats = monthPlan.filter(v => elsewhere.has(v.id));
  if (repeats.length) throw new Error(
    `REPEAT UPLOAD BLOCKED — ${repeats.length} video(s) already recorded:`
    + repeats.map(v => `\n  ${v.id}  first recorded ${elsewhere.get(v.id).date} (${elsewhere.get(v.id).month})`).join('')
    + `\nChange the offending rows in UNIQUE. Never publish a session twice.`);
  console.log(`repeat check: ${monthPlan.length} vs ${past.length} already recorded ✓`);
}

// ── The numeral rules are asserted, not assumed ──────────────────────────────────────────────────
// Every one of these has already shipped wrong once. A generator that can still emit a bad config is
// a generator that eventually will.
{ const OK_FILL = ['solid','glass'], OK_COL = ['White #ffffff','Charcoal #20242e'];
  for (const v of monthPlan){
    const [vis, place, fill, font, sep, ...col] = v.numerals.split(' · ');
    const colour = col.join(' · ');
    if (!['Always','5 min'].includes(vis))
      throw new Error(`${v.id}: visibility "${vis}" — Always or 5 min only. Never and hover are both out.`);
    if (!OK_FILL.includes(fill))     throw new Error(`${v.id}: fill "${fill}" — only ${OK_FILL.join('/')}`);
    if (!OK_COL.includes(colour))    throw new Error(`${v.id}: colour "${colour}" — only white or charcoal`);
    if (colour.startsWith('Charcoal') && !['Midday','Sunrise','Sunset'].includes(v.light))
      throw new Error(`${v.id}: charcoal on "${v.light}" — no sun in that session; sun sessions only`);
    if ((place === 'middle' || place === 'ledge') && sep !== 'none')
      throw new Error(`${v.id}: ${place} must have NO separator, got "${sep}"`);
    if ((place === 'horizon' || place === 'top') && !['colon','dot'].includes(sep))
      throw new Error(`${v.id}: ${place} needs colon or dot, got "${sep}"`);
  }
  // A bell twin is the same video with the sound off. Anything else visible must match exactly.
  for (const v of monthPlan.filter(x => x.silent)){
    const twin = monthPlan.find(x => x.id === v.pairId);
    for (const k of ['numerals','lightSetup','mode','interval','blocks','duration','setup'])
      if (v[k] !== twin[k]) throw new Error(`${v.id} differs from its session ${twin.id} on ${k}: "${v[k]}" vs "${twin[k]}"`);
  }
  { const looks = monthPlan.filter(v => !v.silent).map(v => v.numerals);
    const dupe = looks.find((x, n) => looks.indexOf(x) !== n);
    if (dupe) throw new Error(`two sessions share a look: ${dupe}`); }
  if (monthPlan[0].id !== 'P50-10x2h_sunset_ocn')
    throw new Error(`session 1 is now ${monthPlan[0].id} — the PINNED config belongs to the PUBLISHED `
      + `video P50-10x2h_sunset_ocn. Re-key or drop the pin before reordering UNIQUE.`);
  console.log(`numeral rules + twin parity: ${monthPlan.length} videos ✓`);
}

// Written next to the directory page so it can be fetched with no build step and no server.
fs.writeFileSync(__dirname + '/../../tools/video-directory/month.json',
  JSON.stringify({ month:MONTH, label:MONTH_LABEL, start:START, days:DAYS,
     // An odd day count leaves the last session without its bell twin inside this month. Name it, so
     // next month's list opens with it instead of silently losing the pair.
     carryTwin: monthPlan.length % 2 ? slug(rows.filter(r => r.phase === '1')[monthPlan.length]) : null,
     videos:monthPlan }, null, 1));
console.log(`month.json: ${monthPlan.length} videos (${monthPlan.filter(v=>!v.silent).length} sessions x 2)`);

let tbl='', cur='', i=0, n=0;
for (const r of rows) {
  if (r.phase!==cur){ cur=r.phase; const c=rows.filter(x=>x.phase===cur).length;
    tbl += `\n### ${PH[cur][0]}\n\n${PH[cur][1]}\n\n`
      + `**${c} videos** (one capture each) · ~${(c/30).toFixed(1)} months at one capture a day\n\n`
      + '| ✓ | # | ID | Mode · timer · length · breaks | Time of day · Sun&moon | Numerals: show · place · fill · font · sep · colour | Audio (per-sound · master) | Title | Extra tags | Video ID |\n'
      + '|---|---|---|---|---|---|---|---|---|---|\n'; }
  n++; i++;
  const L=LIGHT[r.light], m=totalOf(r), sh=shapeOf(r);
  const cfg = `**${MODE[r.kind]}** · ${setupOf(r)} → ${durPlain(m)} · ${sh.nBreak} breaks`;
  const col=L.cols[i%L.cols.length];
  tbl += `| ☐ | ${String(n).padStart(2,'0')} | \`${slug(r)}\` | ${cfg} | ${L.setup} · Show `
      +  `| ${numeralsOf(r, Math.floor((i-1)/2))} `
      +  `| ${audioCell(r.sound)} | ${esc(title(r))} | ${tags(r,i)} **(${tags(r,i).length} ch)** | |\n`;
}

let blocks='', bi=0;
for (const r of rows.filter(x=>x.phase==='1')) { bi++;
  const m=totalOf(r), ch=chapters(r), setupTxt = `${MODE[r.kind]} · ${setupOf(r)}`;
  blocks += `\n<details>\n<summary><code>${slug(r)}</code> — ${title(r)}</summary>\n\n`
    + `**Setup:** ${setupTxt} · ${LIGHT[r.light].setup} · ${soundSetup(r.sound)}\n\n`
    + `**Verified length: ${durPlain(m)} exactly.**\n\n**Title:** ${title(r)}\n\n`
    + `**Extra tags** — paste after the Upload-defaults tags (${tags(r,bi).length}/${TAG_BUDGET} chars):\n\n> ${tags(r,bi)}\n\n`
    + `**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,\n`
    + `originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the\n`
    + `head below changes per video, and it goes FIRST because the opening two lines are what appear in\n`
    + `search and above the "…more" fold.\n\n\`\`\`\n`
    + descHead(r)
    + (LINKS_OK ? `▶ Run this exact session free:\n   ${presetURL(r).replace(/^https:\/\//, '')}\n` : '')
    + `\`\`\`\n`
    + (LINKS_OK ? '' : `\n> ⚠️ No preset link: this channel cannot post links yet (advanced features pending). Flip\n`
        + `> \`LINKS_OK = true\` at the top of gen-roadmap.cjs the day verification lands and regenerate —\n`
        + `> every row gains its deep link. Preset for this row: \`${presetURL(r)}\`\n`)
    + `\n</details>\n`;
}

const head = fs.readFileSync(__dirname + '/_head.md','utf8');
fs.writeFileSync(__dirname + '/video-roadmap.md',
  head + tbl + '\n---\n\n## Ready-to-paste blocks — Month 1\n\n'
  + 'Month 1 only, deliberately. Once these land we will have real Analytics, and later phases should be\n'
  + 'rewritten from that data rather than frozen today.\n' + blocks);
console.log(`${rows.length} videos → ${(rows.length/30).toFixed(1)} months at one a day; A-blocks: ${rows.filter(x=>x.phase==='1').length}`);
// prove the headline claim
const bad = rows.filter(r=>totalOf(r)%60!==0);
console.log(bad.length ? `** ${bad.length} rows are NOT round hours: ${bad.slice(0,3).map(slug).join(', ')} **` : 'every row is an exact round hour ✓');
