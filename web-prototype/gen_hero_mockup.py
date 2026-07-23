#!/usr/bin/env python
# Hero v9: "One Glass" — UI glass calibrated to the hourglass (clear, minimal blur,
# bright specular edges). 3 tiers: .glass (panels), .glass-liquid (small, SVG
# refraction), .glass-quiet. Right panel + buttons + dock beside the hourglass.
import base64, io, os
from PIL import Image

ROOT = r"D:\Dev\Trilumos\hourglass\web-prototype\plates-phases"
OUT  = r"D:\Dev\Trilumos\hourglass\.superpowers\brainstorm\2436-1784803145\content\hero-v21.html"

GRAIN = ("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='220' height='220'%3E"
         "%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.82' numOctaves='3' "
         "stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")

im = Image.open(os.path.join(ROOT, "sunset.png")).convert("RGB")
im = im.resize((1600, round(im.height * 1600 / im.width)), Image.LANCZOS)
b = io.BytesIO(); im.save(b, "JPEG", quality=82, subsampling=0)
bg = "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()

Q = "Discipline is choosing between what you want now and what you want most."

# Founder-drawn boxes (from the interactive editor), blur 1px, no darken.
# Feather OUTWARD: grow each box by margin m so the drawn area stays FULLY blurred and
# the fade lands just past the edge (boundary imperceptible, blur unchanged inside).
FB = [(67.9, 28.5, 29.5, 55.2),   # right panel (Focused Today + quote)
      (5.4, 25.1, 23.0, 46.7),    # left column (Sustain -> Google Play)
      (0.4, 0.7, 98.4, 5.9)]      # navbar strip
def _grow(x, y, w, h, m=3.0):
    gx, gy, gw, gh = x - m, y - m, w + 2*m, h + 2*m
    return gx, gy, gw, gh, m/gw*100, m/gh*100
BB_CSS = "\n".join(
    f"  .bb{i+1} {{ left:{gx:.2f}%; top:{gy:.2f}%; width:{gw:.2f}%; height:{gh:.2f}%; --fx:{fx:.1f}%; --fy:{fy:.1f}%; }}"
    for i, (gx, gy, gw, gh, fx, fy) in enumerate(_grow(*b) for b in FB))
FINAL_BOXES = "".join(f'<div class="blurbox bb{i+1}"></div>' for i in range(len(FB)))

BODY = f"""      <div class="nav"><span class="wm">sustain</span>
        <span class="links"><span>About</span><span>Themes</span><span>Get the app</span><span class="ico">&#9881;</span></span></div>
      <div class="left">
        <h1 class="brand">Sustain</h1>
        <p class="tagline">Time flows. You focus.</p>
        <p class="clarity">A calm focus timer that moves with your day.</p>
        <div class="ctas"><a class="cta glass-liquid"><span>Begin Focus</span><span class="arw">&#8594;</span></a></div>
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
        <span class="wv"><i></i><i></i><i></i><i></i><i></i></span></div>"""

def card(choice, label, blurs, desc):
    return f'''  <div class="card" data-choice="{choice}" onclick="toggleSelect(this)" style="cursor:pointer">
    <div class="hero">
      <img class="scene" src="{bg}" alt="">
      {blurs}
      <div class="vign"></div><div class="grain"></div>
{BODY}
    </div>
    <div class="lbl"><span class="k">{label}</span><span class="d">{desc}</span></div>
  </div>'''

SCRIPT = r'''
(function(){
  const hero=document.getElementById('hero'), boxesEl=document.getElementById('boxes'),
        draw=document.getElementById('draw'), prev=document.getElementById('prev'),
        sB=document.getElementById('sB'), sD=document.getElementById('sD'), sF=document.getElementById('sF'),
        vB=document.getElementById('vB'), vD=document.getElementById('vD'), vF=document.getElementById('vF'),
        list=document.getElementById('bblist'), out=document.getElementById('bb-out');
  let boxes=[], sel=-1, drag=null;
  const P=e=>{const r=hero.getBoundingClientRect();return{x:(e.clientX-r.left)/r.width*100,y:(e.clientY-r.top)/r.height*100};};
  function render(){
    boxesEl.innerHTML='';
    boxes.forEach((b,i)=>{const d=document.createElement('div');d.className='blurbox'+(i===sel?' sel':'');
      d.style.left=b.x+'%';d.style.top=b.y+'%';d.style.width=b.w+'%';d.style.height=b.h+'%';
      d.style.setProperty('--bl',b.blur+'px');d.style.setProperty('--br',b.br);d.style.setProperty('--ft',b.ft+'%');
      boxesEl.appendChild(d);});
    let h=boxes.map((b,i)=>'<button data-i="'+i+'" class="'+(i===sel?'on':'')+'">Box '+(i+1)+'</button>').join('');
    if(boxes.length) h+='<button id="delbx">Delete</button><button id="clrbx">Clear all</button>';
    list.innerHTML=h;
    out.textContent=boxes.length?boxes.map((b,i)=>'.bb'+(i+1)+'{left:'+b.x.toFixed(1)+'%;top:'+b.y.toFixed(1)+'%;width:'+b.w.toFixed(1)+'%;height:'+b.h.toFixed(1)+'%}  /* blur '+b.blur+'px  darken '+b.br+'  feather '+b.ft+'% */').join('\n'):'(drag on the hero to draw a box)';
  }
  function sync(){ if(sel<0)return; const b=boxes[sel]; sB.value=b.blur;vB.textContent=b.blur; sD.value=Math.round(b.br*100);vD.textContent=Math.round(b.br*100); sF.value=b.ft;vF.textContent=b.ft; }
  draw.addEventListener('mousedown',e=>{const p=P(e);drag={ox:p.x,oy:p.y,box:null};});
  window.addEventListener('mousemove',e=>{ if(!drag)return; const p=P(e); const x=Math.min(p.x,drag.ox),y=Math.min(p.y,drag.oy),w=Math.abs(p.x-drag.ox),h=Math.abs(p.y-drag.oy); drag.box={x,y,w,h}; prev.style.cssText='display:block;left:'+x+'%;top:'+y+'%;width:'+w+'%;height:'+h+'%'; });
  window.addEventListener('mouseup',()=>{ if(!drag)return; const b=drag.box; prev.style.display='none'; drag=null; if(b&&b.w>1.5&&b.h>1.5){ boxes.push({x:b.x,y:b.y,w:b.w,h:b.h,blur:+sB.value,br:+sD.value/100,ft:+sF.value}); sel=boxes.length-1; render(); } });
  [sB,sD,sF].forEach(s=>s.addEventListener('input',()=>{ vB.textContent=sB.value;vD.textContent=sD.value;vF.textContent=sF.value; if(sel>=0){boxes[sel].blur=+sB.value;boxes[sel].br=+sD.value/100;boxes[sel].ft=+sF.value;render();} }));
  list.addEventListener('click',e=>{ const t=e.target; if(t.dataset.i!=null){sel=+t.dataset.i;sync();render();return;} if(t.id==='delbx'&&sel>=0){boxes.splice(sel,1);sel=Math.min(sel,boxes.length-1);sync();render();} if(t.id==='clrbx'){boxes=[];sel=-1;render();} });
  render();
})();
'''

html = f"""<h2>Hero v21 &mdash; quote in Fraunces, size +2</h2>
<p class="subtitle">Baked your exact rectangles (right panel, left column, navbar) at <b>blur 1px, no darken</b>. The feather now works <b>outward</b> &mdash; the drawn area stays fully blurred and the soft fade sits in a thin margin just past the edge, so the boundary is imperceptible. Quote nudged a touch bolder.</p>

<!-- shared liquid-glass refraction filter (small elements only) -->
<svg style="position:absolute;width:0;height:0" aria-hidden="true">
  <filter id="glassdist" x="-20%" y="-20%" width="140%" height="140%">
    <feTurbulence type="fractalNoise" baseFrequency="0.006 0.006" numOctaves="1" seed="12" result="t"/>
    <feGaussianBlur in="t" stdDeviation="2" result="s"/>
    <feDisplacementMap in="SourceGraphic" in2="s" scale="52" xChannelSelector="R" yChannelSelector="G"/>
  </filter>
</svg>

<style>
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;1,300;1,400&family=Fraunces:ital,opsz,wght@1,9..144,400;1,9..144,500&family=Jost:wght@200;300;400;500&display=swap');
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

  /* ===== RECTANGLE BLUR BEHIND A TEXT BLOCK — block by block =====
     A positioned box; backdrop-filter blurs (and slightly darkens for contrast)
     exactly its rectangle; its four edges are feathered via a two-gradient mask so
     it's a SOFT rectangle, not a hard box. Text sits on top, sharp. Per-letter halo
     is OFF (--halo: none). Tune left/top/width/height per block. */
  .hero {{ --halo: none; --halo-strong: none; }}
  #boxes {{ position:absolute; inset:0; z-index:1; pointer-events:none; }}
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
  #draw {{ position:absolute; inset:0; z-index:9; cursor:crosshair; }}
  #prev {{ position:absolute; z-index:9; display:none; pointer-events:none;
           border:1px dashed rgba(255,255,255,.85); background:rgba(255,255,255,.08); }}
  #bbpanel {{ position:fixed; right:14px; top:14px; z-index:100; width:290px; background:rgba(10,12,18,.94);
              color:#e8ecf3; padding:14px 16px; border-radius:12px; box-shadow:0 10px 40px rgba(0,0,0,.5);
              font:12px/1.5 ui-sans-serif,system-ui,sans-serif; }}
  #bbpanel h4 {{ margin:0 0 10px; font-size:12px; letter-spacing:.08em; text-transform:uppercase; opacity:.8; }}
  #bbpanel label {{ display:flex; align-items:center; justify-content:space-between; gap:10px; margin:7px 0; }}
  #bbpanel input[type=range] {{ flex:1; }}
  #bbpanel .v {{ width:44px; text-align:right; font-variant-numeric:tabular-nums; opacity:.85; }}
  #bblist {{ display:flex; flex-wrap:wrap; gap:6px; margin:10px 0 0; }}
  #bblist button {{ font:11px/1 ui-sans-serif; padding:5px 9px; border-radius:6px; border:1px solid rgba(255,255,255,.18);
                    background:rgba(255,255,255,.06); color:#e8ecf3; cursor:pointer; width:auto; margin:0; }}
  #bblist button.on {{ background:#EACA78; color:#141414; border-color:#EACA78; }}
  #bb-out {{ white-space:pre-wrap; word-break:break-word; font:10.5px/1.5 ui-monospace,monospace;
             background:rgba(0,0,0,.35); padding:8px; border-radius:6px; margin-top:10px; max-height:150px; overflow:auto; }}

  /* ===== GLASS TOKENS (calibrated to the hourglass) ===== */
  /* .glass — clear frost + bright specular edge; for panels (cheap) */
  .glass {{ position:relative; isolation:isolate;
            background:linear-gradient(140deg, rgba(255,255,255,.08), rgba(255,255,255,.025));
            backdrop-filter:blur(5px); -webkit-backdrop-filter:blur(5px);
            border:1px solid rgba(255,255,255,.18);
            box-shadow:0 16px 44px rgba(0,0,0,.22),
                       inset 0 1px 0 rgba(255,255,255,.26),
                       inset 0 -1px 0 rgba(255,255,255,.05); }}
  .glass::before {{ content:''; position:absolute; inset:0; border-radius:inherit; pointer-events:none;
                    background:linear-gradient(138deg, rgba(255,255,255,.10), transparent 46%); }}
  /* .glass-liquid — clear + REAL SVG refraction + thin specular; small elements only */
  .glass-liquid {{ position:relative; isolation:isolate; color:#fff;
                   background:rgba(255,255,255,.07); border:1px solid rgba(255,255,255,.24);
                   box-shadow:0 8px 22px rgba(0,0,0,.2); }}
  .glass-liquid::before {{ content:''; position:absolute; inset:0; border-radius:inherit; z-index:-1;
                           backdrop-filter:blur(2px); -webkit-backdrop-filter:blur(2px); filter:url(#glassdist); }}
  .glass-liquid::after {{ content:''; position:absolute; inset:0; border-radius:inherit; pointer-events:none;
                          box-shadow:inset 1px 1px 0 0 rgba(255,255,255,.38), inset -1px -1px 1px 0 rgba(255,255,255,.16); }}
  /* .glass-quiet — barely-there frost; navbar + during-session panels */
  .glass-quiet {{ background:rgba(255,255,255,.05); backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(8px);
                  border:1px solid rgba(255,255,255,.13); box-shadow:inset 0 1px 0 rgba(255,255,255,.16); }}

  .nav {{ position:absolute; top:0; left:0; right:0; height:11%; z-index:5; display:flex; align-items:center;
          justify-content:space-between; padding:0 4.2%; font-family:Jost,sans-serif; }}
  .nav.glass-quiet {{ border:none; border-bottom:1px solid rgba(255,255,255,.12); box-shadow:inset 0 1px 0 rgba(255,255,255,.14); }}
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
  /* buttons = glass-liquid */
  .cta {{ display:inline-flex; align-items:center; gap:.75em; padding:.82em 1.6em; border-radius:100px;
          font-family:Jost,sans-serif; font-weight:400; letter-spacing:.11em; text-transform:uppercase;
          font-size:clamp(8px,1cqi,13px); color:#fff8ec; cursor:pointer; white-space:nowrap; }}
  .cta .arw {{ transition:transform .7s cubic-bezier(.16,1,.3,1); position:relative; z-index:1; }}
  .cta span {{ position:relative; z-index:1; }}
  .cta:hover .arw {{ transform:translateX(5px); }}
  .play {{ display:inline-flex; align-items:center; gap:.65em; margin-top:1.05em; padding:.62em 1.2em;
           border-radius:11px; cursor:pointer; white-space:nowrap; color:#fdfdff; }}
  .play > * {{ position:relative; z-index:1; }}
  .play .pl {{ display:flex; flex-direction:column; line-height:1.08; font-family:Jost,sans-serif; font-weight:500;
               font-size:clamp(11px,1.3cqi,18px); }}
  .play .pl small {{ font-size:.5em; letter-spacing:.16em; opacity:.82; font-weight:300; }}

  /* right panel = BOXLESS (glass reserved for setup page) */
  .right {{ position:absolute; right:5.5%; top:49%; transform:translateY(-50%); width:25%; z-index:4; text-align:right;
            font-family:Jost,sans-serif; color:#f4ecdd; }}
  .right::before {{ content:''; position:absolute; inset:-24% -30% -18% -48%; z-index:-1; pointer-events:none;
                    background:radial-gradient(64% 60% at 76% 46%, rgba(4,6,14,.5), rgba(4,6,14,.18) 52%, transparent 76%); filter:blur(28px); }}
  .right .ftlabel, .right .ftbig, .right .goal {{ text-shadow:var(--halo); }}
  .right .quote, .right .qmark {{ text-shadow:var(--halo-strong); }}
  .ftlabel {{ font-weight:300; letter-spacing:.3em; text-transform:uppercase; font-size:clamp(7px,.84cqi,11px); opacity:.82; position:relative; z-index:1; }}
  .ftbig {{ font-family:Jost,sans-serif; font-weight:200; line-height:1; font-variant-numeric:tabular-nums lining-nums;
            letter-spacing:.005em; font-size:clamp(26px,4cqi,66px); margin:.24em 0 .6em; position:relative; z-index:1; }}
  .ftbig .u {{ font-size:.4em; opacity:.6; font-weight:300; margin:0 .04em 0 .02em; }}
  /* subtle glass progress bar */
  .goalbar {{ height:6px; background:rgba(255,255,255,.08); border:1px solid rgba(255,255,255,.16); border-radius:100px;
              overflow:hidden; margin-left:auto; width:100%; position:relative; z-index:1;
              backdrop-filter:blur(3px); -webkit-backdrop-filter:blur(3px);
              box-shadow:inset 0 1px 2px rgba(0,0,0,.28), inset 0 -1px 0 rgba(255,255,255,.12); }}
  .goalbar i {{ display:block; height:100%; width:34%; margin-left:auto; border-radius:100px;
                background:linear-gradient(90deg,rgba(255,208,150,.9),rgba(255,176,116,.78));
                box-shadow:inset 0 1px 0 rgba(255,255,255,.5); }}
  .goal {{ font-weight:300; letter-spacing:.04em; font-size:clamp(7px,.88cqi,12px); opacity:.7; margin-top:.5em; position:relative; z-index:1; }}
  .qdiv {{ height:1px; background:linear-gradient(90deg,transparent,rgba(255,255,255,.22)); margin:1.1em 0 1em; position:relative; z-index:1; }}
  .qwrap {{ position:relative; z-index:1; }}
  .qmark {{ display:block; font-family:'Fraunces',Georgia,serif; font-style:italic; font-size:clamp(30px,3.7cqi,60px);
            line-height:.42; opacity:.32; margin-bottom:.2em; }}
  .quote {{ font-family:'Fraunces',Georgia,serif; font-optical-sizing:auto; font-style:italic; font-weight:400; margin:0; line-height:1.42; text-wrap:pretty;
            font-size:clamp(13px,1.66cqi,26px); color:#f4efe6; opacity:.95; }}

  /* ambient dock = glass-liquid */
  .dock {{ position:absolute; left:50%; bottom:5.5%; transform:translateX(-50%); z-index:4;
           display:flex; align-items:center; gap:clamp(8px,1.4cqi,18px); padding:.6em 1.15em; border-radius:100px;
           font-family:Jost,sans-serif; color:#f4ecdd; font-weight:300; letter-spacing:.04em; font-size:clamp(8px,1cqi,13px); text-shadow:var(--halo); }}
  .dock > * {{ position:relative; z-index:1; }}
  .dock .wv {{ display:flex; align-items:flex-end; gap:2px; height:1em; }}
  .dock .wv i {{ width:2px; background:rgba(255,220,170,.85); border-radius:2px; animation:wv 1.4s ease-in-out infinite; }}
  .dock .wv i:nth-child(2){{animation-delay:.2s}} .dock .wv i:nth-child(3){{animation-delay:.4s}} .dock .wv i:nth-child(4){{animation-delay:.1s}} .dock .wv i:nth-child(5){{animation-delay:.5s}}
  @keyframes wv {{ 0%,100%{{height:35%}} 50%{{height:100%}} }}

  @keyframes rise {{ from {{opacity:0;transform:translateY(15px)}} to {{opacity:1;transform:none}} }}
  .left>*, .right, .dock {{ animation:rise 1.4s cubic-bezier(.16,1,.3,1) backwards; }}
  .brand{{animation-delay:.15s}} .tagline{{animation-delay:.34s}} .clarity{{animation-delay:.52s}} .ctas{{animation-delay:.7s}} .play{{animation-delay:.82s}} .right{{animation-delay:.95s}} .dock{{animation-delay:1.05s}}
  .nav {{ animation:rise 1.4s cubic-bezier(.16,1,.3,1) backwards; animation-delay:1.15s; }}
  @media (prefers-reduced-motion: reduce) {{ .left>*,.right,.dock,.nav,.wv i {{animation:none!important}} }}
  .lbl {{ display:flex; align-items:baseline; gap:10px; margin-top:14px; }}
  .lbl .k {{ font-weight:700; }} .lbl .d {{ color:var(--muted,#8891a3); font-size:13px; }}
</style>

<div class="cards" style="grid-template-columns:1fr;">
  <div class="card">
    <div class="hero">
      <img class="scene" src="{bg}" alt="">
      {FINAL_BOXES}
      <div class="vign"></div><div class="grain"></div>
{BODY}
    </div>
    <div class="lbl"><span class="k">Baked</span><span class="d">Your 3 boxes at blur 1px, feathered OUTWARD (drawn area fully blurred, edge fades just past it). Quote a touch bolder (400).</span></div>
  </div>
</div>

<p class="subtitle" style="margin-top:16px">The blurred region now fills each box you drew and the fade lands in a thin margin <i>outside</i> the edge, so the boundary is imperceptible while the blur inside is unchanged. Quote bumped 300&rarr;400. Want the quote a different font instead, or the blur/margin nudged? The editor is still in <code>gen_hero_mockup.py</code> if you want to redraw.</p>
"""
with open(OUT, "w", encoding="utf-8") as f: f.write(html)
print("wrote", OUT)
