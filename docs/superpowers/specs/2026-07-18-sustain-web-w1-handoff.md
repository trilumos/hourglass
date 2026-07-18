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
- **Founder tuned the glass-fit to ~98%.** Baked-in defaults (normalised 0–1 of the image):
  `cx:0.499, top:0.346, neck:0.629, bot:0.889, max:0.067, nh:0.004`.
- **"Show glass edge" = 1 (outline-only mode)** currently ON: draws just the red glass-interior outline,
  NO sand, for fitting. Set it to 0 to see sand.
- **Colour pipeline is identity passthrough** (`renderer.outputColorSpace = LinearSRGBColorSpace`,
  `tex.colorSpace = NoColorSpace`) — fixed an over-saturation/warm-shift bug. Background now matches the PNG.
- **Star glitter**: GLSL, twinkles only on bluish water pixels within a sill↔horizon band, faint
  (Amount 0.6, Density 0.32). Founder wanted "old-anime star sparkle, spontaneous, faint, water only" — done.
- **Sand**: grain-textured (offscreen noise canvas overlaid 'overlay' blend = looks like sand not liquid),
  flat top surface with a shallow central funnel dip, cone pile at angle of repose, fine falling stream.

### ⏳ IMMEDIATE NEXT STEP (where we stopped)
**Get the glass outline to 100% (currently ~98%), THEN turn sand back on.** Founder's instruction: fit the
outline exactly before finalising sand. The remaining 2% is **bezier curve shape** (not slider values) in
`glassPath()` inside `hybrid.html`:
- **Bottom bulb** outline is slightly **wider** than the baked glass — pull the bottom-bulb width in a touch
  (the `cx±mx` control points in the bottom-bulb bezier), and make the very bottom rounder/lower.
- Neck crossing sits a hair high; outline stops just short of the true glass bottom.
- Use "Show glass edge" = 1 and nudge; screenshot-compare against `Empty hourglass midday.png`.

Once outline = 100%: set dbg 0, refine sand shape to match the close-up reference the founder sent (warm
muted tan, flat top with gentle centre dip, clean cone pile), confirm on GPU, then **generate the other 7
empty-hourglass phase plates** and wire the 24h crossfade + rendered sun/moon.

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
- [ ] Finish hybrid hourglass outline → sand (immediate, above).
- [ ] Generate 8 sunless empty-hourglass phase plates (founder; noon master → 7 relight edits).
- [ ] Build rendered sun/moon on a clock arc (they light the hourglass) + glitter path.
- [ ] Build 24h phase crossfade driven by local clock.
- [ ] Founder judges the whole thing on GPU: does it feel premium/alive/calm?
- [ ] THEN: write the full W1 design spec proper, and `writing-plans` → build in Astro.
- [ ] App: founder hit Publish when approved + promo-code verify lifetime→themes.
- [ ] Founder: buy domain (`sustaintimer.com` rec.), separate/shared Firebase, pick MoR (W2).
