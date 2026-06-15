# Hourglass — Design Language

> The single source of truth for how Hourglass looks, moves, and speaks. Every
> screen and component is built to this. It is **ours** — synthesized from the
> best of the category (Headspace, Calm, Flow, Vercel/Geist, Material 3, Apple
> HIG), then warmed and shaped into our own identity. Research that informs it
> lives in `docs/superpowers/specs/` and the project memory.

## The ethos: **Warm Precision**

Engineer the structure like Vercel — token discipline, contrast-driven
hierarchy, generous grid, nothing arbitrary. Then **warm every surface
decision** — warm near-black instead of clinical black, a sand accent used like
punctuation, softened corners, an editorial serif voice, and calm pacing. One
living hero (the hourglass) is the soul; everything else gets quiet so the user's
focus — and their own progress — is the star.

Three words: **calm, warm, exact.**

---

## 1. Principles (govern every screen)

1. **One clear primary action per screen.** Begin, Start/Stop, Save. Everything
   else is visibly secondary. Never two competing CTAs.
2. **Hierarchy by size, weight, and contrast — not by adding elements.** Decide
   primary/secondary/tertiary, then differentiate with those levers.
3. **Emphasize by de-emphasizing.** The primary reads as primary because the
   chrome around it is muted — not because it shouts.
4. **Curate, don't empty.** Calm density = a few intentional elements with air
   around them; never a barren screen that hides the action.
5. **One shared left edge, on the grid.** Default to left alignment; reserve
   centering for short, isolated, symmetric things (the hero, a single button).
6. **Whitespace is the premium signal.** Start over-spaced, then tighten.
7. **Defer to content; keep chrome quiet.** Wordmark, nav, labels recede.
8. **Depth comes from light, not boxes.** Dark: lighter warm surfaces + soft
   glow (no drop shadows — they're invisible on near-black). Light: white cards +
   soft warm shadow. Delineate with low-opacity hairlines, not heavy borders.
9. **Accent is punctuation.** Sand appears on the primary action, live progress,
   and the hero glow — not on every interactive element, never as decoration.
10. **Motion is meaning.** Animate transitions, state changes, and the one
    ambient hero (falling sand). Never animate for decoration. No bounce.
11. **Honor the system.** Follow OS light/dark, respect Reduce Motion (fade /
    instant fallback), meet contrast minimums, support larger text.
12. **No fake science, no overclaim.** Copy is honest (brand constraint): no
    invented stats, no misattributed quotes.

---

## 2. Color

### Model: themes × modes

- A **mode** is `light | dark | system` (brightness; defaults to following the OS).
- A **theme/skin** is a named identity. **Sand** is the default; future
  collectible skins (Obsidian, Sage, …) are added as data, no widget changes.
- **Every theme ships BOTH a light and a dark variant.** The two choices are
  orthogonal and compose cleanly ("I use Sage" × "I'm in light right now").

### Semantic tokens (the only thing widgets read)

`backdrop` · `background` · `surface` · `surfaceRaised` · `surfaceSunken` ·
`textPrimary` · `textSecondary` · `textMuted` · `accent` · `accentMuted` ·
`onAccent` · `hairline` · `glow` · `focusRing` · `scrim` ·
`success` / `warning` / `danger`.

Widgets never use raw hex. Each theme/mode remaps these names to its palette.

### Sand — Dark (default; warm near-black, never pure black for surfaces)

| Token | Hex |
|---|---|
| backdrop | `#000000` (AMOLED outermost only) |
| background | `#0A0907` |
| surface | `#131210` |
| surfaceRaised | `#1C1A16` |
| surfaceSunken | `#0E0D0B` |
| textPrimary | `#F2EDE4` |
| textSecondary | `#B7AF9F` |
| textMuted | `#8A8378` |
| accent | `#E8C9A0` |
| accentMuted | `#3A3024` |
| onAccent | `#1A1206` |
| hairline | `#272521` |
| glow | `#1FE8C9A0` (sand @ ~12%) |
| focusRing | `#E8C9A0` |
| scrim | `#B3000000` |

### Sand — Light (warm paper, not stark white; accent darkened to pass contrast)

| Token | Hex |
|---|---|
| backdrop | `#F2ECE1` |
| background | `#F7F3EC` |
| surface | `#FFFFFF` |
| surfaceRaised | `#FFFFFF` (+ soft warm shadow) |
| surfaceSunken | `#EFE8DB` |
| textPrimary | `#1F1B14` |
| textSecondary | `#5A5246` |
| textMuted | `#8A8073` |
| accent | `#B07A3C` (darkened sand) |
| accentMuted | `#EBDCC4` |
| onAccent | `#FFFFFF` |
| hairline | `#E3DACB` |
| glow | `#14B07A3C` (~8%) |
| focusRing | `#B07A3C` |
| scrim | `#40000000` |

**Text emphasis tiers** (off-white in dark, warm near-black in light): primary
~90%, secondary ~60%, muted ~40%. Never pure `#FFF` or `#000` for text.

---

## 3. Typography

**Fraunces (serif display) + Inter (sans UI/body)** — both SIL OFL 1.1, safe to
bundle in a commercial app. The serif/sans split gives premium hierarchy for free
and lets greetings feel editorial and human while the sans does the quiet work.

- **Fraunces** — greetings, section titles, the occasional hero line. Carries the
  warm-cream accent in dark. Never below ~20sp (its hairlines vanish on black).
- **Inter** — all body, labels, stats, buttons, settings. For the session
  **timer**, use Inter with **tabular figures** (`FontFeature.tabularFigures()`)
  so digits don't jitter. (Geist Mono is a possible future "instrument" option
  for the timer only — not adopted now; it reads too technical for our warmth.)

### Type scale (tuned for dark/AMOLED)

| Role | Font | Size | Line-height | Tracking | Weight |
|---|---|---|---|---|---|
| Display (rare) | Fraunces | 40–44 | 1.15 | 0 | 400 |
| Greeting / H1 | Fraunces | 30–34 | 1.2 | 0 | 400–500 |
| Headline / H2 | Fraunces | 24–26 | 1.25 | 0 | 500 |
| Title / H3 | Inter | 20 | 1.3 | +0.1 | 600 |
| Subtitle | Inter | 16 | 1.4 | +0.1 | 600 |
| Body Large | Inter | 17 | 1.5 | +0.15 | 500 |
| Body | Inter | 15 | 1.45 | +0.15 | 500 |
| Label (buttons/chips) | Inter | 14 | 1.4 | +0.3 | 600 |
| Caption | Inter | 12–13 | 1.4 | +0.3 | 500 |
| Overline / wordmark | Inter | 11 | 1.4 | +1.0 | 600 |
| Timer numerals | Inter (tabular) | 64–96 | 1.0 | -1→0 | 500–600 |

OFL obligation: ship each font's `OFL.txt` and surface it in an in-app licenses
screen; record sources in `assets/fonts/CREDITS.md`.

---

## 4. Spacing, radius, elevation

- **Spacing — 8pt grid, closed set:** `4, 8, 12, 16, 24, 32, 48, 64, 96`. No
  arbitrary values.
- **Radius — softened (warm, not Vercel-sharp):** `sm 12`, `md 16`, `lg 20`,
  `pill 999`. Primary buttons and the timer ring are pills.
- **Elevation rule:** *dark → elevation is a lighter warm surface (no shadow);
  light → elevation is a white surface + soft warm shadow.* One rule, both modes
  premium. Steps: flat (background) · raised (surface) · overlay (surfaceRaised
  +shadow in light) · modal (surfaceRaised + scrim).

---

## 5. Motion

Calm and exact. Decelerate in, accelerate out, faster out than in. No bounce, no
elastic, no decorative animation.

- instant `120ms` · fast `200ms` · medium `400ms` · slow `700ms`.
- enter `cubic(0,0,0.2,1)` · exit `cubic(0.4,0,1,1)` · calm/emphasized
  `cubic(0.2,0,0,1)`.
- UI transitions/feedback: 150–350ms. Cross-fades, never slides, for text swaps.
- The **one slow signature** is the falling sand in the hero — continuous,
  gravity-true, buttery. It is the brand's pulse, never flashy.
- Reduce Motion → cross-fade or instant; never lose information a transition
  carried.

---

## 6. Voice & greetings

Tone: warm, present, encouraging, never preachy or hustle-y. Short. The home
greeting is the personality — varied like a thoughtful companion (the Claude
new-chat feel), not a fixed clock label.

**Greeting pool — chosen fresh each open, never repeating in a row:**

- **Time-aware:** "Good morning" · "Good afternoon" · "Good evening" ·
  late-night: "Burning the midnight oil" / "The quiet hours".
- **Returning / any-time:** "Welcome back" · "Back at it" · "Good to see you" ·
  "Ready when you are" · "Let's get focused" · "Pick up where you left off" ·
  "Keep going".
- **New user (no completed blocks):** "Welcome" · "Let's begin" · "Your first
  block awaits".
- Streak-aware (optional, when streak ≥ 2): "Keep the streak alive".

(When onboarding lands in Plan 3 and we know a name, the greeting appends it:
"Good evening, Maya.")

**Encouragement sub-line** — one quiet rotating teaching beneath the greeting,
focus/flow fused with the value of time, segmented by time of day. Cross-fades
slowly (~15s). All original lines for now (no attribution risk); verified
attributed quotes may be added later. **No fabricated stats / fake science.**

---

## 7. Anti-patterns (forbidden — the "generic / AI-looking" tells)

Purple→blue/cyan gradients · gradient text · glassmorphism everywhere ·
cards-nested-in-cards · center-everything · many accent colors · drop shadows on
dark · emoji as icons · bounce/elastic motion · default font with no hierarchy ·
pure `#000`/`#FFF` surfaces · sharp 0px corners (too cold for us) · dense
dashboard layouts.

---

## 8. Implementation (Flutter)

- Tokens as a `ThemeExtension<HgTokens>` carrying the full semantic set; a thin
  `ColorScheme` underneath for Material defaults. Widgets read
  `context.hg.<token>` (a `BuildContext` extension).
- `HgTheme { id, name, HgTokens light, HgTokens dark }`; `HgThemes.all` is the
  catalog. `buildTheme(tokens, brightness)` produces `ThemeData`.
- `ThemeController` (Riverpod `Notifier`) holds `{ themeId, ThemeMode }`,
  persisted (SharedPreferences); root `MaterialApp` uses `theme` + `darkTheme` +
  `themeMode`. `ThemeMode.system` follows the OS for free; `HgTokens.lerp`
  animates switches.
- `HgSpacing` / `HgRadius` / `HgMotion` / `HgElevation` stay `const` (they don't
  vary per skin). Only theme-varying values live in `HgTokens`.
- Migration from the current flat `HgColors`: add tokens alongside, migrate
  widgets file-by-file to `context.hg`, delete `HgColors` last. Keep the app
  green at every step. Golden-test home in Sand-dark and Sand-light.

---

## 9. Home screen — applied spec (top zone)

- **Header row:** wordmark "HOURGLASS" top-left (Inter overline, `textMuted`,
  +1.0 tracking, quiet); a single settings gear top-right (one icon, low-contrast,
  ~40px tap target, faint hairline rim). All on the 24px screen margin / shared
  left edge.
- **Greeting:** the varied greeting (§6) as the largest type — Fraunces 30–34,
  `accent` (warm cream in dark), left-aligned.
- **Subtitle:** the rotating encouragement — Inter Body @ `textSecondary`,
  left-aligned, cross-fade.
- **Hero:** the locked hourglass centered, resting on the `glow`.
- **Action cluster (bottom):** quiet Today / Streak stats, mode selector, and the
  prominent **Begin** (pill, `accent` / `onAccent`).
- Adaptive tagline: prominent for new users; recedes once they've completed a
  block.
