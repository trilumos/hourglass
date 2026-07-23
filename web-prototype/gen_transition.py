#!/usr/bin/env python
# Focus transition prototype — hero -> SETUP -> session, via the View Transitions API.
# Reuses the LOCKED v22 hero CSS/markup verbatim. Begin Focus morphs the hero into the
# SETUP panel (mode + duration chooser); Start morphs setup -> live session; End/Back reverse.
# The scene plate (hourglass baked in) + grain + vignette PERSIST; ALL hero UI (nav, title,
# quote, Focused-Today, AND the ambient dock) dissolves.  Setup panel = first pass (refined next).
import base64, io, os
from PIL import Image

ROOT = r"D:\Dev\Trilumos\hourglass\web-prototype\plates-phases"
OUT  = r"D:\Dev\Trilumos\hourglass\.superpowers\brainstorm\2436-1784803145\content\hero-transition.html"

GRAIN = ("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='220' height='220'%3E"
         "%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.82' numOctaves='3' "
         "stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")

im = Image.open(os.path.join(ROOT, "sunset.png")).convert("RGB")
im = im.resize((1600, round(im.height * 1600 / im.width)), Image.LANCZOS)
b = io.BytesIO(); im.save(b, "JPEG", quality=82, subsampling=0)
bg = "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()

Q = "Discipline is choosing between what you want now and what you want most."

FB = [(67.9, 28.5, 29.5, 55.2), (5.4, 25.1, 23.0, 46.7), (0.4, 0.7, 98.4, 5.9)]
def _grow(x, y, w, h, m=3.0):
    gx, gy, gw, gh = x - m, y - m, w + 2*m, h + 2*m
    return gx, gy, gw, gh, m/gw*100, m/gh*100
BB_CSS = "\n".join(
    f"  .bb{i+1} {{ left:{gx:.2f}%; top:{gy:.2f}%; width:{gw:.2f}%; height:{gh:.2f}%; --fx:{fx:.1f}%; --fy:{fy:.1f}%; }}"
    for i, (gx, gy, gw, gh, fx, fy) in enumerate(_grow(*box) for box in FB))
FINAL_BOXES = "".join(f'<div class="blurbox bb{i+1}"></div>' for i in range(len(FB)))

HERO_UI = f"""    <div class="hero-ui">
      {FINAL_BOXES}
      <div class="nav"><span class="wm">sustain</span>
        <span class="links"><span>About</span><span>Themes</span><span>Get the app</span><span class="ico">&#9881;</span></span></div>
      <div class="left">
        <h1 class="brand">Sustain</h1>
        <p class="tagline">Time flows. You focus.</p>
        <p class="clarity">A calm focus timer that moves with your day.</p>
        <div class="ctas"><a class="cta glass-liquid" href="#"><span>Begin Focus</span><span class="arw">&#8594;</span></a></div>
        <a class="play glass-liquid"><svg class="gp" viewBox="0 0 26 30" width="1.25em" height="1.42em" aria-hidden="true"><polygon points="3,4 23,15 3,15" fill="#12B5FF"/><polygon points="3,15 23,15 3,26" fill="#00D26A"/><polygon points="23,15 15,10.6 15,15" fill="#FF424B"/><polygon points="23,15 15,19.4 15,15" fill="#FFC400"/></svg><span class="pl"><small>GET IT ON</small>Google&nbsp;Play</span></a>
      </div>
      <div class="right">
        <div class="ftlabel">Focused Today</div>
        <div class="ftbig">2<span class="u">h</span> 45<span class="u">m</span></div>
        <div class="goalbar"><i></i></div>
        <div class="goal">Daily goal 8h</div>
        <div class="qdiv"></div>
        <div class="qwrap"><span class="qmark">&ldquo;</span><p class="quote">{Q}</p></div>
      </div>
      <div class="dock glass-liquid"><span class="ico">&#9834;</span><span>Ocean Breeze</span>
        <span class="wv"><i></i><i></i><i></i><i></i><i></i></span></div>
    </div>"""

SETUP_UI = """    <div class="setup-ui">
      <div class="setup glass">
        <button class="s-back">&#8592;&nbsp;Back</button>
        <div class="setup-h">Set your focus</div>
        <div class="setup-lbl">Mode</div>
        <div class="modes">
          <button class="mode on">Flow</button><button class="mode">Pomodoro</button>
          <button class="mode">Custom</button><button class="mode">Endless</button>
        </div>
        <div class="setup-lbl">Duration</div>
        <div class="dur">
          <button class="d-step" data-d="-5">&#8722;</button>
          <div class="d-val"><span class="d-num">25</span><span class="d-u">min</span></div>
          <button class="d-step" data-d="5">&#43;</button>
        </div>
        <div class="presets">
          <button class="preset on" data-m="25">25</button><button class="preset" data-m="50">50</button><button class="preset" data-m="90">90</button>
        </div>
        <button class="start glass-liquid"><span>Start</span><span class="arw">&#8594;</span></button>
      </div>
    </div>"""

SESSION_UI = """    <div class="session-ui">
      <div class="focus-scrim"></div>
      <div class="timer">
        <div class="t-sub">FLOW &middot; SESSION 1 OF 4</div>
        <div class="t-time">25:00</div>
        <div class="s-ctrls">
          <button class="s-btn s-pause glass-liquid"><span>Pause</span></button>
          <button class="s-btn s-end glass-liquid"><span>End</span></button>
        </div>
      </div>
    </div>"""

SCRIPT = r"""
(function(){
  const body=document.body,
        begin=document.querySelector('.cta'), back=document.querySelector('.s-back'),
        startBtn=document.querySelector('.start'), end=document.querySelector('.s-end'),
        pause=document.querySelector('.s-pause'), timeEl=document.querySelector('.t-time'),
        dnum=document.querySelector('.d-num');
  let secs=1500, tick=null, paused=false, mins=25;
  const fmt=s=>String((s/60|0)).padStart(2,'0')+':'+String(s%60).padStart(2,'0');
  const run=()=>{ clearInterval(tick); tick=setInterval(()=>{ if(secs>0){secs--; timeEl.textContent=fmt(secs);} },1000); };
  function go(t){
    const apply=()=>{ body.classList.toggle('in-setup',t==='setup'); body.classList.toggle('in-session',t==='session');
      if(t==='session'){ secs=mins*60; paused=false; pause.querySelector('span').textContent='Pause'; timeEl.textContent=fmt(secs); run(); }
      else clearInterval(tick); };
    if(document.startViewTransition) document.startViewTransition(apply); else apply();
  }
  begin.addEventListener('click',e=>{ e.preventDefault(); go('setup'); });
  back.addEventListener('click',()=>go('hero'));
  startBtn.addEventListener('click',()=>go('session'));
  end.addEventListener('click',()=>go('hero'));
  pause.addEventListener('click',()=>{ paused=!paused; pause.querySelector('span').textContent=paused?'Resume':'Pause'; if(paused)clearInterval(tick); else run(); });
  document.querySelectorAll('.mode').forEach(m=>m.addEventListener('click',()=>{ const c=document.querySelector('.mode.on'); if(c)c.classList.remove('on'); m.classList.add('on'); }));
  const setMins=v=>{ mins=Math.max(5,Math.min(180,v)); dnum.textContent=mins; document.querySelectorAll('.preset').forEach(p=>p.classList.toggle('on',+p.dataset.m===mins)); };
  document.querySelectorAll('.d-step').forEach(b=>b.addEventListener('click',()=>setMins(mins + (+b.dataset.d))));
  document.querySelectorAll('.preset').forEach(p=>p.addEventListener('click',()=>setMins(+p.dataset.m)));
})();
"""

html = f"""<h2>Focus transition &mdash; Begin Focus &rarr; <b>Setup</b> &rarr; Session</h2>
<p class="subtitle">Corrected flow (View Transitions API, Baseline 2025). <b>Begin Focus</b> morphs the whole hero
&mdash; nav, title, quote, Focused-Today <b>and the Ocean&nbsp;Breeze dock</b> &mdash; away, and the <b>Setup panel</b>
rises in over the persistent scene + hourglass. Pick a mode / duration, hit <b>Start</b> to drop into a live session,
<b>Back</b> or <b>End</b> to reverse. The setup panel is a <b>first pass</b> (its real design is the next task) &mdash;
this screen proves the <b>morph and the flow</b>.</p>

<svg style="position:absolute;width:0;height:0" aria-hidden="true">
  <filter id="glassdist" x="-20%" y="-20%" width="140%" height="140%">
    <feTurbulence type="fractalNoise" baseFrequency="0.006 0.006" numOctaves="1" seed="12" result="t"/>
    <feGaussianBlur in="t" stdDeviation="2" result="s"/>
    <feDisplacementMap in="SourceGraphic" in2="s" scale="52" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
</svg>

<style>
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;1,300;1,400&family=Newsreader:ital,opsz,wght@1,6..72,200..500&family=Jost:wght@200;300;400;500&display=swap');
  .hero {{ position:relative; width:100%; aspect-ratio:16/9; border-radius:16px; overflow:hidden;
           box-shadow:0 18px 60px rgba(0,0,0,.45); margin:12px 0 8px; isolation:isolate; container-type:inline-size; }}
  .hero * {{ box-sizing:border-box; }}
  .scene {{ position:absolute; inset:0; width:100%; height:100%; object-fit:cover; display:block; }}
  .vign {{ position:absolute; inset:0; pointer-events:none; z-index:2;
           background:
             radial-gradient(128% 112% at 50% 45%, transparent 34%, rgba(4,6,14,.22) 60%, rgba(4,6,14,.6) 100%),
             linear-gradient(95deg,  rgba(4,6,14,.78) 0%, rgba(4,6,14,.46) 15%, rgba(4,6,14,.13) 31%, transparent 46%),
             linear-gradient(265deg, rgba(4,6,14,.5) 0%, rgba(4,6,14,.22) 14%, transparent 34%),
             linear-gradient(180deg, rgba(4,6,14,.46) 0%, transparent 15%),
             linear-gradient(0deg,   rgba(4,6,14,.4) 0%, transparent 16%); }}
  .grain {{ position:absolute; inset:0; pointer-events:none; z-index:3;
            background-image:url("{GRAIN}"); background-size:220px 220px; opacity:.12; mix-blend-mode:overlay; }}

  .hero {{ --halo: none; --halo-strong: none; }}
  .blurbox {{ position:absolute; z-index:1; pointer-events:none;
              backdrop-filter:blur(var(--bl,1px)) brightness(var(--br,1));
              -webkit-backdrop-filter:blur(var(--bl,1px)) brightness(var(--br,1));
              mask:linear-gradient(90deg, transparent 0, #000 var(--fx,8%), #000 calc(100% - var(--fx,8%)), transparent 100%),
                   linear-gradient(180deg, transparent 0, #000 var(--fy,8%), #000 calc(100% - var(--fy,8%)), transparent 100%);
              mask-composite:intersect;
              -webkit-mask:linear-gradient(90deg, transparent 0, #000 var(--fx,8%), #000 calc(100% - var(--fx,8%)), transparent 100%),
                           linear-gradient(180deg, transparent 0, #000 var(--fy,8%), #000 calc(100% - var(--fy,8%)), transparent 100%);
              -webkit-mask-composite:source-in; }}
{BB_CSS}

  /* ===== GLASS TOKENS (locked) ===== */
  .glass {{ position:relative; isolation:isolate;
            background:linear-gradient(140deg, rgba(255,255,255,.08), rgba(255,255,255,.025));
            backdrop-filter:blur(5px); -webkit-backdrop-filter:blur(5px);
            border:1px solid rgba(255,255,255,.18);
            box-shadow:0 16px 44px rgba(0,0,0,.22), inset 0 1px 0 rgba(255,255,255,.26), inset 0 -1px 0 rgba(255,255,255,.05); }}
  .glass::before {{ content:''; position:absolute; inset:0; border-radius:inherit; pointer-events:none;
                    background:linear-gradient(138deg, rgba(255,255,255,.10), transparent 46%); }}
  .glass-liquid {{ position:relative; isolation:isolate; color:#fff;
                   background:rgba(255,255,255,.07); border:1px solid rgba(255,255,255,.24);
                   box-shadow:0 8px 22px rgba(0,0,0,.2); }}
  .glass-liquid::before {{ content:''; position:absolute; inset:0; border-radius:inherit; z-index:-1;
                           backdrop-filter:blur(2px); -webkit-backdrop-filter:blur(2px); filter:url(#glassdist); }}
  .glass-liquid::after {{ content:''; position:absolute; inset:0; border-radius:inherit; pointer-events:none;
                          box-shadow:inset 1px 1px 0 0 rgba(255,255,255,.38), inset -1px -1px 1px 0 rgba(255,255,255,.16); }}

  .nav {{ position:absolute; top:0; left:0; right:0; height:11%; z-index:5; display:flex; align-items:center;
          justify-content:space-between; padding:0 4.2%; font-family:Jost,sans-serif; }}
  .wm {{ font-weight:400; letter-spacing:.4em; text-transform:uppercase; font-size:clamp(9px,1.15cqi,14px); color:#f6efe2; text-shadow:var(--halo); }}
  .links {{ display:flex; align-items:center; gap:clamp(11px,2.3cqi,30px); font-weight:300; letter-spacing:.06em;
            font-size:clamp(8px,.98cqi,13px); color:#eef0f6; opacity:.86; text-shadow:var(--halo); }}
  .links .ico {{ opacity:.7; font-size:1.15em; }}

  .left {{ position:absolute; left:6.3%; top:46%; transform:translateY(-50%); width:37%; z-index:4; }}
  .brand {{ font-family:'Cormorant Garamond',Georgia,serif; font-weight:300; margin:0 0 0 -.045em; line-height:.92;
            font-size:clamp(46px,6.9cqi,126px); color:#f8eedb; letter-spacing:.004em; text-shadow:var(--halo); }}
  .tagline {{ font-family:'Cormorant Garamond',Georgia,serif; font-weight:300; font-style:italic; margin:.22em 0 0;
             font-size:clamp(15px,2cqi,35px); color:#f4ead6; opacity:.96; text-wrap:pretty; text-shadow:var(--halo); }}
  .clarity {{ font-family:Jost,sans-serif; font-weight:300; letter-spacing:.02em; white-space:nowrap;
              font-size:clamp(8px,1.02cqi,14px); color:#eef1f7; opacity:.92; margin:1.1em 0 1.7em; text-shadow:var(--halo-strong); }}
  .cta {{ display:inline-flex; align-items:center; gap:.75em; padding:.82em 1.6em; border-radius:100px;
          font-family:Jost,sans-serif; font-weight:400; letter-spacing:.11em; text-transform:uppercase;
          font-size:clamp(8px,1cqi,13px); color:#fff8ec; cursor:pointer; white-space:nowrap; text-decoration:none; }}
  .cta .arw {{ transition:transform .7s cubic-bezier(.16,1,.3,1); position:relative; z-index:1; }}
  .cta span {{ position:relative; z-index:1; }}
  .cta:hover .arw {{ transform:translateX(5px); }}
  .play {{ display:inline-flex; align-items:center; gap:.65em; margin-top:1.05em; padding:.62em 1.2em;
           border-radius:11px; cursor:pointer; white-space:nowrap; color:#fdfdff; }}
  .play > * {{ position:relative; z-index:1; }}
  .play .pl {{ display:flex; flex-direction:column; line-height:1.08; font-family:Jost,sans-serif; font-weight:500;
               font-size:clamp(11px,1.3cqi,18px); }}
  .play .pl small {{ font-size:.5em; letter-spacing:.16em; opacity:.82; font-weight:300; }}

  .right {{ position:absolute; right:5.5%; top:49%; transform:translateY(-50%); width:25%; z-index:4; text-align:right;
            font-family:Jost,sans-serif; color:#f4ecdd; }}
  .right::before {{ content:''; position:absolute; inset:-24% -30% -18% -48%; z-index:-1; pointer-events:none;
                    background:radial-gradient(64% 60% at 76% 46%, rgba(4,6,14,.5), rgba(4,6,14,.18) 52%, transparent 76%); filter:blur(28px); }}
  .ftlabel {{ font-weight:300; letter-spacing:.3em; text-transform:uppercase; font-size:clamp(7px,.84cqi,11px); opacity:.82; position:relative; z-index:1; text-shadow:var(--halo); }}
  .ftbig {{ font-family:Jost,sans-serif; font-weight:200; line-height:1; font-variant-numeric:tabular-nums lining-nums;
            letter-spacing:.005em; font-size:clamp(26px,4cqi,66px); margin:.24em 0 .6em; position:relative; z-index:1; text-shadow:var(--halo); }}
  .ftbig .u {{ font-size:.4em; opacity:.6; font-weight:300; margin:0 .04em 0 .02em; }}
  .goalbar {{ height:6px; background:rgba(255,255,255,.08); border:1px solid rgba(255,255,255,.16); border-radius:100px;
              overflow:hidden; margin-left:auto; width:100%; position:relative; z-index:1;
              backdrop-filter:blur(3px); -webkit-backdrop-filter:blur(3px);
              box-shadow:inset 0 1px 2px rgba(0,0,0,.28), inset 0 -1px 0 rgba(255,255,255,.12); }}
  .goalbar i {{ display:block; height:100%; width:34%; margin-left:auto; border-radius:100px;
                background:linear-gradient(90deg,rgba(255,208,150,.9),rgba(255,176,116,.78));
                box-shadow:inset 0 1px 0 rgba(255,255,255,.5); }}
  .goal {{ font-weight:300; letter-spacing:.04em; font-size:clamp(7px,.88cqi,12px); opacity:.7; margin-top:.5em; position:relative; z-index:1; text-shadow:var(--halo); }}
  .qdiv {{ height:1px; background:linear-gradient(90deg,transparent,rgba(255,255,255,.22)); margin:1.1em 0 1em; position:relative; z-index:1; }}
  .qwrap {{ position:relative; z-index:1; }}
  .qmark {{ display:block; font-family:'Newsreader',Georgia,serif; font-style:italic; font-weight:300;
            font-variation-settings:'opsz' 42; font-size:clamp(24px,3cqi,46px);
            line-height:.4; opacity:.3; margin-bottom:.14em; text-shadow:var(--halo-strong); }}
  .quote {{ font-family:'Newsreader',Georgia,serif; font-style:italic; font-weight:340; font-variation-settings:'opsz' 60;
            margin:0; line-height:1.52; text-wrap:pretty; letter-spacing:.004em;
            font-size:clamp(12px,1.5cqi,23px); color:#f5f0e7; opacity:.94; text-shadow:var(--halo-strong); }}

  .dock {{ position:absolute; left:50%; bottom:5.5%; transform:translateX(-50%); z-index:6;
           display:flex; align-items:center; gap:clamp(8px,1.4cqi,18px); padding:.6em 1.15em; border-radius:100px;
           font-family:Jost,sans-serif; color:#f4ecdd; font-weight:300; letter-spacing:.04em; font-size:clamp(8px,1cqi,13px); text-shadow:var(--halo); }}
  .dock > * {{ position:relative; z-index:1; }}
  .dock .wv {{ display:flex; align-items:flex-end; gap:2px; height:1em; }}
  .dock .wv i {{ width:2px; background:rgba(255,220,170,.85); border-radius:2px; animation:wv 1.4s ease-in-out infinite; }}
  .dock .wv i:nth-child(2){{animation-delay:.2s}} .dock .wv i:nth-child(3){{animation-delay:.4s}} .dock .wv i:nth-child(4){{animation-delay:.1s}} .dock .wv i:nth-child(5){{animation-delay:.5s}}
  @keyframes wv {{ 0%,100%{{height:35%}} 50%{{height:100%}} }}

  /* ===== state visibility: hero <-> setup <-> session ===== */
  /* Whole hero UI is ONE view-transition group -> blur boxes rasterize WITH their text
     and fade as a single unit (no per-box backdrop-filter flash). Full-size layer so the
     group snapshot covers the frame; child %/top positions are unchanged (inset:0). */
  .hero-ui {{ position:absolute; inset:0; z-index:4; view-transition-name:hero; }}
  /* setup + session are ALSO full-frame groups, so every state slides as one train car */
  .setup-ui {{ position:absolute; inset:0; z-index:5; display:none; view-transition-name:setup; }}
  .session-ui {{ position:absolute; inset:0; z-index:5; display:none; view-transition-name:session; }}
  body.in-setup .hero-ui, body.in-session .hero-ui {{ display:none; }}
  body.in-setup .setup-ui {{ display:block; }}
  body.in-session .session-ui {{ display:block; }}

  /* ===== SETUP panel (first pass) ===== */
  .setup {{ position:absolute; left:6.3%; top:50%; transform:translateY(-50%); width:34%; z-index:5;
            padding:clamp(15px,2.3cqi,32px) clamp(16px,2.5cqi,34px); border-radius:20px;
            font-family:Jost,sans-serif; color:#f5eee0; }}
  .s-back {{ background:transparent; border:none; color:#e9e2d4; opacity:.72; cursor:pointer; font-family:Jost,sans-serif;
             font-weight:300; letter-spacing:.08em; font-size:clamp(8px,.95cqi,13px); padding:0; margin-bottom:1.1em; }}
  .s-back:hover {{ opacity:1; }}
  .setup-h {{ font-family:'Cormorant Garamond',Georgia,serif; font-weight:300; line-height:1; margin:0 0 1.1em;
              font-size:clamp(22px,3.4cqi,46px); color:#faf1de; }}
  .setup-lbl {{ font-weight:300; letter-spacing:.26em; text-transform:uppercase; font-size:clamp(7px,.82cqi,11px);
                opacity:.62; margin:0 0 .8em; }}
  .modes {{ display:flex; flex-wrap:wrap; gap:clamp(5px,.8cqi,9px); margin-bottom:1.6em; }}
  .mode {{ font-family:Jost,sans-serif; font-weight:400; letter-spacing:.04em; font-size:clamp(8px,.98cqi,13px);
           color:#efe9db; cursor:pointer; padding:.6em 1.1em; border-radius:100px;
           background:rgba(255,255,255,.05); border:1px solid rgba(255,255,255,.14); opacity:.78; }}
  .mode:hover {{ opacity:1; }}
  .mode.on {{ opacity:1; color:#20242e; background:linear-gradient(180deg,#f4e6c8,#e7cf9c); border-color:transparent;
              box-shadow:0 3px 14px rgba(0,0,0,.22); }}
  .dur {{ display:flex; align-items:center; justify-content:center; gap:clamp(14px,2.4cqi,32px); margin-bottom:1em; }}
  .d-step {{ width:clamp(28px,3.4cqi,44px); aspect-ratio:1; border-radius:50%; cursor:pointer; color:#f3ecdd;
             background:rgba(255,255,255,.06); border:1px solid rgba(255,255,255,.18); font-size:clamp(13px,1.5cqi,22px);
             font-weight:300; line-height:1; display:flex; align-items:center; justify-content:center; }}
  .d-step:hover {{ background:rgba(255,255,255,.12); }}
  .d-val {{ display:flex; align-items:baseline; gap:.28em; }}
  .d-num {{ font-family:Jost,sans-serif; font-weight:200; font-variant-numeric:tabular-nums lining-nums;
            font-size:clamp(40px,6cqi,86px); line-height:1; color:#fbf3e1; }}
  .d-u {{ font-weight:300; letter-spacing:.14em; text-transform:uppercase; font-size:clamp(8px,.9cqi,12px); opacity:.62; }}
  .presets {{ display:flex; justify-content:center; gap:clamp(6px,1cqi,12px); margin-bottom:1.8em; }}
  .preset {{ font-family:Jost,sans-serif; font-weight:300; font-size:clamp(8px,.92cqi,12px); color:#e9e2d4; cursor:pointer;
             padding:.42em .95em; border-radius:100px; background:transparent; border:1px solid rgba(255,255,255,.14); opacity:.7; }}
  .preset:hover {{ opacity:1; }}
  .preset.on {{ opacity:1; color:#faf2df; border-color:rgba(255,255,255,.4); background:rgba(255,255,255,.08); }}
  .start {{ display:flex; align-items:center; justify-content:center; gap:.7em; width:100%; padding:.95em 1.6em;
            border-radius:100px; cursor:pointer; font-family:Jost,sans-serif; font-weight:400; letter-spacing:.14em;
            text-transform:uppercase; font-size:clamp(8px,1cqi,13px); color:#fff8ec; border:none; background:transparent; }}
  .start > * {{ position:relative; z-index:1; }}
  .start .arw {{ transition:transform .6s cubic-bezier(.16,1,.3,1); }}
  .start:hover .arw {{ transform:translateX(5px); }}

  /* ===== SESSION ===== */
  .focus-scrim {{ position:absolute; inset:0; z-index:3; pointer-events:none;
                  background:radial-gradient(122% 104% at 50% 42%, transparent 26%, rgba(3,5,12,.42) 66%, rgba(3,5,12,.72) 100%); }}
  .timer {{ position:absolute; left:50%; top:61%; transform:translateX(-50%); z-index:5; text-align:center;
            font-family:Jost,sans-serif; color:#f6efe2; }}
  .t-sub {{ font-weight:300; letter-spacing:.42em; text-transform:uppercase; font-size:clamp(7px,.92cqi,12px);
            opacity:.72; margin-left:.42em; text-shadow:0 0 10px rgba(4,6,14,.6); }}
  .t-time {{ font-weight:200; line-height:1; font-variant-numeric:tabular-nums lining-nums; letter-spacing:.012em;
             font-size:clamp(48px,10cqi,132px); margin:.14em 0 .34em; text-shadow:0 2px 30px rgba(4,6,14,.5); }}
  .s-ctrls {{ display:flex; gap:12px; justify-content:center; }}
  .s-btn {{ font-family:Jost,sans-serif; font-weight:400; letter-spacing:.1em; text-transform:uppercase;
            font-size:clamp(8px,.98cqi,13px); color:#fdf7ec; cursor:pointer; border-radius:100px;
            padding:.72em 1.5em; border:none; background:transparent; }}
  .s-btn span {{ position:relative; z-index:1; }}

  /* NOTE: animate `translate`, NOT `transform` — .right/.dock use transform:translate(-50%)
     to centre themselves, and a transform keyframe overrides it (element loads low, then snaps). */
  @keyframes rise {{ from {{opacity:0; translate:0 15px}} to {{opacity:1; translate:0 0}} }}
  .left>*, .right, .dock {{ animation:rise 1.4s cubic-bezier(.16,1,.3,1) backwards; }}
  .brand{{animation-delay:.15s}} .tagline{{animation-delay:.34s}} .clarity{{animation-delay:.52s}} .ctas{{animation-delay:.7s}} .play{{animation-delay:.82s}} .right{{animation-delay:.95s}} .dock{{animation-delay:1.05s}}
  .nav {{ animation:rise 1.4s cubic-bezier(.16,1,.3,1) backwards; animation-delay:1.15s; }}

  /* ===== the View Transitions morph ===== */
  /* Scene + vignette + grain are IDENTICAL across states -> freeze root so nothing flickers. */
  ::view-transition-old(root), ::view-transition-new(root) {{ animation:none; }}
  /* TRAIN: everything that changes travels LEFT -> RIGHT. Outgoing slides out to the right,
     incoming slides in from the left behind it. Fade rides along so nothing escapes the frame. */
  @keyframes train-out {{ from {{opacity:1; transform:translateX(0)}}   to {{opacity:0; transform:translateX(38%)}} }}
  @keyframes train-in  {{ from {{opacity:0; transform:translateX(-38%)}} to {{opacity:1; transform:translateX(0)}} }}
  ::view-transition-old(hero), ::view-transition-old(setup), ::view-transition-old(session) {{
    animation:train-out .62s cubic-bezier(.5,0,.2,1) both; }}
  ::view-transition-new(hero), ::view-transition-new(setup), ::view-transition-new(session) {{
    animation:train-in .62s cubic-bezier(.5,0,.2,1) both; }}

  @media (prefers-reduced-motion: reduce) {{
    .left>*,.right,.dock,.nav,.wv i {{ animation:none!important; }}
    ::view-transition-group(*),::view-transition-old(*),::view-transition-new(*) {{ animation-duration:.01ms!important; }}
  }}
  .lbl {{ display:flex; align-items:baseline; gap:10px; margin-top:14px; }}
  .lbl .k {{ font-weight:700; }} .lbl .d {{ color:var(--muted,#8891a3); font-size:13px; }}
</style>

<div class="card">
  <div class="hero">
    <img class="scene" src="{bg}" alt="">
    <div class="vign"></div><div class="grain"></div>
{HERO_UI}
{SETUP_UI}
{SESSION_UI}
  </div>
  <div class="lbl"><span class="k">hero &rarr; setup &rarr; session</span><span class="d">Begin Focus opens Setup (all hero UI + dock dissolve, hourglass persists). Start drops into the live session. Back / End reverse.</span></div>
</div>

<script>{SCRIPT}</script>

<p class="subtitle" style="margin-top:16px">The <b>setup panel is a first pass</b> only &mdash; mode chips, a duration stepper (&minus;/&plus; and 25/50/90 presets), Start.
Its real design (app parity minus Pro, theme-progression chooser, ambient control) is the next dedicated task. Right now the point is: does the
<b>Begin&nbsp;Focus &rarr; Setup morph</b> feel right, and is the correct set of things dissolving vs. persisting?</p>
"""
with open(OUT, "w", encoding="utf-8") as f: f.write(html)
print("wrote", OUT)
