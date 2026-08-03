// Generator for video-roadmap.md.  Run:  node docs/youtube/gen-roadmap.cjs
//
// Durations and chapters are computed from the SHIPPED plan.js, never from my own arithmetic — the real
// builder drops the trailing break AND inserts a long break every 4th block, so hand-derived numbers were
// wrong (a "4-Hour" 50/10 video is really 3h50m). Two tracks fall out of that:
//
//   ROUND-HOUR track  → Custom mode, which CAN hit 60/120/180… exactly. Chases "N hour timer" queries.
//   INTERVAL track    → Pomodoro mode, titled with its TRUE length. Chases "50/10 pomodoro" queries.
const fs = require('fs');
eval(fs.readFileSync(__dirname + '/../../web-astro/public/js/plan.js', 'utf8'));   // sets module.exports
const P = module.exports;

const LIGHT = {
  predawn:  { cap:'Pre-Dawn',      emo:'🌌', setup:'Hold one light → Pre-dawn',  cols:['Ivory #f2ecdd','White #ffffff'] },
  sunrise:  { cap:'Sunrise',       emo:'🌅', setup:'Hold one light → Sunrise',   cols:['Ivory #f2ecdd','Charcoal #20242e'] },
  midday:   { cap:'Midday',        emo:'☀️', setup:'Hold one light → Midday',    cols:['Charcoal #20242e','White #ffffff'] },
  sunset:   { cap:'Sunset',        emo:'🌇', setup:'Hold one light → Sunset',    cols:['Ivory #f2ecdd','White #ffffff'] },
  twilight: { cap:'Twilight',      emo:'🌆', setup:'Hold one light → Twilight',  cols:['Gold #eaca78','Ivory #f2ecdd'] },
  midnight: { cap:'Midnight',      emo:'🌙', setup:'Hold one light → Midnight',  cols:['Gold #eaca78','White #ffffff'] },
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

// ── MONTH 1 — 30 videos, chosen from search volume, not taste ────────────────────────────────────
// vidIQ, 2026-08-03:  study with me 2,533,520/mo · 2 hour timer 204,296 · study with me pomodoro 47,568
//                     study with me 4 hours 44,753 · 60 minute timer 33,037 · study timer 103,138
//                     study with me late night 6,242  ← midnight is a QUERY, not just our aesthetic
//                     study with me no break no music 4,388  ← the bell-only rows
// REAL Pomodoro throughout: /stage's uniform mode makes 50/10 x N land on exactly N hours, so there is no
// longer any Custom-mode workaround and no ambiguity about whether a video "is a Pomodoro".
for (const l of ['sunset','midnight','sunrise','midday','twilight','predawn']) addP('1','50/10',2,l,'ocn'); // 2h x6
for (const l of ['sunset','midnight','sunrise','midday','twilight','predawn']) addP('1','50/10',4,l,'ocn'); // 4h x6
for (const l of ['sunset','midnight','sunrise','midday'])                      addP('1','25/5', 4,l,'ocn'); // 2h x4
for (const l of ['sunset','midnight','sunrise','midday'])                      addP('1','25/5', 8,l,'ocn'); // 4h x4
for (const l of ['sunset','midnight','twilight'])                              addP('1','50/10',1,l,'ocn'); // 1h x3
for (const l of ['sunset','midnight','twilight'])                              addP('1','50/10',3,l,'ocn'); // 3h x3
for (const b of [2,4]) for (const l of ['sunset','midnight'])                  addP('1','50/10',b,l,'bell');// x4

// ── MONTH 2+ — a HOLDING list, not a plan ────────────────────────────────────────────────────────
// Do not shoot these blind. Month 1's Analytics decide which axis actually earned its views, and Month 2
// gets rewritten from that. They are here so the shape of the next expansion is visible, nothing more.
for (const b of [6,8]) for (const l of ['sunset','midnight','twilight']) addP('2','50/10',b,l,'ocn');
// Blocks chosen PER INTERVAL so uniform mode still lands on a round hour: total = blocks x (focus+break).
// 30/10 cycles every 40m (x3=2h, x6=4h); 90/15 every 105m (x4=7h); 60/10 every 70m (x6=7h).
for (const [iv,b] of [['30/10',3],['30/10',6],['90/15',4],['60/10',6]])
  for (const l of ['sunset','midnight']) addP('2',iv,b,l,'ocn');
for (const b of [2,4]) for (const l of ['intonight','intoday','wholeday']) addP('2','50/10',b,l,'ocn');
for (const s2 of ['snd','brz','brd','ocn+brd','ocn+brz','ocn+snd','all4']) addP('2','50/10',4,'sunset',s2);

const key = r => [r.kind, r.iv||'', r.blocks||r.hours, r.light, r.sound].join('|');
{ const seen=new Map();
  rows.forEach((r,i)=>{ const k=key(r);
    if(seen.has(k)) throw new Error(`DUPLICATE row ${i+1} (first at ${seen.get(k)+1}): ${k}`);
    seen.set(k,i); });
  console.log(`unique combinations: ${seen.size}/${rows.length} ✓`); }

const ts=m=>{const s=Math.round(m*60),h=Math.floor(s/3600),mm=Math.floor(s%3600/60),ss=s%60;
  return h?`${h}:${String(mm).padStart(2,'0')}:${String(ss).padStart(2,'0')}`:`${mm}:${String(ss).padStart(2,'0')}`;};
const totalOf = r => P.totalMinOf(P.buildPlan(stOf(r)));
const durTxt = m => { const h=Math.floor(m/60), mm=m%60;
  return h ? (mm ? `${h}h ${mm}m` : `${h}-Hour`) : `${mm}-Min`; };
const durPlain = m => { const h=Math.floor(m/60), mm=m%60;
  return h ? (mm ? `${h} hour ${mm} min` : `${h} hour`) : `${mm} min`; };
// Chapters come straight off the real plan, so the long-break-every-4th rule is baked in.
const chapters = r => { const plan=P.buildPlan(stOf(r)); const out=[]; let t=0,f=0,b=0;
  for (const seg of plan){ if(seg.kind==='focus'){ out.push(`${ts(t)} Focus ${++f}`); } else { out.push(`${ts(t)} Break ${++b}`); } t+=seg.min; }
  return out; };
const nBreaks = r => P.buildPlan(stOf(r)).filter(s=>s.kind!=='focus').length;

const slug = r => (r.kind==='custom' ? `C${r.hours}h` : `P${r.iv.replace('/','-')}x${r.blocks}`)
  + `_${r.light}_${r.sound.replace(/\+/g,'-')}`;
const title = r => { const L=LIGHT[r.light], S=SOUND[r.sound], m=totalOf(r);
  if (r.sound==='bell') return `${durTxt(m)} Study With Me | No Music 🔔 Bell Only | ${L.cap} Focus Timer`;
  return r.kind==='custom'
    ? `${durTxt(m)} Study With Me ${L.emo} ${L.cap} Pomodoro Timer | ${S} for Deep Focus`
    : `${r.iv} Pomodoro Timer ${L.emo} ${durTxt(m)} ${L.cap} Study With Me | ${S} for Deep Focus`; };
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
let tbl='', cur='', i=0, n=0;
for (const r of rows) {
  if (r.phase!==cur){ cur=r.phase; const c=rows.filter(x=>x.phase===cur).length;
    tbl += `\n### ${PH[cur][0].split(' — ')[0]} — ${PH[cur][0]}\n\n${PH[cur][1]}\n\n`
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
    + `**Description:**\n\n\`\`\`\n`
    + `${durPlain(m).replace(/^\w/,c=>c.toUpperCase())} of ambient focus under a ${LIGHT[r.light].cap.toLowerCase()} sky, with ${SOUND[r.sound].toLowerCase()}.\n`
    + `Press play, start your block, and let the sand do the counting.\n\n`
    + `▶ Run this exact session yourself — free, no sign-up:\n   https://sustaintimer.com\n\n`
    + `⏱ Chapters\n${ch.map(c=>'   '+c).join('\n')}\n\n{{BOILERPLATE}}\n\`\`\`\n\n</details>\n`;
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
