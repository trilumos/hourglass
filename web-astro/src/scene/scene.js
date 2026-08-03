// PORTED VERBATIM from web-prototype/hybrid.html (spec §6.1 / §18) — PLUMBING-ONLY changes:
//   three via npm import · shaders from ./shaders.js · timer from ../lib/timer.js · assets -> /public.
// The tuned scene logic (S constants, day cycle, sun/moon, sand painter, refraction) is UNCHANGED.
// The lab UI is still wired here; SceneWorld.astro keeps that markup hidden so every getElementById
// resolves. Both get stripped when the real Setup/Session UI is layered + the scene API is exposed.


import * as THREE from 'three';
import { createSession } from '../lib/timer.js';
import { VERT, FRAG } from './shaders.js';
import { localSunTimes, preciseSunTimes } from './geo.js';
import './audio.js';   // shared Web-Audio engine → window.SustainAudio (Session plays the mix live + bell cues)

// The 6 time-of-day plates, PIXEL-LOCKED to Mid Day (built in plates-phases/ by
// an integer-shift align pass — verified 0px residual). Because the hourglass
// silhouette sits in the exact same pixels in every plate, the coded sand never
// shifts when the background crossfades between phases.
const PLATES = [
  '/plates-phases/pre-dawn.webp', '/plates-phases/sunrise.webp', '/plates-phases/midday.webp',
  '/plates-phases/sunset.webp',   '/plates-phases/twilight.webp', '/plates-phases/midnight.webp',
];
const PHASE_NAMES = ['Pre-Dawn','Sunrise','Mid Day','Sunset','Twilight','Mid Night'];
const IMG_W = 1600, IMG_H = 901, AR = IMG_W / IMG_H;   // session's assets/plates framing (ledge-safe margin)
const $ = id => document.getElementById(id);

// ── layout: letterbox the image, size both canvases to the displayed rect ────
const frame = $('frame'), glitterCv = $('glitter'), sandCv = $('sand'), occCv = $('occ');
let DW = 0, DH = 0;
let _skyTop = 0;   // fraction of the plate cropped off the TOP by fit() — the sun/moon must never arc above it
// Vertical framing rule (founder): trim only a LITTLE off the bottom deck (BOTTOM_TRIM), then crop the rest of
// the overflow off the TOP sky; when the window is tall enough (≈ the plate's 16:9) the whole plate shows. So the
// deck is always mostly present, the top sky yields on short/non-fullscreen windows, and the base is never cut.
const BOTTOM_TRIM = 0.06;   // max fraction of the plate cropped off the bottom lip. One knob — tune to taste.
// Hourglass width as a fraction of the plate width: the glass silhouette spans ~0.134 around axis S.cx, the
// wooden posts + plinth ~0.234; 0.27 adds clearance. Published as --hg-w for the landing's centre gutter.
const HG_FRAC = 0.27;

// ── Power budget (must be defined before fit() — it sets the canvas size) ────────────────────────────
// This scene is a full-screen FRAGMENT shader plus a per-frame 2D sand pass, so cost scales with PIXELS.
// A modern phone reports devicePixelRatio 3: at the old `min(dpr,2)` cap a 390x844 viewport rendered
// 780x1688 = 1.3M px every frame, forever, at 60fps. That is what heats a phone, flattens a battery, and
// makes an old laptop's integrated GPU crawl. Budget by CAPABILITY, never by user-agent — an old laptop
// and a new phone deserve the same mercy, and sniffing "is it mobile" gets both wrong.
const LOW = (() => {
  try {
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) return true;
    const cores  = navigator.hardwareConcurrency || 4;
    const mem    = navigator.deviceMemory || 4;            // undefined on Safari/Firefox -> assume mid
    const coarse = matchMedia('(hover: none)').matches;    // phone / tablet
    return coarse || cores <= 4 || mem <= 4;
  } catch (e) { return false; }
})();
let _slow = false;                                          // set by the adaptive check in loop()
// 1.25 still looks sharp for a soft painterly plate — it is a gradient, not text.
const DPR_CAP = () => Math.min(devicePixelRatio || 1, (LOW || _slow) ? 1.25 : 2);

function fit(){
  const vw = innerWidth, vh = innerHeight;
  if (vw/vh > AR) { DW = vw; DH = vw/AR; } else { DH = vh; DW = vh*AR; }   // COVER: fill the viewport, crop the overflow (locked plate rule — no side gaps)
  frame.style.width = DW+'px'; frame.style.height = DH+'px';
  // position the covered frame: centre horizontally; SCENE_OY = vertical crop anchor (0.5 = session's 50% centre)
  frame.style.left = -(DW - vw)/2 + 'px';
  // Trim at most BOTTOM_TRIM off the bottom deck; crop the REST of the vertical overflow off the top sky. When the
  // window is tall enough (overflow ≤ BOTTOM_TRIM) nothing crops the top (whole plate, tiny bottom trim only).
  frame.style.top  = Math.min(0, vh - (1 - BOTTOM_TRIM)*DH) + 'px';
  _skyTop = Math.max(0, (1 - BOTTOM_TRIM) - vh/DH);   // fraction cropped off the top → sun/moon must peak below it
  // Publish the hourglass's displayed width so the landing page's centre gutter tracks it exactly at any
  // viewport (the plate is cover-fit, so on tall/narrow windows the glass is a far bigger share of the
  // screen than on wide ones). HG_FRAC covers the wooden posts + plinth, not just the glass silhouette.
  document.documentElement.style.setProperty('--hg-w', (DW * HG_FRAC) + 'px');
  // ...and the hourglass AXIS in layout px. Two reasons `left:50%` is wrong for anything that must line up
  // with the glass: the axis sits at S.cx (0.49885), not 50%; and `innerWidth` (used for the cover maths)
  // includes the scrollbar while a percentage resolves against the layout viewport, which does not. Reading
  // the frame's REAL offset puts --hg-axis in exactly the same coordinate space as a fixed/absolute overlay.
  // (Named --hg-axis, NOT --hg-cx: that name is already taken by the numeral geometry set on #frame.)
  document.documentElement.style.setProperty('--hg-axis', (frame.offsetLeft + DW * S.cx) + 'px');
  const dpr = DPR_CAP();
  for (const cv of [glitterCv, sandCv, occCv]) {
    cv.width = DW*dpr; cv.height = DH*dpr; cv.style.width = DW+'px'; cv.style.height = DH+'px';
  }
  renderer.setSize(DW, DH);
  sctx.setTransform(dpr,0,0,dpr,0,0);
  refrDirty = true;                    // refraction is built at display size
}

// ── Layer 0: WebGL — the image + old-anime star glitter on the water ────────
// preserveDrawingBuffer: the session occluder (#occ) copies this canvas via drawImage each frame; without
// it, an antialiased buffer can read back empty on some GPUs. Cheap on a desktop GPU.
//
// NOT cheap on a phone. Every mobile GPU is tile-based, and BOTH of these flags force a full-framebuffer
// resolve every single frame: `antialias` for the MSAA resolve, `preserveDrawingBuffer` to stop the driver
// discarding the tile buffer it would otherwise throw away for free. Together they were the dominant cost
// of the scene on mobile — far more than the shader itself.
//
// On a constrained device we drop both. The only thing preserveDrawingBuffer buys is the session occluder
// (numerals passing BEHIND the glass), and #occ is a plain overlay: if it never draws, the numerals simply
// render on top, fully legible. That is a fine trade for a site that actually runs. MSAA is likewise
// invisible at DPR 1.25 on a soft painterly plate.
const renderer = new THREE.WebGLRenderer({
  canvas: glitterCv,
  alpha: false,
  antialias: !LOW,
  preserveDrawingBuffer: !LOW,
  powerPreference: LOW ? 'low-power' : 'high-performance',
});
renderer.setPixelRatio(DPR_CAP());
// Identity colour pipeline: no input decode, no output encode. The texture's
// sRGB bytes pass straight through to the sRGB canvas, so the background looks
// EXACTLY like the PNG (no saturation/warm shift). Sparkle is added in the same
// space — fine for a simple additive white glint.
renderer.outputColorSpace = THREE.LinearSRGBColorSpace;
const loaderTex = new THREE.TextureLoader();
// three defaults to crossOrigin:'anonymous'. Setting it to undefined makes ImageLoader skip the attribute
// entirely, so the plate is fetched NO-CORS like the preload and the CSS background-image dots — one shared
// request instead of a CORS fetch that can never reuse them. Safe because the plates are same-origin (a
// same-origin image never taints a canvas, so getImageData in buildRefraction still works). If plates ever
// move to another origin, restore 'anonymous' HERE and on the preload, and the CSS dots must become <img>.
loaderTex.crossOrigin = undefined;
// Load plates ON FIRST USE, not all six up front (spec §13: "load one plate, not six" — six eager loads was
// ~960 KB before first paint). Frame 1 pulls the current phase (and its crossfade partner, if we load inside
// a fade band); reveal() then warms the remaining plates, so the day cycle and the landing's scroll-sweep
// never wait on a fetch. Callers that read .image already guard on it being undefined.
const TEX = PLATES.map(() => null);
const EMPTY_TEX = new THREE.Texture();          // uniform seed only — never sampled once frame 1 binds a plate
function plateTex(i){
  i = ((i|0) % PLATES.length + PLATES.length) % PLATES.length;
  if (!TEX[i]) { TEX[i] = loaderTex.load(PLATES[i]); TEX[i].colorSpace = THREE.NoColorSpace; }
  return TEX[i];
}
// Reveal the scene the moment the CURRENTLY-VISIBLE plate is decoded (the loop calls reveal() once uTex has
// an image). A blur-up LQIP shows until then; a 3 s timeout is the backstop against a slow/failed plate.
let _revealed = false;
// `scene-ready` means ONE thing: the plate texture is decoded and the canvas has something real to draw.
// It is never set on a timer. Forcing it on a timeout showed an empty canvas — on a phone that rendered as
// the sand geometry floating on white, because the sand needs no plate texture while the glass, frame and
// sky all come FROM the plate. (Reloading hid it: the plate was cached and decoded before the timer fired.)
function reveal(){
  if (_revealed) return; _revealed = true;
  document.documentElement.classList.add('scene-ready');
  chromeReady();
  for (let i = 0; i < PLATES.length; i++) plateTex(i);   // warm the rest AFTER first paint (never before)
}
// `chrome-ready` means "the page is usable" and is deliberately independent of the GPU: the nav, headline
// and actions must never wait on a texture. Safe to fire on a timer — it reveals no canvas.
function chromeReady(){ document.documentElement.classList.add('chrome-ready'); }
setTimeout(chromeReady, 3000);
// The moon is PAINTED, not generated. Every procedural attempt — selenographic
// maria, then ring craters — read as stains or pimples at this on-screen size.
// plates/moon-tex.png is the founder's artwork, cropped to the opaque disc so the
// shader's halo is the only glow (the source's own bloom is deliberately dropped).
const MOON_TEX = loaderTex.load('/plates/moon-tex.webp');
MOON_TEX.colorSpace = THREE.NoColorSpace;

const U = {
  // Seeded with an EMPTY texture (no fetch): the render loop binds the real current plate on frame 1, so
  // only the phase actually on screen is downloaded. reveal() waits for uTex to have a decoded image.
  uTex:{value:EMPTY_TEX}, uTex2:{value:EMPTY_TEX}, uMix:{value:0},
  uCelA:{value:new THREE.Vector2(0.3,0.7)}, uCelB:{value:new THREE.Vector2(0.3,0.7)},
  uCelAamt:{value:0}, uCelBamt:{value:0}, uCelAtype:{value:1}, uCelBtype:{value:1},
  uCelAalt:{value:0}, uCelBalt:{value:0},
  uMoonR:{value:0.040}, uMoonSoft:{value:0.07},
  uMoonK:{value:1.20}, uAspect:{value:AR},
  uMoonGlowW:{value:1.30}, uMoonGlowA:{value:1.50},
  uMoonFarW:{value:0.540}, uMoonFarA:{value:0.16},
  uMoonTex:{value:MOON_TEX}, uMoonTexAmt:{value:1.0},
  uMoonWarm:{value:0.15}, uMoonHaze:{value:0.30}, uMoonWarmH:{value:0.35},
  uMoonWarmCol:{value:new THREE.Vector3(1.0,0.722,0.467)},
  uMoonCol:{value:new THREE.Vector3(1.0,1.0,1.0)},
  uMoonGlowCol:{value:new THREE.Vector3(0.878,0.937,1.0)},
  uMoonFarCol:{value:new THREE.Vector3(0.616,0.714,0.894)},
  // sun, blended from SUNKEY each frame
  uSunSize:{value:0.020}, uCoreW:{value:2.0}, uCoreA:{value:2.4},
  uNearW:{value:0.38}, uNearA:{value:1.15}, uFarW:{value:0.07}, uFarA:{value:0.30},
  uCoreCol:{value:new THREE.Vector3(1,1,0.98)},
  uNearCol:{value:new THREE.Vector3(1,0.82,0.44)},
  uFarCol:{value:new THREE.Vector3(1,0.68,0.26)},
  uLightCol:{value:new THREE.Vector3(1.0,0.90,0.70)},
  uTime:{value:0}, uGl:{value:0.6}, uGd:{value:0.32}, uGs:{value:1},
  // Constrained device: skip sun/moon + water glitter, keep the plate and its crossfade (founder call).
  uLite:{value: LOW ? 1 : 0},
  uHor:{value:0.42}, uSill:{value:0.17}, uPathX:{value:0.5}, uPathW:{value:2.0},
  uPersp:{value:0.8}, uGdrift:{value:0.200},   // long lines  // short dashes
  uGlen:{value:0.38}, uGthk:{value:0.045},
  // starts fully white so water shows everywhere until a sea region is drawn —
  // a null sampler here would black the whole effect out
  uMask:{value:(()=>{ const t=new THREE.DataTexture(new Uint8Array([255,255,255,255]),1,1);
                      t.needsUpdate=true; return t; })()},
};
const quad = new THREE.Mesh(new THREE.PlaneGeometry(2,2), new THREE.ShaderMaterial({
  uniforms:U, depthTest:false,
  vertexShader: VERT,
  fragmentShader: FRAG,
}));
const scene = new THREE.Scene(); scene.add(quad);
const cam = new THREE.Camera();

// ── Layer 1: 2D canvas — sand inside the baked glass ────────────────────────
const sctx = sandCv.getContext('2d');
const S = { prog:0.35, cx:0.498850, top:0.347, neck:0.627, bot:0.888, max:0.065, nh:0.003,
            // curve shape — founder-tuned to the baked glass (2026-07-18)
            rimK:0.79, wTop:0.370, aTop:0.075, bTop:0.345, cTop:0.080,
            mxBot:0.985, wBot:0.700, aBot:0.150, bBot:0.375, cBot:0.110, baseK:0.91,
            topW:0.000, botW:0.000,              // flat rim/base, for the ends under the caps
            // ── FOUNDER-LOCKED sand + optics (2026-07-18) ──
            flat:0.20, persp:0.090, repose:0.545, apexR:0.07, topBulge:0.30,
            sandVol:0.75,                        // total sand ÷ top-bulb capacity
            gspec:0.32, grim:0.20, gshad:0.40, scool:1.0,  // glass optics + sand light
            phase:2, live:1, daytime:12,          // live:1 = day-cycle follows the real LOCAL clock (user's timezone)
            celEdit:0, horEdit:0,                             // moon is always FULL
            // LOCKED by the founder 2026-07-19
            moonR:0.040, moonK:1.20, moonSoft:0.07, moonTexAmt:0.50,
            moonWarm:0.15, moonHaze:0.30, moonWarmH:0.35,
            moonWarmCol:'#ffb877',           // a low moon reddens, like a low sun           // moon reads BIGGER than the sun
            moonGlowW:1.30, moonGlowA:1.50, moonFarW:0.540, moonFarA:0.16,
            moonCol:'#ffffff',
            moonGlowCol:'#e0efff', moonFarCol:'#9db6e4',
            // live sun params — these MIRROR SUNKEY[S.sunKey]; editing a slider
            // writes through to that key, and switching keys reloads them.
            sunKey:0, sunSize:0.020, coreW:2.00, coreA:2.40,
            nearW:0.38, nearA:1.15, farW:0.07, farA:0.30,
            coreCol:'#fffffa', nearCol:'#ffd170', farCol:'#ffae42',
            glassOn:0, gtint:1.0, gEdge:0.9, gEdgeW:2.2,   // (dead) bare glass
            refr:0.35, fres:0.60, gtex:0.15,      // refraction · Fresnel · imperfection
            hlSoft:2.0, hlX:0.51, hlW:0.15, hlCurve:0.25, hlTop:0.12, hlBot:0.65,
            // LOCKED by the founder 2026-07-19
            coneLift:-0.040, coneTopShd:0.085, coneBotShd:0.180,
            bedNight:-0.400, bedDay:-0.300,   // bed tracks the sun's height
            rimCapT:0.04, rimCapB:0.04,        // rim light dies at the wooden contacts
            // falling sand — the APP's constants, ported verbatim
            // LOCKED by the founder 2026-07-19
            streamN:220, streamCol:1.00, streamPer:0.82, streamV0:0.30,
            streamSize:1.20, streamA:1.00, streamLit:0.020, streamScat:0.60,
            streamLand:0.0,   // px the grains bury into the pile top
            // LOCKED by the founder 2026-07-19
            pileStart:0.00, pileRamp:0.25,
            bedEarly:0.000, bedTint:0.25,    // starts at the TOP pile's tone
            bedHand:0.60,                    // bed level handover ramp
            topHold:0.800, topShown:0.995,
            streamThin:0.97, streamThinTo:0.20,   // stream tapers away at the end
            crookT:0.0010, crookB:0.015, crookF:26, // sand edges are never straight —
                                                  // the top is a settled surface so
                                                  // it stays near-flat; the pile is
                                                  // freshly poured, so it slumps
            grain:0.07, grainScale:0.005,         // texture: amount, and feature size
                                                  // as a fraction of hourglass width
                                                  // (measured 5px over 151px = 0.033)
            // sand colour per half. Founder went FLAT on top (lit=shadow=0): the
            // upper mass is one uniform shadowed tone, exactly as intended.
            shueT:30, ssatT:34, slitT:0.52, litT:0.000, shdT:0.000,
            shueB:30, ssatB:34, slitB:0.65, litB:0.060, shdB:0.245,
            dbg:0, gl:0.32, gd:0.25, gs:0.25, hor:0.4475, sill:0.17,
            // water — glitter only. The ripple/swell/wave-line layers were cut:
            // drifting glints already read as advancing crests.
            persp2:1.20, pathX:0.500, pathW:1.00,
            glen:0.40, gthk:0.030, gdrift:0.200, seaEdit:0, seaFeather:6 };

// ── The focus timer. Session state lives here, never in S (which is the
// slider-bound render-param object). The loop samples this and writes S.prog.
const session = createSession();

const clamp=(x,a,b)=>Math.min(b,Math.max(a,x));
const smooth=x=>{const c=clamp(x,0,1);return c*c*(3-2*c);};

// Sand boundaries are never straight: the angle of repose is an AVERAGE, and the
// real surface is broken up by grain-scale bumps and avalanche terracing. This
// is smooth 1D value noise, driven by WORLD position (not by time, and not by a
// normalised t) so the bumps stay anchored in place as the pile grows, instead
// of crawling or flickering frame to frame.
const hsh=n=>{ const s=Math.sin(n*127.1)*43758.5453; return (s-Math.floor(s))*2-1; };
function wob1(p, seed){
  const oct=q=>{ const i=Math.floor(q), t=q-i, u=t*t*(3-2*t);
                 return hsh(i+seed)*(1-u)+hsh(i+1+seed)*u; };
  return oct(p)*0.68 + oct(p*2.3+11.7)*0.32;
}
// SEPARATE ramps per half — the two masses are not lit the same way. The top
// sand is lit THROUGH itself, so it reads as one shadowed body; the bottom cone
// has a genuinely lit flank. Measured from plates/sand-anime.png (form smoothed,
// texture removed):
//        lightness spread   saturation   hue
//   TOP        12.7            32.4%     30.7   <- shadow desaturates it
//   BOT        17.1 (1.34x)    56.9%     28.9   <- real light, real range
// Keeping them separate is also what lets time-of-day drive each half properly.
const HALF = { T:{h:'shueT',s:'ssatT',l:'slitT',lit:'litT',shd:'shdT'},
               B:{h:'shueB',s:'ssatB',l:'slitB',lit:'litB',shd:'shdB'} };

// ── TIME-OF-DAY RELIGHT (ANIME) ─────────────────────────────────────────────
// Art direction: the sand is the SUBJECT and must stay bright, readable and the
// SAME colour in every phase — the time of day shows only through the SHADOW.
// So: lit side = white tint, exposure 1, saturation 1 in ALL phases (constant
// day sand). Only the SHADOW colour is the per-phase lever (classic warm-light /
// cool-shadow anime look). Midday shadow = white → the locked sand is untouched.
// The tint is driven by each tone's LIGHTNESS: bright/base tones stay day sand,
// only the darker tones (bottom-cone shadow, the shadowed top mass) take it.
// Phase order: pre-dawn · sunrise · midday · sunset · twilight · midnight.
const hexToRgb = h => { h=h.replace('#',''); return [parseInt(h.slice(0,2),16),
  parseInt(h.slice(2,4),16), parseInt(h.slice(4,6),16)]; };
const rgbToHex = a => '#'+a.map(v=>Math.round(clamp(v,0,255)).toString(16).padStart(2,'0')).join('');
function hslToRgb(h,s,l){
  if(s===0){ const v=l*255; return [v,v,v]; }
  const q=l<0.5?l*(1+s):l+s-l*s, p=2*l-q;
  const f=t=>{ if(t<0)t+=1; if(t>1)t-=1;
    if(t<1/6)return p+(q-p)*6*t; if(t<0.5)return q; if(t<2/3)return p+(q-p)*(2/3-t)*6; return p; };
  return [f(h+1/3)*255, f(h)*255, f(h-1/3)*255];
}
// lit/expo/sat are barely off Mid Day — just enough that the bright sand picks up
// the scene and doesn't read as pasted. SHADOW carries the phase.
const PH_EXPO = [0.97, 1.00, 1.00, 0.99, 0.97, 0.95];
const PH_LIT  = ['#fff3f7','#fffdef','#ffffff','#fff8ee','#fff6f4','#f4f7ff'].map(hexToRgb);
const PH_SHD  = ['#8ea6da','#c9bfe0','#ffffff','#b3a0cc','#9a94d4','#7f92cf'].map(hexToRgb);
const PH_SAT  = [1.08, 1.02, 1.00, 1.05, 1.08, 1.12];
// Scales the EXISTING glass rim-light (S.grim) per phase: strong in dark phases,
// dim at midday — so the hourglass edge catches light and reads as the hero.
const PH_RIM  = [3.0, 1.2, 0.6, 1.8, 3.2, 4.0];

// ── DAY CYCLE ───────────────────────────────────────────────────────────────
// A continuous local-clock time (0–24h) drives everything: the two bracketing
// phase plates crossfade, and every per-phase value is interpolated between
// them, so the scene glides through the day instead of snapping between phases.
// Peak hour of each phase (index order: pre-dawn, sunrise, midday, sunset,
// twilight, midnight). Tunable later; these are sensible stylised times.
// Each phase HOLDS across its own window and crossfades only for a short TR at
// the boundary. (Interpolating across the whole gap meant pre-dawn light bled
// back to 2am — deep night was already 35% sunrise.) Long night and day, SHORT
// sunrise/sunset, per the founder's schedule.
// Each row is [hour, phase, tr] where `hour` is when the phase is FULLY in and
// `tr` is how long it took to get there — the crossfade runs in the tr hours
// BEFORE the boundary and completes on it. (It used to start on the boundary, so
// the sunset plate only began shifting once the sun was already at the horizon and
// then snapped over in 36 min. Now the warm hue creeps in from 16:42 while the sun
// is still descending, and lands exactly as the sun touches the water at 18:30 —
// the sun's own altitude drop runs over that identical span.)
//   midnight 21:48 · pre-dawn 04:48 · sunrise 06:00 · day 07:45
//   sunset 18:30 · twilight 20:36
// Sunrise and sunset are the strongest plates, so they HOLD long (founder's call).
// NO transition is shorter than 1.0h. sunrise→midday was 0.5h and it showed: the
// warm sky drained to blue inside ~25 min, fast enough to read as two images
// dissolving rather than the light changing. It is the largest colour move of the
// day, so it gets the second-longest fade. smoothstep peaks at 1.5/T, so T=1.3h
// caps the rate at ~1.15/h — below the threshold where the change draws the eye.
// Day schedule in REFERENCE time (warpTime maps the real local day onto this). [hourFULLYshown, phase, crossfade-in hrs].
// A phase is PURE from its hour until (next hour − next crossfade). Reference windows (sunrise 6:00, sunset ≈18:24):
//   midnight 21:45→04:12 · pre-dawn 04:54→05:24 · sunrise 06:06→07:06 · midday 08:24→16:51 ·
//   sunset 18:12→18:51 · twilight 19:39→20:45 — the midday→sunset golden build starts ~1.5 h before sunset.
//   phases: 0 pre-dawn · 1 sunrise · 2 midday · 3 sunset · 4 twilight · 5 midnight
// REFERENCE sunset = 18.4. Real civil+nautical twilight (the visible glow) lasts ~1h after sunset, not ~2h —
// so night (midnight plate) now begins at 19.5 ref (~1.1 h after sunset), and the sun's glow (SUN_ALT below)
// dies by then. Warped to a real ~7 PM sunset, night lands by ~8 PM, not 9 PM. (Fixes twilight-glow-at-9-PM.)
const SEG = [[0.0,5,0],[4.9,0,0.7],[6.1,1,0.7],[8.0,2,1.3],
             [17.9,3,1.35],[18.7,4,0.55],[19.5,5,0.7],[24.0,5,0]];
// picking a phase to edit jumps here — where the phase reads purest
const PH_HOUR = [5.4, 6.4, 12.0, 18.0, 19.0, 1.0];   // representative hour per phase (twilight now 19.0, matching the shortened dusk)
function phaseAt(t){                              // t hours → {a,b,blend}
  t=((t%24)+24)%24;
  let i=0;
  for(let k=0;k<SEG.length-1;k++){ if(t>=SEG[k][0] && t<SEG[k+1][0]){ i=k; break; } }
  const cur=SEG[i][1], nx=SEG[i+1], tr=nx[2], left=nx[0]-t;
  if(tr>0 && left<tr && nx[1]!==cur)              // crossfading INTO the next phase
    return {a:cur, b:nx[1], blend:smooth(1-left/tr)};
  return {a:cur, b:cur, blend:0};                 // holding — pure phase
}
const lerp=(a,b,t)=>a+(b-a)*t;
const lerp3=(A,B,t)=>[lerp(A[0],B[0],t),lerp(A[1],B[1],t),lerp(A[2],B[2],t)];

// ── SUN / MOON per phase ── position (canvas-normalised, y DOWN 0=top),
// body (0 moon · 1 sun), intensity. Left-biased so shadows fall right. Draggable.
const SUN_POS = [[0.20,0.30],[0.30,0.40],[0.36,0.16],[0.26,0.40],[0.22,0.32],[0.24,0.22]];
const SUN_TYPE= [0, 1, 1, 1, 0, 0];              // pre-dawn..midnight
const SUN_INT = [0.45, 0.90, 1.00, 0.85, 0.45, 0.55];
// Sunrise / sunset hours. Local clock is already the visitor's timezone; these
// bound the sun's up-window, and the moon's window never overlaps it, so the two
// discs are NEVER up together.
let SR=6.0, SS=18.5;                    // sun up-window
let MR=19.7, MS=4.6;                    // moon up-window: rises once the sun's dusk glow is dead (~19.5), sets before the dawn glow (~4.9)
// ── Location-based day cycle (2026-07-30) ─────────────────────────────────────
// SEG / SUN_ALT / SR·SS / MOON_ALT below are tuned for a REFERENCE day (sunrise 6:00, sunset ≈18:24).
// warpTime() piecewise-stretches the viewer's REAL local day (SunCalc, from their timezone's coords) onto the
// reference, so plates + sun + moon all shift together to match the region. The moon's arc sits inside the
// reference NIGHT, so after warping it stays in the real night — it can never coincide with the sun/glow.
const REF_SR = 6.0, REF_SS = 18.4;
let SR_real = REF_SR, SS_real = REF_SS;
try { const _st = localSunTimes(); SR_real = _st.sr; SS_real = _st.ss; } catch(e){}
// NOT called on load. Firing getCurrentPosition here threw a browser location prompt at every visitor within a
// second of landing — against the locked decision in master spec §5 (timezone→coords, "no permission prompt,
// privacy-clean"), and a conversion killer on the landing page. `preciseSunTimes` stays in geo.js for the
// opt-in "use my exact location" control that spec §5 defers to later; wire it to a user gesture, never to load.
// window.SustainScene.useExactLocation() below is that gesture hook.
function useExactLocation(){ try { preciseSunTimes(function(sr,ss){ SR_real=sr; SS_real=ss; }); } catch(e){} }
// ...but if the visitor has ALREADY granted location, use it — that is not a prompt, so §5's "no permission
// prompt" rule still holds, and it is the only way to be accurate: one representative coord per timezone is
// off by up to half an hour across a wide country (Asia/Kolkata sits at 80°E, ~9° east of Rajkot, which is
// ~37 min of sunset). Permissions API tells us the state without triggering the prompt.
try {
  if (navigator.permissions && navigator.permissions.query) {
    navigator.permissions.query({ name: 'geolocation' })
      .then(function(st){
        if (st.state === 'granted') useExactLocation();
        st.onchange = function(){ if (st.state === 'granted') useExactLocation(); };
      })
      .catch(function(){});
  }
} catch(e){}
function warpTime(t){
  const dayR = SS_real - SR_real, dayRef = REF_SS - REF_SR;
  if (t >= SR_real && t < SS_real) return REF_SR + (t - SR_real) / dayR * dayRef;   // daytime
  const tn = (t >= SS_real) ? (t - SS_real) : (t + 24 - SS_real);                   // hours since sunset
  return (REF_SS + tn / (24 - dayR) * (24 - dayRef)) % 24;                          // night
}

// ALTITUDE KEYFRAMES: [hour, altitude], 0 = horizon, 1 = peak, negative = below
// (afterglow only — the disc is clipped by the horizon in the shader).
// This replaces sin(π·u), which peaked for an instant and then fell steadily: by
// 16:00 the sun sat near the horizon while the midday plate was still up. The real
// high-sun hours are a PLATEAU, and the descent belongs inside the sunset window —
// so the drop (16:42→18:30) now runs over exactly the same span as the sunset
// plate's crossfade, and the two move together instead of the sun arriving early.
// The window must OPEN BELOW the horizon (−0.46, where amt is still 0), not at 0.
// Starting at 0 put the disc's CENTRE on the water line at 06:00, so half the sun
// popped into existence in one frame. Now it climbs from fully submerged: glow
// builds from 06:00, the upper limb breaks the water ~06:15, half disc ~06:27,
// fully clear ~06:45 — an actual rise. Sunset mirrors it through 18:21→18:39.
// Sun at the horizon (alt 0) at reference sunset 18.4, then drops to −0.46 (glow fully dead) by 19.5 — so the
// afterglow lasts ~1.1 h, matching the twilight window above (was −0.46 at 20.4, a ~2 h glow that read at 9 PM).
const SUN_ALT = [[6.0,-0.46],[6.30,-0.06],[6.85,0.28],[7.75,0.62],[11.0,0.95],
                 [12.75,1.00],[14.5,0.80],[16.0,0.52],[17.4,0.26],[18.4,0.0],[18.75,-0.16],[19.5,-0.46]];
// Moon hours are in the shifted domain used by trackMoon (evening→dawn continuous).
// Moon rises 21:45, once the sun's afterglow is fully dead (20:24), and is gone by
// 05:30 — before the sunrise glow starts at 06:00. Hours are in the shifted domain
// trackMoon uses (evening→dawn continuous), so 29.5 == 05:30.
// Shifted domain (evening→dawn continuous; +24 after midnight). Rises 19.7 (glow dead), peaks at 24.0 (midnight),
// sets 28.6 == 04:36 — fully down before the dawn glow, so sun & moon (and their glows) are never up together.
const MOON_ALT= [[19.7,-0.46],[20.0,-0.06],[20.6,0.28],[21.4,0.55],[24.0,0.92],
                 [26.3,0.80],[27.8,0.0],[28.2,-0.16],[28.6,-0.46]];
// smoothstep between keyframes; outside the table the body is fully below.
function altAt(t, K){
  if(t < K[0][0] || t > K[K.length-1][0]) return -1;
  for(let i=0;i<K.length-1;i++)
    if(t>=K[i][0] && t<=K[i+1][0])
      return lerp(K[i][1], K[i+1][1], smooth((t-K[i][0])/(K[i+1][0]-K[i][0])));
  return -1;
}
// ONE body on a real ALTITUDE ARC. Screen height rises from the horizon, holds
// high through the day, and sinks back; below the horizon the disc is CLIPPED in
// the shader, so it truly rises from and sets beyond the sea — never fades in
// mid-sky. x + peak-height come from the 3 draggable keyframes.
function celTrack(t, on, span, kf, inten, ALT){
  const alt=altAt(t, ALT);
  const u=(t-on)/span;
  const cu=clamp(u,0,1), f=cu<0.5?cu*2:(cu-0.5)*2, A=cu<0.5?0:1, B=cu<0.5?1:2;
  const x=lerp(SUN_POS[kf[A]][0], SUN_POS[kf[B]][0], f);
  let peakY=lerp(SUN_POS[kf[A]][1], SUN_POS[kf[B]][1], f);     // canvas-y (down) of the peak
  const hc=1-S.hor;                                            // horizon in canvas-y
  // Keep the body in the VISIBLE sky: fit() can crop the top (_skyTop). Never let the peak rise past _skyTop plus
  // a disc/glow+breathing margin; keep it above the horizon too. So on short windows the sun simply arcs lower.
  peakY = Math.min(hc-0.02, Math.max(peakY, _skyTop + 0.13));
  const y=hc + (peakY-hc)*alt;                                 // horizon at alt 0, peak at alt 1
  // Brightness fades only BELOW the horizon. The ramp reaches zero at alt −0.46,
  // which is where the fade window ends — so the afterglow dies exactly at 20:24
  // rather than being cut short at 19:40 by a too-narrow ramp.
  const amt=clamp(smooth((alt+0.46)/0.51),0,1) * lerp(inten[A],inten[B],f);

  return { pos:[x,y], amt, alt };
}
// NOTE: per-altitude glow INTENSITY ramps used to live here. Several attempts read
// wrong at one hour or another; the glow is now simply bright whenever the body is
// up, and only its COLOUR moves with altitude. Simpler, and correct.
function trackSun(t){
  return celTrack(t, SR, SS-SR, [1,2,3], [SUN_INT[1],SUN_INT[2],SUN_INT[3]], SUN_ALT);
}
function trackMoon(t){
  const tt = t>=MR ? t : t+24;                                // evening→dawn continuous
  return celTrack(tt, MR, (MS+24)-MR, [4,5,0], [SUN_INT[4],SUN_INT[5],SUN_INT[0]], MOON_ALT);
}
// ── SUN KEYS ── three fully independent looks. The rendered sun BLENDS between
// them by the sun's own height: on the way up sunrise→midday, on the way down
// midday→sunset. One global setting could never read right at every hour, which is
// what every previous attempt was trying to do.
const SUN_FIELDS = ['sunSize','coreW','coreA','nearW','nearA','farW','farA'];
const SUN_COLS   = ['coreCol','nearCol','farCol'];
// LOCKED by the founder 2026-07-19. The near/far glow layers are deliberately OFF
// (nearA/farA = 0): the look is a single steep, bright core and nothing else, with
// only its colour shifting through the day. Do not "restore" the glow layers.
const SUNKEY = [
  { name:'sunrise', sunSize:0.09, coreW:8, coreA:6, nearW:3, nearA:0,
    farW:0.01, farA:0, coreCol:'#fffffa', nearCol:'#ffd170', farCol:'#ffae42' },
  { name:'midday',  sunSize:0.09, coreW:8, coreA:6, nearW:3, nearA:0,
    farW:0.01, farA:0, coreCol:'#fffffe', nearCol:'#ffeaa8', farCol:'#ffe8bb' },
  { name:'sunset',  sunSize:0.09, coreW:8, coreA:6, nearW:3, nearA:0,
    farW:0.01, farA:0, coreCol:'#fffff8', nearCol:'#ffc55e', farCol:'#ff9a34' },
];
const hex2rgb = h => [parseInt(h.slice(1,3),16)/255,
                      parseInt(h.slice(3,5),16)/255,
                      parseInt(h.slice(5,7),16)/255];
// pull the edited key's values into S so the sliders show/write the right set
function loadSunKey(){
  const k = SUNKEY[S.sunKey|0];
  for(const f of SUN_FIELDS.concat(SUN_COLS)) S[f] = k[f];
  for(const f of SUN_FIELDS){ const el=$(f); if(el){ el.value=k[f]; const o=$('v'+f[0].toUpperCase()+f.slice(1)); if(o) o.textContent=(+k[f]).toFixed(f==='sunSize'?3:2); } }
  for(const f of SUN_COLS){ const el=$(f); if(el) el.value=k[f]; }
  const nm=$('vSunKey'); if(nm) nm.textContent=k.name;
  dumpSunKeys();
}
function dumpSunKeys(){
  const t=$('sunOut'); if(!t) return;
  t.value = SUNKEY.map(k=>`${k.name}: `+SUN_FIELDS.map(f=>`${f}=${k[f]}`).join(' ')
            +' '+SUN_COLS.map(f=>`${f}=${k[f]}`).join(' ')).join('\n');
}
// writing a slider edits the KEY being viewed, not a global
function storeSunKey(){
  const k = SUNKEY[S.sunKey|0];
  for(const f of SUN_FIELDS.concat(SUN_COLS)) k[f] = S[f];
  dumpSunKeys();
}
// The sand against the glass is darker at night and lifts toward midday. Driven by
// the sun's ALTITUDE, not the clock, so it tracks where the light actually is and
// lands mid-range through sunrise and sunset on its own.
const BED = { lift: -0.400 };
// interpolated "current" light — what the sand grade and rim actually read
const CUR = { expo:1, lit:[255,255,255], shd:[255,255,255], sat:1, rim:0.6, t:12, a:2, b:2, blend:0 };
const clockHours=()=>{ const d=new Date(); return d.getHours()+d.getMinutes()/60+d.getSeconds()/3600; };
const fmtHM=t=>{ const h=Math.floor(t), m=Math.floor((t-h)*60); return `${h}:${String(m).padStart(2,'0')}`; };
function updateDayCycle(){
  const t = S.live ? warpTime(clockHours()) : S.daytime;   // live -> real local day warped onto the reference
  const {a,b,blend} = phaseAt(t);
  CUR.t=t; CUR.a=a; CUR.b=b; CUR.blend=blend;
  U.uTex.value=plateTex(a); U.uTex2.value=plateTex(b); U.uMix.value=blend;
  CUR.expo=lerp(PH_EXPO[a],PH_EXPO[b],blend);
  CUR.lit =lerp3(PH_LIT[a],PH_LIT[b],blend);
  CUR.shd =lerp3(PH_SHD[a],PH_SHD[b],blend);
  CUR.sat =lerp(PH_SAT[a],PH_SAT[b],blend);
  CUR.rim =lerp(PH_RIM[a],PH_RIM[b],blend);
  // one sun (A) + one moon (B), each travelling its own path (continuous, on the location-warped clock)
  const su=trackSun(t), mo=trackMoon(t);
  BED.lift = lerp(S.bedNight, S.bedDay, smooth(clamp(su.alt,0,1)/0.70));
  U.uCelA.value.set(su.pos[0], 1-su.pos[1]); U.uCelAtype.value=1; U.uCelAamt.value=su.amt;
  U.uCelB.value.set(mo.pos[0], 1-mo.pos[1]); U.uCelBtype.value=0; U.uCelBamt.value=mo.amt;
  U.uCelAalt.value=clamp(su.alt,0,1); U.uCelBalt.value=clamp(mo.alt,0,1);
  // Blend the three sun keys by the sun's own HEIGHT: climbing runs sunrise→midday,
  // descending runs midday→sunset. Using altitude (not the clock) means the look
  // always matches where the sun actually is.
  {
    const h = clamp(su.alt,0,1);
    const rising = altAt(t+0.05, SUN_ALT) > su.alt;
    const A = SUNKEY[rising ? 0 : 2], B = SUNKEY[1], f = smooth(h);
    for(const k of SUN_FIELDS) U['u'+k[0].toUpperCase()+k.slice(1)].value = lerp(A[k], B[k], f);
    for(const k of SUN_COLS){
      const a=hex2rgb(A[k]), b=hex2rgb(B[k]);
      U['u'+k[0].toUpperCase()+k.slice(1)].value.set(lerp(a[0],b[0],f), lerp(a[1],b[1],f), lerp(a[2],b[2],f));
    }
  }
  // colour of the light currently in the sky — a low sun is ORANGE (long
  // atmospheric path scatters the blue out), a high sun warm-white, the moon cool.
  // Everything the light touches (water path, glints) takes this colour.
  const sunUp = su.amt>=mo.amt, aF = clamp(sunUp?su.alt:mo.alt, 0, 1);
  const LC = sunUp ? [lerp(1.00,1.00,aF), lerp(0.74,0.93,aF), lerp(0.40,0.75,aF)]
                   : [0.70,0.82,1.00];
  U.uLightCol.value.set(LC[0],LC[1],LC[2]);
  U.uPathX.value = su.amt>=mo.amt ? su.pos[0] : mo.pos[0];   // glitter follows the brighter body
  if(S.live && $('vDaytime')) $('vDaytime').textContent=fmtHM(t);
}

// r,g,b in 0–255; lit in [0,1] (1 = key-lit tone, 0 = shadow tone). Returns [r,g,b].
// LUMINANCE-PRESERVING: the phase tint shifts HUE only — each tone's brightness
// is restored (× exposure) afterward. That's what keeps the sand equally bright
// and readable in every phase (a plain multiply darkened the shadows into mud).
function gradeRGB(r,g,b,lit){
  const e=CUR.expo, L=CUR.lit, D=CUR.shd, t=clamp(lit,0,1);
  const L0=0.299*r+0.587*g+0.114*b;
  let R=r*(D[0]+(L[0]-D[0])*t)/255, G=g*(D[1]+(L[1]-D[1])*t)/255, B=b*(D[2]+(L[2]-D[2])*t)/255;
  const k=(L0*e)/(0.299*R+0.587*G+0.114*B||1);
  R*=k; G*=k; B*=k;
  const s=CUR.sat;
  if(s!==1){ const y=0.299*R+0.587*G+0.114*B; R=y+(R-y)*s; G=y+(G-y)*s; B=y+(B-y)*s; }
  return [clamp(R,0,255),clamp(G,0,255),clamp(B,0,255)];
}
function sandCol(dl, half){                 // day albedo → relit; the tone's own
  const m = HALF[half] || HALF.B;           // LIGHTNESS decides lit↔shadow, so
  const L = clamp(S[m.l]+dl, 0, 1);         // bright tones keep day sand and only
  const [r,g,b] = hslToRgb(S[m.h]/360, S[m.s]/100, L);   // the dark tones take the phase.
  const hiL=Math.max(S.slitT+S.litT, S.slitB+S.litB), loL=Math.min(S.slitT-S.shdT, S.slitB-S.shdB);
  const c = gradeRGB(r,g,b, clamp((L-loL)/Math.max(hiL-loL,0.02),0,1));
  return `rgb(${c[0]|0},${c[1]|0},${c[2]|0})`;
}

// SAND TEXTURE — measured from plates/sand-anime.png, interior pixels only:
//   · neighbouring pixels differ by just 5.2/255 while the overall spread is
//     16.7  → adjacent pixels are nearly equal, so it is NOT per-pixel grain
//   · 51% of the variance survives 16x16 block-averaging → the texture lives at
//     LARGE scales: soft mottling, not film grain
//   · chroma std 4.0 vs luminance std 16.7 → brightness only, no colour speckle
// The old version was independent random values per pixel at ±46 — photographic
// grain, i.e. exactly the wrong frequency AND far too strong. This builds smooth
// multi-octave value noise instead, low frequency dominant.
const grainCv = document.createElement('canvas');
let grainPat = null, grainBuiltAt = 0;
// Octave mix SOLVED against the reference's autocorrelation curve
// (r1 .78 · r2 .61 · r3 .52 · r5 .37, correlation length ~5px over 151px of sand):
// a dominant ~F mottle, two coarser tails for the long-range correlation, and —
// crucially — a WHITE per-pixel octave. Without white, adjacent pixels came out
// far too alike (r1 .96 vs .78); adding it at weight .40 cut the total error
// across 8 lags from 0.88 to 0.50. F is a FRACTION of the hourglass width, so
// the texture scales with the object instead of with the window.
function buildGrain(featPx){
  const N = 512;                       // wider than the hourglass → never tiles visibly
  const F = Math.max(2, featPx);
  grainCv.width = grainCv.height = N;
  const oct = [[F,1.0], [F*2.8,0.40], [F*8,0.35], [0,0.40]];   // 0 = per-pixel white
  const buf = new Float64Array(N*N);
  for (const [f,w] of oct){
    if (f <= 0){ for(let i=0;i<buf.length;i++) buf[i]+=(Math.random()*2-1)*w; continue; }
    const cells = Math.max(2, Math.round(N/f));
    const g = new Float64Array(cells*cells);
    for (let i=0;i<g.length;i++) g[i] = Math.random()*2-1;
    const s = cells/N;
    const at = (a,b)=> g[(((b%cells)+cells)%cells)*cells + (((a%cells)+cells)%cells)];
    for (let y=0;y<N;y++) for (let x=0;x<N;x++){
      const fx=x*s-0.5, fy=y*s-0.5;
      const x0=Math.floor(fx), y0=Math.floor(fy), tx=fx-x0, ty=fy-y0;
      buf[y*N+x] += w*( at(x0,y0)*(1-tx)*(1-ty) + at(x0+1,y0)*tx*(1-ty)
                      + at(x0,y0+1)*(1-tx)*ty  + at(x0+1,y0+1)*tx*ty );
    }
  }
  // Normalise to a known std, so the Texture slider maps predictably onto real
  // brightness variation (the reference residual measured 7.2%).
  let m=0; for(let i=0;i<buf.length;i++) m+=buf[i]; m/=buf.length;
  let v=0; for(let i=0;i<buf.length;i++) v+=(buf[i]-m)**2;
  const sd = Math.sqrt(v/buf.length) || 1;
  const gx = grainCv.getContext('2d'), im = gx.createImageData(N,N);
  for (let i=0;i<buf.length;i++){
    const val = clamp(128 + (buf[i]-m)/sd*48, 0, 255);
    im.data[i*4]=im.data[i*4+1]=im.data[i*4+2]=val; im.data[i*4+3]=255;
  }
  gx.putImageData(im,0,0);
  grainPat = null; grainBuiltAt = F;    // pattern must be rebuilt from the new canvas
}

// Fill a sand region: base vertical gradient for form, then grain overlay
// clipped to the same path, then a soft top-edge catch-light.
// CEL SHADING. Two different jobs, because they are NOT the same problem:
//
// celBand — the sand MASS. Anime paints a body of sand as ONE flat tone, with
// only a thin lit strip along the top surface and a thin shadow at the base.
// (Splitting it 50/50 drew a hard line straight across the middle of the mass,
// matching no real form — that's the artifact at high flatness.)
function celBand(g, hi, mid, lo){
  const t = S.flat;
  const a = 0.05 + 0.35*(1-t);            // lit strip ends here
  const b = 0.95 - 0.35*(1-t);            // shadow starts here
  g.addColorStop(0, hi);
  g.addColorStop(a, mid);
  g.addColorStop(Math.max(a+0.001, b), mid);
  g.addColorStop(1, lo);
}

// The bottom cone gets its own fill rather than sharing fillSand's: it needs its
// apex and its base shaded INDEPENDENTLY, and fillSand's single lift cannot do that.
function fillCone(path, topY, botY){
  if (!grainPat) grainPat = sctx.createPattern(grainCv, 'repeat');
  if (Math.abs(botY-topY) < 1) botY = topY + 1;
  const g = sctx.createLinearGradient(0, topY, 0, botY);
  g.addColorStop(0,    sandCol(S.coneLift - S.coneTopShd,      'B'));  // apex
  g.addColorStop(0.22, sandCol(S.coneLift - S.coneTopShd*0.35, 'B'));
  g.addColorStop(0.55, sandCol(S.coneLift,                     'B'));  // body
  g.addColorStop(0.82, sandCol(S.coneLift - S.coneBotShd*0.45, 'B'));
  g.addColorStop(1,    sandCol(S.coneLift - S.coneBotShd,      'B'));  // meets the bed
  sctx.save();
  sctx.clip(path);
  sctx.fillStyle = g; sctx.fill(path);
  sctx.globalCompositeOperation = 'overlay';
  sctx.globalAlpha = S.grain;
  sctx.fillStyle = grainPat; sctx.fillRect(0, 0, DW, DH);
  sctx.globalAlpha = 1; sctx.globalCompositeOperation = 'source-over';
  sctx.restore();
}

function fillSand(path, topY, botY, lift, half){
  if (!grainPat) grainPat = sctx.createPattern(grainCv, 'repeat');
  if (Math.abs(botY-topY) < 1) botY = topY + 1;   // degenerate on flat ellipses
  const m = HALF[half] || HALF.B;
  const g = sctx.createLinearGradient(0, topY, 0, botY);
  celBand(g, sandCol(lift+S[m.lit], half), sandCol(lift, half), sandCol(lift-S[m.shd], half));
  sctx.save();
  sctx.clip(path);
  sctx.fillStyle = g; sctx.fill(path);
  sctx.globalCompositeOperation = 'overlay';
  sctx.globalAlpha = S.grain;
  sctx.fillStyle = grainPat; sctx.fillRect(0, 0, DW, DH);
  sctx.globalAlpha = 1; sctx.globalCompositeOperation = 'source-over';
  sctx.restore();
}

// Build the glass interior path in DISPLAYED pixels (so sand clips to the glass).
// Every bezier handle below is driven by a "Curve" slider, so the whole silhouette
// is tunable live. Left side mirrors the right, so it always stays symmetric.
//   w* = the Y where each bulb is widest (fraction of that bulb's height)
//   a*/b*/c* = handle lengths that set how full/round the curve is at each end
//   rimK/baseK = how far the top-rim / bottom-base corners round out (× width)
//   mxBot = bottom-bulb width relative to the top (1 = equal)
// ── SEA REGION MASK ─────────────────────────────────────────────────────────
// A colour test cannot separate sea from blue shadow on the cliffs, which is why
// sparkle was leaking onto land. So the sea is a hand-drawn region instead.
// ONE texture carries both masks: R = sea, G = the hourglass glass.
// [x, y, sharp] — sharp=1 gives a hard corner / straight run, 0 gives a curve.
// Edge markers sit just INSIDE the canvas so they can actually be grabbed.
// FOUNDER-LOCKED sea region (2026-07-18) — traced around the coastline.
let SEA = [
  [0.1851,0.7496,0],[0.1347,0.7733,0],[-0.0042,0.6527,0],[0.0085,0.5589,0],
  [0.5946,0.5546,0],[0.6747,0.5740,0],[0.6669,0.6053,0],[0.7348,0.6279,0],
  [0.7281,0.7076,0],[0.6863,0.7475,0],[0.7287,0.7960,0],[0.6395,0.8800,0],
  [0.2919,0.8778,0],
];
const maskCv=document.createElement('canvas'), maskCtx=maskCv.getContext('2d');
let maskTex=null, maskDirty=true;
function dumpSea(){
  const el=$('seaOut'); if(!el) return;
  const r=v=>+v.toFixed(4);
  el.value = JSON.stringify(SEA.map(q=>[r(q[0]), r(q[1]), q[2]|0]));
}
const markMaskDirty=()=>{ maskDirty=true; dumpSea(); };

// Catmull-Rom through EVERY node, converted to cubics. The curve passes exactly
// through each marker (a midpoint scheme only passes near them, which makes
// tracing a coastline guesswork). Flagging a node 'sharp' zeroes its tangent, so
// two adjacent sharp nodes collapse the cubic into a genuine straight line —
// that's how you get straight runs and curves in the same outline.
function seaPath(){
  const n=SEA.length;
  const P=i=>{ const q=SEA[(i%n+n)%n]; return [q[0]*DW, q[1]*DH]; };
  const sharp=i=>!!SEA[(i%n+n)%n][2];
  const p=new Path2D(), a0=P(0);
  p.moveTo(a0[0],a0[1]);
  for(let i=0;i<n;i++){
    const A=P(i), B=P(i+1), Pm=P(i-1), Pn=P(i+2);
    const c1 = sharp(i)   ? A : [A[0]+(B[0]-Pm[0])/6, A[1]+(B[1]-Pm[1])/6];
    const c2 = sharp(i+1) ? B : [B[0]-(Pn[0]-A[0])/6, B[1]-(Pn[1]-A[1])/6];
    p.bezierCurveTo(c1[0],c1[1], c2[0],c2[1], B[0],B[1]);
  }
  p.closePath(); return p;
}

function rebuildMask(G){
  const W=Math.max(1,Math.round(DW)), H=Math.max(1,Math.round(DH));
  maskCv.width=W; maskCv.height=H;
  maskCtx.setTransform(1,0,0,1,0,0);
  maskCtx.globalCompositeOperation='source-over';
  maskCtx.fillStyle='#000'; maskCtx.fillRect(0,0,W,H);
  maskCtx.save();
  if(S.seaFeather>0) maskCtx.filter=`blur(${S.seaFeather}px)`;  // soft shoreline
  maskCtx.fillStyle='#ff0000'; maskCtx.fill(seaPath());          // R = sea
  maskCtx.restore();
  maskCtx.globalCompositeOperation='lighter';
  maskCtx.fillStyle='#00ff00'; maskCtx.fill(G.p);                // G = glass
  maskCtx.globalCompositeOperation='source-over';
  if(!maskTex){ maskTex=new THREE.CanvasTexture(maskCv); U.uMask.value=maskTex; }
  maskTex.needsUpdate=true;
}

// ── Session number OCCLUSION: numbers pass BEHIND the hourglass / sea-horizon / ledge. The #occ layer
//    copies the LIVE WebGL plate each frame and keeps only the silhouette, so it matches the render exactly
//    (crossfade, sun/moon, glitter). Mattes come from maskCv's own channels — G = glass, R = sea — the same
//    silhouette the shader composites, so they track the founder's re-traced hourglass. Rebuilt with the mask. ──
const occtx = occCv.getContext('2d');
let occGlassCv=null, occHorizonCv=null;
// Occlusion rules (number-lab.html §289): the HOURGLASS matte occludes in EVERY mode; the SEA (horizon)
// matte occludes ONLY in horizon mode; the ledge NEVER occludes (numbers rest ON the ledge). So the glass
// matte is the base for every placement, and horizon additionally unions the sea.
function buildOccMattes(){
  const mw=maskCv.width, mh=maskCv.height;
  const d = maskCtx.getImageData(0,0,mw,mh).data;
  // glass matte: alpha = the G (glass) channel, hard-edged (only the SEA carries the shoreline feather).
  occGlassCv = document.createElement('canvas'); occGlassCv.width=mw; occGlassCv.height=mh;
  { const cx=occGlassCv.getContext('2d'), im=cx.createImageData(mw,mh), o=im.data;
    for(let i=0;i<d.length;i+=4) o[i+3]=d[i+1];
    cx.putImageData(im,0,0); }
  // horizon matte = glass ∪ a HARD sea. Filling seaPath() directly (no seaFeather blur) gives a CRISP horizon
  // edge, so the numbers VANISH cleanly beyond it — not the translucent fade the feathered R channel produced.
  occHorizonCv = document.createElement('canvas'); occHorizonCv.width=mw; occHorizonCv.height=mh;
  const hx = occHorizonCv.getContext('2d');
  hx.fillStyle='#000'; hx.fill(seaPath());   // seaPath uses DW/DH == mw/mh → aligns; opaque fill = alpha 255
  hx.drawImage(occGlassCv, 0, 0);            // union the hourglass on top
}
function drawOcc(place){
  const matte = place==='horizon' ? occHorizonCv : occGlassCv;   // hourglass occludes every mode; horizon adds the sea
  occtx.setTransform(1,0,0,1,0,0);
  occtx.globalCompositeOperation='source-over';
  occtx.clearRect(0,0,occCv.width,occCv.height);
  if(!matte) return;
  occtx.drawImage(glitterCv, 0,0, occCv.width, occCv.height);   // live plate render, 1:1
  occtx.globalCompositeOperation='destination-in';
  occtx.drawImage(matte, 0,0, occCv.width, occCv.height);        // keep only the occluder silhouette
  occtx.globalCompositeOperation='source-over';
}

// ── EDITABLE OUTLINE (pen tool) ─────────────────────────────────────────────
// The RIGHT half is a list of nodes; the left mirrors about cx, so the glass
// stays symmetric for free. Coords are normalised 0–1 of the image, so they
// survive resize and can be baked straight into the defaults.
//   a = anchor · hi = handle IN (from previous node) · ho = handle OUT (to next)
// The sliders only SEED this list. Dragging any point makes it authoritative —
// which is the whole point: sliders forced the handles to stay axis-aligned, so
// some shoulder curves were literally unreachable. Free handles reach them.
// FOUNDER-LOCKED OUTLINE — dragged to 100% on 2026-07-18. This is the source of
// truth for the silhouette now; the curve sliders below only regenerate a
// starting shape if you deliberately go back to them (Shift+R).
const LOCKED_NODES = [
  {a:[0.4976,0.3471], hi:null,             ho:[0.5352,0.3492]},
  {a:[0.5520,0.3675], hi:[0.5449,0.3428],  ho:[0.5587,0.3815]},
  {a:[0.5661,0.4430], hi:[0.5661,0.4017],  ho:[0.5631,0.5464]},
  {a:[0.5009,0.6344], hi:[0.4991,0.5999],  ho:[0.5031,0.6735]},   // neck (founder re-traced 2026-07-29)
  {a:[0.5649,0.8114], hi:[0.5588,0.7120],  ho:[0.5636,0.8415]},
  {a:[0.5507,0.8764], hi:[0.5631,0.8520],  ho:[0.5495,0.8743]},
  {a:[0.4988,0.8829], hi:[0.5279,0.8829],  ho:null},
];
const cloneNodes = ns => ns.map(n=>({a:[...n.a], hi:n.hi&&[...n.hi], ho:n.ho&&[...n.ho]}));
// custom starts TRUE so the sliders' initial run cannot clobber the locked shape.
let NODES = cloneNodes(LOCKED_NODES), custom = true;

const lerpP=(A,B,t)=>[A[0]+(B[0]-A[0])*t, A[1]+(B[1]-A[1])*t];

// de Casteljau: split a cubic into two cubics at t. EXACT — the curve does not
// move, we just gain an editable anchor in the middle of it.
function splitCubic(s,t){
  const [P0,P1,P2,P3]=s;
  const Q1=lerpP(P0,P1,t), R=lerpP(P1,P2,t), S2=lerpP(P2,P3,t);
  const Q2=lerpP(Q1,R,t),  S1=lerpP(R,S2,t);
  const M =lerpP(Q2,S1,t);
  return [[P0,Q1,Q2,M],[M,S1,S2,P3]];
}
function segsToNodes(segs){
  const N=segs.map((s,i)=>({ a:s[0], hi: i? segs[i-1][2] : null, ho: s[1] }));
  const last=segs[segs.length-1];
  N.push({ a:last[3], hi:last[2], ho:null });
  return N;
}

function rebuildNodes(){
  const cx=S.cx, mx=S.max, mxB=S.max*S.mxBot, nh=S.nh, topW=S.topW, botW=S.botW;
  const yT=S.top, yN=S.neck, yB=S.bot, tb=yN-yT, bb=yB-yN;
  const yWT=yT+tb*S.wTop, yWB=yN+bb*S.wBot;
  let segs=[
    [[cx+topW,yT],[cx+topW+(mx-topW)*S.rimK,yT],[cx+mx,yT+tb*S.aTop],[cx+mx,yWT]],
    [[cx+mx,yWT],[cx+mx,yN-tb*S.bTop],[cx+nh,yN-tb*S.cTop],[cx+nh,yN]],
    [[cx+nh,yN],[cx+nh,yN+bb*S.aBot],[cx+mxB,yN+bb*S.bBot],[cx+mxB,yWB]],
    [[cx+mxB,yWB],[cx+mxB,yB-bb*S.cBot],[cx+botW+(mxB-botW)*S.baseK,yB],[cx+botW,yB]],
  ];
  // Split both SHOULDER segments (the ones next to the wood caps — where the
  // curve was hardest to trace) so each bulb ends up with 2 mid anchors.
  // Right half becomes: rim · A · widest · NECK · widest · C · base = 7 nodes,
  // i.e. 5 points around the top, 5 around the bottom, 1 neck.
  const a=splitCubic(segs[0],0.5), b=splitCubic(segs[3],0.5);
  NODES = segsToNodes([a[0],a[1],segs[1],segs[2],b[0],b[1]]);
}

function glassPath(){
  if (!NODES) rebuildNodes();
  const N=NODES, ax=S.cx;                       // ax = mirror axis (normalised)
  const X=v=>v*DW, Y=v=>v*DH, MX=v=>(2*ax-v)*DW;
  const p=new Path2D();
  p.moveTo(MX(N[0].a[0]), Y(N[0].a[1]));
  p.lineTo(X(N[0].a[0]),  Y(N[0].a[1]));        // flat top rim
  for(let i=0;i<N.length-1;i++){                // right side, top → bottom
    const A=N[i], B=N[i+1];
    p.bezierCurveTo(X(A.ho[0]),Y(A.ho[1]), X(B.hi[0]),Y(B.hi[1]), X(B.a[0]),Y(B.a[1]));
  }
  const L=N[N.length-1];
  p.lineTo(MX(L.a[0]), Y(L.a[1]));              // flat base
  for(let i=N.length-1;i>0;i--){                // left side, bottom → top (mirrored)
    const A=N[i], B=N[i-1];
    p.bezierCurveTo(MX(A.hi[0]),Y(A.hi[1]), MX(B.ho[0]),Y(B.ho[1]), MX(B.a[0]),Y(B.a[1]));
  }
  p.closePath();

  const cx=X(ax);
  const yT=Y(N[0].a[1]), yB=Y(N[N.length-1].a[1]);
  // Derived by SHAPE, not by index, so adding/removing nodes can't break it:
  // the neck is the narrowest INTERIOR node. Endpoints are excluded on purpose —
  // with a pointed rim/base (topW=botW=0) they sit exactly on the axis and would
  // otherwise win as "narrowest", collapsing yN onto yT.
  let ni=1;
  for(let i=2;i<N.length-1;i++) if(Math.abs(N[i].a[0]-ax) < Math.abs(N[ni].a[0]-ax)) ni=i;
  const yN=Y(N[ni].a[1]), nh=X(N[ni].a[0])-cx;
  // Sample the RIGHT silhouette so the sand can ask "how wide is the glass at
  // this height?" — needed to size every 3D surface ellipse.
  const prof=[];
  for(let i=0;i<N.length-1;i++){
    const A=N[i], B=N[i+1];
    const s=[X(A.a[0]),Y(A.a[1]), X(A.ho[0]),Y(A.ho[1]), X(B.hi[0]),Y(B.hi[1]), X(B.a[0]),Y(B.a[1])];
    for(let j=0;j<=24;j++){
      const u=j/24, v=1-u, a=v*v*v, b=3*v*v*u, c=3*v*u*u, e=u*u*u;
      // clamp: a negative half-width is meaningless to the sand, and the rim
      // anchor can sit a hair past the axis.
      prof.push([a*s[1]+b*s[3]+c*s[5]+e*s[7], Math.max(0, a*s[0]+b*s[2]+c*s[4]+e*s[6]-cx)]);
    }
  }
  prof.sort((m,n)=>m[0]-n[0]);
  const halfAt=(y)=>{
    if(y<=prof[0][0]) return prof[0][1];
    if(y>=prof[prof.length-1][0]) return prof[prof.length-1][1];
    let lo=0,hi=prof.length-1;
    while(hi-lo>1){ const m=(lo+hi)>>1; if(prof[m][0]<=y) lo=m; else hi=m; }
    const [y0,h0]=prof[lo],[y1,h1]=prof[hi];
    return y1===y0?h0:h0+(h1-h0)*(y-y0)/(y1-y0);
  };
  // widest point of each bulb, straight off the sampled profile
  let mx=0, mxB=0;
  for(const [y,h] of prof){ if(y<yN) mx=Math.max(mx,h); else mxB=Math.max(mxB,h); }
  return {p,cx,mx,mxB,nh,yT,yN,yB,halfAt};
}

// ── pen-tool overlay + dragging ─────────────────────────────────────────────
// Small ROUND markers — squares hid the very curve we're tracing.
// Both sides are drawn and both are grabbable; the mirror keeps them in sync.
function drawNodes(){
  const ax=S.cx, Y=v=>v*DH;
  const PX=(v,m)=>(m ? 2*ax-v : v)*DW;
  sctx.save();
  for(const m of [true,false]){                 // mirrored side first, fainter
    const A = m ? 0.45 : 1;
    for(const n of NODES){                      // handle arms + handle dots
      for(const h of [n.hi,n.ho]){
        if(!h) continue;
        sctx.strokeStyle=`rgba(80,200,255,${0.7*A})`; sctx.lineWidth=1;
        sctx.beginPath(); sctx.moveTo(PX(n.a[0],m),Y(n.a[1])); sctx.lineTo(PX(h[0],m),Y(h[1])); sctx.stroke();
        sctx.fillStyle=`rgba(80,200,255,${0.9*A})`;
        sctx.beginPath(); sctx.arc(PX(h[0],m),Y(h[1]),3,0,7); sctx.fill();
      }
    }
    for(const n of NODES){                      // anchors on top
      sctx.fillStyle=`rgba(255,255,255,${0.95*A})`;
      sctx.strokeStyle=`rgba(255,45,95,${A})`; sctx.lineWidth=1.5;
      sctx.beginPath(); sctx.arc(PX(n.a[0],m),Y(n.a[1]),4,0,7); sctx.fill(); sctx.stroke();
    }
  }
  sctx.restore();
}

function dumpNodes(){
  const r=v=>+v.toFixed(4);
  $('nodeOut').value = JSON.stringify(NODES.map(n=>({
    a:n.a.map(r), hi:n.hi&&n.hi.map(r), ho:n.ho&&n.ho.map(r) })));
}

let drag=null;
// Picks on EITHER side — grabbing the left mirror drags the right node inverted,
// so the two halves always move together.
function pickNode(px,py){
  const ax=S.cx, Y=v=>v*DH;
  let best=null, bd=12;
  NODES.forEach((n,i)=>{
    for(const key of ['ho','hi','a']){          // handles win ties over anchors
      const pt=n[key]; if(!pt) continue;
      for(const m of [false,true]){
        const x=(m ? 2*ax-pt[0] : pt[0])*DW;
        const dd=Math.hypot(x-px, Y(pt[1])-py);
        if(dd<bd){ bd=dd; best={i,key,mirror:m}; }
      }
    }
  });
  return best;
}

// A horizontal circle drawn in screen space IS an ellipse. Every 3D surface in
// the sand (top of the sand, top of the pile, the cone's base) is one of these.
function surfEllipse(cx,y,r,k){
  const p=new Path2D();
  p.ellipse(cx,y,Math.max(r,0.5),Math.max(r*k,0.4),0,0,Math.PI*2);
  return p;
}

// ── CODED GLASS: REAL refraction ────────────────────────────────────────────
// A hollow glass vessel barely bends light through its middle — you look through
// two near-parallel walls — but bends it hard at the rim, where the wall is seen
// edge-on and the light path through it is longest. So displacement grows with
// u² (u = how far across the glass you are), and we sample the ACTUAL plate
// through it: the background really is refracted, not faked with a gradient.
// Depends only on plate + outline, so it's cached and rebuilt on change, never
// per frame. ponytail: CPU pass over ~the glass box only (~100k px, a few ms).
const refrCv=document.createElement('canvas'), refrCtx=refrCv.getContext('2d',{willReadFrequently:true});
const srcCv =document.createElement('canvas'), srcCtx =srcCv.getContext('2d',{willReadFrequently:true});
let refrDirty=true;
const markGlassDirty=()=>{ refrDirty=true; };

function buildRefraction(G){
  const img=plateTex(S.phase|0).image;
  if(!img || !img.width) return false;                 // texture still loading
  const W=Math.max(1,Math.round(DW)), H=Math.max(1,Math.round(DH));
  srcCv.width=W; srcCv.height=H; refrCv.width=W; refrCv.height=H;
  srcCtx.drawImage(img,0,0,W,H);
  const sd=srcCtx.getImageData(0,0,W,H).data;
  const dst=refrCtx.createImageData(W,H), dd=dst.data;
  const {cx,yT,yB,halfAt}=G;
  const k=S.refr, tint=S.gtint, fres=S.fres, tex=S.gtex;
  const y0=Math.max(0,Math.floor(yT)), y1=Math.min(H-1,Math.ceil(yB));
  for(let y=y0;y<=y1;y++){
    const h=halfAt(y); if(h<=1) continue;
    const xa=Math.max(0,Math.floor(cx-h)), xb=Math.min(W-1,Math.ceil(cx+h));
    for(let x=xa;x<=xb;x++){
      const u=(x-cx)/h; if(u<-1||u>1) continue;
      const au=Math.abs(u);
      // refract: sample from further out, so the view compresses toward the rim
      let sx=cx+h*(u*(1+k*u*u));
      sx=sx<0?0:(sx>W-1?W-1:sx);
      const si=((y*W)+(sx|0))*4;
      let r=sd[si], g=sd[si+1], b=sd[si+2];
      // absorption — the path through the wall is longest at the rim, so it
      // picks up the glass's cool tint there and stays clear in the middle
      const t=tint*0.30*au*au;
      r=r*(1-t)+188*t; g=g*(1-t)+222*t; b=b*(1-t)+245*t;
      // Fresnel — glass turns reflective at grazing angles, so the rim goes bright
      const f=fres*Math.pow(au,4)*0.75;
      r+=(255-r)*f; g+=(255-g)*f; b+=(255-b)*f;
      // faint imperfection, so it doesn't read as CG-perfect
      if(tex>0){
        const n=((Math.sin(x*12.9898+y*78.233)*43758.5453)%1+1)%1;
        const dv=(n-0.5)*tex*26; r+=dv; g+=dv; b+=dv;
      }
      const di=((y*W)+x)*4;
      dd[di]=r; dd[di+1]=g; dd[di+2]=b; dd[di+3]=255;
    }
  }
  refrCtx.putImageData(dst,0,0);
  return true;
}

// ── GRANULAR PHYSICS ────────────────────────────────────────────────────────
// Dry sand rests at its ANGLE OF REPOSE (~34°, tan≈0.675): the pile steepens
// until gravity's downslope component equals friction, then avalanches back. So
// a poured pile is a CONE at that fixed angle — never a rounded bump — and it
// keeps the angle as it grows until the glass wall cuts it off.
// Everything below is volume-CONSERVING: we solve for the surface height that
// holds exactly the sand that has fallen. That's why it reads true at every
// fill level instead of only at the one that got hand-tuned.

// Sand half-width at height y: a cone from yApex, clipped by the glass wall.
const pileHalf=(y,yApex,rep,halfAt)=>Math.min(Math.max(y-yApex,0)/rep, halfAt(y));

// Volume of the solid of revolution (π dropped — only ratios matter).
function volBelow(yApex,yB,rep,halfAt,N=72){
  const dy=(yB-yApex)/N; if(dy<=0) return 0;
  let V=0; for(let i=0;i<N;i++){ const r=pileHalf(yApex+(i+0.5)*dy,yApex,rep,halfAt); V+=r*r*dy; }
  return V;
}
// Volume of a flat-topped fill between two heights (the TOP bulb — just a level).
function volLevel(yFrom,yTo,halfAt,N=72){
  const dy=(yTo-yFrom)/N; if(dy<=0) return 0;
  let V=0; for(let i=0;i<N;i++){ const r=halfAt(yFrom+(i+0.5)*dy); V+=r*r*dy; }
  return V;
}
// Both volumes fall monotonically as the free height drops, so bisect.
function solveHeight(target,lo,hi,f){
  for(let i=0;i<40;i++){ const m=(lo+hi)/2; if(f(m)>target) lo=m; else hi=m; }
  return (lo+hi)/2;
}

function drawSand(t){
  sctx.clearRect(0,0,DW,DH);
  const G = glassPath();
  const d = S.prog, {cx,mx,mxB,nh,yT,yN,yB,halfAt} = G;
  if (maskDirty){ rebuildMask(G); buildOccMattes(); maskDirty=false; }   // occluder mattes track the mask

  // OUTLINE-ONLY mode: trace the glass interior, NO sand, to fit it 100% first.
  if (S.dbg){
    sctx.save();
    sctx.strokeStyle='rgba(255,45,95,0.95)'; sctx.lineWidth=2; sctx.stroke(G.p);
    sctx.restore();
    drawNodes(); drawSeaOverlay(); drawCelOverlay(); drawHorOverlay();
    return;
  }

  // ONE glass clip wraps everything; the glass walls form the sand's sides.
  // k = how squashed a horizontal circle looks on screen, i.e. how far we are
  // looking DOWN onto the sand. This is the entire 3D illusion — 0 = edge-on.
  const k = S.persp;
  // Texture scales with the hourglass, not the window: rebuild only when the
  // feature size actually moves (a rebuild is ~1M samples, far too slow per frame).
  const featPx = Math.max(2, S.grainScale*2*mx);
  if (!grainBuiltAt || Math.abs(featPx-grainBuiltAt)/grainBuiltAt > 0.12) buildGrain(featPx);
  sctx.save();
  sctx.clip(G.p);

  // ── CODED GLASS BODY (behind the sand) — the refracted background. Only
  // needed on the bare plate, where no glass is painted in.
  if (S.glassOn){
    if (refrDirty && buildRefraction(G)) refrDirty=false;
    if (!refrDirty) sctx.drawImage(refrCv, 0, 0, DW, DH);
  }

  // ── TOP BULB: the eye is level with the NECK, so the top sand sits ABOVE us.
  // You therefore CANNOT see its top surface — no ellipse, and above all no
  // crater: a funnel is only visible looking DOWN into it. All that is visible
  // is the sand's FRONT rim, which bulges slightly up at centre because we're
  // looking at it from just below. Edge-on, i.e. it reads flat. That is why the
  // real reference looks 2D up top and 3D down below.
  // Total sand = a fraction of the top bulb's capacity, so both bulbs stay
  // consistent and the level is solved from the volume left, not interpolated.
  const rep  = S.repose;
  const Vtot = S.sandVol * volLevel(yT, yN, halfAt);
  if (d < 1){
    // The top drains on a LAGGED clock, not the raw progress. Left on the raw
    // clock it was already near-empty at 99%; the founder wants 99% to still show
    // what 96% shows, and the remainder to go all at once in the final window.
    //   d <= topHold : the top has only drained to topShown, so it holds its sand
    //   d >  topHold : the rest empties across topHold -> 1
    // dTop hits exactly 1 at d=1, so the solve itself returns the neck — no blend
    // to empty is needed, and there is no sliver left to flash away.
    // topShown >= topHold means NO lag: the top drains on the raw clock until
    // topHold, then empties over the remainder. That is the founder's intended
    // setting (0.800 / 0.995), not an accident — the readout says so explicitly
    // rather than the panel showing one number while the code uses another.
    const hold = S.topHold, shown = Math.min(S.topShown, hold);
    const dTop = d <= hold ? d*(shown/Math.max(hold,1e-4))
                           : lerp(shown, 1, smooth((d-hold)/Math.max(1-hold,1e-4)));
    const ySurf = solveHeight((1-dTop)*Vtot, yT, yN, ys=>volLevel(ys, yN, halfAt));
    const rS = Math.max(halfAt(ySurf), 1);
    const bulge = rS*k*S.topBulge;
    const body = new Path2D();
    body.moveTo(0, ySurf);
    body.lineTo(cx-rS, ySurf);
    // front rim seen from below, plus granular crookedness. Tapered at both ends
    // so the sand still meets the glass wall cleanly.
    const ampT = S.crookT*2*mx, NS = 44;
    for (let i=0;i<=NS;i++){
      const t=i/NS, xs=cx-rS+2*rS*t;
      const rim = -4*bulge*t*(1-t);
      const w = wob1(xs/(2*mx)*S.crookF, 3.1)*ampT*Math.sin(Math.PI*t);
      body.lineTo(xs, ySurf + rim + w);
    }
    body.lineTo(DW, ySurf);
    body.lineTo(DW, yN); body.lineTo(0, yN); body.closePath();
    fillSand(body, ySurf-bulge, yN, 0.0, 'T');
  }

  // ── BOTTOM BULB: the pile is solved, not shaped by hand. Find the apex height
  // whose cone-at-repose (clipped by the glass) holds exactly the fallen sand.
  // Below where that cone meets the wall the glass is simply full; the sand then
  // rides UP the back wall, which is the contact ellipse.
  const yApexS = solveHeight(d*Vtot, yN, yB, ya=>volBelow(ya, yB, rep, halfAt));
  // The height where the cone first meets the wall. This USED to be read straight
  // off a 96-rung ladder, so the answer could only ever be one of 97 positions —
  // and as the pile grew the bed jumped from rung to rung. That was the bottom
  // filling in visible steps. Bracket on the ladder, then BISECT for a continuous
  // answer; everything downstream (bed level, contact radius, the mound sitting on
  // it) inherits the smoothness.
  let yCs = yB, rCs = Math.max(halfAt(yB), 0.5);
  const wallGap = y => (y-yApexS)/rep - halfAt(y);
  let lo = yApexS, hi = null;
  for(let i=1;i<=96;i++){
    const y = yApexS + (yB-yApexS)*i/96;
    if (wallGap(y) >= 0){ hi = y; break; }
    lo = y;
  }
  if (hi !== null){
    for(let i=0;i<40;i++){ const m=(lo+hi)/2; if(wallGap(m)>=0) hi=m; else lo=m; }
    yCs = hi; rCs = Math.max(halfAt(yCs), 0.5);
  }
  // GATHERING. Solved purely by volume, the very first grains produce a
  // full-bulb-width triangle — the pile pops into existence at its final width and
  // only grows taller. Instead the sand SPREADS EVENLY first, then a pile starts as
  // a tiny mound and builds.
  //   coneAmt 0 -> a flat level holding all the sand, no cone at all
  //   coneAmt 1 -> the solved repose cone, i.e. the locked shape, untouched
  // Both ends are volume-correct: yFlat is solved for a flat fill exactly as yApexS
  // is solved for a cone, so nothing is faked at either extreme.
  const coneAmt = smooth(clamp((d - S.pileStart)/Math.max(S.pileRamp,1e-4), 0, 1));
  const yFlat = solveHeight(d*Vtot, yN, yB, ys=>volLevel(ys, yB, halfAt));
  // The bed's handover from flat-fill to solved-contact has its OWN, much longer
  // ramp than the mound's. Tying them together meant a fast mound forced a fast
  // handover, and a fast handover had to be clamped to stop the level dropping —
  // which froze the pile for a long stretch mid-drain. Spread over bedHand, the
  // rising fill always outruns the handover and the level simply never falls.
  const bedAmt = smooth(clamp(d/Math.max(S.bedHand,1e-4), 0, 1));
  const yC = lerp(yFlat, yCs, bedAmt);
  const rC = Math.max(halfAt(yC), 0.5);          // the BED's contact, always full width
  // The MOUND grows outward from the centre. Deriving the apex from a growing
  // RADIUS (rather than lerping the apex directly) means the repose angle is
  // preserved at every size — the mound is the same cone, just smaller. Lerping
  // the apex alone left a full-bulb-width disc that only got taller.
  const rCone = Math.max(rC*coneAmt, 0.001);
  const yApex = yC - rCone*rep;
  if (d>0){
    const body = new Path2D();
    body.moveTo(0, yC);
    body.lineTo(cx-rC, yC);
    body.ellipse(cx, yC, rC, rC*k, 0, Math.PI, 0, false);   // BACK (upper) half
    body.lineTo(DW, yC);
    body.lineTo(DW, yB); body.lineTo(0, yB); body.closePath();
    // The first sand to arrive came straight off the TOP pile, so it starts at the
    // top half's tone and only slowly becomes the bed's own. The two halves share
    // hue and saturation and differ only in lightness (check-pile asserts this), so
    // matching is a lift of slitT-slitB on the B half; bedEarly nudges from there.
    // Its own ramp, deliberately much longer than the mound's — the colour should
    // still be settling long after the pile has taken shape.
    const bedMix = smooth(clamp(d/Math.max(S.bedTint,1e-4), 0, 1));
    const earlyLift = (S.slitT - S.slitB) + S.bedEarly;
    fillSand(body, yC-rC*k, yB, lerp(earlyLift, BED.lift, bedMix), 'B');
    if (yC-yApex > 1.5 && rCone > 1.5){
      // Flanks at the repose angle, but ROUNDED at the apex — the falling stream
      // scatters grains off the tip, so it never stays sharp — and CROOKED along
      // their length, because a pile slumps in little avalanches and is only
      // straight on average. Each side has its own seed so they aren't mirror
      // twins, and both taper to 0 at base and apex so they still meet cleanly.
      const ax = rCone*S.apexR, ay = yApex + ax*rep;
      const ampB = S.crookB*2*mxB;
      const flankTo=(p,x0,y0,x1,y1,seed)=>{
        const N=18;
        for(let i=1;i<=N;i++){
          const t=i/N, xf=x0+(x1-x0)*t, yf=y0+(y1-y0)*t;
          p.lineTo(xf + wob1(yf/(2*mxB)*S.crookF, seed)*ampB*Math.sin(Math.PI*t), yf);
        }
      };
      const cone = new Path2D();
      cone.moveTo(cx-rCone, yC);
      cone.ellipse(cx, yC, rCone, rCone*k, 0, Math.PI, 0, true);  // FRONT (lower) half
      flankTo(cone, cx+rCone, yC, cx+ax, ay, 7.3);           // right flank, upward
      cone.quadraticCurveTo(cx, yApex, cx-ax, ay);
      flankTo(cone, cx-ax, ay, cx-rCone, yC, 19.1);          // left flank, downward
      cone.closePath();
      // SAME TREATMENT AS THE TOP PILE — one graded band, no light/shadow split.
      // A fixed terminator read as painted-on, and driving it from the sun/moon was
      // more machinery than the shot needs. Its colour comes from the per-phase
      // grade alone, so it shifts through the day exactly as the top pile does.
      // Three separate deltas, because they answer three different questions:
      //   coneLift    how far the raised cone sits above the flat bed behind it
      //   coneTopShd  shadow at the APEX — the tip is thin and takes less light
      //   coneBotShd  contact shadow where the pile meets the bed; without it the
      //               cone and the sand against the glass merge into one mass
      // The gradient must run to the BOTTOM OF THE PATH, not to yC. The cone's front
      // ellipse bulges rC*k below yC, and ending the gradient at yC left that whole
      // lobe clamped to the last colour stop — a hard dark band across the base.
      fillCone(cone, yApex, yC + rCone*k);
    }
  }

  // FALLING SAND — ported from the APP, lib/hourglass/hourglass_painter.dart.
  // A thin near-straight central column of matte grains that ACCELERATE under
  // gravity: slow and packed at the hole, fast and sparse at the pile. No glow, no
  // cone, no splash. A continuous column was tried here and cut — it reads as a
  // poured ribbon, not sand. Same constants as the app so the two products match.
  if (S._sandOn && d<0.999){
    const holeY=yN;
    // The pile's TRUE top is NOT yApex. The apex is rounded by a quadratic whose
    // CONTROL point is at yApex, and a quadratic never reaches its control — the
    // visible tip sits at (yApex+ay)/2, roughly 2 px lower. Culling grains at yApex
    // left exactly that gap between the stream and the pile.
    const axP=rCone*S.apexR, ayP=yApex+axP*rep;
    const coneDrawn = (yC-yApex > 1.5 && rCone > 1.5);
    const pileTop = coneDrawn ? (yApex+ayP)*0.5 : yC;
    const landY = Math.max(pileTop + S.streamLand, holeY+2);   // +overlap: no hairline
    const gap=landY-holeY;
    // The stream THINS as the top runs out — the throat is delivering less. It
    // never reaches zero before d=1, so sand is still falling right up to the end.
    const thin = lerp(1, S.streamThinTo,
                      smooth(clamp((d - S.streamThin)/Math.max(1-S.streamThin,1e-4), 0, 1)));
    const colHalf = Math.max(nh,1)*S.streamCol*thin;   // thin column ~ the hole width
    const v0 = S.streamV0;                         // small exit speed; rest is gravity
    // ONSET: at a focus start the stream head descends from the neck over one fall-period —
    // t is the session sand-clock (0 at onset), so grains below the head aren't emitted yet.
    const headFall = clamp(t / S.streamPer, 0, 1);
    // A grain LEAVES the top pile and JOINS the bottom one, so it carries the top
    // half's colour at the neck and arrives as the bottom half's. The two halves
    // are graded separately (top fully shadowed, bottom half lit), so a single
    // colour made the stream belong to neither. Precomputed as a 16-step LUT —
    // hslToRgb + gradeRGB per grain would be 220 conversions every frame.
    const NL=16, LUT=[];
    for(let i=0;i<NL;i++){
      const f=i/(NL-1);
      const [r_,g_,b_]=hslToRgb(lerp(S.shueT,S.shueB,f)/360,
                                lerp(S.ssatT,S.ssatB,f)/100,
                                clamp(lerp(S.slitT,S.slitB,f)+S.streamLit,0,1));
      const c=gradeRGB(r_,g_,b_,0.5);              // relit for the phase, mid tone
      LUT.push(`${c[0]|0},${c[1]|0},${c[2]|0}`);
    }
    const gcs=LUT[NL-1];                           // the scatter is already at the pile
    const rng=mulberry(7);                         // seeded -> stable per grain
    const nGrains = Math.max(6, Math.round(S.streamN*thin));
    for(let i=0;i<nGrains;i++){
      const lane=rng()*2-1, laneR=rng(), sizeR=rng();
      const speedR=0.8+0.4*rng(), offR=rng();      // varied speed, irregular spacing
      const ph=((t/(S.streamPer*speedR))+offR)%1;
      const fall=v0*ph+(1-v0)*ph*ph;               // gravity: phase squared
      if(fall>headFall) continue;                  // below the descending head -> not emitted yet (onset)
      const py=holeY+fall*gap; if(py>=landY) continue;   // landed -> not into the pile
      const px=cx + Math.abs(lane)*lane*colHalf + Math.sin(ph*6.28318+i)*0.5;
      // fine grains: a touch over 1px leaving the hole, tapering finer as they fall
      const r=clamp((1.05-0.4*fall)*(0.55+0.4*sizeR), 0.4, 1.1)*S.streamSize;
      const a=clamp((1.0-0.16*fall)*(0.82+0.18*laneR), 0, 1)*S.streamA;
      sctx.fillStyle=`rgba(${LUT[Math.min(NL-1,(fall*(NL-1))|0)]},${a})`;
      sctx.beginPath(); sctx.arc(px,py,r,0,7); sctx.fill();
    }
    // IMPACT SCATTER — grains the stream kicks off the pile apex. Each is a tiny
    // ballistic hop: launched at a low angle, gravity pulling it back to the slope
    // (g = 2·v·sinθ, so it lands exactly at p=1, giving v·sinθ·p·(1−p)). Count and
    // energy GROW with the pile, so a small pile barely stirs and a tall one sprays.
    const fill=clamp(d,0,1);
    const scatterN=Math.round((3+13*fill)*S.streamScat*headFall);   // no spray until the head reaches the pile
    if (scatterN>0){
      const hScale=mxB*(0.10+0.40*fill)*2.2, vScale=(yB-yN)*(0.010+0.055*fill)*2.2;
      const erng=mulberry(31);
      for(let i=0;i<scatterN;i++){
        const dir=(i%2===0)?-1:1;                  // alternate sides: balanced spray
        const ang=(20+65*erng())*Math.PI/180;
        const v=0.55+0.45*erng(), sizeR=erng();
        const per=0.30+0.35*erng(), offR=erng();
        const p=((t/per)+offR)%1;
        const yUp=v*Math.sin(ang)*p*(1-p);         // 0 at both ends, peak mid-flight
        const ex=cx+dir*(v*Math.cos(ang))*p*hScale;
        const ey=landY-yUp*vScale;
        if (ey>=landY) continue;                   // back on the slope -> gone
        const a=clamp((1-p)*0.8, 0, 1)*S.streamA;
        if (a<=0.02) continue;
        sctx.fillStyle=`rgba(${gcs},${a})`;
        sctx.beginPath(); sctx.arc(ex,ey,(0.25+0.35*sizeR)*S.streamSize,0,7); sctx.fill();
      }
    }
  }

  // ═══ LIGHT-INTEGRATE THE SAND ══════════════════════════════════════════════
  // 'source-atop' paints ONLY where pixels already exist — i.e. the sand, never
  // the empty middle. Turns a uniformly-warm blob into sand lit by THIS scene.
  if (S.scool > 0){
    sctx.globalCompositeOperation = 'source-atop';
    const cool = sctx.createLinearGradient(0, yT, 0, yB);      // cool sky bounce
    cool.addColorStop(0.00, `rgba(150,196,255,${0.34*S.scool})`);
    cool.addColorStop(0.55, 'rgba(150,196,255,0)');
    sctx.fillStyle = cool; sctx.fillRect(0,0,DW,DH);
    const warm = sctx.createLinearGradient(cx-mx, yB, cx+mx, yT); // warm key, lower-left
    warm.addColorStop(0.00, `rgba(255,196,128,${0.16*S.scool})`);
    warm.addColorStop(0.50, 'rgba(255,196,128,0)');
    sctx.fillStyle = warm; sctx.fillRect(0,0,DW,DH);
    sctx.globalCompositeOperation = 'source-over';
  }

  // ═══ GLASS FRONT OPTICS ════════════════════════════════════════════════════
  // Drawn OVER the sand, inside the glass clip, so the sand finally sits BEHIND
  // glass instead of on top of it. This is the layer the hybrid never had — the
  // real cause of 'pasted-on'. The streaks also span the neck, tying the two
  // sand masses into one vessel instead of two floating blobs.
  if (S.gshad > 0){                       // inner-edge shadow = the glass thickness
    sctx.save(); sctx.filter='blur(7px)';
    sctx.strokeStyle=`rgba(20,30,46,${0.55*S.gshad})`; sctx.lineWidth=13;
    sctx.stroke(G.p); sctx.restore();
  }
  // ANIME highlights: crisp filled SLIVERS, not soft photoreal blooms. Cel art
  // draws a couple of hard-edged lens shapes — that hard edge is the whole look,
  // so Softness defaults to 0. Raise it only if you want it realistic again.
  if (S.gspec > 0){
    const sliver=(x,y0,y1,w,curve)=>{           // a tapered lens, pointed at both ends
      const ym=(y0+y1)/2, p=new Path2D();
      p.moveTo(x,y0);
      p.quadraticCurveTo(x-curve,     ym, x, y1);
      p.quadraticCurveTo(x-curve+w,   ym, x, y0);
      p.closePath(); return p;
    };
    const tbh=yN-yT, bbh=yB-yN;
    sctx.save();
    if (S.hlSoft>0) sctx.filter=`blur(${S.hlSoft}px)`;
    // main sliver, top bulb
    sctx.fillStyle=`rgba(255,255,255,${0.85*S.gspec})`;
    sctx.fill(sliver(cx-mx*S.hlX, yT+tbh*S.hlTop, yT+tbh*S.hlBot, mx*S.hlW, mx*S.hlCurve));
    // thin companion sliver — the classic second glass catch
    sctx.fillStyle=`rgba(255,255,255,${0.45*S.gspec})`;
    sctx.fill(sliver(cx-mx*(S.hlX-0.26), yT+tbh*(S.hlTop+0.07), yT+tbh*(S.hlBot-0.16),
                     mx*S.hlW*0.42, mx*S.hlCurve*0.55));
    // bottom bulb
    sctx.fillStyle=`rgba(255,255,255,${0.7*S.gspec})`;
    sctx.fill(sliver(cx-mxB*S.hlX, yN+bbh*S.hlTop, yN+bbh*S.hlBot, mxB*S.hlW, mxB*S.hlCurve));
    sctx.restore();
  }
  if (S.grim > 0){                        // cool rim catch — scaled up in dark phases
    const rimA = clamp(0.55*S.grim*CUR.rim, 0, 1);
    // NO rim light where the glass meets the wooden cap and base. Those edges are
    // buried in the stand — nothing can catch light there, and a bright line across
    // them read as the glass floating in front of the wood rather than seated in it.
    // A gradient stroke rather than a clip, so it FADES out instead of stopping dead.
    const yA = G.yT, yZ = G.yB, span = Math.max(yZ-yA, 1);
    const t0 = clamp(S.rimCapT, 0, 0.45);
    const t1 = clamp(1 - S.rimCapB, t0 + 0.02, 1);
    const gr = sctx.createLinearGradient(0, yA, 0, yZ);
    const rc = a => `rgba(208,234,255,${a})`;
    gr.addColorStop(0, rc(0)); gr.addColorStop(t0, rc(rimA));
    gr.addColorStop(t1, rc(rimA)); gr.addColorStop(1, rc(0));
    sctx.save(); sctx.filter='blur(1.4px)';
    sctx.strokeStyle=gr; sctx.lineWidth=2.4;
    sctx.stroke(G.p); sctx.restore();
  }

  sctx.restore();

  // The glass WALL itself — drawn outside the clip so the full stroke shows, not
  // just its inner half. This is what makes a bare hourglass read as glass.
  if (S.glassOn && S.gEdge > 0){
    sctx.save();
    sctx.strokeStyle=`rgba(232,248,255,${0.95*S.gEdge})`;
    sctx.lineWidth=S.gEdgeW; sctx.lineJoin='round';
    sctx.stroke(G.p);
    sctx.restore();
  }
  drawSeaOverlay(); drawCelOverlay(); drawHorOverlay();
}

// The HORIZON line — sun/moon are fully clipped below it (disc AND glow), so
// nothing ever glows "underwater". Drag it to sit exactly on the sea horizon.
function drawHorOverlay(){
  if(!S.horEdit) return;
  const y=(1-S.hor)*DH;
  sctx.save();
  sctx.strokeStyle='rgba(120,255,180,0.95)'; sctx.lineWidth=2; sctx.setLineDash([10,6]);
  sctx.beginPath(); sctx.moveTo(0,y); sctx.lineTo(DW,y); sctx.stroke();
  sctx.setLineDash([]);
  sctx.fillStyle='rgba(120,255,180,0.95)'; sctx.font='11px ui-monospace,monospace';
  sctx.fillText('horizon — drag onto the sea line; sun/moon vanish below it', 12, y-8);
  sctx.restore();
}

// The sun/moon handle, shown only while placing it.
function drawCelOverlay(){
  if(!S.celEdit) return;
  const dom=CUR.blend<0.5?CUR.a:CUR.b, p=SUN_POS[dom], x=p[0]*DW, y=p[1]*DH;
  const rad=(SUN_TYPE[dom]>0.5?S.sunSize:S.moonR);  // handle matches the body it places
  sctx.save();
  sctx.strokeStyle='rgba(255,220,120,0.95)'; sctx.lineWidth=2;
  sctx.beginPath(); sctx.arc(x,y,Math.max(rad*DW,10),0,7); sctx.stroke();
  sctx.fillStyle='#ffdc78'; sctx.beginPath(); sctx.arc(x,y,4,0,7); sctx.fill();
  sctx.font='11px ui-monospace,monospace'; sctx.fillStyle='rgba(255,220,120,0.95)';
  sctx.fillText(`${PHASE_NAMES[dom]} · ${SUN_TYPE[dom]?'sun':'moon'}`, x+12, y-10);
  sctx.restore();
}
function dumpCel(){
  const el=$('celOut'); if(!el) return; const r=v=>+v.toFixed(3);
  el.value=JSON.stringify({pos:SUN_POS.map(p=>[r(p[0]),r(p[1])]), type:SUN_TYPE, int:SUN_INT.map(r)});
}

// The sea region, shown only while editing it.
function drawSeaOverlay(){
  if (!S.seaEdit) return;
  const p = seaPath();
  sctx.save();
  sctx.fillStyle='rgba(80,220,255,0.12)'; sctx.fill(p);
  sctx.strokeStyle='rgba(80,220,255,0.95)'; sctx.lineWidth=2; sctx.stroke(p);
  // square = sharp corner (straight run) · circle = smooth curve
  for (const q of SEA){
    const x=q[0]*DW, y=q[1]*DH;
    sctx.fillStyle='#fff'; sctx.strokeStyle=q[2]?'#ffb020':'#18b6e0'; sctx.lineWidth=1.8;
    sctx.beginPath();
    if(q[2]) sctx.rect(x-4.5,y-4.5,9,9); else sctx.arc(x,y,4.5,0,7);
    sctx.fill(); sctx.stroke();
  }
  sctx.restore();
}
function mulberry(s){return function(){s|=0;s=s+0x6D2B79F5|0;let t=Math.imul(s^s>>>15,1|s);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}

// ── wiring ──────────────────────────────────────────────────────────────────
const bind=(id,out,key,fmt=v=>v.toFixed(3),fn=()=>{})=>{const el=$(id);
  const run=()=>{S[key]=parseFloat(el.value);$(out).textContent=fmt(S[key]);fn();};
  el.addEventListener('input',run);run();};
// Declared BEFORE the first bind() that uses them. const is not hoisted, so a
// bind() above this line referencing F2 throws 'Cannot access F2 before
// initialization' at load and the whole module dies. (MDN: temporal dead zone.)
const F3=v=>v.toFixed(3), F2=v=>v.toFixed(2);
bind('prog','vProg','prog',v=>v.toFixed(2));
bind('coneLift','vConeLift','coneLift',v=>v.toFixed(3));
bind('coneTopShd','vConeTopShd','coneTopShd',v=>v.toFixed(3));
bind('coneBotShd','vConeBotShd','coneBotShd',v=>v.toFixed(3));
bind('bedNight','vBedNight','bedNight',v=>v.toFixed(3));
bind('bedDay','vBedDay','bedDay',v=>v.toFixed(3));
bind('rimCapT','vRimCapT','rimCapT',F2);
bind('rimCapB','vRimCapB','rimCapB',F2);
const STREAM_FIELDS=['streamN','streamCol','streamPer','streamV0','streamSize',
                     'streamA','streamLit','streamScat','streamLand'];
const dumpStream=()=>{ const t=$('streamOut');
  if(t) t.value = STREAM_FIELDS.map(f=>`${f}=${S[f]}`).join(' '); };
bind('streamN','vStreamN','streamN',v=>String(v|0),dumpStream);
bind('streamCol','vStreamCol','streamCol',F2,dumpStream);
bind('streamPer','vStreamPer','streamPer',F2,dumpStream);
bind('streamV0','vStreamV0','streamV0',F2,dumpStream);
bind('streamSize','vStreamSize','streamSize',F2,dumpStream);
bind('streamA','vStreamA','streamA',F2,dumpStream);
bind('streamLit','vStreamLit','streamLit',F3,dumpStream);
bind('streamScat','vStreamScat','streamScat',F2,dumpStream);
bind('streamLand','vStreamLand','streamLand',v=>v.toFixed(1),dumpStream);
bind('pileStart','vPileStart','pileStart',F2);
bind('pileRamp','vPileRamp','pileRamp',F2);
bind('bedEarly','vBedEarly','bedEarly',F3);
bind('bedTint','vBedTint','bedTint',F2);
bind('bedHand','vBedHand','bedHand',F2);
bind('topHold','vTopHold','topHold',v=>v.toFixed(3));
bind('topShown','vTopShown','topShown',
     v=>v>=S.topHold ? v.toFixed(3)+' (no lag)' : v.toFixed(3));
bind('streamThin','vStreamThin','streamThin',F2);
bind('streamThinTo','vStreamThinTo','streamThinTo',F2);
// Outline sliders only SEED the node list — once the founder drags, they stop.
const reCurve = ()=>{ if(!custom) rebuildNodes(); markGlassDirty(); };
bind('cx','vCx','cx',v=>v.toFixed(6),reCurve); bind('top','vTop','top',F3,reCurve); bind('neck','vNeck','neck',F3,reCurve);
bind('bot','vBot','bot',F3,reCurve); bind('max','vMax','max',F3,reCurve); bind('nh','vNh','nh',F3,reCurve);
bind('rimK','vRimK','rimK',F2,reCurve); bind('wTop','vWTop','wTop',F3,reCurve); bind('aTop','vATop','aTop',F3,reCurve);
bind('bTop','vBTop','bTop',F3,reCurve); bind('cTop','vCTop','cTop',F3,reCurve);
bind('mxBot','vMxBot','mxBot',F3,reCurve); bind('wBot','vWBot','wBot',F3,reCurve); bind('aBot','vABot','aBot',F3,reCurve);
bind('bBot','vBBot','bBot',F3,reCurve); bind('cBot','vCBot','cBot',F3,reCurve); bind('baseK','vBaseK','baseK',F2,reCurve);
bind('topW','vTopW','topW',F3,reCurve); bind('botW','vBotW','botW',F3,reCurve);
bind('flat','vFlat','flat',v=>v.toFixed(2));
bind('persp','vPersp','persp',v=>v.toFixed(3)); bind('repose','vRepose','repose',v=>v.toFixed(3));
bind('sandVol','vSandVol','sandVol',v=>v.toFixed(2));
bind('apexR','vApexR','apexR',v=>v.toFixed(2)); bind('topBulge','vTopBulge','topBulge',v=>v.toFixed(2));
bind('crookT','vCrookT','crookT',v=>v.toFixed(4)); bind('crookB','vCrookB','crookB',v=>v.toFixed(3));
bind('crookF','vCrookF','crookF',v=>String(v|0));
bind('scool','vScool','scool',v=>v.toFixed(2)); bind('gspec','vGspec','gspec',v=>v.toFixed(2));
bind('grim','vGrim','grim',v=>v.toFixed(2)); bind('gshad','vGshad','gshad',v=>v.toFixed(2));
bind('dbg','vDbg','dbg',v=>String(v|0),()=>{
  // only grab the mouse while actually editing something
  sandCv.style.pointerEvents = (S.dbg||S.seaEdit||S.celEdit||S.horEdit) ? "auto" : "none";
});

// ── drag the outline like a pen tool ────────────────────────────────────────
const evPos = e => { const r=sandCv.getBoundingClientRect(); return [e.clientX-r.left, e.clientY-r.top]; };
const goCustom=()=>{ if(!custom){ custom=true;
  $('curveState').textContent='CUSTOM (dragged) — sliders off, R resets'; } };

sandCv.addEventListener('pointerdown', e=>{
  const [ex,ey]=evPos(e);
  if(S.horEdit){                          // drag the horizon line
    drag={hor:true}; sandCv.setPointerCapture(e.pointerId); e.preventDefault(); return;
  }
  if(S.celEdit){                          // drag the sun/moon (the phase you're viewing)
    drag={cel: CUR.blend<0.5?CUR.a:CUR.b};
    sandCv.setPointerCapture(e.pointerId); e.preventDefault(); return;
  }
  if(S.seaEdit){                          // sea editing wins over glass editing
    let bi=-1, bd=14;
    SEA.forEach((q,i)=>{ const dd=Math.hypot(q[0]*DW-ex, q[1]*DH-ey);
                         if(dd<bd){ bd=dd; bi=i; } });
    if(bi>=0){ drag={sea:bi}; sandCv.setPointerCapture(e.pointerId); e.preventDefault(); }
    return;
  }
  if(!S.dbg) return;
  const [px,py]=[ex,ey]; const hit=pickNode(px,py);
  // Missing every point means "grab the whole hourglass" and slide it around.
  drag = hit || { move:true, last:[px,py] };
  sandCv.setPointerCapture(e.pointerId); e.preventDefault();
});
sandCv.addEventListener('pointermove', e=>{
  if(!drag) return;
  const [px,py]=evPos(e);
  if(drag.hor){                           // set the horizon line
    S.hor=clamp(1-py/DH, 0.20, 0.80); U.uHor.value=S.hor;
    $('hor').value=S.hor; $('vHor').textContent=S.hor.toFixed(2);
    $('vHorVal').textContent=S.hor.toFixed(4);
    return;
  }
  if(drag.cel!==undefined){               // move the sun/moon, clamped to the sky
    SUN_POS[drag.cel]=[clamp(px/DW,0.02,0.98), clamp(py/DH,0.02,0.55)];
    dumpCel(); return;
  }
  if(drag.sea!==undefined){               // reshaping the sea region
    SEA[drag.sea]=[px/DW, py/DH];
    markMaskDirty();
    return;
  }
  if(drag.move){                         // translate the entire outline
    const dx=(px-drag.last[0])/DW, dy=(py-drag.last[1])/DH;
    S.cx += dx;                          // carry the mirror axis, or symmetry breaks
    $('cx').value=S.cx; $('vCx').textContent=S.cx.toFixed(3);
    for(const n of NODES){
      n.a=[n.a[0]+dx, n.a[1]+dy];
      if(n.hi) n.hi=[n.hi[0]+dx, n.hi[1]+dy];
      if(n.ho) n.ho=[n.ho[0]+dx, n.ho[1]+dy];
    }
    drag.last=[px,py];
  } else {
    const n=NODES[drag.i];
    const nx = drag.mirror ? (2*S.cx - px/DW) : px/DW, ny = py/DH;
    if(drag.key==='a'){                  // moving an anchor carries its arms along
      const dx=nx-n.a[0], dy=ny-n.a[1];
      n.a=[nx,ny];
      if(n.hi) n.hi=[n.hi[0]+dx, n.hi[1]+dy];
      if(n.ho) n.ho=[n.ho[0]+dx, n.ho[1]+dy];
    } else n[drag.key]=[nx,ny];
  }
  goCustom(); dumpNodes(); markGlassDirty();   // outline moved → refraction is stale
});
addEventListener('pointerup', ()=>{ drag=null; });

// Sea editing: double-click a marker to flip it straight/curved, double-click the
// water to insert a marker, right-click one to remove it.
const seaPick=(ex,ey)=>{
  let bi=-1, bd=14;
  SEA.forEach((q,i)=>{ const d=Math.hypot(q[0]*DW-ex, q[1]*DH-ey); if(d<bd){bd=d;bi=i;} });
  return bi;
};
sandCv.addEventListener('dblclick', e=>{
  if(!S.seaEdit) return;
  e.preventDefault();
  const [ex,ey]=evPos(e), i=seaPick(ex,ey);
  if(i>=0){ SEA[i][2] = SEA[i][2]?0:1; }        // straight <-> curved
  else {                                         // insert into the nearest edge
    let bi=0, bd=Infinity;
    for(let k=0;k<SEA.length;k++){
      const a=SEA[k], b=SEA[(k+1)%SEA.length];
      const ax=a[0]*DW, ay=a[1]*DH, bx=b[0]*DW, by=b[1]*DH;
      const vx=bx-ax, vy=by-ay, L=vx*vx+vy*vy || 1;
      const t=Math.max(0,Math.min(1,((ex-ax)*vx+(ey-ay)*vy)/L));
      const d=Math.hypot(ax+vx*t-ex, ay+vy*t-ey);
      if(d<bd){ bd=d; bi=k; }
    }
    SEA.splice(bi+1, 0, [ex/DW, ey/DH, 0]);
  }
  markMaskDirty();
});
sandCv.addEventListener('contextmenu', e=>{
  if(!S.seaEdit) return;
  e.preventDefault();
  const [ex,ey]=evPos(e), i=seaPick(ex,ey);
  if(i>=0 && SEA.length>4){ SEA.splice(i,1); markMaskDirty(); }
});
// Everything settled (glass shape, curves, scene) is hidden but NOT removed —
// still live, still tunable, just out of the way while the sand is the question.
const lockGrps=[...document.querySelectorAll('.lockgrp')];
function setLocked(hide){
  lockGrps.forEach(g=>g.classList.toggle('hid',hide));
  $('lockToggle').textContent = hide ? '▸ Locked — DAY plate (all params)'
                                     : '▾ Locked params — click to hide';
}
const lockedNow = ()=> lockGrps[0].classList.contains('hid');
$('lockToggle').addEventListener('click', ()=>setLocked(!lockedNow()));
setLocked(true);

$('copyNodes').addEventListener('click', ()=>{
  $('nodeOut').select();
  if(navigator.clipboard) navigator.clipboard.writeText($('nodeOut').value);
});
$('copySea').addEventListener('click', ()=>{
  $('seaOut').select();
  if(navigator.clipboard) navigator.clipboard.writeText($('seaOut').value);
});
bind('shueT','vShueT','shueT',v=>String(v|0)); bind('ssatT','vSsatT','ssatT',v=>String(v|0));
bind('slitT','vSlitT','slitT',v=>v.toFixed(2)); bind('litT','vLitT','litT',v=>v.toFixed(3));
bind('shdT','vShdT','shdT',v=>v.toFixed(3));
bind('shueB','vShueB','shueB',v=>String(v|0)); bind('ssatB','vSsatB','ssatB',v=>String(v|0));
bind('slitB','vSlitB','slitB',v=>v.toFixed(2)); bind('litB','vLitB','litB',v=>v.toFixed(3));
bind('shdB','vShdB','shdB',v=>v.toFixed(3));
bind('grain','vGrain','grain',v=>v.toFixed(2));
bind('grainScale','vGrainScale','grainScale',v=>v.toFixed(3),()=>{ grainBuiltAt=0; });
// ── per-phase sand-light widgets (custom: they edit the PH_* tables, not S) ──
function loadPhaseGrade(){
  const p=S.phase|0;
  $('texpo').value=PH_EXPO[p]; $('vTexpo').textContent=PH_EXPO[p].toFixed(2);
  $('tsat').value =PH_SAT[p];  $('vTsat').textContent =PH_SAT[p].toFixed(2);
  $('tlit').value =rgbToHex(PH_LIT[p]); $('tshd').value=rgbToHex(PH_SHD[p]);
  $('phTag').textContent=PHASE_NAMES[p];
}
function dumpPhaseGrades(){
  $('phOut').value=JSON.stringify(PHASE_NAMES.map((n,i)=>
    ({phase:n, expo:+PH_EXPO[i].toFixed(2), lit:rgbToHex(PH_LIT[i]),
      shd:rgbToHex(PH_SHD[i]), sat:+PH_SAT[i].toFixed(2)})));
}
$('texpo').addEventListener('input',()=>{ PH_EXPO[S.phase|0]=parseFloat($('texpo').value);
  $('vTexpo').textContent=PH_EXPO[S.phase|0].toFixed(2); dumpPhaseGrades(); });
$('tsat').addEventListener('input',()=>{ PH_SAT[S.phase|0]=parseFloat($('tsat').value);
  $('vTsat').textContent=PH_SAT[S.phase|0].toFixed(2); dumpPhaseGrades(); });
$('tlit').addEventListener('input',()=>{ PH_LIT[S.phase|0]=hexToRgb($('tlit').value); dumpPhaseGrades(); });
$('tshd').addEventListener('input',()=>{ PH_SHD[S.phase|0]=hexToRgb($('tshd').value); dumpPhaseGrades(); });
$('phCopy').addEventListener('click',()=>{ $('phOut').select();
  if(navigator.clipboard) navigator.clipboard.writeText($('phOut').value); });

// "Edit phase" jumps the day-time to that phase's peak (live off) so you SEE the
// phase you're tuning; the render itself is always driven by the day clock.
bind('phase','vPhase','phase',v=>PHASE_NAMES[v|0],()=>{
  S.daytime=PH_HOUR[S.phase|0]; S.live=0;
  $('daytime').value=S.daytime; $('vDaytime').textContent=fmtHM(S.daytime);
  $('live').value=0; $('vLive').textContent='0';
  loadPhaseGrade();
});
bind('live','vLive','live',v=>String(v|0));
bind('daytime','vDaytime','daytime',v=>fmtHM(v));
bind('celEdit','vCelEdit','celEdit',v=>String(v|0),()=>{
  sandCv.style.pointerEvents=(S.dbg||S.seaEdit||S.celEdit||S.horEdit)?'auto':'none';
});
bind('horEdit','vHorEdit','horEdit',v=>String(v|0),()=>{
  sandCv.style.pointerEvents=(S.dbg||S.seaEdit||S.celEdit||S.horEdit)?'auto':'none';
});
// MOON — every parameter, same contract as the sun.
const MOON_FIELDS = ['moonR','moonK','moonSoft','moonTexAmt',
                     'moonWarm','moonHaze','moonWarmH',
                     'moonGlowW','moonGlowA','moonFarW','moonFarA'];
const MOON_COLS   = ['moonCol','moonWarmCol','moonGlowCol','moonFarCol'];
function dumpMoon(){
  const t=$('moonOut'); if(!t) return;
  t.value = MOON_FIELDS.map(f=>`${f}=${S[f]}`).join(' ') + '\n'
          + MOON_COLS.map(f=>`${f}=${S[f]}`).join(' ');
}
const pushMoon=()=>{
  for(const f of MOON_FIELDS) U['u'+f[0].toUpperCase()+f.slice(1)].value = S[f];
  for(const f of MOON_COLS){ const c=hex2rgb(S[f]);
    U['u'+f[0].toUpperCase()+f.slice(1)].value.set(c[0],c[1],c[2]); }
  dumpMoon();
};
bind('moonR','vMoonR','moonR',v=>v.toFixed(3),pushMoon);
bind('moonK','vMoonK','moonK',F2,pushMoon);
bind('moonSoft','vMoonSoft','moonSoft',F2,pushMoon);
bind('moonTexAmt','vMoonTexAmt','moonTexAmt',F2,pushMoon);
bind('moonWarm','vMoonWarm','moonWarm',F2,pushMoon);
bind('moonHaze','vMoonHaze','moonHaze',F2,pushMoon);
bind('moonWarmH','vMoonWarmH','moonWarmH',F2,pushMoon);
bind('moonGlowW','vMoonGlowW','moonGlowW',F2,pushMoon);
bind('moonGlowA','vMoonGlowA','moonGlowA',F2,pushMoon);
bind('moonFarW','vMoonFarW','moonFarW',v=>v.toFixed(3),pushMoon);
bind('moonFarA','vMoonFarA','moonFarA',F2,pushMoon);
const bindMoonCol=(id,key)=>{const el=$(id);
  const run=()=>{S[key]=el.value;pushMoon();};
  el.addEventListener('input',run);run();};
bindMoonCol('moonCol','moonCol'); bindMoonCol('moonWarmCol','moonWarmCol');       bindMoonCol('moonGlowCol','moonGlowCol'); bindMoonCol('moonFarCol','moonFarCol');
// SUN KEYS — every slider writes through to the key currently being viewed.
bind('sunKey','vSunKey','sunKey',v=>SUNKEY[v|0].name,()=>loadSunKey());
bind('sunSize','vSunSize','sunSize',v=>v.toFixed(3),storeSunKey);
bind('coreW','vCoreW','coreW',F2,storeSunKey);
bind('coreA','vCoreA','coreA',F2,storeSunKey);
bind('nearW','vNearW','nearW',F2,storeSunKey);
bind('nearA','vNearA','nearA',F2,storeSunKey);
bind('farW','vFarW','farW',v=>v.toFixed(3),storeSunKey);
bind('farA','vFarA','farA',F2,storeSunKey);
// colour pickers write the same way (hex, so they need their own tiny binder)
const bindCol=(id,key)=>{const el=$(id);
  const run=()=>{S[key]=el.value;storeSunKey();};
  el.addEventListener('input',run);run();};
bindCol('coreCol','coreCol'); bindCol('nearCol','nearCol'); bindCol('farCol','farCol');
loadSunKey();
// haze feeds celTrack, not a uniform directly — recompute the day cycle to push it
$('celCopy').addEventListener('click',()=>{ $('celOut').select();
  if(navigator.clipboard) navigator.clipboard.writeText($('celOut').value); });
loadPhaseGrade(); dumpPhaseGrades(); dumpCel();
$('vHorVal').textContent=S.hor.toFixed(4);
bind('glassOn','vGlassOn','glassOn',v=>String(v|0));
bind('refr','vRefr','refr',v=>v.toFixed(2),markGlassDirty);
bind('fres','vFres','fres',v=>v.toFixed(2),markGlassDirty);
bind('gtex','vGtex','gtex',v=>v.toFixed(2),markGlassDirty);
bind('gtint','vGtint','gtint',v=>v.toFixed(2),markGlassDirty); bind('gEdge','vGEdge','gEdge',v=>v.toFixed(2));
bind('gEdgeW','vGEdgeW','gEdgeW',v=>v.toFixed(1));
bind('hlSoft','vHlSoft','hlSoft',v=>v.toFixed(1)); bind('hlX','vHlX','hlX',v=>v.toFixed(2));
bind('hlW','vHlW','hlW',v=>v.toFixed(2)); bind('hlCurve','vHlCurve','hlCurve',v=>v.toFixed(2));
bind('hlTop','vHlTop','hlTop',v=>v.toFixed(2)); bind('hlBot','vHlBot','hlBot',v=>v.toFixed(2));
bind('gl','vGl','gl',v=>v.toFixed(2),()=>U.uGl.value=S.gl);
bind('gd','vGd','gd',v=>v.toFixed(2),()=>U.uGd.value=S.gd);
bind('gs','vGs','gs',v=>v.toFixed(2),()=>U.uGs.value=S.gs);
bind('gdrift','vGdrift','gdrift',v=>v.toFixed(3),()=>U.uGdrift.value=S.gdrift);
bind('hor','vHor','hor',v=>v.toFixed(2),()=>U.uHor.value=S.hor);
bind('sill','vSill','sill',v=>v.toFixed(2),()=>U.uSill.value=S.sill);
bind('persp2','vPersp2','persp2',v=>v.toFixed(2),()=>U.uPersp.value=S.persp2);
bind('pathX','vPathX','pathX',v=>v.toFixed(3),()=>U.uPathX.value=S.pathX);
bind('pathW','vPathW','pathW',v=>v.toFixed(2),()=>U.uPathW.value=S.pathW);
bind('glen','vGlen','glen',v=>v.toFixed(2),()=>U.uGlen.value=S.glen);
bind('gthk','vGthk','gthk',v=>v.toFixed(3),()=>U.uGthk.value=S.gthk);
bind('seaEdit','vSeaEdit','seaEdit',v=>String(v|0),()=>{
  sandCv.style.pointerEvents = (S.dbg||S.seaEdit||S.celEdit||S.horEdit) ? "auto" : "none";
});
bind('seaFeather','vSeaFeather','seaFeather',v=>String(v|0),markMaskDirty);
addEventListener('keydown',e=>{
  if(e.key==='h'||e.key==='H') $('ui').classList.toggle('hidden');
  if(e.key==='l'||e.key==='L') setLocked(!lockedNow());
  if(e.key==='r'&&!e.shiftKey){          // back to the locked 100% outline
    NODES=cloneNodes(LOCKED_NODES); custom=true;
    $('curveState').textContent='LOCKED — 100% outline'; dumpNodes(); markGlassDirty();
  }
  if(e.key==='R'&&e.shiftKey){           // abandon it and go back to slider-driven
    custom=false; rebuildNodes(); $('curveState').textContent='slider-driven';
    dumpNodes(); markGlassDirty();
  }
});
addEventListener('resize',fit);

// ── Session setup UI ────────────────────────────────────────────────────────
const cfg = { workMin:25, breakMin:5, longBreakMin:15, rounds:4 };
const sUI = $('session-ui');
function syncDurFields(mode){
  // Flow/Endless: focus only. Pomodoro/Custom: focus + break + rounds.
  const many = (mode === 'pomodoro' || mode === 'custom');
  $('bWrap').style.display = many ? '' : 'none';
  $('rWrap').style.display = many ? '' : 'none';
  $('wWrap').firstChild.textContent = mode === 'endless' ? 'Block ' : 'Focus ';
}
let curMode = 'flow';
sUI.querySelectorAll('.mode').forEach(btn => btn.addEventListener('click', () => {
  sUI.querySelectorAll('.mode').forEach(b => b.classList.remove('on'));
  btn.classList.add('on');
  curMode = btn.dataset.mode;
  syncDurFields(curMode);
}));
$('workMin').addEventListener('input', e => { cfg.workMin = +e.target.value || 1; });
$('breakMin').addEventListener('input', e => { cfg.breakMin = +e.target.value || 1; });
$('rounds').addEventListener('input', e => { cfg.rounds = +e.target.value || 1; });

function startSession(){
  session.configure(curMode, cfg);
  session.start();
  sUI.classList.add('running');
  $('beginBtn').hidden = true; $('pauseBtn').hidden = false; $('resetBtn').hidden = false;
  $('pauseBtn').textContent = 'Pause';
}
function togglePause(){
  if (session.state.running) { session.pause(); $('pauseBtn').textContent = 'Resume'; }
  else { session.resume(); $('pauseBtn').textContent = 'Pause'; }
}
function resetSession(){
  const r = session.sample();
  if (r.kind !== 'idle' && !r.done) bumpFocusedToday(r.focusSec);   // credit focus done so far
  session.reset(); S.prog = 0; wasDone = false;
  sUI.classList.remove('running');
  $('beginBtn').hidden = false; $('beginBtn').textContent = 'Begin';
  $('pauseBtn').hidden = true; $('resetBtn').hidden = true;
}
$('beginBtn').addEventListener('click', startSession);
$('pauseBtn').addEventListener('click', togglePause);
$('resetBtn').addEventListener('click', resetSession);
syncDurFields('flow');
S.prog = 0;   // idle = full glass, ready to begin

// ── The [min] · hourglass · [secs] readout (hidden, fades in on move) ────────
let timerVis = 'hover', hideTimer = 0;
const pad = n => String(Math.max(0, n | 0)).padStart(2, '0');
function updateSessionUI(r){
  const secs = r.remainingSec | 0;   // ALL modes count down (endless now loops a chosen block, not a stopwatch)
  $('mm').textContent = pad(secs / 60 | 0);
  $('ss').textContent = pad(secs % 60);
  if (r.done) revealNums();   // always show the final 00 · drained glass
  onSampleExtras(r);
}
function revealNums(){
  frame.classList.add('show-nums');
  if (timerVis === 'hover') {
    clearTimeout(hideTimer);
    hideTimer = setTimeout(() => frame.classList.remove('show-nums'), 1600);
  }
}
// A touch device has no mousemove, so 'hover' visibility meant the numerals NEVER appeared on a phone (and
// 'hover' is the default). Treat it as 'always' wherever hovering is not a thing.
const noHover = () => matchMedia('(hover: none)').matches;
// Portrait/narrow: only the TOP placement is offered (founder). The other placements put the numerals over
// or beside the glass, which a phone has no room for.
const narrowVP = () => matchMedia('(max-width: 900px), (orientation: portrait)').matches;
// 'flash' = the Setup option labelled "5 min", whose own description promises "surfaces briefly every 5
// minutes, then fades away". It used to be mapped straight to 'always' (a v1 shortcut), so the option did
// nothing. Interval is anchored to applyVis, i.e. to the session start, not to page load.
const FLASH_EVERY = 300000, FLASH_HOLD = 4200;
let flashTimer = 0;
function flashNums(){
  clearTimeout(hideTimer);
  frame.classList.add('show-nums');
  hideTimer = setTimeout(() => frame.classList.remove('show-nums'), FLASH_HOLD);
}
function applyVis(){
  clearInterval(flashTimer); flashTimer = 0;
  if (timerVis === 'always' || (timerVis === 'hover' && noHover())) { clearTimeout(hideTimer); frame.classList.add('show-nums'); }
  else if (timerVis === 'flash') {
    flashNums();                                   // show at the start, then fade...
    flashTimer = setInterval(() => { if (session.state.running) flashNums(); }, FLASH_EVERY);   // ...and every 5 min
  }
  else frame.classList.remove('show-nums');
}
window.addEventListener('mousemove', () => { if (timerVis === 'hover') revealNums(); });
sUI.querySelectorAll('.visbtn').forEach(btn => btn.addEventListener('click', () => {
  sUI.querySelectorAll('.visbtn').forEach(b => b.classList.remove('on'));
  btn.classList.add('on'); timerVis = btn.dataset.vis; applyVis();
}));

// ── "Focused today" (localStorage, resets on date change) + completion + refill ─
function focusedTodayKey(){ return 'sustain.focusedToday.' + new Date().toDateString(); }
function bumpFocusedToday(sec){
  const k = focusedTodayKey();
  localStorage.setItem(k, (+localStorage.getItem(k) || 0) + Math.round(sec));
  renderFocusedToday();
}
function renderFocusedToday(){
  const v = +localStorage.getItem(focusedTodayKey()) || 0;
  $('focused-today').textContent = v >= 60 ? `Focused today · ${Math.round(v/60)} min` : '';
}
renderFocusedToday();

let wasDone = false, lastProg = 0;
function onSampleExtras(r){
  // Endless refill: prog just wrapped high→low → a brief fade so it reads as a flip.
  if (r.endless && r.prog < lastProg - 0.5) {
    sandCv.classList.add('refill');
    setTimeout(() => sandCv.classList.remove('refill'), 420);
  }
  lastProg = r.prog;
  // Completion fires once, on the done edge — credit FOCUS time (never breaks).
  if (r.done && !wasDone) {
    wasDone = true;
    bumpFocusedToday(r.focusSec);
    sUI.classList.remove('running');
    $('pauseBtn').hidden = true; $('resetBtn').hidden = true;
    $('beginBtn').hidden = false; $('beginBtn').textContent = 'Begin again';
  }
  if (!r.done) wasDone = false;
}

// ── temp: hide the basic controls, reveal on mouse move / tap, so the sand is unobstructed.
//    (throwaway with the basic #session-ui; the real Setup/Session UI supersedes it.)
let _uiHideT = 0;
function _revealUI(){ document.body.classList.add('show-ui'); clearTimeout(_uiHideT);
  _uiHideT = setTimeout(() => document.body.classList.remove('show-ui'), 2500); }
addEventListener('mousemove', _revealUI); addEventListener('pointerdown', _revealUI);

fit();
dumpNodes(); dumpSea();
let t0=performance.now(), tSec=0;
// ── session-driven SAND CLOCK (deploy behaviour; diverges from the lab hybrid.html) ──
// The falling stream belongs to the session, not the wall clock: it onsets from the neck at
// each focus start, FREEZES when paused (frozen mid-air), and is absent while idle / on a
// break / done. tSec still drives the living sky (glitter/sun/moon) so the world stays alive.
let sandClock=0, prevSandKind='idle';
// A throw inside drawSand used to blank the canvas with no clue why (twice: a
// bad neck index, then an undefined S key -> addColorStop(NaN)). Surface it.
let lastErr='';
function updateSession(){
  const r = session.sample();
  if (r.kind !== 'idle') S.prog = r.prog;   // idle leaves the debug slider in control
  if (typeof updateSessionUI === 'function') updateSessionUI(r);   // wired in Tasks 5–7
  return r;
}
// Adaptive: measured frame time is the only signal that tells the truth about a device we guessed wrong on.
let _frames = 0, _acc = 0;
const FRAME_MS = () => (LOW || _slow) ? 33.3 : 0;            // 30fps when constrained, uncapped otherwise
let _lastDraw = 0;

function loop(now){
  requestAnimationFrame(loop);                              // schedule first: a skipped frame must still re-arm

  // Hidden tab: burn nothing. (visibilitychange already parks the CSS breathe; this parks the GPU.)
  if (document.hidden) { t0 = now; return; }

  // Frame cap. Skipping the DRAW while still advancing time keeps the day cycle and sand clock honest.
  const cap = FRAME_MS();
  if (cap && now - _lastDraw < cap - 1) return;
  _lastDraw = now;

  // Watch real frame cost for ~90 frames; if we are consistently missing 30fps, drop a tier for good.
  if (!_slow && !LOW && _frames < 90) {
    _acc += Math.min(now - t0, 100); _frames++;
    if (_frames === 90 && _acc / 90 > 28) {                  // avg worse than ~35fps
      _slow = true;
      renderer.setPixelRatio(DPR_CAP());
      fit();
    }
  }
  return loopBody(now);
}
function loopBody(now){ const dt=Math.min((now-t0)/1000, 0.05); tSec+=dt; t0=now;   // clamp dt: no lurch after a hidden tab
  updateDayCycle();
  if (S._sunMoonOff){ U.uCelAamt.value=0; U.uCelBamt.value=0; }                 // Setup: sun & moon hidden
  if (document.documentElement.classList.contains('session-active')){           // numeral auto-contrast, live plate luminance
    const bl = PH_LUMA[CUR.a]*(1-CUR.blend) + PH_LUMA[CUR.b]*CUR.blend;
    if (Math.abs(bl-_bgLumaLast) > 0.01){ _bgLumaLast = bl; setNumTone(bl); }
  }
  if (!_revealed && U.uTex.value.image && U.uTex.value.image.width) reveal();   // scene-ready = current plate decoded
  const r = updateSession();
  if (r.kind === 'idle') {                                      // HOME idle: ~40% fill, sand falling continuously (looped, NEVER filling)
    S.prog = 0.4; S._sandOn = true; sandClock += dt;
  } else {
    const focusActive = (r.kind === 'focus');                   // sand present (falling or frozen)
    if (focusActive && prevSandKind !== 'focus') sandClock = 0; // new focus block -> stream onsets from the neck
    if (focusActive && session.state.running) sandClock += dt;  // advance ONLY while running (frozen on pause)
    if (!focusActive) sandClock = 0;                            // rest / done -> no stream
    S._sandOn = focusActive;                                    // drawSand gates the stream on this
  }
  prevSandKind = r.kind;
  U.uTime.value=tSec; renderer.render(scene,cam);
  try {
    drawSand(sandClock);                                        // stream time = the session sand-clock (also rebuilds occ mattes when dirty)
    // Occluder needs preserveDrawingBuffer, which we do not grant on a constrained device (see the
    // renderer above). Skipping it just means the numerals sit ON the glass instead of behind it.
    if (!LOW && document.documentElement.classList.contains('session-active'))
      drawOcc(frame.dataset.place || 'middle');                // numbers pass behind the glass/sea/ledge
    if(lastErr){ lastErr=''; $('err').style.display='none'; }
  } catch(e){
    const msg=e && e.message ? e.message : String(e);
    if(msg!==lastErr){ lastErr=msg; console.error(e);
      $('err').textContent='drawSand: '+msg; $('err').style.display='block'; }
  }
  // (rAF is scheduled at the TOP of loop(), so a capped/skipped frame still re-arms.)
}
// Deploy runs LIVE: the hidden lab's phase-bind fires once on init and flips S.live=0 (to preview a phase).
// Undo it here so the day cycle follows the REAL clock. Nothing in the deploy re-disables it (lab UI hidden).
S.live = 1;
requestAnimationFrame(loop);

// Pause the CSS "breathing" zoom while the tab is hidden, so it doesn't jump/catch-up on return.
document.addEventListener('visibilitychange', () => {
  const f = document.getElementById('frame');
  if (f) f.style.animationPlayState = document.hidden ? 'paused' : 'running';
});

// ── Session numeral look: per-place geometry (LOCKED, byte-for-byte from session.html / timer-modes.json)
//    + auto-contrast tone (ported from session.html setTone: a DARK chosen colour lifts toward white on
//    DARK plates only; a light colour never changes). bgLuma is estimated per phase and blended live. ──
// All PLATE-relative (cqh/cqw of #frame + % of the plate): the numbers are pasted on the plate and move/scale/crop
// with it. Values are number-lab.html's (timer-modes.json) verbatim — the lab was perfected on the plate-cover.
// Full per-place numeral geometry — each mode keeps its OWN designed X/position (from number-lab.html /
// timer-modes.json): horizon sits wide-left (--dx -30%, --hg-cx 50%, small gap), top/middle/ledge flank the
// hourglass axis (--hg-cx 49.79%) at their own gaps and vertical bands. ONLY `size` (cqh) and `dy` (vertical
// offset %, nudges the block up/down) are tunable — live-edited via the dev panel and persisted to
// localStorage['sustain.numTune'], overriding these. Everything else (X, gap, tb-top, weight) is a design
// constant and never changes (founder: modes stay in their positions; Y-only nudge).
const NUM_DEF = {   // size(cqh) & dy(%) LOCKED by the founder 2026-08-01 via the tuner; X/gap/tb-top are design constants
  horizon: { size:13, dy:-3.5, gap:'3cqw',  tbtop:'55%', hgcx:'50%',    dx:'-30%' },
  middle:  { size:20, dy:5,   gap:'15cqw', tbtop:'48%', hgcx:'49.79%', dx:'0'    },
  top:     { size:15, dy:2.5, gap:'3cqw',  tbtop:'15%', hgcx:'49.79%', dx:'0'    },
  ledge:   { size:20, dy:8,   gap:'15cqw', tbtop:'78%', hgcx:'49.79%', dx:'0'    }
};
function numTune(){ try { return JSON.parse(localStorage.getItem('sustain.numTune') || '{}'); } catch(e){ return {}; } }
function numFor(place){
  const d = NUM_DEF[place] || NUM_DEF.middle;
  // Baked NUM_DEF is authoritative in normal sessions; the localStorage override only applies in the opt-in
  // tuner (window.__numTuneMode), so stale tuning never diverges the shipped numbers from the locked defaults.
  const o = window.__numTuneMode ? (numTune()[place] || {}) : {};
  return { size: o.size!=null ? o.size : d.size, dy: o.dy!=null ? o.dy : d.dy };
}
// Per-mode separator rule (number-lab.html applySepForMode): Middle/Ledge = none (the glass is the divider
// between the wide-flanked numbers); Top/Horizon = the user's colon|dot, never none.
let numSep = 'colon';   // user's divider pick, only used by Top/Horizon
function sepForPlace(place){ return (place==='middle' || place==='ledge') ? 'none' : (numSep==='dot' ? 'dot' : 'colon'); }
function applyNum(place){                          // designed geometry (X fixed per mode) + tuned size/dy; selects the active place → occluder follows
  // Phones get TOP only. The other placements sit beside or across the glass, and a portrait viewport has no
  // room for that. The size/gap themselves are re-expressed in viewport units by the portrait CSS in
  // SceneWorld: these values are cqh/cqw of #frame, and on portrait the plate is ~4x wider than the screen,
  // so `3cqw` and `15cqh` computed the pair straight off the edge of the display.
  if (narrowVP()) place = 'top';
  const d = NUM_DEF[place] || NUM_DEF.middle, n = numFor(place);
  frame.style.setProperty('--num-size', String(n.size));
  frame.style.setProperty('--dy', n.dy + '%');
  frame.style.setProperty('--gap', d.gap);
  frame.style.setProperty('--tb-top', d.tbtop);
  frame.style.setProperty('--hg-cx', d.hgcx);
  frame.style.setProperty('--dx', d.dx);
  frame.style.setProperty('--num-weight', '550');
  frame.style.setProperty('--num-scaleX', '1');
  frame.dataset.place = place;
  frame.dataset.sep = sepForPlace(place);          // separator follows the mode rule, not the raw cfg
}
// Rotating a phone flips whether the narrow rule applies, so re-run the placement (and the visibility rule,
// since a hover-less device can gain/lose a mouse). numPlace holds the user's real choice, not the forced one.
let numPlace = 'middle';
addEventListener('resize', () => { applyNum(numPlace); applyVis(); });

const PH_LUMA = [0.32, 0.52, 0.72, 0.50, 0.28, 0.14];   // pre-dawn,sunrise,midday,sunset,twilight,midnight
let numColor = '#ffffff', numAuto = true, _bgLumaLast = -1;
function _rgbOf(c){
  c = (c || '#ffffff').trim(); let r=255,g=255,b=255;
  if (c[0]==='#'){ let h=c.slice(1); if (h.length===3) h=h.split('').map(x=>x+x).join('');
    r=parseInt(h.slice(0,2),16); g=parseInt(h.slice(2,4),16); b=parseInt(h.slice(4,6),16); }
  else { const m=c.match(/\d+/g); if (m){ r=+m[0]; g=+m[1]; b=+m[2]; } }
  return [r,g,b];
}
function setNumTone(bgLuma){
  if (!numAuto){ frame.style.setProperty('--num-eff', numColor); return; }
  let [r,g,b] = _rgbOf(numColor);
  const cL = (0.299*r + 0.587*g + 0.114*b)/255; let t = 0;
  if (cL < 0.5){                                       // dark colour → lift toward white on dark plates only
    const s = Math.min(1, Math.max(0, (0.46 - bgLuma)/0.08));
    const targetL = cL + (0.9 - cL)*s; t = Math.min(1, (targetL - cL)/(1 - cL));
  }
  r += (255-r)*t; g += (255-g)*t; b += (255-b)*t;
  frame.style.setProperty('--num-eff', `rgb(${Math.round(r)} ${Math.round(g)} ${Math.round(b)})`);
}

// Setup drives the scene: preview a phase (index 0–5) or 'follow' the live clock, and toggle sun+moon.
// ── Thumbnail crop — ONE fixed rect for the whole catalogue ──────────────────────────────────────────
// Founder's rule: the hourglass and the sun/moon must both be visible, and the crop must NOT change from
// video to video. Those pull against each other, because the body arcs right across the sky as the day
// turns — so the rect is the UNION of the hourglass box with every celestial position across a full 24 h,
// sampled from the same trackSun/trackMoon the scene itself uses. Computed once and cached: identical
// framing on all 57 rows, which is what makes a series recognisable in a feed.
// ── TUNABLE. Founder-verified by eye — adjust these two and re-export ────────────────────────────────
//   HEIGHT : fraction of the plate's height the thumbnail keeps. 1 = the whole frame (no zoom).
//   YBIAS  : 0 anchors the crop to the top of the plate, 1 to the bottom.
// The output is 16:9 and the PLATE is 16:9, so a 16:9 crop is SQUARE in plate-fraction space: cropping
// height by this much crops exactly as much width, which is what tightens the sides while the full
// hourglass and the sky above it stay in shot.
const THUMB_HEIGHT = 0.88, THUMB_YBIAS = 0.62;
let _crop = null;                                       // cached: the rect never changes between videos
function thumbCrop(aspect){
  if (_crop && _crop.aspect === aspect) return _crop;
  const target = aspect * (DH / DW);                    // 16:9 in plate-fraction space (≈1 for a 16:9 plate)
  let h = Math.min(1, THUMB_HEIGHT), w = Math.min(1, h * target);
  h = w / target;                                       // keep it exact if width clamped
  // Horizontally centred on the hourglass AXIS, not the plate: the glass is what must sit in the middle.
  let x = S.cx - w/2;
  if (x < 0) x = 0; if (x + w > 1) x = 1 - w;
  // Vertically biased low — the deck and the glass matter more than empty top sky, but leave enough sky
  // that the sun/moon is still in shot for the lights we actually shoot.
  let y = (1 - h) * THUMB_YBIAS;
  if (y < 0) y = 0; if (y + h > 1) y = 1 - h;
  // `axis` = where the hourglass centreline falls INSIDE the crop, 0–1. The thumbnail UI draws its
  // centring guide off this, so "centred" means centred on the glass, not on the frame.
  return (_crop = { aspect, x, y, w, h, axis: (S.cx - x) / w });
}

window.SustainScene = {
  setDay: function(v){ if (v==='follow' || v==null){ S.live=1; } else { S.live=0; S.daytime=PH_HOUR[v|0]; } },
  // Continuous day position for the light-cycle: set an arbitrary reference hour (0–24, wraps); the scene
  // crossfades plates + moves sun/moon to it. The Session interpolates this through the cycle over elapsed.
  setDayHour: function(h){ S.live=0; S.daytime=((h%24)+24)%24; },
  // The viewer's real local time expressed in the scene's REFERENCE day (warped by their sunrise/sunset).
  // The landing's scroll sweep anchors on this so the top of the page is always the true current sky.
  refHour: function(){ return warpTime(clockHours()); },
  // Opt-in only (spec §5): a representative timezone coord can be ~30–60 min off inside a wide timezone.
  // Call this from a user gesture — it prompts for location. Never call it on load.
  useExactLocation: useExactLocation,
  phaseHour: function(i){ return PH_HOUR[((i|0)%6+6)%6]; },   // reference hour of a phase index (0–5)
  setSunMoon: function(show){ S._sunMoonOff = !show; },
  // ── Session: drive the shared hourglass + numerals from a prebuilt plan ([{kind,dur(sec)}]) ──
  startSession: function(plan, endless){
    session.setPlan(plan, endless ? 'endless' : 'custom');
    session.start(); wasDone = false; S.prog = 0;
    document.documentElement.classList.add('session-active');
    applyVis();
  },
  togglePauseSession: function(){ if (session.state.running) session.pause(); else session.resume(); return session.state.running; },
  // Reset the running plan's clock back to zero. `freeze` also parks it paused. /stage uses this for its
  // 3-2-1 lead-in: pause/resume alone would keep the ~80 ms that elapsed before the pause landed, so a
  // 25-minute block began at 24:59. Restarting means the block starts at EXACTLY its full length.
  restartSession: function(freeze){
    session.start(); wasDone = false; S.prog = 0;
    if (freeze) session.pause();
    return !freeze;
  },
  endSession: function(){
    const r = session.sample(); if (r.kind !== 'idle' && !r.done) bumpFocusedToday(r.focusSec);
    session.reset(); S.prog = 0; wasDone = false;
    document.documentElement.classList.remove('session-active');
    occtx.setTransform(1,0,0,1,0,0); occtx.clearRect(0,0,occCv.width,occCv.height);   // drop the occluder
  },
  sampleSession: function(){ return session.sample(); },
  flipEndless: function(){ session.flip(); },   // refill the endless glass; elapsed timer keeps running
  skipToBreak: function(){ return session.skipToBreak(); },   // pomodoro/custom: take the next scheduled break early
  skipBreak: function(){ return session.skipBreak(); },       // end the current rest early → focus resumes
  // ── Thumbnail frame (/stage only) ──────────────────────────────────────────────────────────────
  // Composites the live scene into a 1280x720 canvas, cropped to the founder's rule: THE HOURGLASS AND
  // THE SUN/MOON MUST BOTH BE VISIBLE, everything else is expendable. The celestial body arcs with the
  // time of day, so this cannot be a fixed rect — the crop is computed per light from the body's actual
  // position. That is also the point: at 168px in a feed the hourglass has to dominate, and a wide
  // seascape crop leaves it a sliver.
  //
  // Renders once immediately before reading the WebGL canvas, so it does not depend on
  // preserveDrawingBuffer (which is off on constrained devices).
  //   paint(ctx, W, H) — optional. Called AFTER the scene and BEFORE the hourglass is drawn back on top,
  //   so anything painted there passes BEHIND the glass exactly like the session numerals do. That depth
  //   is the whole trick: "Study with me" can sit across the hourglass and have the word it collides with
  //   occluded, which is what stops thumbnail text reading as a flat sticker.
  thumbFrame: function(opts){
    opts = opts || {};
    const W = opts.w || 1280, H = opts.h || 720;
    U.uTime.value = tSec; renderer.render(scene, cam);      // fresh buffer, no preserveDrawingBuffer needed

    const r = thumbCrop(W / H);
    const out = document.createElement('canvas'); out.width = W; out.height = H;
    const o = out.getContext('2d');
    o.imageSmoothingQuality = 'high';
    // Every layer is a different pixel size (dpr, mask resolution), so crop in each layer's OWN pixels.
    const blit = (cv, ctx) => ctx.drawImage(cv,
      r.x * cv.width, r.y * cv.height, r.w * cv.width, r.h * cv.height, 0, 0, W, H);

    blit(glitterCv, o);
    blit(sandCv, o);

    if (typeof opts.paint === 'function') opts.paint(o, W, H);   // BEHIND the glass

    // Hourglass back on top, silhouette only — same technique as drawOcc(): take the live plate and keep
    // only the pixels inside the glass matte.
    if (occGlassCv){
      const t = document.createElement('canvas'); t.width = W; t.height = H;
      const tc = t.getContext('2d');
      tc.imageSmoothingQuality = 'high';
      blit(glitterCv, tc);
      tc.globalCompositeOperation = 'destination-in';
      blit(occGlassCv, tc);
      // occAlpha lets the caller dial how much the hourglass hides what is behind it. The matte is the
      // GLASS silhouette (maskCv's G channel), so at 1 the bulbs hide text completely — correct for the
      // session numerals, but heavy-handed for thin thumbnail type crossing the sand.
      o.save(); o.globalAlpha = (opts.occAlpha == null ? 1 : opts.occAlpha);
      o.drawImage(t, 0, 0);
      o.restore();
      blit(sandCv, o);                                     // sand rides in front of the glass
    }
    // ...and anything that must sit IN FRONT of the hourglass — the bottom line, which should read as
    // a caption on the image rather than something the stand is standing on.
    if (typeof opts.paintOver === 'function') opts.paintOver(o, W, H);
    return out;
  },
  // Expose the crop so a UI can show what will be kept, and so it can be tuned by eye.
  thumbCropRect: function(aspect){ return thumbCrop(aspect || 16/9); },
  // Mean luminance of a band, so overlay text can pick its own contrast the way the numerals do.
  thumbLuma: function(cv, yFrac, hFrac){
    const c = document.createElement('canvas'); c.width = 64; c.height = 36;
    const g = c.getContext('2d');
    g.drawImage(cv, 0, cv.height * yFrac, cv.width, cv.height * hFrac, 0, 0, 64, 36);
    const d = g.getImageData(0, 0, 64, 36).data;
    let s = 0; for (let i = 0; i < d.length; i += 4) s += 0.299*d[i] + 0.587*d[i+1] + 0.114*d[i+2];
    return s / (d.length / 4) / 255;
  },
  setTimerVis: function(v){
    timerVis = (v==='hidden' ? 'hidden' : v==='hover' ? 'hover' : v==='flash' ? 'flash' : 'always');
    applyVis();
  },
  // Numeral look from the Setup cfg: font (→ overlap-removed numeral face), colour + auto-contrast,
  // fill/separator (data-attrs), and the LOCKED per-place geometry (size/gap/weight/stretch/offset).
  setNumStyle: function(cfg){
    numColor = cfg.color || '#ffffff';
    numAuto  = cfg.autoContrast !== false;
    frame.style.setProperty('--num-color', numColor);
    frame.style.setProperty('--num-font', /Jost/i.test(cfg.font || '') ? "'NumSans',sans-serif" : "'NumSerif',serif");
    numSep = (cfg.sep === 'dot' ? 'dot' : 'colon');     // user's divider; applyNum enforces the per-mode rule (mid/ledge → none)
    numPlace = cfg.place || 'middle';                   // the user's CHOICE, kept so rotating back to landscape restores it
    applyNum(numPlace);                                 // size / top / gap / separator (merged with any tuned overrides); X fixed
    frame.dataset.fill  = cfg.fill  || 'solid';
    _bgLumaLast = -1;                                   // force an auto-contrast recompute next frame
  },
  // ── Dev number-tuner: live-edit + persist each mode's size (cqh) & vertical offset dy (%). Each mode keeps
  //    its OWN X/position; only Y nudges. ──
  editNum: function(place, size, dy){
    const t = numTune(); t[place] = t[place] || {};
    if (size != null) t[place].size = size;
    if (dy   != null) t[place].dy   = dy;
    try { localStorage.setItem('sustain.numTune', JSON.stringify(t)); } catch(e){}
    applyNum(place);                                   // reflects immediately + switches active place (occluder follows)
  },
  numState: function(){ const o = {}; for (const k in NUM_DEF) o[k] = numFor(k); return o; }
};
