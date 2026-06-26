# Sustain — Brand & Design Philosophy

*A reference for anyone (or any tool) creating visuals for Sustain. It describes
how the app looks, feels, and speaks — its design DNA — not how to lay out any
specific asset.*

---

## 1. What Sustain is

A **focus-training** app — positioned as *"Train your focus like an athlete."* You
do deliberate blocks of deep focus, then recover, and your focus grows over time.

It is **not** a busy productivity dashboard or a flashy timer. It is a **calm,
premium, honest instrument** for deep work — quiet, warm, and beautiful, so the
user's attention (and their own progress) is the star, never the UI.

## 2. The aesthetic in three words: **calm · warm · exact**

The ethos is **"Warm Precision."**

- **Precision:** engineered structure — disciplined spacing on a grid, hierarchy
  built from size/weight/contrast (never clutter), generous whitespace, nothing
  arbitrary.
- **Warmth:** every surface decision is warmed — a warm near-black instead of
  clinical black, a **golden-sand accent used like punctuation**, softened
  corners, calm pacing.

Premium comes from **restraint and space**, not from effects.

## 3. The soul: the hourglass

The signature motif is a **minimalist hourglass with fine, falling golden sand**.
It is the one living element; everything else stays quiet around it. Sand = time,
focus, and material made visible.

- Style: clean, elegant, slightly glassy outline; a **fine, dense spray of small
  round grains** falling through the neck — not thick streaks.
- **The falling sand and the piled sand are always the exact same colour** (one
  material) — never two different tones.
- It feels like a gentle, gravity-true, continuous fall — the brand's slow pulse.

## 4. Colour

### Default identity — **"Sand"**: warm, golden, earthy. Ships in **dark (default)** and **light**.

**Sand — Dark (the hero look):**

| Role | Hex |
|---|---|
| Background (warm golden-dark, never pure black) | `#161009` |
| Surface | `#211913` |
| Raised surface | `#2C2218` |
| Text — primary (warm off-white) | `#F5EFE1` |
| Text — secondary | `#C0B299` |
| Text — muted | `#8E8167` |
| **Accent — warm gold (punctuation only)** | `#F0C85C` |
| On-accent (text on gold) | `#1A1204` |
| Hairline (subtle separators) | `#342A1C` |
| Falling/piled sand | `#EACA78` |
| Ambient background gradient | `#4E3F27` → `#21190E` → `#140F08` |

**Sand — Light (warm paper, not stark white):**

| Role | Hex |
|---|---|
| Background (warm paper) | `#FAF2DF` |
| Surface | `#FFFFFF` |
| Text — primary (warm near-black) | `#221A0E` |
| Text — secondary | `#5E5340` |
| **Accent — deep gold** | `#BA8A14` |
| Hairline | `#EBDDBA` |
| Ambient background gradient | `#F1DEB0` → `#F6EBCC` → `#FAF2DF` |

**Colour rules**
- **Accent is punctuation.** The gold appears on the primary action, live
  progress, and the hero — *not* on every element, never as decoration.
- **Never pure `#000` or `#FFF`** for surfaces or text. Warm near-black, warm
  off-white. Text emphasis tiers ≈ 90 % / 60 % / 40 %.
- **Depth comes from light, not boxes.** Dark = slightly lighter warm surfaces + a
  soft top-down ambient gradient (no drop shadows, no glowing "blob" behind the
  hero). Light = white cards + a soft warm shadow. Separate with **low-opacity
  hairlines**, not heavy borders.

### The theme system — one mood per skin

Sand is the free default. There are **9 premium themes**, each a distinct mood,
each shipping its own light + dark. The structure never changes — only the palette:

| Theme | Mood / accent |
|---|---|
| **Sand** (default) | warm golden sand |
| Obsidian | deep blue-black · electric-blue accent |
| Sage | dark forest green · bright sage accent |
| Rosé | deep burgundy-rose · blush-pink accent |
| Indigo | midnight indigo · violet-blue accent |
| Dusk | soft purple-dark · orchid accent |
| Tide | near-black teal · cyan-teal accent |
| Noir | almost-pure black · molten-gold accent |
| Mocha | deep espresso brown · warm-amber accent |
| **Aurora** (flagship) | cosmic dark · teal aurora accent + full-spectrum shimmer |

The **Sand** identity is the face of the brand; the others are collectible moods.

## 5. Typography

**Geist** — a single, clean, premium sans (Vercel's typeface). One family for
everything; **weight and size carry hierarchy**, not extra fonts.

- Feel: minimal, precise, editorial. Headings use slight **negative tracking**;
  small labels/wordmarks use **wide positive tracking** (quiet, spaced overline).
- The wordmark **"Sustain"** is set in Geist.
- Numbers (timers/stats) use **tabular figures** so digits don't jitter.
- **No serif, no script, no decorative or "default-looking" fonts.**

## 6. Shape & form

*"Curves carry the calm; the hourglass sets the curve."*

- Rounded, but **deliberately tuned — not bubbly**. Smooth curvature, no hard
  angles. **0px sharp corners are forbidden** (too cold).
- **Pill** (fully rounded) = the primary action and live progress only — the shape
  equivalent of "accent is punctuation."
- **Capsule** (small pill) = a single choice/chip.
- **Soft-rounded rectangles** = containers and tiles (gentle radii).
- **One curvature family per surface** — never drop a sharp element into a rounded
  layout.

## 7. Space & composition

- **Whitespace is the premium signal.** Start over-spaced, then tighten. Generous
  air around few, intentional elements.
- **One clear focal point.** Hierarchy by emphasis *and* de-emphasis — the focus
  reads as primary because everything around it is quiet.
- **Curate, don't clutter — and never barren.** Calm density: a few meaningful
  elements with room to breathe.
- Composition leans to a **shared left edge** for text, with the **hero and a
  single primary action centred**. Chrome (wordmarks, labels) recedes.

## 8. Motion & energy (the feel, even in stills)

Calm and exact — decelerate in, accelerate out, **no bounce, no elastic, no
decorative motion.** The single slow signature is the **falling sand**: continuous,
gravity-true, buttery. For static imagery, evoke **stillness + a gentle, quiet
fall** — never frenetic or sparkly.

## 9. Voice & tone

Warm, present, encouraging — **never preachy, hustle-y, or salesy**. Short, human
sentences. **Honest by constraint:** no fabricated stats, no fake science, no
manufactured guilt, **no emoji**, no dark patterns. The brand is the calm,
trustworthy companion — think a thoughtful coach, not a hype machine.

## 10. Anti-patterns — the "generic / AI-looking" tells to avoid

These instantly break the brand:

- Purple→blue / cyan tech-gradients; **gradient text**; rainbow or many accent
  colours.
- Glassmorphism everywhere; cards nested in cards; dense dashboard grids.
- Centre-everything layouts; drop shadows on dark backgrounds; a glowing "blob"
  behind the subject.
- **Emoji as icons**; bounce / elastic motion; sparkles, confetti, lens flares.
- Pure `#000` / `#FFF`; cold pure-grey neutrals (ours are warm); sharp 0px corners.
- A loud, busy, "feature-packed" feeling. Sustain is the opposite of loud.

## 11. The feeling, in one breath

> A warm, golden-lit calm. A single elegant hourglass, sand quietly falling. Deep,
> warm near-black (or soft warm paper), generous space, one whisper of gold. Quiet,
> premium, exact — the visual equivalent of a deep breath before focused work.
