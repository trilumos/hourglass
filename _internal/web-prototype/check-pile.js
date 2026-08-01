// Does the pile GATHER, or pop into existence? Simulates the real geometry from
// hybrid.html across the whole drain. The bug this guards: solved purely by volume,
// the first grains produced a full-bulb-width triangle that only grew taller.
const fs=require('fs');
const s=fs.readFileSync('d:/Dev/Trilumos/hourglass/web-prototype/hybrid.html','utf8');
const clamp=(v,a,b)=>v<a?a:v>b?b:v, lerp=(a,b,t)=>a+(b-a)*t;
const smooth=t=>{t=clamp(t,0,1);return t*t*(3-2*t);};
// String.raw, or the template literal eats \b and \d before RegExp ever sees them
const num=k=>parseFloat(new RegExp(String.raw`\b`+k+String.raw`:(-?[\d.]+)`).exec(s)[1]);
const pileStart=num('pileStart'), pileRamp=num('pileRamp'), rep=num('repose');
const bedHand=num('bedHand');
let LADDER=false;   // set true to simulate the old coarse-rung behaviour

// A stand-in bulb: half-width tapers from the neck down to the widest point and
// back, which is all the geometry these formulas depend on.
const yN=0.63, yB=0.89;
const halfAt=y=>{const u=clamp((y-yN)/(yB-yN),0,1); return 0.02+0.20*Math.sin(u*Math.PI*0.72);};
const NS=400;
const volLevel=(yTop,yBot)=>{let v=0;const h=(yBot-yTop)/NS;
  for(let i=0;i<NS;i++){const r=halfAt(yTop+h*(i+0.5)); v+=Math.PI*r*r*h;} return v;};
const volBelow=(ya,yBot)=>{let v=0;const h=(yBot-ya)/NS;
  for(let i=0;i<NS;i++){const y=ya+h*(i+0.5); const r=Math.min((y-ya)/rep, halfAt(y)); v+=Math.PI*r*r*h;} return v;};
const solve=(target,lo,hi,fn)=>{let a=lo,b=hi;
  for(let i=0;i<60;i++){const m=(a+b)/2; (fn(m)<target)?b=m:a=m;} return (a+b)/2;};

const Vtot=volLevel(yN,yB)*0.75;
function pile(d){
  const yApexS=solve(d*Vtot,yN,yB,ya=>volBelow(ya,yB));
  let yCs=yB;
  const wallGap=y=>(y-yApexS)/rep-halfAt(y);
  let lo=yApexS, hi=null;
  for(let i=1;i<=96;i++){const y=yApexS+(yB-yApexS)*i/96;
    if(wallGap(y)>=0){hi=y;break;} lo=y;}
  if(hi!==null){ if(!LADDER){for(let i=0;i<40;i++){const m=(lo+hi)/2; if(wallGap(m)>=0) hi=m; else lo=m;}} yCs=hi; }
  const coneAmt=smooth(clamp((d-pileStart)/Math.max(pileRamp,1e-4),0,1));
  const yFlat=solve(d*Vtot,yN,yB,ys=>volLevel(ys,yB));
  const bedAmt=smooth(clamp(d/Math.max(bedHand,1e-4),0,1));
  const yC=lerp(yFlat,yCs,bedAmt);
  const rC=Math.max(halfAt(yC),0.001);
  const rCone=Math.max(rC*coneAmt,1e-6);
  const yApex=yC-rCone*rep;
  return {yC,rC,rCone,coneH:yC-yApex,coneAmt,yFlat,yCs};
}
console.log(' d    coneAmt  bed top   mound radius  mound height');
const prev={};
let fail=[];
for(let i=0;i<=20;i++){
  const d=i/20, p=pile(d);
  if(i%2===0) console.log(`${d.toFixed(2)}   ${p.coneAmt.toFixed(2)}    ${p.yC.toFixed(4)}    ${p.rCone.toFixed(4)}        ${p.coneH.toFixed(4)}`);
}
// 1. no mound before it is meant to start - it must spread FLAT first
if(pile(pileStart*0.5).coneH > 1e-4) fail.push('a mound exists before pileStart - not spreading flat first');
// 1b. the mound must grow OUTWARD, not appear at full width
const r0=pile(pileStart+0.15*pileRamp).rCone, r1=pile(1).rCone;
if(!(r0 < r1*0.35)) fail.push(`mound starts at ${(r0/r1*100).toFixed(0)}% of full radius - it should start tiny`);
// Only through the GROWTH phase. Past it the bed rises above the bulb's widest
// point and the glass itself narrows, so the contact radius correctly shrinks.
let rbad=0;
const st=pileRamp/12;
for(let d=pileStart; d<pileStart+pileRamp; d+=st)
  if(pile(d+st).rCone < pile(d).rCone - 1e-9) rbad++;
if(rbad) fail.push('mound radius shrinks while it should still be growing');
// 2. the mound must GROW, not appear
const hs=[]; for(let d=pileStart; d<=1; d+=Math.min(0.02,pileRamp/6)) hs.push(pile(d).coneH);
let worstJump=0; for(let i=1;i<hs.length;i++) worstJump=Math.max(worstJump, hs[i]-hs[i-1]);
const maxH=Math.max(...hs);
if(worstJump > maxH*0.25) fail.push(`cone height jumps ${(worstJump/maxH*100).toFixed(0)}% of its max in one step - still popping`);
// 3. the bed must rise monotonically (sand only accumulates)
// Blending a flat fill into a cone genuinely redistributes sand, so a tiny dip is
// inherent. Tolerance is ONE PIXEL on a 900px-tall render (~1.1e-3 normalised);
// measured worst case across the whole valid parameter region is ~9e-4.
const PX = 1/900;
let dip=0; for(let d=0.005; d<=1; d+=0.005) dip=Math.max(dip, pile(d).yC - pile(d-0.005).yC);
if(dip > PX) fail.push(`bed level falls ${(dip*900).toFixed(2)}px - visible un-accumulation`);
// 4. at full drain the locked solved shape must be reached exactly
if(Math.abs(pile(1).coneAmt-1) > 1e-9) fail.push('never reaches the solved cone - the locked shape is not restored');
console.log(`\nlargest single-step growth: ${(worstJump/maxH*100).toFixed(1)}% of max cone height`);

// ---- guards for the two bugs the founder found on 2026-07-19 ----
const num2=k=>parseFloat(new RegExp(String.raw`\b`+k+String.raw`:(-?[\d.]+)`).exec(s)[1]);

// A. THE FREEZE. The bed must keep rising the whole way down. Clamping it to a
// fixed level once stopped it dead mid-drain, which read as the progress pausing.
let worstRun=0, run=0;
for(let d=0.02; d<=0.98; d+=0.01){
  const rise = pile(d-0.01).yC - pile(d).yC;        // +ve = level rising
  if(rise < 1e-5){ run++; worstRun=Math.max(worstRun,run); } else run=0;
}
console.log(`longest bed stall: ${(worstRun*0.01).toFixed(2)} of the drain`);
if(worstRun*0.01 > 0.08) fail.push(`bed stalls for ${(worstRun*0.01).toFixed(2)} of the drain - reads as the progress pausing`);

// B. THE TOP FLASH. The top surface must reach the neck EXACTLY at d=1 and get
// there smoothly - it used to leave a tall sliver in the throat and vanish at 100%.
// The TOP bulb, modelled properly: wide at the cap, pinching to a NARROW throat at
// the neck. That narrowness is the whole bug - a small leftover volume in a thin
// throat is TALL, so it stayed visible until it vanished at 100%. An earlier
// version of this check solved over the BOTTOM bulb and therefore passed trivially.
const yT=0.35;
const halfTop=y=>{const u=clamp((y-yT)/(yN-yT),0,1); return 0.015+0.185*Math.sin((1-u)*Math.PI*0.62);};
const volTop=(a,b)=>{let v=0;const h=(b-a)/NS;for(let i=0;i<NS;i++){const r=halfTop(a+h*(i+0.5));v+=Math.PI*r*r*h;}return v;};
const VtopFull=volTop(yT,yN);
const topHold=num2('topHold'), topShown=Math.min(num2('topShown'),num2('topHold'));
const dTopOf=d=> d<=topHold ? d*(topShown/Math.max(topHold,1e-4))
                            : lerp(topShown,1,smooth((d-topHold)/Math.max(1-topHold,1e-4)));
const topSurf=d=>solve((1-dTopOf(d))*VtopFull, yT, yN, ys=>volTop(ys,yN));
// how much sand is LEFT in the top, as a fraction of full
const topLeft=d=>volTop(topSurf(d), yN)/VtopFull;
const leftover=Math.abs(topSurf(1)-yN);
console.log(`top sand left:  96%->${(topLeft(0.96)*100).toFixed(1)}%   99%->${(topLeft(0.99)*100).toFixed(1)}%   100%->${(topLeft(1)*100).toFixed(2)}%`);
if(leftover>1e-6) fail.push('top still holds sand at d=1 - it will flash empty');
// THE ASK: 99% must still show roughly what the UNLAGGED clock showed at 96%.
const want=volTop(solve((1-0.96)*VtopFull,yT,yN,ys=>volTop(ys,yN)),yN)/VtopFull;
const got=topLeft(0.99);
console.log(`at 99% the top holds ${(got*100).toFixed(1)}% - the raw clock shows ${(want*100).toFixed(1)}% at 96%`);
// The lag pair is the founder's call and 0.800/0.995 (lag off) is confirmed as
// intended, so these are REPORTED, not enforced. What IS enforced is that the top
// reaches exactly empty at d=1 - that was the actual flashing bug.
console.log(`  (lag ${num2('topShown')>=num2('topHold')?'OFF by design':'on'} - top pair is a look call)`);

// C. The early bed matches the TOP pile via a lightness lift on the BOTTOM half.
// That only holds while the halves share hue+saturation.
if(Math.abs(num2('shueT')-num2('shueB'))>1e-9 || Math.abs(num2('ssatT')-num2('ssatB'))>1e-9)
  fail.push('halves no longer share hue+saturation - the early-bed lift can no longer match the top pile');
// Likewise the colour ramp vs mound ramp is a look call, not a correctness one.
console.log(`  bed colour settles over ${num2('bedTint')}, mound forms by ${(num2('pileStart')+num2('pileRamp')).toFixed(2)}`);


// SMOOTHNESS. Reading the contact height off a coarse 96-rung ladder meant the bed
// could only sit at 97 discrete heights, so as the pile grew it jumped rung to rung
// - the bottom filled in visible STEPS. Measure the largest single-tick move, and
// compare against the old behaviour so the fix is demonstrably the cause.
const DHpx=900, dstep=0.0005;                  // one Progress slider tick
const worstMove=()=>{let w=0;
  for(let d=0.02; d<=0.98; d+=dstep*4) w=Math.max(w, Math.abs(pile(d+dstep).yC-pile(d).yC));
  return w*DHpx;};
const smoothPx=worstMove();
LADDER=true;  const ladderPx=worstMove();  LADDER=false;
console.log(`bed move per slider tick: ${smoothPx.toFixed(2)}px   (old coarse ladder: ${ladderPx.toFixed(2)}px)`);
if(smoothPx > 1.0) fail.push(`bed jumps ${smoothPx.toFixed(2)}px per slider tick - still stepping`);

console.log(fail.length?'\nFAIL:\n  '+fail.join('\n  '):'\nOK - spreads flat, then the mound grows smoothly into the locked cone.');
process.exit(fail.length?1:0);
