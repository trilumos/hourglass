# Sustain Web W1 — Session Handoff (2026-07-18)

> **Purpose:** full context to continue the Sustain **website (W1)** work in a fresh session.
> This session ran long; this doc captures everything decided, built, and still open.
> **Canonical design specs it builds on:**
> - [`2026-07-17-sustain-platform-strategy-design.md`](2026-07-17-sustain-platform-strategy-design.md) — the master strategy (web + app, money, phases). READ THIS.
> - Prototype assets + notes live in [`../../../web-prototype/`](../../../web-prototype/) (esp. `PLATES.md`).

---

## 0. App status (unrelated to web, but LIVE — don't lose)

- **v1.0.0+6 submitted to Google Play, in review.** Tagged `v1.0.0+6` on commit `b685171`.
- **Managed publishing is ON** → after Google approves, the founder must **manually hit Publish**.
- **Founder to-do after publish:** create a Play **promo code** for `pro.lifetime`, redeem it, and
  **verify the themes unlock** — the lifetime→themes money path (`entitlements.dart`, `isLifetime =
  expirationDate == null`) has NEVER run against a real purchase. Promo redemption = free real test.
- Prices already updated in Play Console: Monthly $2.99/₹89 · Yearly $19.99/₹549 · Lifetime $49.99/₹1,299.
- Themes are now **Lifetime-only** (subs get every feature, no themes). All false "Pro includes themes"
  copy was scrubbed app-wide this session-cluster. `pubspec.yaml` = 1.0.0+6.

---

## 1. Web W1 — the LOCKED art direction

**"Living painting"** — a still anime scene brought to life with a few procedural effects. `95% still,
5% moving.` Not a video, not a full 3D world.

**The scene:** a Makoto-Shinkai-style seaside — an ornate **wooden hourglass on a wooden window sill /
ledge**, overlooking an ocean, cherry-blossom cliff + stone lanterns on the right. (Started as "hourglass
on a rock"; founder changed it to a **window sill** — better: flat, cozy, "your space at a window".)

**The four layers** (bottom → top):
1. **Anime plate** (AI still) — the world.
2. **Procedural motion** — water shimmer / old-anime **star-glitter**, rendered **sun & moon**, drifting
   clouds, lanterns glow, occasional bird. All GPU shaders / canvas.
3. **The hourglass** — the app's mascot, sand tied to the real timer.
4. **Glass UI** — setup/session controls (anime.js/GSAP for these, NOT the scene).

### Locked sub-decisions (do not re-litigate)
- **Sun & moon are RENDERED by us, not baked into the plates.** So plates are **sunless** (coloured sky,
  clouds, sea, rocks, lanterns — NO sun disc, NO moon disc, NO glitter path on water). Why: our sun IS the
  hourglass's key light (coherence, no "pasted-on"), zero crossfade ghosting, minute-by-minute position,
  real moon phase (date-only, no location/permission). See `web-prototype/PLATES.md`.
- **Time of day is real** — driven by the visitor's local clock. Landing: scroll advances the phase,
  starting at the user's real phase. Session: the real clock drives it, minute-by-minute (a 4-hour evening
  session watches an actual sunset; a 25-min Pomodoro barely shifts).
- **Hourglass never moves/rotates/tilts** — only the sand moves. It's the one still point while the world's
  time passes. Camera may *pan* horizontally (image wider than viewport) but the sill+glass move together.
- **8 phase plates**, every 3h: midnight, pre-dawn, sunrise, morning, noon (MASTER), afternoon, sunset,
  twilight. Generate the **noon master** first, then **edit-model relight** the other 7 (Nano Banana 2 /
  Flux Kontext / Photoshop generative — NOT fresh text-to-image, which drifts). **16:9**, content centred.
- **Consistency fix (plate drift):** inpaint **only the sky** (mask foreground) so rocks/sill never move;
  OR I auto-align the batch in code; OR shared-foreground + per-phase-sky. Founder saw minute drift —
  addressed. Also: normalise all 8 to identical pixel size (I have a PIL one-liner; done for the 2 tests).

### The HYBRID hourglass decision (current active experiment)
Three candidates were on the table (2.5D painter port / 3D Three.js lathe glass / **hybrid**). Founder
chose the **hybrid**, and it's what's being prototyped:

> **The AI generates a beautiful EMPTY anime hourglass baked into each scene plate; we render ONLY the
> SAND inside it** (falling stream + levels + pile), clipped to the glass interior, tied to the timer.

- Pro: the glass/frame is AI-gorgeous and already lit to match the scene; we get real timer-driven sand.
- Con: **each of the 8 phases needs its own empty-hourglass plate** (the glass is baked, so it's relit per
  phase). Accepted. Founder wants midday perfected FIRST, then generate the other 7.
- The app's ported 2.5D painter (`web-prototype/hourglass.js`) and the 3D `living.html` test still exist as
  fallbacks if the hybrid fails, but hybrid is the chosen path.

### Tech stack (locked via research)
- **Astro** (SEO-first static/SSR — the whole reason we're not Flutter-web) + **React islands** for the canvas.
- **Three.js + GLSL** for water shimmer / sun-moon / glitter (anime.js CANNOT do these — it's DOM/SVG
  tweening only; use it for UI). **GSAP + ScrollTrigger** (now 100% free incl. ScrollTrigger) + **Lenis**
  for scroll. All free/MIT.
- Anime look = gradient-ramp sky + FBM clouds + toon water + **LUT + Kuwahara + bloom** post — IF we ever
  render the scene; but the hybrid uses AI plates so most of this is moot for W1.

---

## 2. The prototype — `web-prototype/`

**Runs on a local static server (Claude Code runs on the founder's Windows machine, so localhost works in
their browser).** Server dies at session end — **restart it next session:**
```
cd d:/Dev/Trilumos/hourglass/web-prototype && python -m http.server 8899 --bind 127.0.0.1
```
Then open in a browser (GPU — headless screenshots can't judge transmission glass / shaders well):

| File | URL | What it is |
|---|---|---|
| **`hybrid.html`** | http://localhost:8899/hybrid.html | **THE ACTIVE ONE.** Baked empty-hourglass plate + sand rendered inside + old-anime star-glitter on the water. |
| `living.html` | …/living.html | Earlier test: plate + water shimmer + 3D lathe glass / 2.5D painter toggle (press `2`). Superseded by hybrid but kept. |
| `scene.html` | …/scene.html | Fully-coded Three.js Sky+Water (realistic, NOT anime) — proved coded scenes look realistic not anime; kept as a reference/dead-end. |
| `index.html` | …/index.html | First composite test (2.5D painter on plate). Oldest. |

**Assets in `web-prototype/plates/`:**
- `Empty hourglass midday.png` (1671×941) — **the current hybrid base** (empty anime hourglass on sill).
- `plate-golden.png`, `plate-dusk.png` (normalised to 1920×820) — early sunless-ish test plates.
- `PLATES.md` — the plate-generation bible (prompts, sunless rule, 16:9, consistency, sun/moon rendered).

**`hourglass.js`** — faithful JS Canvas 2D port of `lib/hourglass/hourglass_painter.dart` (Gerstner top
surface, grain spray, pile, impact scatter). Used by `living.html`/`index.html`. The hybrid uses its OWN
simpler sand renderer inside `hybrid.html` (grain-textured, flat-top, no wave — per founder feedback that
the wave "looked like water").

### `hybrid.html` — current state & exact tuning
- **OUTLINE LOCKED (founder, "99.99%").** The last 2% was *curve shape*, so `glassPath()` was refactored:
  every bezier handle is now a live slider (UI "Curve — top/bottom bulb"), left mirrors right. Founder
  tuned the full silhouette; the locked defaults are baked into the `S` object:
  - frame: `cx:0.499, top:0.347, neck:0.629, bot:0.892, max:0.069, nh:0.004`
  - top bulb: `rimK:0.79, wTop:0.370, aTop:0.075, bTop:0.345, cTop:0.080`
  - bottom bulb: `mxBot:0.960, wBot:0.660, aBot:0.150, bBot:0.375, cBot:0.110, baseK:0.91`
  - sand hue `shue:27`. (`mxBot` = bottom-bulb width vs top; solved the "bottom too wide" issue.)
- **"Show glass edge" now defaults to 0 (sand ON)** — outline fitting is done. Slide it to 1 to re-trace
  the red glass-interior outline and re-verify the lock.
- **Colour pipeline is identity passthrough** (`renderer.outputColorSpace = LinearSRGBColorSpace`,
  `tex.colorSpace = NoColorSpace`) — fixed an over-saturation/warm-shift bug. Background now matches the PNG.
- **Star glitter**: GLSL, twinkles only on bluish water pixels within a sill↔horizon band, faint
  (Amount 0.6, Density 0.32). Founder wanted "old-anime star sparkle, spontaneous, faint, water only" — done.
- **Sand**: grain-textured (offscreen noise canvas overlaid 'overlay' blend = looks like sand not liquid),
  flat top surface with a shallow central funnel dip, cone pile at angle of repose, fine falling stream.

### ✅ ALL LOCKED (2026-07-18, later session) — outline · sand · optics · water
Everything below is founder-approved on GPU and baked as the defaults in `hybrid.html`.
**The `S` literal AND the HTML `value=` attributes must always agree** — the sliders' HTML values
overwrite `S` at load, so changing only one silently loses the tuning. `check-wiring.py` verifies this.

**Glass outline — pen tool.** The curve sliders now only SEED an editable node list; the founder dragged
it to 100%. `LOCKED_NODES` (7 nodes/side, mirrored about `cx`) is the source of truth; `custom` starts
`true` so sliders can't clobber it. `R` restores it, `Shift+R` reverts to slider-driven. Nodes are
draggable on either side, handles move freely in 2D (the old sliders forced them axis-aligned, which is
why some shoulder curves were literally unreachable). Drag off a point = move the whole hourglass.

**Sand — real granular physics, not shaped by hand.** Volume-CONSERVING: solves for the surface height
that holds exactly the sand that has fallen (bisection), so it reads true at every fill, not just one
tuned value. Pile = a cone at the angle of repose clipped by the glass wall; below the contact ring the
glass is simply full. Verified: volume conserved to 0.00%, flank at the set angle, pile monotonic.
- Dry sand's real angle of repose is 34° (tan 0.675) — but the anime reference measures **28° (0.53)**;
  the artist drew a deliberately broader pile. Founder settled on **0.545**.
- Eye level is at the NECK: the top sand is ABOVE the viewer so its top surface is INVISIBLE — no
  ellipse, and above all no funnel crater (only visible looking *down* into one). The bottom pile IS
  below eye level, so it gets the elliptical top. That asymmetry is why it finally read right.
- Colour is per-half (top is one flat shadowed tone, bottom is half lit). Measured from
  `plates/sand-anime.png`: bottom carries 1.34× the lightness range and is far more saturated
  (57% vs 32%) — shadow desaturates. Founder took the top fully flat (`litT=shdT=0`).
- Texture is soft MOTTLING, not film grain. Measured: neighbours differ 5.2/255 vs a 16.7 spread, 51%
  of variance survives 16×16, luminance-only. Octave mix was solved against the reference's
  autocorrelation curve; a white per-pixel octave was essential (r1 .96 → .78).
- Edges are crooked, separately for top (settled, near-flat) and bottom (freshly poured, slumping).

**Water — glitter ONLY.** Ripple displacement, swell drift and white wave-lines were all built, judged,
and **cut** — drifting glints alone read as advancing crests. Glints are horizontal dashes (not 4-point
stars); each is born, slides a little shoreward over its own life, then dies, with position re-seeded per
cycle so nothing looks fixed.
- **Sea region is a hand-drawn mask** (`SEA`, 13 markers, Catmull-Rom through every point, per-node
  straight/curve flag). A colour test could never separate sea from blue shadow on the cliffs.
- One texture carries both masks: **R = sea, G = glass**. Glitter is killed inside the hourglass (a
  mirror-angle specular can't survive curved glass) while water's own appearance passes through.

**Bare coded glass was tried and REJECTED** — it floated with no stand or contact shadow and could not
compete with the AI-painted glass. The refraction code (real u² rim displacement, Fresnel, absorption)
is still in the file, inert unless `glassOn=1`. Delete it if it's still unused next session.

**Tooling added:** `check-wiring.py` (every `S` key has a default, every bind is wired, no dead
controls, S↔HTML agree) and a red on-screen error banner. Two separate silent-blank bugs happened this
session — a collapsed neck index and an undefined `S` key throwing inside `addColorStop` — plus a bulk
regex edit that broke the `S` literal. **Run `python check-wiring.py` after every edit to this file.**

### ✅ PHASE PLATES DONE + PIXEL-LOCKED (2026-07-18, later session)
Founder delivered **6** phase plates (not 8): Pre-Dawn · Sunrise · Mid Day · Sunset · Twilight · Mid Night,
in `web-prototype/final hourglass plates/`. They were within ±2px of each other; a Python integer-shift
align pass (`plates-phases/`, pure copy — nothing resampled) locked all 6 to Mid Day at **0px residual**,
verified by edge cross-correlation. `hybrid.html` now loads all 6 (`PLATES`/`PHASE_NAMES`) and a visible
**Time of day** slider (0–5) crossfades — wait, SWAPS — the background. Because the hourglass renders on a
SEPARATE canvas from the plate, switching phase never moves the glass by a pixel (founder's hard rule).
The bare-glass "Plate: baked⇄bare" control is gone (that path was rejected); `Scene` group is now just the
inert bare-glass refraction knobs, still hidden behind the lock.

### ⏳ IMMEDIATE NEXT STEP
Phase SWAP works but it's a hard cut. Next: (1) **crossfade** between adjacent phases driven by the local
clock (blend two textures in the shader by time-of-day), and (2) the **rendered sun/moon** on a clock arc.
Also: the sand colour is still DAY-locked — night phases show day-coloured sand until time-of-day drives it.
Two hooks are already waiting:
- `Light-path X` should stop being a slider and be driven by the sun's real position.
- The per-half sand colour is the time-of-day hook: a sunset can warm the lit bottom flank while the
  shadowed top goes cool and grey — they must NOT move in lockstep.

NOTE: the outline is fitted to *this* plate. If a relit plate's glass drifts, the pen tool makes
re-fitting quick — but keeping the glass pixel-identical across relights is better.

---

## 3. Money / positioning reminders (from the master spec)
- Web **W1 is FREE** — a funnel to rank on SEO + convert to app installs. No billing code in W1.
- W2 adds paid scenes (à-la-carte cosmetics) + Sustain Sync (the only recurring line). App is primary/proven.
- YouTube = CAC not revenue. The `/stage`-style clean view + OBS is the studio.

## 4. Standing rules reaffirmed this session (in `docs/project-context.md`)
- **IRON RULE — RESEARCH FIRST:** never answer from memory on anything versioned/platform/policy/pricing/
  **code**; official docs + web search first, cite them, the search wins. (Caught real errors this session.)
- **Never drive the founder's phone** without explicit permission (install when asked; ask before anything else).
- Iron rule (original): founder owns look/feel + on-device testing; I own correctness end-to-end.

## 5. Open threads / TODO
- [x] Hybrid hourglass **outline LOCKED** (curve sliders added, founder-tuned "99.99%", baked into `S`).
- [ ] Refine hybrid hourglass **sand** shape to the founder's close-up reference (immediate, above).
- [ ] Generate 8 sunless empty-hourglass phase plates (founder; noon master → 7 relight edits).
- [ ] Build rendered sun/moon on a clock arc (they light the hourglass) + glitter path.
- [ ] Build 24h phase crossfade driven by local clock.
- [ ] Founder judges the whole thing on GPU: does it feel premium/alive/calm?
- [ ] THEN: write the full W1 design spec proper, and `writing-plans` → build in Astro.
- [ ] App: founder hit Publish when approved + promo-code verify lifetime→themes.
- [ ] Founder: buy domain (`sustaintimer.com` rec.), separate/shared Firebase, pick MoR (W2).

---

# SESSION 2026-07-19 — sun, moon and day cycle LOCKED

## Locked state (all baked into `web-prototype/hybrid.html`)

**Day schedule** — `SEG` holds each plate then crossfades into the next, the fade
*completing* on the boundary hour so the change eases in while the sun is still
moving. Every transition is >= 1.3h; fastest rate 1.15/h (a 0.5h fade read as two
images dissolving, which the founder caught).

| | |
|---|---|
| midnight | 23:00 -> 04:24 |
| pre-dawn | 04:24 |
| sunrise  | 06:00 (disc breaks the water ~06:15) |
| midday   | 08:00 |
| sunset   | 18:30 |
| twilight | 20:36 |

**Sun/moon motion** — `SUN_ALT` / `MOON_ALT` are altitude keyframes in real hours,
replacing `sin(pi*u)`. A sine peaked for an instant then fell steadily, so the sun
sat near the horizon by 16:00 while midday was still showing. Now the high hours are
a PLATEAU and the descent runs over the same span as the sunset crossfade. Both
windows open BELOW the horizon (-0.46) so the disc rises through the water instead
of half-popping into existence.

- Sun up 06:00->18:30, afterglow dead 20:24. Moon 21:45 -> 05:30 (gone before the
  sunrise glow). They are never both up — asserted per-minute in `check-schedule.js`.

**SUN — locked by founder.** Three keys (sunrise/midday/sunset) blended by the sun's
own height: rising = sunrise->midday, setting = midday->sunset. All three keys are
`sunSize=0.09 coreW=8 coreA=6 nearW=3 nearA=0 farW=0.01 farA=0`; only the colours
differ. **The near/far glow layers are deliberately OFF** — the look is one steep
bright core. Do not "restore" them.

**MOON — locked by founder.** A PAINTED texture, `plates/moon-tex.png`, cropped from
the founder's `plates/Moon.png` to the opaque disc only (588x584 @ (520,714)); the
artwork's own bloom is dropped so the shader halo is the single tunable glow.
`moonR=0.04 moonK=1.2 moonSoft=0.07 moonTexAmt=1 moonGlowW=1.3 moonGlowA=1.5
moonFarW=0.54 moonFarA=0.16 moonCol=#ffffff moonGlowCol=#cfe4ff moonFarCol=#6f8fd0`

## Things that cost time — do not repeat them

- **Procedural moons do not work at ~60px.** Selenographic maria (accurate, 30%
  coverage) read as a stain; ring craters read as pimples. Artwork wins. Two
  attempts too many before switching.
- **Blend operator decides apparent size.** An ADDITIVE sun tracked the plate behind
  it — 120% of frame width on sunrise (sky already 0.99 in red) vs 1.4% on midnight.
  The body is now a `mix`, so size is a pure function of radius. Wide glow layers
  screen; the body mixes.
- **`clamp()` on the body alpha created a visible border** — it plateaued at exactly
  1.0 then fell, and that shoulder was the edge. `1 - exp(-x)` has no shoulder.
- **Backticks inside the shader template literal truncate the module** and blank the
  page. Hit three times; now a named check in `check-wiring.py`.

## Verification (run all four after editing hybrid.html)
- `python check-wiring.py` — every S key has a default, every bind live, no backticks
- `node check-schedule.js` — sun/moon ordering, plate windows, crossfade rate, rise shape
- `python check-glow.py` — sun body size + plate-independence
- `node --check` on the extracted module

## Sand — bottom pile (LOCKED 2026-07-19)

The bottom cone has **no light/shadow split**. A fixed terminator read as painted-on;
driving it from the sun/moon was tried and cut as more machinery than the shot needs
(`celSplit`, `LIT`, `updateSandLight` and five sliders all deleted). The cone is now
graded exactly like the top pile — colour comes from the per-phase grade alone, so it
shifts through the day the same way.

Four deltas keep the raised cone readable against the flat sand behind it:
`coneLift:-0.040 coneTopShd:0.085 coneBotShd:0.180 bedLift:-0.300`
-> apex -0.125, body -0.040, base -0.220, bed -0.300. Controls live in the SESSION
block, NOT under Locked — they are judged against the moving sun/moon.

**Bug worth remembering:** the cone's front ellipse bulges `rC*k` BELOW `yC`. Running
its gradient only to `yC` clamped that whole lobe to the last colour stop and painted
a hard dark slab across the base. Gradients must span the full path, not the
construction line.

## Moon — low-altitude treatment
A cold blue-white moon in a peach dawn sky is what reads as pasted on. Two effects,
both strongest at the horizon and gone by `moonWarmH`:
- **extinction** — the disc reddens toward `moonWarmCol`, a FIXED warm colour. Tinting
  by the sampled sky was tried first and is WRONG: measured at the moon's own
  position the night sky is deep blue (hue R-B of -1.9 to -3.7), so it turned the
  moon blue.
- **haze** — it also loses contrast, mixed toward the plate sampled at its position
  (clamped to just above the horizon, or the sea colour bleeds in).

## STILL THE GAP
`Progress` is a manual slider. There is no countdown, no Start/Pause/Reset, no
completion. The scene is done; **the timer is the product** and it is not built.
