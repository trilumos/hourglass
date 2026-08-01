# Sustain Web — scene plates: how they're made

> Working record of the asset pipeline, kept next to the plates it describes.
> Design context: [`../docs/superpowers/specs/2026-07-17-sustain-platform-strategy-design.md`](../docs/superpowers/specs/2026-07-17-sustain-platform-strategy-design.md)

## The idea these serve

**Timelapse.** The camera never moves. The hourglass never moves. **Only the light changes** —
sunrise → morning → noon → sunset → twilight → moonrise → night → dawn, looping.

- **Landing:** scroll advances the phase. Starts at the visitor's *real* local phase.
- **Session:** the real clock drives it, minute by minute. A 25-min Pomodoro barely shifts; a 4-hour
  evening session watches the actual sunset happen.

*The world's time passes. The hourglass measures yours. You stay still.* — that's the whole product in
one image, which is why this direction beat the photoreal and the camera-orbit versions.

## 🔑 The technique that makes it work (founder, 2026-07-17)

**Generate the hero mock WITH the hourglass first — that's the art direction. Then ask for the same
world WITHOUT it — that's the asset.**

The line that did the work:

> *"Give exact same shape of the rocks, where the hourglass is standing. But here just no hourglass."*

Referencing the existing mock is what keeps the composition; prompting a fresh scene gives a new
painting every time. **The mock is the art direction. The plate is the asset. Never generate the plate
from scratch.**

## Why no hourglass in the plate

Ours is drawn live on a canvas over the top (`hourglass.js`, ported from
`lib/hourglass/hourglass_painter.dart`) because it must track a real timer. A painted-in hourglass
would double up — and would lock its size, position and design into the image forever.

**Division of labour:** the world is generated (regenerate to change the rock); the object and all its
behaviour are code (change instantly, any value). See the spec's §6.4.2-style split.

## The prompts that worked

**Golden hour** — `plate-golden.png`

```
Give me the Anime background art in the style of Makoto Shinkai. Wide panoramic
seascape at golden hour, sun low over the ocean. Open sea to the horizon. Warm
clouds. Cliffs with cherry trees far right. Lush, painterly, highly detailed,
calm and serene.

IMPORTANT: no hourglass. no people. nothing standing on the rock.
Aspect ratio 21:9.

Give exact same shape of the rocks, where the hourglass is standing. But here
just no hourglass.
```

**Dusk** — `plate-dusk.png`

```
[the same seascape, identical composition and camera, relit at dusk — sun just
below the horizon, deep blue-violet sky, first stars, lanterns on the far cliff,
the wet rock catching the last light]

IDENTICAL composition to the previous image: the same rocky outcrop, same jagged
silhouette, same position, same framing. ONLY the light and time of day change.

Same rules: no hourglass, no people, nothing on the rock. 21:9.
```

### Prompt notes — what fails

- **"flat rock" / "rock shelf"** → produces a *tiled tidal shelf*, paved and geometric. Wrong.
- **"flat-topped boulder in the centre"** → produces a *plinth*, which makes it a product shot rather
  than a place.
- What's wanted is a **rugged sea stack**: jagged, angular, wedge-shaped, waves breaking round it, with
  a naturally level crown. Useful words: *sea stack · angular · wedge · jagged · tilted slabs · broken
  basalt · craggy*, plus the explicit negative *"not a flat shelf, not paved."*
- **No stone dais under the glass.** Keep the crown bare — the hourglass's own base is drawn in code, so
  it stays free to move, scale and tune. A dais in the plate locks all three forever.

## Aspect ratio: 16:9 (corrected 2026-07-17)

Full-screen background → `object-fit: cover`. Match the primary screen: **16:9**
laptops/desktops (a focus app is used at a desk). A 21:9 plate would crop ~25%
off the sides of a 16:9 screen — wasteful. **Generate 16:9**, but keep the rock +
hourglass zone **centred with breathing room** (sky above, sea below) so every
crop survives: ultrawide crops top/bottom, taller screens crop the sides, centred
content stays.

**Mobile portrait (9:19.5) is a W2 problem** — a landscape plate crops to a thin
strip on a phone; needs a separate portrait plate later. W1 users are on laptops.

## ⚠️ HARD CONSTRAINT: every phase must be pixel-identical in size

Current plates are **not**:

| File | Size | Aspect |
|---|---|---|
| `plate-golden.png` | 1916 × 821 | 2.334 |
| `plate-dusk.png` | 1857 × 847 | 2.192 |

**Different dimensions make the rock shift and scale during a crossfade — the world would breathe
between phases.** Fine for the prototype (we normalise and measure the drift), fatal in production.

**Lock the export resolution across every phase of the set.** Same width, same height, every time.

## 🔒 Sun/moon: RENDERED, not baked (locked 2026-07-17)

**The 8 plates carry NO sun disc, NO moon disc, NO glitter/reflection path on the
water** — only the coloured sky, clouds, sea, rocks, cliff, lanterns. We render the
sun and moon as our own bloomed objects on a clock-driven arc.

**Why this is strictly better:**
- Our sun **IS the hourglass's key light** — the visible sun and the light on the
  glass are the same object, so the hourglass belongs *by construction* (this is
  the fix to the whole "pasted on" problem).
- **Zero ghosting** — the sky *colour* crossfades (nothing to ghost); the sun
  *moves* continuously on top.
- Minute-by-minute real position; real moon phase (date-only, no location).
- The glitter path on the water is ours, tracking the sun.

Cost: sunless prompt is slightly harder ("orange sky, no visible sun"), and we
render the sun/glitter. Worth it.

**Prompt rule for all 8:** *"do NOT paint a sun or moon; no sun disc; no
sun-reflection glitter path on the water."* The AI loves painting that bright
streak — it must be excluded or it ghosts.

## (Superseded) Sun/moon baked options

Crossfading two plates with suns baked in gives **two ghost suns** dissolving through each other.
Options, to be decided by test:

1. **More plates** (~24 hourly) → the sun steps only 15°/hr, crossfades stay short.
2. **Sun/moon as separate sprites**, plates carry sky + water only → smooth continuous motion, but the
   sun's **glitter path on the water** is baked into the plate and would ghost instead.
3. **Hold + snap** → hold a plate, crossfade fast. Brief ghost, rarely witnessed.

Stylised on purpose: sun and moon **hand off cleanly** (moon rises only once the sun's light has gone).
That is *not* how the real sky behaves — the moon is up in daylight constantly — but one light source at
a time is calmer and more legible, and we already chose a fixed arc over real astronomy. **The moon's
phase stays real** (`SunCalc.getMoonIllumination()` needs only the date, no location, no permission).

## Files

| | |
|---|---|
| `plates/plate-golden.png` | golden hour — sun low, left of the rock |
| `plates/plate-dusk.png` | dusk — sun below horizon, lanterns lit, first stars |
| `hourglass.js` | the painter, ported from Dart. Faithful translation, not a lookalike. |
| `index.html` | the prototype: plates crossfading, live hourglass on the rock, sliders for everything |
