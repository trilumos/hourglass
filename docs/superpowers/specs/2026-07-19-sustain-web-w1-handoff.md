# Sustain W1 — handoff, 2026-07-19

**The scene prototype is FINISHED and LOCKED.** Every visual is founder-approved and
baked. The next session builds the WEBSITE: the actual timer, then Astro + deploy.

Read this first, then `2026-07-18-sustain-web-w1-handoff.md` for the earlier detail.

---

## 1. Where the work is

`web-prototype/hybrid.html` — one self-contained file. Serve it and open on a **GPU
browser** (headless cannot judge shaders):

    cd web-prototype && python -m http.server 8899 --bind 127.0.0.1

Layers, bottom to top: 6 anime plates cross-faded by a 24h clock (Three.js/GLSL) ->
rendered sun + moon in that shader -> hourglass sand on a 2D canvas -> glass optics.
The empty hourglass is BAKED INTO the plates; we render only the sand.

## 2. What is locked (do not re-tune without being asked)

- **Glass outline** — 7 founder-traced nodes, `LOCKED_NODES`; `cx = 0.498850`.
- **Sand** — shape, texture, per-half colour, cone/bed separation, crookedness.
- **Pile gathering** — spreads flat, then a mound grows outward from the centre.
- **Falling sand** — ported from the APP (`lib/hourglass/hourglass_painter.dart`),
  same acceleration curve, radius/alpha shaping and ballistic impact scatter.
- **6 plates**, pixel-aligned, in `web-prototype/plates-phases/`.
- **Day cycle** — sun 06:00-18:30 (afterglow dead 20:24), moon 21:45-05:30. Never
  both up. All crossfades >= 1.3h; fastest 1.15/h.
- **Sun** — 3 keys (sunrise/midday/sunset) blended by ALTITUDE. Glow layers are
  deliberately OFF (`nearA=farA=0`); the look is one steep bright core.
- **Moon** — PAINTED texture `plates/moon-tex.png` (cropped from the founder's
  `plates/Moon.png`), `moonTexAmt 0.50`, plus a shader halo and sky spill.
- **Rim light** — dies at the wooden cap and base contacts.

## 3. Verification — run ALL SIX after touching hybrid.html

    cd web-prototype
    python check-wiring.py     # S keys, binds, unbound inputs, TDZ, shader data-blocks
    node   check-schedule.js   # sun/moon ordering, plate windows, crossfade rate
    python check-glow.py       # locked sun keys + body-is-a-mix
    node   check-bed.js        # bed tracks night -> midday
    python check-stream.py     # falling sand still matches the app's ALGORITHM
    node   check-pile.js       # gathering, smoothness, top empties exactly at 1
    # plus: extract the module and `node --check` it

**Every one of these exists because a real bug shipped.** Do not weaken them to make
a change pass — if a check fails, either the change is wrong or the check encodes an
assumption the founder has since overruled (say which).

## 4. Traps that cost hours — do not rediscover them

- **Shaders live in `<script type="x-shader/...">` DATA BLOCKS, not template
  literals.** A backtick in a GLSL comment used to truncate the whole module and
  blank the page (three times). MDN: a non-JS MIME type is "treated as a data block".
- **`const` is not hoisted.** A `bind(...F2)` above `const F2 = ...` throws at load
  and blanks the page. `node --check` CANNOT see it — it is a runtime error.
- **Blend operator decides apparent size.** An ADDITIVE sun tracked the plate behind
  it (120% of frame width on sunrise vs 1.4% on midnight). The body is a `mix`.
- **`clamp()` on an alpha creates a visible border** — it plateaus then falls, and
  that shoulder is an edge. `1 - exp(-x)` has no shoulder.
- **Procedural moons do not survive at ~60px.** Selenographic maria read as a stain;
  ring craters read as pimples. Artwork won.
- **Gradients must span the whole path.** The cone's ellipse bulges below its base
  line; ending the gradient at the line slabbed a hard dark band across it.
- **Anything read off a coarse ladder quantises.** The wall-contact height came off a
  96-rung scan and the bed filled in visible 2px steps. Bracket, then bisect.
- **Tinting the moon by sampled sky is WRONG** — measured at the moon's own position
  the night sky is deep blue (hue R-B -1.9 to -3.7); it turned the moon blue.

## 5. Working agreement that emerged

- The founder owns every look/feel call. I own correctness, and I MEASURE rather
  than guess — sampling the reference PNGs settled the sand palette, the stream
  width, the maria coverage and the sun's plate-dependence.
- **"Locked" means BOTH**: bake the value into the `S` literal AND the HTML
  `value=`, AND move the control inside `<div class="lockgrp hid">`. Automatic now.
- Verify a new check FAILS on the bug it targets before trusting it. Two checks
  this session were structurally incapable of firing.

---

## 6. NEXT SESSION — build the website

### 6.1 The timer (this is the product; it does not exist yet)
`Progress` is still a manual slider. Needed:
- real seconds driving `S.prog`; Start / Pause / Reset; completion state
- the modes the app has (Flow / Pomodoro / Custom) — check `lib/` for exact rules
- minimal session UI over the scene; the hourglass stays the hero

### 6.2 Then the site
- **Astro + React islands** (SEO), GSAP + ScrollTrigger + Lenis, Three.js for the scene
- W1 is **FREE**, zero billing code. Its jobs are RANK and CONVERT TO APP INSTALL.
- Landing page with the scroll-driven persistent hourglass; local "focused today" only
- Then: domain, deploy

### 6.3 Carry forward
- Port `hybrid.html` into the Astro component structure without losing the locked
  values — move the six check scripts with it and keep them running.
- `plates-phases/*.png` are ~2MB each; they need compressing for the web.
