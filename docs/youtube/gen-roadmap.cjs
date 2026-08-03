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
const stOf = r => r.kind==='custom'
  ? { mode:'custom', customMode:'count', customWork:ROUND[r.hours].work,
      customBreaks:ROUND[r.hours].breaks, customBreakLen:ROUND[r.hours].len }
  : { mode:'pomodoro', pomoFocus:+r.iv.split('/')[0], pomoBreak:+r.iv.split('/')[1], blocks:r.blocks,
      uniform:true };   // /stage: uniform blocks + trailing break => blocks x (focus+break) exactly

const PLACE=['middle','horizon','ledge','top'], FILL=['solid','glass','outline'],
      FONT=['Serif','Jost'], SEP=['none','colon','dot'];

const rows=[];
const addC=(phase,hours,light,sound)=>rows.push({phase,kind:'custom',hours,light,sound});
const addP=(phase,iv,blocks,light,sound)=>rows.push({phase,kind:'pomo',iv,blocks,light,sound});

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
const UNIQUE = [
  ['50/10', 2, 'sunset',   'ocn'],           // ← PUBLISHED 2026-08-03, do not change
  ['50/10', 2, 'midnight', 'ocn+brz'],       // quiet night: sea and a little wind
  ['50/10', 2, 'sunrise',  'ocn+brd'],       // dawn chorus
  ['50/10', 2, 'midday',   'brz+brd'],       // bright, airy
  ['50/10', 2, 'twilight', 'ocn+snd'],
  ['50/10', 2, 'predawn',  'snd'],           // the stillest hour: only the sand
  ['50/10', 4, 'sunset',   'ocn+brz'],
  ['50/10', 4, 'midnight', 'ocn'],
  ['50/10', 4, 'sunrise',  'ocn+snd+brd'],
  ['50/10', 4, 'midday',   'all4'],          // full shore ambience
  ['25/5',  4, 'sunset',   'snd+brz'],
  ['25/5',  4, 'midnight', 'ocn+snd'],
  ['25/5',  8, 'sunset',   'ocn+brd'],
  ['25/5',  8, 'midnight', 'brz'],           // shore breeze alone
  ['50/10', 1, 'sunset',   'snd+brz+brd'],
];
// Interleaved so the silent twin follows its own session the very next day — the pair reads as a
// deliberate choice on the channel page rather than two unrelated uploads.
UNIQUE.forEach(([iv, blocks, light, snd]) => {
  addP('1', iv, blocks, light, snd);
  addP('1', iv, blocks, light, 'bell');
});

const key = r => [r.kind, r.iv||'', r.blocks||r.hours, r.light, r.sound].join('|');
{ const seen=new Map();
  rows.forEach((r,i)=>{ const k=key(r);
    if(seen.has(k)) throw new Error(`DUPLICATE row ${i+1} (first at ${seen.get(k)+1}): ${k}`);
    seen.set(k,i); });
  console.log(`unique combinations: ${seen.size}/${rows.length} ✓`); }

// Minutes are ALWAYS two digits, so the first chapter reads 00:00 rather than 0:00. YouTube's chapter
// docs are explicit — "make sure that the first timestamp you list starts with 00:00" — and with 0:00 the
// timestamps still render as blue links (any timestamp does) while chapter validation silently fails and
// the progress bar never segments. One missing zero costs you the chapter markers entirely.
const ts=m=>{const s=Math.round(m*60),h=Math.floor(s/3600),mm=Math.floor(s%3600/60),ss=s%60;
  return h?`${h}:${String(mm).padStart(2,'0')}:${String(ss).padStart(2,'0')}`
          :`${String(mm).padStart(2,'0')}:${String(ss).padStart(2,'0')}`;};
const totalOf = r => P.totalMinOf(P.buildPlan(stOf(r)));
// ── Guard-rails, asserted not trusted ────────────────────────────────────────────────────────────
// A short block is a worse product: 15/5 means the viewer is interrupted every fifteen minutes, and a
// sub-30-minute timer is not something anyone leaves running. Both would also read as filler in a
// library, which is exactly what the inauthentic-content policy punishes. The generator refuses to emit
// them rather than relying on whoever edits UNIQUE next month to remember.
const slugOf = r => `P${r.iv.replace('/','-')}x${r.blocks}_${r.light}_${r.sound}`;
const MIN_FOCUS = 25, MIN_BREAK = 5, MIN_TOTAL = 30;
for (const r of rows){
  if (r.kind !== 'pomo') continue;
  const [w, b] = r.iv.split('/').map(Number);
  if (w < MIN_FOCUS) throw new Error(`focus block too short: ${r.iv} (min ${MIN_FOCUS})`);
  if (b < MIN_BREAK) throw new Error(`break too short: ${r.iv} (min ${MIN_BREAK})`);
  const t = P.totalMinOf(P.buildPlan(stOf(r)));
  if (t < MIN_TOTAL) throw new Error(`video too short: ${slugOf(r)} = ${t}min (min ${MIN_TOTAL})`);
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
  const q = ['mode=' + (r.kind==='custom' ? 'custom' : 'pomodoro')];
  if (r.kind !== 'custom'){ const [w,b]=r.iv.split('/');
    q.push('work='+w, 'break='+b, 'blocks='+r.blocks); }
  if (TOD[r.light]) q.push('phase=' + TOD[r.light]);
  q.push('sound=' + (r.sound==='bell' ? '' : r.sound.split('+').map(k=>SND_ID[k]).join(',')));
  return 'https://sustaintimer.com/?' + q.join('&');
};
// Chapters come straight off the real plan, so the long-break-every-4th rule is baked in.
// The VIDEO clock is not the SESSION clock. /stage records the intro card (INTRO_MS 10 s) and the 3-2-1
// countdown before the engine starts, so the first focus block begins 13 s into the file — every session
// timestamp has to shift by that much or the chapters point at the wrong moments all the way through.
// Keep in step with stage.astro: INTRO_MS/1000 + 3.
const LEAD_IN = 13 / 60;                       // minutes, to match the plan's units
// No closing chapter for the thank-you card: recording stops 5 s into it (OUTRO_STOP_MS), and a chapter
// under 10 s is invalid and would silently kill the markers for the whole video. The last break absorbs it.
const chapters = r => { const plan=P.buildPlan(stOf(r)); const out=[`${ts(0)} Intro`]; let t=LEAD_IN,f=0,b=0;
  for (const seg of plan){ if(seg.kind==='focus'){ out.push(`${ts(t)} Focus ${++f}`); } else { out.push(`${ts(t)} Break ${++b}`); } t+=seg.min; }
  return out; };
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
const slug = r => (r.kind==='custom' ? `C${r.hours}h` : `P${r.iv.replace('/','-')}x${r.blocks}`)
  + `_${r.light}_${r.sound.replace(/\+/g,'-')}`;
// ── Title formula ───────────────────────────────────────────────────────────────────────────────────
// Search + Suggested show ~60-70 chars, mobile truncates near 50, and front-loading the primary keyword
// inside the first 30 chars is worth up to ~20% in search ranking. So the opening characters are the
// whole asset and they go to the biggest terms, in volume order (vidIQ, 2026-08-03):
//     study with me 2,525,198/mo   ·   pomodoro 982,562   ·   2 hour timer 204,296
//     study with me sunset 12,415  ·   50/10 pomodoro ~5,000
// The earlier formula opened on the interval — a ~5k term in the prime slot, pushing the 2.5M term out
// to char 37. Now "{N} Hour Study With Me" leads, which lands TWO high-volume strings in the first 20
// characters, and the light (our differentiator, and its own real query) sits by char ~30.
//
// Shape is Focus with Elora's — a 157-SUBSCRIBER channel that pulled 8,442 views on
// "4 Hour Study with Me | Pomodoro Timer 50/10 | Deep Focus Lofi Music". The title did the work.
// LOCKED to the format of video #1 (published 2026-08-03), which the founder settled on after testing
// against vidIQ's scorer:
//   2-Hour Study With Me | Pomodoro 50/10 for Focus & ADHD | Ocean Waves & Sunset
// Front-loads "{N}-Hour Study With Me" — study with me is 2,525,198/mo, the biggest term in the niche —
// then Pomodoro (982,562) and the interval, all inside the ~50 chars a phone shows. The sound and light
// ride in the tail: still indexed, and the thumbnail already says which sky it is.
const title = r => { const L=LIGHT[r.light], S=SOUND[r.sound], m=totalOf(r);
  const head = `${durTxt(m)} Study With Me | Pomodoro ${r.kind==='custom' ? '' : r.iv + ' '}for Focus & ADHD`;
  return r.sound === 'bell' ? `${head} | No Music, ${L.cap}` : `${head} | ${S} & ${L.cap}`; };
const TAG_BUDGET = 500-353;
const NONEN = ['ポモドーロタイマー','अध्ययन टाइमर','temporizador de estudio','مؤقت للدراسة',
               'temporizador de estudo','핑크 노이즈 공부','timer belajar','çalışma zamanlayıcısı'];
const tags = (r,i) => { const L=LIGHT[r.light], m=totalOf(r), h=Math.floor(m/60), t=[];
  if (r.kind==='pomo'){ const [w,b]=r.iv.split('/'); t.push(`${w}/${b} pomodoro`,`${w} ${b} pomodoro`,`${w} minute pomodoro`); }
  if (m%60===0) t.push(`${h} hour timer`,`${h} hour study timer`);   // "2 hour timer" = 204k/mo
  t.push(`${L.cap.toLowerCase()} ambience`);
  if (r.sound==='bell') t.push('silent timer','no music pomodoro');
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
const monthPlan = rows.filter(r => r.phase === '1').map((r, i) => {
  const m = totalOf(r);
  return {
    day: i + 1,
    id: slug(r),
    pairId: slug({ ...r, sound: 'ocn' }),        // the silent twin points at its own session
    silent: r.sound === 'bell',
    mode: 'Pomodoro', interval: r.iv, blocks: r.blocks,
    minutes: m, duration: durPlain(m),
    light: LIGHT[r.light].cap, lightSetup: LIGHT[r.light].setup,
    sound: soundSetup(r.sound), audio: audioCell(r.sound),
    numerals: `Always · ${PLACE[(i+1)%4]} · ${FILL[(i+1)%3]} · ${FONT[(i+1)%2]} · ${SEP[(i+1)%3]} · ${LIGHT[r.light].cols[(i+1) % LIGHT[r.light].cols.length]}`,
    title: title(r), tags: tags(r, i+1), chapters: chapters(r),
    preset: presetURL(r), sentence: sentence(r),
  };
});
// Written next to the directory page so it can be fetched with no build step and no server.
fs.writeFileSync(__dirname + '/../../tools/video-directory/month.json',
  JSON.stringify({ month:'2026-08', label:'August 2026', videos:monthPlan }, null, 1));
console.log(`month.json: ${monthPlan.length} videos (${monthPlan.filter(v=>!v.silent).length} sessions x 2)`);

let tbl='', cur='', i=0, n=0;
for (const r of rows) {
  if (r.phase!==cur){ cur=r.phase; const c=rows.filter(x=>x.phase===cur).length;
    tbl += `\n### ${PH[cur][0]}\n\n${PH[cur][1]}\n\n`
      + `**${c} videos** (one capture each) · ~${(c/30).toFixed(1)} months at one capture a day\n\n`
      + '| ✓ | # | ID | Mode · timer · length · breaks | Time of day · Sun&moon | Numerals: show · place · fill · font · sep · colour | Audio (per-sound · master) | Title | Extra tags | Video ID |\n'
      + '|---|---|---|---|---|---|---|---|---|---|\n'; }
  n++; i++;
  const L=LIGHT[r.light], m=totalOf(r), R=ROUND[r.hours];
  const cfg = r.kind==='custom'
    ? `**Custom → By count** · work **${R.work}m** · breaks **${R.breaks}** · break len **${R.len}m** → ${durPlain(m)}`
    : `**Pomodoro** · ${r.iv} · blocks **${r.blocks}** → ${durPlain(m)} · ${nBreaks(r)} breaks`;
  const col=L.cols[i%L.cols.length];
  tbl += `| ☐ | ${String(n).padStart(2,'0')} | \`${slug(r)}\` | ${cfg} | ${L.setup} · Show `
      +  `| Always · ${PLACE[i%4]} · ${FILL[i%3]} · ${FONT[i%2]} · ${SEP[i%3]} · ${col} `
      +  `| ${audioCell(r.sound)} | ${esc(title(r))} | ${tags(r,i)} **(${tags(r,i).length} ch)** | |\n`;
}

let blocks='', bi=0;
for (const r of rows.filter(x=>x.phase==='1')) { bi++;
  const m=totalOf(r), ch=chapters(r), R=ROUND[r.hours];
  const setupTxt = r.kind==='custom'
    ? `Custom → By count · work **${R.work}m** · breaks **${R.breaks}** · break length **${R.len}m**`
    : `Pomodoro · focus **${r.iv.split('/')[0]}m** · break **${r.iv.split('/')[1]}m** · blocks **${r.blocks}**`;
  blocks += `\n<details>\n<summary><code>${slug(r)}</code> — ${title(r)}</summary>\n\n`
    + `**Setup:** ${setupTxt} · ${LIGHT[r.light].setup} · ${soundSetup(r.sound)}\n\n`
    + `**Verified length: ${durPlain(m)} exactly.**\n\n**Title:** ${title(r)}\n\n`
    + `**Extra tags** — paste after the Upload-defaults tags (${tags(r,bi).length}/${TAG_BUDGET} chars):\n\n> ${tags(r,bi)}\n\n`
    + `**Description — paste ABOVE the Upload-defaults text.** The standing block (channel blurb,\n`
    + `originality declaration, hashtags) lives in Upload defaults and pre-fills every video; only the\n`
    + `head below changes per video, and it goes FIRST because the opening two lines are what appear in\n`
    + `search and above the "…more" fold.\n\n\`\`\`\n`
    + `${durPlain(m)} Study With Me pomodoro timer — ${r.kind==='pomo' ? r.iv + ' focus blocks' : 'timed focus blocks'} `
    + `with ${SOUND[r.sound].toLowerCase()} under a ${LIGHT[r.light].cap.toLowerCase()} sky.\n`
    + `A calm, no-talking study timer for deep focus, ADHD, exam revision, coding and long work sessions.\n\n`
    + `${sentence(r)}\n\n`
    + `⏱ Chapters\n${ch.join('\n')}\n\n`
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
