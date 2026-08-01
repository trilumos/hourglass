// Shared Web-Audio engine — the graph is ported VERBATIM from the LOCKED Setup mixer (gapless crossfade
// loops, loudness-calibrated gains, tone-notch filters, ocean→sand sidechain, bird tide) plus a soft bell
// cue. Exposed as window.SustainAudio so the Session plays the user's mix LIVE (no preview gating) and rings
// the ritual bell at start / breaks / end. Setup keeps its own inline copy for preview; this is the runtime one.
const AUDIO_FILE = { sand:'sand.m4a', ocean:'ocean.mp3', breeze:'breeze.mp3', birds:'birds.mp3' };
const LOOP_POINTS = { sand:[0.15,13.20], ocean:[0.35,70.0], breeze:[0.35,97.846], birds:[0.0,22.5] };
const SOUND_GAIN = { sand:26, ocean:2.2, breeze:0.40, birds:8.0 };
const DUCK = { breeze:{ ocean:0.60 } };
const TONE_HZ = { breeze:10870, sand:16970, birds:10853, ocean:19450 };
const LOWPASS_HZ = { sand:12000, ocean:16000, breeze:9000, birds:9000 };
const HIGHPASS_HZ = { birds:220 };
const BIRD_TIDE = [1.0, 0.06, 12];
const XFADE = { sand:0.4, ocean:4.0, breeze:4.0, birds:5.0 };
const SC_LO=0.02, SC_HI=0.13, SC_DEPTH=0.72, SC_SMOOTH=0.05;
const WIN_N = 512, FADE_N = 64;
const FADE_IN = new Float32Array(FADE_N), FADE_OUT = new Float32Array(FADE_N);
for (let i=0;i<FADE_N;i++){ const th=i/(FADE_N-1)*Math.PI/2; FADE_IN[i]=Math.sin(th); FADE_OUT[i]=Math.cos(th); }

let AC=null, master=null, A={}, cueBuf=null;
let onSet={ sand:0, ocean:0, breeze:0, birds:0 };
let volSet={ sand:100, ocean:100, breeze:100, birds:100 };
let masterPos=100, muted=false, ducked=false;   // ducked = ambient hushed on a break
let sandDuck=null, oceanTap=null, scRAF=null;
const BREAK_DUCK=0.45;   // ambient level during a break (app parity: hush, don't silence)

function ensureAudio(){
  if (AC) return;
  AC = new (window.AudioContext || window.webkitAudioContext)();
  const lim = AC.createDynamicsCompressor();
  lim.threshold.value=-1.5; lim.knee.value=0; lim.ratio.value=20; lim.attack.value=0.003; lim.release.value=0.15;
  master = AC.createGain(); master.gain.value=0;
  master.connect(lim); lim.connect(AC.destination);
}
function gainFor(){ return muted ? 0 : (ducked ? BREAK_DUCK : 1) * Math.pow(masterPos/100, 2.5); }
function isOn(id){ return !!onSet[id]; }
function duckFactor(id){ const d=DUCK[id]; let f=1; if(d) for(const k in d) if(isOn(k)) f*=d[k]; return f; }
function userMult(id){ return Math.pow((volSet[id]==null?100:volSet[id])/100, 2.5); }
function baseGain(id){ return (SOUND_GAIN[id]||1)*userMult(id)*duckFactor(id); }
function fileFor(id){ return '/assets/audio/'+(AUDIO_FILE[id]||id+'.mp3'); }
function loadBuffer(id){
  const n=A[id]=A[id]||{};
  if(n.buffer) return Promise.resolve(n.buffer);
  if(n.dead)   return Promise.resolve(null);
  if(n.loading) return n.loading;
  n.loading=fetch(fileFor(id))
    .then(r=>{ if(!r.ok) throw new Error('HTTP '+r.status); return r.arrayBuffer(); })
    .then(b=>AC.decodeAudioData(b))
    .then(buf=>{ n.buffer=buf; n.loading=null; return buf; })
    .catch(()=>{ n.dead=true; n.loading=null; return null; });
  return n.loading;
}
function filterChain(id, from){
  let tail=from; const made=[];
  if(TONE_HZ[id]){
    [[TONE_HZ[id],8,-30],[TONE_HZ[id],20,-24]].forEach(p=>{
      const b=AC.createBiquadFilter(); b.type='peaking'; b.frequency.value=p[0]; b.Q.value=p[1]; b.gain.value=p[2];
      tail.connect(b); tail=b; made.push(b);
    });
  }
  if(HIGHPASS_HZ[id]){
    for(let h=0;h<2;h++){ const hpf=AC.createBiquadFilter(); hpf.type='highpass'; hpf.frequency.value=HIGHPASS_HZ[id]; hpf.Q.value=0.707; tail.connect(hpf); tail=hpf; made.push(hpf); }
  }
  for(let i=0;i<2;i++){ const l=AC.createBiquadFilter(); l.type='lowpass'; l.frequency.value=(LOWPASS_HZ[id]||9000); l.Q.value=0.707; tail.connect(l); tail=l; made.push(l); }
  return { tail, nodes:made };
}
function attachBirdTide(n){
  const p=BIRD_TIDE, G=baseGain('birds');
  n.bus.gain.value=(p[0]+p[1])/2*G;
  n.lfo=AC.createOscillator(); n.lfo.type='sine'; n.lfo.frequency.value=1/p[2];
  n.lfoGain=AC.createGain(); n.lfoGain.gain.value=(p[0]-p[1])/2*G;
  n.lfo.connect(n.lfoGain); n.lfoGain.connect(n.bus.gain); n.lfo.start();
}
function applyVol(id){
  const n=A[id]; if(!n||!n.bus) return; const t=AC.currentTime;
  if(id==='birds'){ const p=BIRD_TIDE, G=baseGain('birds');
    n.bus.gain.setTargetAtTime((p[0]+p[1])/2*G, t, 0.08);
    if(n.lfoGain) n.lfoGain.gain.setTargetAtTime((p[0]-p[1])/2*G, t, 0.08);
  } else n.bus.gain.setTargetAtTime(baseGain(id), t, 0.08);
}
function sineWindow(scale){ const w=new Float32Array(WIN_N); for(let i=0;i<WIN_N;i++) w[i]=scale*Math.sin(Math.PI*i/(WIN_N-1)); w[0]=w[WIN_N-1]=0.0001; return w; }
function pumpLoop(id){
  const n=A[id]; if(!n||!n.seg) return;
  const horizon=AC.currentTime+1.2;
  while(n.next<horizon){
    const t=n.next, S=n.seg;
    const src=AC.createBufferSource(); src.buffer=n.buffer;
    const g=AC.createGain();
    if(S.win) g.gain.setValueCurveAtTime(S.win,t,S.d);
    else { g.gain.setValueCurveAtTime(FADE_IN,t,S.xf); g.gain.setValueCurveAtTime(FADE_OUT,t+S.d-S.xf,S.xf); }
    src.connect(g); g.connect(n.bus);
    src.start(t,S.s,S.d+0.02); src.stop(t+S.d+0.02);
    ((a,b)=>{ a.onended=()=>{ try{ a.disconnect(); b.disconnect(); }catch(e){} }; })(src,g);
    n.live.push(src); if(n.live.length>8) n.live.shift();
    n.next = t + S.hop;
  }
}
function startSound(id){
  const n=A[id]=A[id]||{};
  if(!n.buffer||n.bus) return;
  const lp=LOOP_POINTS[id]||[0,n.buffer.duration], d=lp[1]-lp[0];
  n.bus=AC.createGain(); n.bus.gain.value=baseGain(id);
  if(id==='birds') attachBirdTide(n);
  const ch=filterChain(id,n.bus); n.chain=ch;
  if(id==='sand'){ sandDuck=AC.createGain(); sandDuck.gain.value=1; ch.tail.connect(sandDuck); sandDuck.connect(master); }
  else ch.tail.connect(master);
  if(id==='ocean'){ oceanTap=AC.createAnalyser(); oceanTap.fftSize=256; oceanTap.smoothingTimeConstant=0.3; ch.tail.connect(oceanTap); }
  startSidechain();
  const spec=XFADE[id]||2;
  if(spec<=1) n.seg={ s:lp[0], d, hop:d*spec, win:sineWindow(Math.sqrt(2*spec)) };
  else { const xf=Math.min(spec, d/2); n.seg={ s:lp[0], d, hop:d-xf, xf }; }
  n.next=AC.currentTime+0.06; n.live=[];
  n.pump=setInterval(()=>pumpLoop(id),300); pumpLoop(id);
}
function stopSound(id){
  const n=A[id]; if(!n||!n.bus) return;
  clearInterval(n.pump); n.pump=null;
  if(n.lfo){ try{ n.lfo.stop(); n.lfo.disconnect(); n.lfoGain.disconnect(); }catch(e){} n.lfo=null; n.lfoGain=null; }
  (n.live||[]).forEach(s=>{ try{ s.stop(); s.disconnect(); }catch(e){} });
  if(id==='sand' && sandDuck){ try{ sandDuck.disconnect(); }catch(e){} sandDuck=null; }
  if(id==='ocean'){ oceanTap=null; if(sandDuck) sandDuck.gain.setTargetAtTime(1, AC.currentTime, 0.12); }
  try{ n.bus.disconnect(); }catch(e){}
  if(n.chain) n.chain.nodes.forEach(f=>{ try{ f.disconnect(); }catch(e){} });
  n.bus=null; n.chain=null; n.seg=null; n.live=null;
}
function startSidechain(){ if(scRAF==null) sidechainTick(); }
function sidechainTick(){
  if(sandDuck && oceanTap){
    const buf=new Float32Array(oceanTap.fftSize); oceanTap.getFloatTimeDomainData(buf);
    let s=0; for(let i=0;i<buf.length;i++) s+=buf[i]*buf[i];
    const rms=Math.sqrt(s/buf.length), x=Math.max(0,Math.min(1,(rms-SC_LO)/(SC_HI-SC_LO)));
    sandDuck.gain.setTargetAtTime(1 - x*SC_DEPTH, AC.currentTime, SC_SMOOTH);
    scRAF=requestAnimationFrame(sidechainTick);
  } else scRAF=null;
}
function sync(){
  ensureAudio();
  if(AC.state==='suspended') AC.resume();
  const wanted=Object.keys(onSet).filter(id=>onSet[id]);
  Promise.all(wanted.map(loadBuffer)).then(()=>{
    Object.keys(AUDIO_FILE).forEach(id=>{ if(onSet[id]) startSound(id); else stopSound(id); });
    wanted.forEach(id=>applyVol(id));
    const t=AC.currentTime; master.gain.cancelScheduledValues(t); master.gain.setTargetAtTime(gainFor(), t, 0.08);
  });
}

// ── ritual bell (cue_bell.mp3) — soft ~4.5s ring with a tail fade, app's cue volume 0.55 ──
function cue(){
  ensureAudio(); if(AC.state==='suspended') AC.resume();
  const play=(buf)=>{
    const t=AC.currentTime, src=AC.createBufferSource(); src.buffer=buf;
    const g=AC.createGain(); g.gain.value=0.55;
    g.gain.setValueAtTime(0.55, t+4.2); g.gain.linearRampToValueAtTime(0, t+4.9);
    src.connect(g).connect(AC.destination); src.start(t); src.stop(t+5.0);
  };
  if(cueBuf) return play(cueBuf);
  fetch('/assets/audio/cue_bell.mp3').then(r=>r.arrayBuffer()).then(b=>AC.decodeAudioData(b))
    .then(buf=>{ cueBuf=buf; play(buf); }).catch(()=>{});
}

window.SustainAudio = {
  // Configure + play the user's mix live. cfg: {sounds:[ids], vol:0-100, soundVol:{id:0-100}}.
  set(cfg){
    onSet={ sand:0, ocean:0, breeze:0, birds:0 };
    (cfg.sounds||[]).forEach(id=>{ if(id in onSet) onSet[id]=1; });
    if(cfg.soundVol) for(const k in cfg.soundVol) if(k in volSet) volSet[k]=cfg.soundVol[k];
    if(cfg.vol!=null) masterPos=cfg.vol;
    muted=false; sync();
  },
  toggle(id, on){ if(id in onSet){ onSet[id]=on?1:0; sync(); } },
  setMaster(v){ masterPos=v; if(AC&&master) master.gain.setTargetAtTime(gainFor(), AC.currentTime, 0.08); },
  setMix(id, v){ if(id in volSet){ volSet[id]=v; applyVol(id); } },
  mute(on){ muted=on; if(AC&&master) master.gain.setTargetAtTime(gainFor(), AC.currentTime, 0.15); },
  duck(on){ ducked=on; if(AC&&master && !muted) master.gain.setTargetAtTime(gainFor(), AC.currentTime, 0.6); },   // hush ambient on breaks
  cue,
  stop(){ if(!AC) return; Object.keys(AUDIO_FILE).forEach(stopSound); if(master) master.gain.setTargetAtTime(0, AC.currentTime, 0.2); }
};
