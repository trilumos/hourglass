# Sustain Web — Hero + Glass System handoff (2026-07-23)

> **Read this first**, then [`2026-07-22-website-design-decisions.md`](2026-07-22-website-design-decisions.md)
> (page architecture, money model, schedule) and
> [`2026-07-22-sustain-web-w1-first-push-design.md`](2026-07-22-sustain-web-w1-first-push-design.md) (W1 scope).
>
> **Status:** hero **LOCKED (v22)** after ~22 mock iterations. Not yet built in code.
> Generator: **`web-prototype/gen_hero_mockup.py`** (repo-synced; scratchpad twin `gen_hero_v9.py`).
> Companion mockups are in `.superpowers/brainstorm/` (gitignored, ephemeral — regenerate from the script).
>
> **Type stack (locked):** **Cormorant Garamond** display heading · **Jost** numbers + UI
> (`weight 200, tabular-nums lining-nums`) · **Newsreader** italic quote (`weight 340, opsz 60, ~23px,
> line-height 1.52` — elegant = light + airy, chosen over Fraunces/Playfair/Baskerville on an on-scene test).

---

## 1. The standing bars (do not trade one for the other)

- **Aesthetic:** beautiful anime-style site, target **Awwwards Site of the Month**. "Too plain" is a valid
  rejection. Anything that raises feel/mood/vibe is welcome.
- **Performance:** **FAST and beautiful** — explicitly "not like Flocus" (founder found it unusably slow).
- **HD:** plates must not look blurry. **Founder action: regenerate plates at ≥2560px (ideally 3840px)** —
  current ~1920px plates are upscaled on a 1440p/4K monitor, which is the softness the founder sees.

## 2. The hero — converged design

**Layout (golden-ratio, measured):** the hourglass assembly occupies **x 0.390–0.610**; the frame's golden
sections are **0.382 / 0.618**. So the plate is already a three-panel golden composition.

| Zone | Content |
|---|---|
| **Nav** (top) | `sustain` wordmark left · About · Themes · Get the app · ⚙ right. Uses `.glass-quiet`. |
| **LEFT φ-band** | **Sustain** (Cormorant, ~110–126px) → *"Time flows. You focus."* (italic tagline) → one-line clarity → **Begin Focus** (glass) → **Google Play** badge (glass, real 4-colour logo). |
| **CENTRE** | The hourglass. **Text is hard-capped left of x=0.34** so nothing ever crosses the glass. |
| **RIGHT φ-band** | **BOXLESS** (no glass here): Focused Today → `2h 45m` → glass progress bar → "Daily goal 8h" → divider → quote. |
| **Bottom** | Ambient dock (`.glass-liquid`) + centred scroll cue. No named phase rail. |

**Locked founder calls along the way:**
- Hero direction **B (editorial, left-weighted)** over centred/immersive; **warm serif (Cormorant)** over sans
  ("too plain"). Sans dropped also because `frontend-design` bans Inter/Roboto/Arial/Space Grotesk.
- **Keep the big "Sustain" title** + tagline beneath (do not replace with headline-only).
- **Right panel is boxless.** Glass there was only ever a testbed for the recipe.
- **No fabricated stats, no App Store badge** (Android-only — overselling trap from the platform spec).
- Numbers were switched **off Cormorant** ("ughh") → **Jost, weight 200, `tabular-nums lining-nums`**.
- **Nothing may start further left than "Sustain."** Fixed with `margin-left:-.045em` on the display heading
  (compensates the large glyph's side-bearing; `hanging-punctuation` is Safari-only so unusable).
- **Subheadline must be ONE line** — two lines reads as a paragraph and kills hero scanning
  (research: subheadline 15–25 words max, headline → subheadline → CTA sequence).

## 3. The glass system — LOCKED, reuse everywhere

Derived by analysing 9 liquid-glass examples in [`glass UI examples/`](../../../glass%20UI%20examples/) plus the
principle that **the hourglass itself is our glass reference** ("One Glass" — the UI is cut from the same
material as the hero object). That's why the glass is **clear, not frosted**: the hourglass shows the scene
sharply through it with bright specular edges.

```css
/* .glass — panels. Cheap, universal, Safari-safe. */
background: linear-gradient(140deg, rgba(255,255,255,.08), rgba(255,255,255,.025));
backdrop-filter: blur(5px);
border: 1px solid rgba(255,255,255,.18);
box-shadow: 0 16px 44px rgba(0,0,0,.22),
            inset 0 1px 0 rgba(255,255,255,.26), inset 0 -1px 0 rgba(255,255,255,.05);
/* + ::before specular sheen: linear-gradient(138deg, rgba(255,255,255,.10), transparent 46%) */

/* .glass-liquid — SMALL elements only (buttons, dock, chips). Real SVG refraction. */
/* .glass + ::before { backdrop-filter: blur(2px); filter: url(#glassdist); z-index:-1 }
   ::after { box-shadow: inset 1px 1px 0 rgba(255,255,255,.38), inset -1px -1px 1px rgba(255,255,255,.16) } */

/* .glass-quiet — navbar + during-session panels. */
background: rgba(255,255,255,.05); backdrop-filter: blur(8px);
border: 1px solid rgba(255,255,255,.13); box-shadow: inset 0 1px 0 rgba(255,255,255,.16);
```

The shared SVG filter (from ex 9 / lucasromerodb):
```html
<filter id="glassdist"><feTurbulence type="fractalNoise" baseFrequency="0.006 0.006" numOctaves="1" seed="12" result="t"/>
<feGaussianBlur in="t" stdDeviation="2" result="s"/>
<feDisplacementMap in="SourceGraphic" in2="s" scale="52" xChannelSelector="R" yChannelSelector="G"/></filter>
```

**Hard rules learned the hard way:**
- **Dark-tinted glass is ugly** — it muddies the scene. Glass must be **light**.
- **Heavy blur (14–26px) is wrong** — the scene must read *through* the glass. 5px panels / 2px liquid.
- **Heavy `saturate()` turns the panel into a coloured slab.** Use a gentle `brightness()` instead if contrast is needed.
- **Bright thick rims make glass look like a slab.** Keep the rim thin/subtle.
- **`feDisplacementMap` is affordable on SMALL elements only** — never on large panels over a live scene.
  It degrades gracefully to plain frost in Safari (Safari can't do `backdrop-filter: url()`).
- **⚠️ Perf law:** `backdrop-filter` re-computes every frame the layer behind it repaints. **Keep the plate a
  static `<img>`** and confine animation to the centre (sand) so side panels stay cached and cheap.

## 4. Text legibility over the scene — the system

1. **Per-glyph text halo — LOCKED, scene stays 100% sharp** (v16, `e5357f6`). A layered `text-shadow`
   token on `.hero`:
   ```css
   --halo:        0 0 1px rgba(6,8,16,.7), 0 0 2px rgba(6,8,16,.58), 0 0 4px rgba(6,8,16,.42),
                  0 0 8px rgba(6,8,16,.26), 0 1px 2px rgba(6,8,16,.55);
   --halo-strong: /* same, higher alphas + a 15px layer */  /* quote + description (busiest backdrops) */
   ```
   Applied to every scene-overlaid text element (`text-shadow: var(--halo)`). If a spot still washes,
   the only knob is `--halo-strong`'s alphas — no structural change.
   **⚠️ THE BIG LESSON — do NOT re-attempt scene blur.** We burned ~6 rounds trying `backdrop-filter`
   halos to soften the busy backdrop behind text. **It cannot work:** `backdrop-filter` blurs a
   *rectangle*, so behind text the blur only ever shows *in the gaps between glyphs*, never hugging the
   letters — and any masked region leaves a visible seam/"box", or blurs the scene the founder explicitly
   wants sharp (HD goal). Rejected in order: 7px T-zones (*"TOO TOO MUCH"*), 3px radial region halos (box
   around Sustain), per-block ellipses (blurred the gaps, skipped the quote). **The answer is
   `text-shadow` (follows glyph outlines) — full stop.** If a *scene* softening is ever truly wanted, bake
   a subtle darken into the plate itself, never a runtime blur.
2. **Per-glyph dark halo** — `text-shadow: 0 0 2px rgba(5,7,15,.66), 0 1px 3px …, 0 3px 24px …`. The tight
   `0 0 2px` contour is what makes **light text readable on light backgrounds** with no visible box.
3. **Cinematic vignette** — darkens edges/corners where UI lives, keeps centre real.
4. **`text-wrap: pretty/balance`** + `max-width`, so lines don't sprawl into busy areas.
5. **Unified film grain + colour grade over the whole frame** so UI and painting read as one image.

## 5. Still open / next steps (in order)

1. ~~Founder verdict on v11~~ — **DONE. Hero LOCKED at v22** (halo legibility + baked outward-feathered
   blur boxes, Jost numbers, glass progress bar, one-line subheadline, left alignment, Newsreader quote).
2. **Per-phase adaptive scrim** — measured left-third luminance: **midnight 22 · sunset 99 · midday 129**
   (~6× spread). A scrim tuned on sunset breaks at midday. Fix: measure each plate **once at build time**,
   bake a per-phase `--scrim` into the theme JSON. Slots into the "theme = plates + config" contract.
3. **The Focus transform** — nav + title dissolve, scene + hourglass persist (never re-mounted).
   Native: `@starting-style` + `transition-behavior: allow-discrete`, View Transitions API for the bigger
   state change.
4. **Setup panel** — app-parity modes minus Pro, theme-progression chooser (fixed plate / live clock /
   dynamic arc), ambient dock. **Uses the locked glass tokens — no re-tuning.**
5. **Session view** — big floating Apple-glass numbers behind the hourglass; `.glass-quiet` panels.
6. **Location-based sunrise/sunset schedule** (source still undecided: geolocation opt-in vs
   timezone→coords vs IP). Windows are specified in the 07-22 decisions doc §6.
7. Then **spec + `writing-plans`** for Phase 1b (the Astro build).

## 6. State of the code

- Branch **`web-w1-timer`**, 8 commits. `web-prototype/timer.js` (pure engine, **25 assertions green** via
  `check-timer.js`) + wired into `hybrid.html`. **`timer.js` is the keeper**; the hybrid timer UI was a
  prototype and is NOT the website UI.
- **`hybrid.html` = the theme lab, permanently.** Where new theme plates are authored/tuned. The website is
  a separate fresh Astro build that ports the locked scene + `timer.js`.
- Tooling installed: `chrome-devtools-mcp` (perf), `context7` (current docs), `modern-web-guidance`,
  `accesslint` (WCAG 2.2).
