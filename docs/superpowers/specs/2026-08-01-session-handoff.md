# Session handoff — Sustain web (web-astro), 2026-08-01

Continue from here in the new chat. The web **source of truth** is `2026-07-29-sustain-web-master-spec.md`
(read it first; its §22 changelog has the full history). This doc is the current state + what's left.

## Where things are

The web version (`web-astro/`, Astro + Three.js) has a working **Home → Setup → Session** over one persistent
WebGL seascape. All of the following landed today and **build clean**; most were browser-verified, the day/night
timing + phase drift need the founder's **on-device** eye across a real day.

### Architecture (unchanged)
- `src/pages/index.astro` — the ONE page: mounts the scene once, hash router (`#setup`/`#session`), nav controller.
- `src/components/` — `Home.astro`, `Setup.astro`, `Session.astro`, `SceneWorld.astro` (scene markup + numeral CSS).
- `src/scene/` — `scene.js` (WebGL day-cycle/sun/moon/sand; `window.SustainScene`), `shaders.js`, `geo.js`
  (SunCalc sunrise/sunset), `audio.js` (`window.SustainAudio`; shared mixer + bell), `lqip.js`.
- `src/lib/timer.js` — session plan/timer engine (`createSession`). `public/js/plan.js` — plan builder.
- Design references: `_internal/site/` (session.html/setup.html — LOCKED) + `_internal/web-prototype/` (number-lab).

### Done today (this session)
- **Break screen** (`Session.astro`): a rest segment shows a blurred **BREAK** overlay with its OWN floored
  countdown (`mmss`) + **End break** button. During a break: **no pause/resume button**, **no Break button**,
  **scene numerals hidden** (`:root.on-break #nums{display:none}`), **audio muted**. A break can never be paused.
  `on-break` is reset on start + both exit paths. Applies to pomodoro / custom / endless.
- **Endless redesign** (complete): Setup shows a 2×2 **block picker** (25/5, 50/10, 90/15, 52/17) → sets
  `pomoFocus/pomoBreak`; `planFromCfg` builds a looping `[focus,break]`; the engine loops it (`elapsed % total`,
  `_endlessJumpTo`) counting **down** per block; breaks use the break screen. (No more stopwatch / open block.)
- **Day-cycle timing** (`scene.js`): reference **twilight shortened to ~1.1 h** (night/midnight begins at 19.5
  ref); **sun glow dies by 19.5** (`SUN_ALT` last key 20.4→19.5); **moon** rises 19.7 (after glow) / sets 4.6
  (before dawn) so sun & moon never coincide. `warpTime` maps this onto the viewer's real SunCalc day → at a
  ~7 PM real sunset, night lands ~8 PM, not 9 PM. `PH_HOUR` twilight 20.3→19.0.
- **Single-phase = witness the FULL phase, stretched over the whole session** (`Session.astro buildCycle` +
  `PH_SPAN`): picking sunrise drifts pre-dawn→sun-up→into-midday across the session length; sunset drifts
  golden-descent→sun-down→into-twilight (never "after it's set"). Fixed the bug where a picked phase was ignored
  and the session followed live time (`cfg.cycle.preset='follow'` was overriding `cfg.phase`).
- **Navigation**: Setup **Back → Home** always (not `history.back`); browser **back/swipe never re-enters a
  spent `#session`** (bounces to Home; reload still shows the session-over popcard); in-session guard hardened
  with a 2-deep buffer against a rapid double-back.
- **Defaults**: sounds **OFF** for new users; timer visibility **On hover**.
- **Bug fixes**: break-timer float (`57.2459…`→floored), favicon, preload crossorigin, aria-hidden focus.
- **Repo**: loose noise/labs moved to `_internal/` (git mv, nothing deleted); root README rewritten.

## What needs the founder's on-device verification
- Day/night **plate + sun + moon timing** across a real day (the big retune above — check sunset/twilight/night
  land at the right real hours for the location; sun & moon never overlap).
- Single-phase **witness drift** (sunrise/sunset/etc. play the full phase over the session length).
- **Break screen** in each mode (no pause button, no scene timer, silent, End break resumes focus + hourglass).
- **Navigation** (Back→Home, back/swipe never returns to session, reload → session-over).

## Remaining / next (from the roadmap)
- **Landing page** — the full scroll-through day→night marketing page (below the hero).
- **Deploy** — Cloudflare Pages + domain, then GSC.
- **Perf pass** — self-host fonts fully, strip the remaining hidden lab UI from `SceneWorld.astro`.
- Confirm the **circular favicon** reads right in the tab (was updated today).
- Possible polish: the endless Setup readout shows ∞/"NO SET END" (correct: the session is open-ended; each
  block still counts down) — confirm the founder is happy with that framing.

## How to run
`cd web-astro && npm run dev` → http://localhost:4321. `?tune` on a session opens the localhost-only numeral
tuner. Founder verifies visual/UX/audio on-device himself (Iron Rule).
