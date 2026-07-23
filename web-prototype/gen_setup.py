#!/usr/bin/env python
# Setup screen — EXACT app parity (lib/ui/setup_screen.dart + lib/session/session_plan.dart),
# rendered in the locked web glass/type system.
#   3 modes: Flow / Pomodoro / Custom.  Endless is a TOGGLE (not a mode), shown when
#   mode != pomodoro && plan.isSingleFocus — same rule as the app.
#   Stamina is OMITTED (Pro-only, and founder-excluded for web Flow).
# Plan builders below are a faithful JS port of SessionPlan.*, so the big total duration
# and the cadence subline are computed from a real plan, exactly like the app.
import base64, io, os
from PIL import Image

ROOT = r"D:\Dev\Trilumos\hourglass\web-prototype\plates-phases"
OUT  = r"D:\Dev\Trilumos\hourglass\.superpowers\brainstorm\2436-1784803145\content\setup-screen.html"

GRAIN = ("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='220' height='220'%3E"
         "%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.82' numOctaves='3' "
         "stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")

im = Image.open(os.path.join(ROOT, "sunset.png")).convert("RGB")
im = im.resize((1600, round(im.height * 1600 / im.width)), Image.LANCZOS)
b = io.BytesIO(); im.save(b, "JPEG", quality=82, subsampling=0)
bg = "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()

PANEL = """    <button class="s-backbtn glass-liquid" id="backBtn" aria-label="Back">&#8592;</button>
    <button class="s-resume glass-liquid" id="resumeBtn"><span>Begin Focus &#8594;</span></button>
    <div class="s-stack" id="stack">
      <div class="s-modes glass">
        <button class="mode on" data-m="flow">Flow</button
        ><button class="mode" data-m="pomodoro">Pomodoro</button
        ><button class="mode" data-m="custom">Custom</button
        ><button class="mode" data-m="endless">Endless</button>
      </div>
      <div class="setup glass">
      <div class="s-lbl">Intention</div>
      <input class="s-intent" placeholder="What are you focusing on?" />

      <div class="s-total">
        <div class="s-lbl c" id="topLabel">BLOCK LENGTH</div>
        <div class="s-big" id="bigDur"></div>
        <div class="s-sub" id="subline"></div>
      </div>

      <div class="s-ctrl" id="ctrl"></div>

      <div class="s-endless" id="endlessRow">
        <div><div class="s-et">Endless flow</div>
          <div class="s-eh">Keep going past the goal until you stop.</div></div>
        <button class="sw" id="endlessSw" role="switch" aria-checked="false"><i></i></button>
      </div>

      <div class="s-desc" id="modeDesc"></div>
      <button class="s-begin glass-liquid"><span>Begin</span></button>
      </div>
    </div>"""

SCRIPT = r"""
(function(){
  // ── Faithful port of SessionPlan.* (lib/session/session_plan.dart) ─────────
  const F = m => ({kind:'focus', min:m}), R = m => ({kind:'rest', min:m});
  const flowBlock   = m => [F(m)];
  const pomodoroPlan = (work, shortB, longB, blocks, longEvery=4) => {
    const s=[]; for(let i=0;i<blocks;i++){ s.push(F(work));
      if(i !== blocks-1){ const n=i+1; s.push(R(longEvery>0 && n%longEvery===0 ? longB : shortB)); } }
    return s; };
  const flowmodoro = (totalMin, blocks) => {
    const base = blocks<=0 ? 0 : Math.floor(totalMin/blocks);
    if(blocks<=1 || base<=0) return [F(totalMin)];
    const rem = totalMin - base*blocks, rest = Math.min(60, Math.max(1, Math.round(base/5))), s=[];
    for(let i=0;i<blocks;i++){ const last=i===blocks-1; s.push(F(last?base+rem:base)); if(!last) s.push(R(rest)); }
    return s; };
  const customByCount = (totalMin, breaks, breakLen) => {
    const chunks = breaks+1, base = Math.floor(totalMin/chunks);
    if(breaks<=0 || base<=0) return [F(totalMin)];
    const rem = totalMin - base*chunks, s=[];
    for(let i=0;i<chunks;i++){ const last=i===chunks-1; s.push(F(last?base+rem:base)); if(!last) s.push(R(breakLen)); }
    return s; };
  const customByInterval = (totalMin, interval, breakLen) => {
    if(interval<=0 || totalMin<=interval) return [F(totalMin)];
    const s=[]; let left=totalMin;
    while(left>0){ const take=Math.min(left,interval); s.push(F(take)); left-=take; if(left>0) s.push(R(breakLen)); }
    return s; };

  const focusOf = p => p.filter(s=>s.kind==='focus');
  const restsOf = p => p.filter(s=>s.kind==='rest');
  const totalMinOf = p => p.reduce((a,s)=>a+s.min,0);
  const totalFocusOf = p => focusOf(p).reduce((a,s)=>a+s.min,0);
  const isSingleFocus = p => p.length===1 && p[0].kind==='focus';
  const fmt = m => { const h=Math.floor(m/60), mm=m%60;
    return h===0 ? mm+'m' : (mm===0 ? h+'h' : h+'h '+mm+'m'); };

  // ── State (defaults copied from the app) ──────────────────────────────────
  const RATIOS=[{w:25,s:5,l:15},{w:50,s:10,l:20},{w:52,s:17,l:25},{w:90,s:15,l:30}];
  const SOFT_CAP=90, LONG_EVERY=4;
  const st={ mode:'flow', flowMin:25, endless:false,
    pomoEntry:'duration', ratioIndex:0, blocks:4, pomoTarget:120, durBlocks:4,
    customMode:'count', customWork:120, customBreaks:3, customInterval:30, customBreakLen:10 };

  const DESC={ flow:'One unbroken block of deep focus — recovery comes after.',
    pomodoro:'Focus in cycles with short breaks between.',
    custom:'Design your own focus-and-break schedule.',
    // Endless is WEB-ONLY (not an app mode). Spec: one open focus segment, break
    // whenever the user says; the glass drains, flips and refills.
    endless:'Focus with no set end — you decide when to stop.' };

  const buildPlan = () => {
    if(st.mode==='flow') return flowBlock(st.flowMin);
    if(st.mode==='pomodoro'){
      if(st.pomoEntry==='duration') return flowmodoro(st.pomoTarget, st.durBlocks);
      const r=RATIOS[st.ratioIndex]; return pomodoroPlan(r.w,r.s,r.l,st.blocks,LONG_EVERY); }
    return st.customMode==='count'
      ? customByCount(st.customWork, st.customBreaks, st.customBreakLen)
      : customByInterval(st.customWork, st.customInterval, st.customBreakLen); };

  // ── Controls markup per mode (labels/ranges/hints exactly as the app) ─────
  const stepper=(id,label,val)=>`<div class="stp"><span class="stp-l">${label}</span>
    <button class="stp-b" data-step="${id}:-1">&#8722;</button>
    <span class="stp-v" id="v-${id}">${val}</span>
    <button class="stp-b" data-step="${id}:1">&#43;</button></div>`;
  const toggle=(id,a,b,sel)=>`<div class="sub2" data-toggle="${id}">
    <button class="${sel===0?'on':''}" data-i="0">${a}</button>
    <button class="${sel===1?'on':''}" data-i="1">${b}</button></div>`;
  const hint=t=>`<div class="s-hint">${t}</div>`;
  const head=t=>`<div class="s-head">${t}</div>`;

  function ctrlHTML(){
    if(st.mode==='endless'){
      return head('No set end')+hint('Focus with no set end — take a break whenever you want. '+
        'The glass drains, flips and refills for as long as you keep going.');
    }
    if(st.mode==='flow'){
      const fixed=[15,25,30,45,60,90].filter(m=>m<=SOFT_CAP);
      return head('Length')+hint('Pick a block length that fits your focus.')+
        '<div class="chips">'+fixed.map(m=>`<button class="chip ${m===st.flowMin?'on':''}" data-flow="${m}">${m} min</button>`).join('')+
        '<button class="chip out" data-flow="+5">+5</button></div>';
    }
    if(st.mode==='pomodoro'){
      const h = st.pomoEntry==='duration'
        ? 'Set your exact focus time — we split it into blocks with rests.'
        : 'Pick a classic work/break length and how many blocks.';
      let out = toggle('pomoEntry','By duration','By blocks', st.pomoEntry==='duration'?0:1)+hint(h);
      if(st.pomoEntry==='duration'){
        out += stepper('pomoTarget','Focus time',fmt(st.pomoTarget))+stepper('durBlocks','Blocks',st.durBlocks);
      } else {
        out += stepper('blocks','Focus blocks',st.blocks)+head('Work / break per block')+
          '<div class="chips">'+RATIOS.map((r,i)=>`<button class="chip ${i===st.ratioIndex?'on':''}" data-ratio="${i}">${r.w}/${r.s}</button>`).join('')+'</div>';
      }
      return out;
    }
    const h = st.customMode==='count'
      ? 'Choose how many breaks — spread evenly through your focus.'
      : 'Take a break every set interval of focus.';
    return stepper('customWork','Focus time',fmt(st.customWork))+head('Break schedule')+
      toggle('customMode','By count','By interval', st.customMode==='count'?0:1)+hint(h)+
      (st.customMode==='count' ? stepper('customBreaks','Number of breaks',st.customBreaks)
                               : stepper('customInterval','Break every',fmt(st.customInterval)))+
      stepper('customBreakLen','Break length',fmt(st.customBreakLen));
  }

  // ── Subline: read back from the generated plan (app's _subline) ───────────
  function subline(plan){
    if(st.mode==='flow'){
      // App also cites Focus Stamina here; stamina is omitted on web, so the
      // calm line drops that clause. The >90 caution is kept verbatim.
      return st.flowMin>SOFT_CAP
        ? {t:'Past ~90 min, focus tends to fade. A fresh block after a break often serves you better.', w:true}
        : {t:'One unbroken block — recovery comes after.', w:false};
    }
    const f=focusOf(plan), r=restsOf(plan);
    if(st.mode==='pomodoro'){
      if(st.pomoEntry==='duration'){
        if(!r.length) return {t:'One '+fmt(totalFocusOf(plan))+' block · no breaks', w:false};
        const avg=Math.round(totalFocusOf(plan)/f.length);
        return {t:f.length+' × ~'+avg+'m focus + '+r[0].min+'m break', w:false};
      }
      const ra=RATIOS[st.ratioIndex];
      let t=f.length+' rounds of '+ra.w+'m focus + '+ra.s+'m break';
      if(f.length>LONG_EVERY) t+='<br>'+ra.l+'m long break every '+LONG_EVERY+'th';
      return {t, w:false};
    }
    if(!r.length) return {t:'One '+fmt(totalFocusOf(plan))+' block · no breaks', w:false};
    const allEq=f.every(s=>s.min===f[0].min), avg=Math.round(totalFocusOf(plan)/f.length);
    return {t:(allEq? f.length+' × '+f[0].min+'m focus' : f.length+' × ~'+avg+'m focus')
      +' · '+r.length+' × '+r[0].min+'m break', w:false};
  }

  const $=s=>document.querySelector(s);
  function render(){
    if(st.mode==='endless'){
      $('#topLabel').textContent='NO SET END';
      $('#bigDur').innerHTML='<b>&#8734;</b>';
      $('#subline').innerHTML='Open focus · break whenever you say'; $('#subline').classList.remove('warn');
      $('#ctrl').innerHTML=ctrlHTML();
      $('#endlessRow').style.display='none';       // the mode IS endless
      $('#modeDesc').textContent=DESC.endless;
      document.querySelectorAll('.mode').forEach(b=>b.classList.toggle('on',b.dataset.m===st.mode));
      return;
    }
    const plan=buildPlan(), tot=totalMinOf(plan);
    $('#topLabel').textContent = st.mode==='flow' ? 'BLOCK LENGTH' : 'TOTAL TIME';
    const h=Math.floor(tot/60), mm=tot%60;
    $('#bigDur').innerHTML = h>0
      ? `<b>${h}</b><s>h</s>` + (mm>0?` <b>${mm}</b><s>m</s>`:'')
      : `<b>${mm}</b><s>min</s>`;
    const sl=subline(plan);
    $('#subline').innerHTML=sl.t; $('#subline').classList.toggle('warn',!!sl.w);
    $('#ctrl').innerHTML=ctrlHTML();
    // Endless toggle: same availability rule as the app.
    const avail = st.mode!=='pomodoro' && isSingleFocus(plan);
    $('#endlessRow').style.display = avail ? 'flex' : 'none';
    if(!avail) st.endless=false;
    $('#endlessSw').classList.toggle('on',st.endless);
    $('#endlessSw').setAttribute('aria-checked',String(st.endless));
    $('#modeDesc').textContent=DESC[st.mode];
    document.querySelectorAll('.mode').forEach(b=>b.classList.toggle('on',b.dataset.m===st.mode));
  }

  // Step ranges/increments copied from the app.
  const STEPS={ pomoTarget:{d:15,min:30,max:360}, durBlocks:{d:1,min:1,max:12},
    blocks:{d:1,min:1,max:16}, customWork:{d:15,min:15,max:480},
    customBreaks:{d:1,min:0,max:12}, customInterval:{d:5,min:10,max:120},
    customBreakLen:{d:1,min:1,max:30} };

  document.addEventListener('click',e=>{
    const t=e.target.closest('button'); if(!t) return;
    if(t.dataset.m){ st.mode=t.dataset.m; return render(); }
    if(t.dataset.flow){ st.flowMin = t.dataset.flow==='+5'
        ? Math.min(240,Math.max(5,st.flowMin+5)) : +t.dataset.flow; return render(); }
    if(t.dataset.ratio){ st.ratioIndex=+t.dataset.ratio; return render(); }
    if(t.dataset.i!==undefined && t.parentElement.dataset.toggle){
      const k=t.parentElement.dataset.toggle, i=+t.dataset.i;
      st[k] = k==='pomoEntry' ? (i===0?'duration':'blocks') : (i===0?'count':'interval');
      return render(); }
    if(t.dataset.step){ const [k,dir]=t.dataset.step.split(':'); const c=STEPS[k];
      let v=st[k] + c.d*(+dir);
      // app guard: never let breaks squeeze focus below 5m per chunk
      if(k==='customBreaks' && +dir>0 && Math.floor(st.customWork/(st.customBreaks+2))<5) return;
      st[k]=Math.min(c.max,Math.max(c.min,v)); return render(); }
    if(t.id==='endlessSw'){ st.endless=!st.endless; return render(); }
    // Back dismisses setup (right-to-left, matching the train). In the real flow this
    // returns to the hero; standalone here, so a Begin Focus pill brings it back.
    if(t.id==='backBtn'){ $('#stack').classList.add('gone'); $('#resumeBtn').style.display='block'; return; }
    if(t.id==='resumeBtn'){ $('#stack').classList.remove('gone'); $('#resumeBtn').style.display='none'; return; }
  });
  render();
})();
"""

html = f"""<h2>Setup screen &mdash; exact app parity</h2>
<p class="subtitle">Ported straight from <code>lib/ui/setup_screen.dart</code> + <code>lib/session/session_plan.dart</code>:
the same hierarchy (<b>intention &rarr; total time &rarr; focus time &rarr; configuration</b>), the same controls, labels,
hints, presets, step increments and ranges. The plan builders are a faithful JS port, so the <b>big duration</b> and the
<b>cadence line</b> are computed from a real plan &mdash; change anything and they update exactly as the app does.
Everything is live: switch modes, step values, toggle Endless.</p>

<svg style="position:absolute;width:0;height:0" aria-hidden="true">
  <filter id="glassdist" x="-20%" y="-20%" width="140%" height="140%">
    <feTurbulence type="fractalNoise" baseFrequency="0.006 0.006" numOctaves="1" seed="12" result="t"/>
    <feGaussianBlur in="t" stdDeviation="2" result="s"/>
    <feDisplacementMap in="SourceGraphic" in2="s" scale="52" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
</svg>

<style>
/* MUJI-minimal: setup + session use ONE quiet neutral sans. No serif, no italic,
   no display face — the scene carries the beauty, the controls stay silent. */
@import url('https://fonts.googleapis.com/css2?family=Jost:wght@200;300;400;500&display=swap');
  .hero {{ position:relative; width:100%; aspect-ratio:16/9; border-radius:16px; overflow:hidden;
           box-shadow:0 18px 60px rgba(0,0,0,.45); margin:12px 0 8px; isolation:isolate; container-type:inline-size; }}
  .hero * {{ box-sizing:border-box; }}
  .scene {{ position:absolute; inset:0; width:100%; height:100%; object-fit:cover; display:block; }}
  .vign {{ position:absolute; inset:0; pointer-events:none; z-index:2;
           background:radial-gradient(128% 112% at 50% 45%, transparent 34%, rgba(4,6,14,.22) 60%, rgba(4,6,14,.6) 100%),
             linear-gradient(95deg, rgba(4,6,14,.72) 0%, rgba(4,6,14,.42) 18%, rgba(4,6,14,.1) 36%, transparent 50%); }}
  .grain {{ position:absolute; inset:0; pointer-events:none; z-index:3;
            background-image:url("{GRAIN}"); background-size:220px 220px; opacity:.12; mix-blend-mode:overlay; }}
  .glass {{ position:relative; isolation:isolate;
            background:linear-gradient(140deg, rgba(255,255,255,.08), rgba(255,255,255,.025));
            backdrop-filter:blur(5px); -webkit-backdrop-filter:blur(5px);
            border:1px solid rgba(255,255,255,.18);
            box-shadow:0 16px 44px rgba(0,0,0,.22), inset 0 1px 0 rgba(255,255,255,.26); }}
  .glass-liquid {{ position:relative; isolation:isolate; color:#fff;
                   background:rgba(255,255,255,.07); border:1px solid rgba(255,255,255,.24); }}
  .glass-liquid::before {{ content:''; position:absolute; inset:0; border-radius:inherit; z-index:-1;
                           backdrop-filter:blur(2px); filter:url(#glassdist); }}
  .glass-liquid::after {{ content:''; position:absolute; inset:0; border-radius:inherit; pointer-events:none;
                          box-shadow:inset 1px 1px 0 0 rgba(255,255,255,.34); }}

  /* Centred stack: mode chooser floats ABOVE the panel as its own element. */
  .s-stack {{ position:absolute; left:50%; top:50%; transform:translate(-50%,-50%); z-index:5;
              width:40%; max-height:94%; display:flex; flex-direction:column; align-items:center;
              gap:clamp(8px,1.1cqi,15px); transition:opacity .42s cubic-bezier(.4,0,.2,1),
              transform .42s cubic-bezier(.4,0,.2,1); }}
  .s-stack.gone {{ opacity:0; transform:translate(-50%,-50%) translateX(-26%); pointer-events:none; }}
  .setup {{ width:100%; overflow-y:auto; padding:clamp(13px,1.9cqi,26px) clamp(15px,2.1cqi,28px);
            border-radius:20px; font-family:Jost,sans-serif; color:#f3ecdd; }}
  .setup::-webkit-scrollbar {{ width:5px; }}
  .setup::-webkit-scrollbar-thumb {{ background:rgba(255,255,255,.18); border-radius:9px; }}
  /* Glass back button — top-left of the SCREEN, fully separate from the panel. */
  .s-backbtn {{ position:absolute; left:2.6%; top:4.6%; z-index:6; width:clamp(26px,3cqi,42px); aspect-ratio:1;
                border-radius:50%; cursor:pointer; color:#f6efe2; font-size:clamp(11px,1.25cqi,18px);
                line-height:1; display:flex; align-items:center; justify-content:center; padding:0; }}
  .s-backbtn:hover {{ background:rgba(255,255,255,.13); }}
  .s-resume {{ position:absolute; left:50%; top:50%; transform:translate(-50%,-50%); z-index:5; display:none;
               padding:.85em 1.9em; border-radius:100px; cursor:pointer; font-family:Jost,sans-serif;
               font-weight:400; letter-spacing:.13em; text-transform:uppercase; color:#fff8ec;
               font-size:clamp(8px,.98cqi,13px); border:none; background:transparent; }}
  .s-resume span {{ position:relative; z-index:1; }}
  .s-modes {{ display:flex; gap:0; border-radius:100px; padding:3px; }}
  .mode {{ font-family:Jost,sans-serif; font-weight:400; font-size:clamp(7.5px,.92cqi,12px); letter-spacing:.04em;
           color:#e7e0d2; cursor:pointer; padding:.5em 1.05em; border-radius:100px; background:transparent;
           border:none; opacity:.72; white-space:nowrap; }}
  .mode:hover {{ opacity:1; }}
  .mode.on {{ opacity:1; color:#20242e; background:linear-gradient(180deg,#f4e6c8,#e7cf9c); font-weight:500; }}

  .s-lbl {{ font-weight:500; letter-spacing:.2em; text-transform:uppercase; font-size:clamp(6.5px,.76cqi,10px);
            opacity:.6; }}
  .s-lbl.c {{ text-align:center; }}
  .s-intent {{ width:100%; background:transparent; border:none; border-bottom:1px solid rgba(255,255,255,.2);
               color:#faf3e4; font-family:Jost,sans-serif; font-weight:300; font-size:clamp(11px,1.34cqi,19px);
               padding:.45em 0 .5em; margin:.4em 0 1.5em; outline:none; }}
  .s-intent::placeholder {{ color:rgba(244,236,221,.42); }}
  .s-intent:focus {{ border-bottom-color:rgba(234,202,120,.75); }}

  .s-total {{ text-align:center; margin-bottom:1.4em; }}
  .s-big {{ display:flex; align-items:baseline; justify-content:center; gap:.12em; margin:.28em 0 .34em;
            font-variant-numeric:tabular-nums lining-nums; }}
  .s-big b {{ font-weight:200; font-size:clamp(34px,5.2cqi,74px); line-height:1; letter-spacing:-.02em; color:#fdf6e6; }}
  .s-big s {{ text-decoration:none; font-weight:300; font-size:clamp(9px,1.1cqi,16px); opacity:.55; margin-right:.3em; }}
  .s-sub {{ font-weight:300; font-size:clamp(7.5px,.9cqi,12.5px); line-height:1.45; color:#EACA78; opacity:.9; }}
  .s-sub.warn {{ color:#F0A98C; }}

  .s-head {{ font-weight:500; font-size:clamp(9px,1.06cqi,15px); color:#f6efe0; margin:0 0 .5em; }}
  .s-hint {{ font-weight:300; font-size:clamp(7px,.86cqi,12px); line-height:1.4; opacity:.6; margin:0 0 1em; }}
  .chips {{ display:flex; flex-wrap:wrap; gap:clamp(4px,.62cqi,8px); }}
  .chip {{ font-family:Jost,sans-serif; font-weight:400; font-size:clamp(7.5px,.9cqi,12.5px); color:#e9e2d4;
           cursor:pointer; padding:.5em 1em; border-radius:100px; background:transparent;
           border:1px solid rgba(255,255,255,.16); opacity:.8; }}
  .chip:hover {{ opacity:1; }}
  .chip.on {{ opacity:1; color:#20242e; background:linear-gradient(180deg,#f4e6c8,#e7cf9c); border-color:transparent; font-weight:500; }}
  .chip.out {{ opacity:.6; border-style:dashed; }}

  .sub2 {{ display:flex; background:rgba(255,255,255,.06); border-radius:100px; padding:3px; margin-bottom:.7em;
           border:1px solid rgba(255,255,255,.1); }}
  .sub2 button {{ flex:1; font-family:Jost,sans-serif; font-weight:400; font-size:clamp(7.5px,.9cqi,12.5px);
                  color:#ded7c9; cursor:pointer; padding:.55em .8em; border-radius:100px; background:transparent; border:none; }}
  .sub2 button.on {{ color:#20242e; background:linear-gradient(180deg,#f4e6c8,#e7cf9c); font-weight:500; }}

  .stp {{ display:flex; align-items:center; gap:clamp(6px,.9cqi,12px); margin:0 0 1em; }}
  .stp-l {{ flex:1; font-weight:300; font-size:clamp(9px,1.04cqi,15px); color:#f2ebdc; }}
  .stp-b {{ width:clamp(21px,2.5cqi,34px); aspect-ratio:1; border-radius:50%; cursor:pointer; color:#f0e9da;
            background:transparent; border:1px solid rgba(255,255,255,.2); font-size:clamp(10px,1.1cqi,16px);
            line-height:1; display:flex; align-items:center; justify-content:center; flex:none; }}
  .stp-b:hover {{ background:rgba(255,255,255,.1); }}
  .stp-v {{ width:clamp(40px,5cqi,74px); text-align:center; font-weight:500; font-size:clamp(9.5px,1.12cqi,16px);
            font-variant-numeric:tabular-nums; }}

  .s-endless {{ display:flex; align-items:center; gap:12px; margin:.3em 0 1.2em; }}
  .s-et {{ font-weight:400; font-size:clamp(9px,1.04cqi,15px); }}
  .s-eh {{ font-weight:300; font-size:clamp(7px,.86cqi,12px); opacity:.6; margin-top:1px; }}
  .sw {{ width:clamp(30px,3.5cqi,48px); height:clamp(17px,2cqi,27px); border-radius:100px; flex:none; cursor:pointer;
         background:rgba(255,255,255,.12); border:1px solid rgba(255,255,255,.16); position:relative; padding:0; }}
  .sw i {{ position:absolute; top:50%; left:2px; transform:translateY(-50%); width:calc(50% - 3px); aspect-ratio:1;
           border-radius:50%; background:#cfc7b6; transition:left .22s cubic-bezier(.4,0,.2,1), background .22s; }}
  .sw.on {{ background:linear-gradient(180deg,#f4e6c8,#e7cf9c); border-color:transparent; }}
  .sw.on i {{ left:calc(50% + 1px); background:#2b2f3a; }}

  .s-desc {{ text-align:center; font-weight:300; font-size:clamp(7.5px,.9cqi,12.5px);
             line-height:1.35; opacity:.62; margin-bottom:.9em; }}
  .s-begin {{ display:block; width:100%; padding:.85em 1.6em; border-radius:100px; cursor:pointer;
              font-family:Jost,sans-serif; font-weight:400; letter-spacing:.14em; text-transform:uppercase;
              font-size:clamp(8px,.98cqi,13px); color:#fff8ec; border:none; background:transparent; }}
  .s-begin span {{ position:relative; z-index:1; }}
  .lbl {{ display:flex; align-items:baseline; gap:10px; margin-top:14px; }}
  .lbl .k {{ font-weight:700; }} .lbl .d {{ color:var(--muted,#8891a3); font-size:13px; }}
</style>

<div class="card">
  <div class="hero">
    <img class="scene" src="{bg}" alt="">
    <div class="vign"></div><div class="grain"></div>
{PANEL}
  </div>
  <div class="lbl"><span class="k">Setup &mdash; app parity</span><span class="d">Flow / Pomodoro / Custom &middot; Endless is a toggle, not a mode &middot; live plan math</span></div>
</div>

<script>{SCRIPT}</script>

<p class="subtitle" style="margin-top:16px"><b>Type:</b> setup is now a single quiet sans (Jost) &mdash; no serif, no italic,
no display face. The scene carries the beauty; the controls stay silent. Same rule will apply to the session screen.</p>

<p class="subtitle"><b>One overlap to settle.</b> <b>Endless</b> is now the web-only 4th mode, as you said. But the three
app modes were ported <i>exactly</i>, and the app also carries an <b>&ldquo;Endless flow&rdquo; toggle</b> on Flow (and on
Custom when breaks are 0) &mdash; so both now exist. They aren't quite the same thing: the toggle keeps a
<i>goal</i> and runs past it, while Endless mode has <b>no goal at all</b>. Keep both, or drop the toggle now that
Endless is its own mode? <b>Stamina</b> is omitted as instructed &mdash; that orphaned one phrase in the app's calm Flow
subline (&ldquo;…finish it to hold your stamina, pass it to grow&rdquo;), which I dropped. The &gt;90&nbsp;min caution is verbatim.</p>
"""
with open(OUT, "w", encoding="utf-8") as f: f.write(html)
print("wrote", OUT)
