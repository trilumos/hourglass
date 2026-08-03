// Static review of the built /stage capture flow. Checks the ORDER and TIMING that a 2-hour take depends
// on, plus that nothing leaked into the user-facing page.
import { readFileSync } from 'node:fs';
const D = 'd:/Dev/Trilumos/hourglass/web-astro/dist/';
const stage = readFileSync(D + 'stage/index.html', 'utf8');
const home  = readFileSync(D + 'index.html', 'utf8');

let fail = 0;
const ok = (cond, msg) => { console.log((cond ? '  ok   ' : '  FAIL ') + msg); if (!cond) fail++; };

console.log('/stage — capture flow');
ok(/INTRO_MS *= *10000/.test(stage),      'intro card 10 s');
ok(/OUTRO_MS *= *7000/.test(stage),       'outro card 7 s on screen');
ok(/OUTRO_STOP_MS *= *5000/.test(stage),  'recording STOPS at 5 s (ends on the card, not on black)');
ok(stage.indexOf('OUTRO_STOP_MS') < stage.indexOf('}, OUTRO_MS)'),
                                          'stop is scheduled BEFORE the fade');
ok(/setTimeout\(obsStop, OUTRO_STOP_MS\)/.test(stage), 'obsStop bound to the 5 s timer');
ok(/setTimeout\(rearm, 3200\)/.test(stage), 'returns to Setup after the fade (no forever-black)');

console.log('\n/stage — escape hatches');
ok(/location\.hash !== '#setup'\) location\.replace\('#setup'\)/.test(stage),
                                          'a reload always lands on Setup (hash cannot resume a session)');
ok(/e\.key !== 'Escape' && e\.key !== 'Backspace'/.test(stage), 'Esc / Backspace bail-out exists');
ok(/if \(location\.hash !== '#session'\) return;[\s\S]{0,120}preventDefault/.test(stage),
                                          'bail-out is guarded to sessions only (Backspace still types on Setup)');
ok(/obsStop\(\);\s*rearm\(\);/.test(stage), 'bail-out stops the recording before leaving');

console.log('\n/stage — re-entrancy');
ok(/if \(done \|\| counting \|\|/.test(stage), 'completion watcher ignores intro/countdown (no instant outro on take 2)');
ok(/done = false; counting = false;/.test(stage), 'rearm resets both flags');
ok(/clearTimeout\(introT\); clearTimeout\(stopT\); clearTimeout\(fadeT\); clearTimeout\(homeT\)/.test(stage),
                                          'rearm clears every pending timer');

// The card must describe the light that ACTUALLY renders. The bug this guards: cycle.preset defaults to
// 'follow' without the user ever opening the Advanced sheet, so reading the preset first made every held
// time-of-day announce itself as "a sky that follows the real time of day".
console.log('\n/stage — the card must describe the light that renders');
ok(/var MOVING = \{ dawn:1, dusk:1, day:1, custom:1 \}/.test(stage),
                                          'only dawn/dusk/day/custom count as a moving sky');
ok(!/var MOVING = \{[^}]*follow/.test(stage),
                                          "'follow' is NOT in MOVING — it is the default preset, not a choice");
ok(!/var MOVING = \{[^}]*hold/.test(stage), "'hold' is not moving either");
ok(stage.indexOf('if (pre && MOVING[pre])') < stage.indexOf('if (c.followDay)'),
                                          'lightOf order: moving cycle, then followDay, then the held phase');
ok(/return PHASE_PHRASE\[c\.phase \| 0\]/.test(stage), 'a held time-of-day falls through to its own phrase');
ok(/CYCLE_LABEL = \{ dawn:'Dawn to Day'/.test(stage), 'config line has short labels for moving skies');
ok(/bits\.push\(lightLabel\(c\)\)/.test(stage), 'config line uses lightLabel, not the raw phase name');

console.log('\nuser-facing site — must be unaffected');
ok(!/OUTRO_STOP_MS|stageOutro|obsStop/.test(home), 'no capture code leaked into the home page');
ok(/chrome-ready/.test(home), 'home still has its WebGL failsafe');
ok(!/obsstudio/.test(home), 'home never references OBS');

console.log(fail ? `\n${fail} FAILED` : '\nALL CHECKS PASS');
process.exit(fail ? 1 : 0);
