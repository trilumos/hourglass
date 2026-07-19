// What does the bed actually do across 24h? Pulls the real curve from hybrid.html.
const fs=require('fs');
const s=fs.readFileSync('d:/Dev/Trilumos/hourglass/web-prototype/hybrid.html','utf8');
const grab=(a,b)=>{const i=s.indexOf(a),j=s.indexOf(b,i);return s.slice(i,j);};
const clamp=(v,a,b)=>v<a?a:v>b?b:v, lerp=(a,b,t)=>a+(b-a)*t;
const smooth=t=>{t=clamp(t,0,1);return t*t*(3-2*t);};
const run=src=>(0,eval)(src.replace(/\b(const|let) /g,'var '));
globalThis.clamp=clamp; globalThis.lerp=lerp; globalThis.smooth=smooth;
globalThis.S={hor:0.4475};
run(grab('const SEG =','function phaseAt'));
run(grab('function phaseAt','const SUN_POS'));
run(grab('const SUN_POS','// The sand against the glass'));
const night=parseFloat(/bedNight:(-?[\d.]+)/.exec(s)[1]);
const day  =parseFloat(/bedDay:(-?[\d.]+)/.exec(s)[1]);
const hhmm=t=>String(Math.floor(t)).padStart(2,'0')+':'+String(Math.round((t%1)*60)).padStart(2,'0');
const bed=t=>lerp(night, day, smooth(clamp(trackSun(t).alt,0,1)/0.70));
console.log(`bed range: night ${night}  midday ${day}`);
for(const t of [0,3,6,6.5,7,8,10,12,15,17,18,18.5,20,22]) console.log(`  ${hhmm(t)}  ${bed(t).toFixed(3)}`);
const fail=[];
if(Math.abs(bed(1)-night)>1e-3)  fail.push(`night not at ${night} (got ${bed(1).toFixed(3)})`);
if(Math.abs(bed(12)-day)>1e-3)   fail.push(`midday not at ${day} (got ${bed(12).toFixed(3)})`);
const mid=bed(7);
if(!(mid>night+0.005 && mid<day-0.005)) fail.push(`sunrise not mid-range (got ${mid.toFixed(3)})`);
let worst=0; for(let t=0;t<24;t+=1/60) worst=Math.max(worst, Math.abs(bed(t+1/60)-bed(t))*60);
// The whole range is 0.1, so 0.30/h is a full sweep in ~20 min. Anything faster
// than that would read as the bed stepping rather than drifting.
if(worst>0.30) fail.push(`bed changes too fast: ${worst.toFixed(3)}/h (full sweep in ${(0.1/worst*60).toFixed(0)} min)`);
console.log(`\nfastest change ${worst.toFixed(3)}/h`);
console.log(fail.length?'FAIL:\n  '+fail.join('\n  '):'OK - bed tracks night -> midday smoothly.');
process.exit(fail.length?1:0);
