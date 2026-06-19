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
8. **Depth comes from light, not boxes.** Dark: lighter warm surfaces + a subtle
   full-screen gradient (ambient light from above), no drop shadows (invisible on
   near-black) and no spotlight "glow blob". Light: white cards + soft warm
   shadow. Delineate with low-opacity hairlines, not heavy borders.
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
| background | `#15120E` (warm charcoal) |
| surface | `#1E1A15` |
| surfaceRaised | `#272118` |
| surfaceSunken | `#110E0A` |
| textPrimary | `#F2EDE4` |
| textSecondary | `#B7AF9F` |
| textMuted | `#8A8378` |
| accent | `#E8C9A0` |
| accentMuted | `#3A3024` |
| onAccent | `#1A1206` |
| hairline | `#2E2A24` |
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

**Geist (single family, SIL OFL 1.1)** — Vercel's typeface, for the minimal,
premium, productivity feel the founder wants. One clean sans for everything; no
curvy serif (Fraunces was tried and rejected as too decorative / "AI-slop").

- **Geist** — greetings, titles, body, labels, stats, buttons. Greetings are
  larger/heavier weight with slight negative tracking (editorial, not ornamental).
- Secondary/supporting lines (e.g. the rotating encouragement) are **italic** for
  a quiet voice distinction.
- Session **timer** will use Geist with **tabular figures** so digits don't
  jitter (Geist Mono is a possible future "instrument" option).

### Type scale (tuned for dark/AMOLED)

Single family **Geist** for all roles (weight carries hierarchy):

| Role | Font | Size | Line-height | Tracking | Weight |
|---|---|---|---|---|---|
| Display (rare) | Geist | 40–44 | 1.15 | -0.5 | 500 |
| Greeting / H1 | Geist | 29–34 | 1.15 | -0.3→-0.5 | 400–500 |
| Headline / H2 | Geist | 24–26 | 1.25 | -0.2 | 500–600 |
| Title / H3 | Geist | 20 | 1.3 | +0.1 | 600 |
| Subtitle | Geist | 16 | 1.4 | +0.1 | 600 |
| Body Large | Geist | 17 | 1.5 | +0.15 | 500 |
| Body | Geist | 15 | 1.45 | +0.15 | 400–500 |
| Label (buttons/chips) | Geist | 14 | 1.4 | +0.3 | 600 |
| Caption | Geist | 12–13 | 1.4 | +0.3 | 500 |
| Overline / wordmark | Geist | 11–14 | 1.4 | +3.5→+4 | 600–700 |
| Timer numerals | Geist (tabular) | 64–96 | 1.0 | -1→0 | 500–600 |

OFL obligation: ship `Geist-OFL.txt` and surface it in an in-app licenses screen;
sources recorded in `assets/fonts/CREDITS.md`.

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
  gravity-true, buttery. It is the brand's pulse, never flashy. **The falling
  sand always uses the same colour as the sand piled in the bulbs** (same
  material) — never a separate grain colour, in any theme (enforced in
  `HourglassSkin.grainColor`).
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

**Alignment:** wordmark, tagline, hourglass hero, and the bottom stats are
**centered**; the **greeting block is left-aligned** (editorial, reads well left).
The whole screen sits on a subtle **full-screen radial gradient** (ambient light
from above: `surface` → `background`) — NOT a glowing blob behind the hero (the
blob read as AI-slop and was removed).

- **Top:** wordmark "HOURGLASS" centered (Geist overline, `textMuted`, +4
  tracking, quiet) with a single settings gear at top-right (low-contrast,
  ~40px tap target). The gear opens a light/dark/system sheet.
- **Tagline:** the adaptive tagline (§ below), centered.
- **Greeting:** the varied greeting (§6) as the largest type — Geist 30, w500,
  `textPrimary`, **left-aligned**.
- **Encouragement:** rotating line under the greeting — Geist 15, *italic*,
  `textSecondary`, left-aligned, **slide-up + fade** transition (no flash).
- **Hero:** the locked hourglass, centered, on the gradient.
- **Action cluster (bottom, centered):** quiet Today / Streak stats (divider
  between), mode selector, and the prominent **Begin** (pill, `accent` /
  `onAccent`).
- Adaptive tagline: prominent for new users; recedes once they've completed a
  block.

---

## 10. Layout system

**Every screen is four vertical bands** so the app feels like one room rearranged:
1. **System band** — status bar / safe-area insets. Never draw into it (`SafeArea`).
2. **Chrome band** — minimal app bar: wordmark/back left, ≤1 quiet icon right. Recedes.
3. **Content band** — the screen's reason to exist; scrolls if needed; single shared
   left edge at the **24dp screen margin**.
4. **Action band** — the one primary action, anchored low in the thumb easy-zone,
   ≥16dp above the bottom safe inset.

**Thumb zone:** reading flows top→down, acting happens bottom→up. The primary action
lives in the bottom ~25% (full-width-ish pill); the top-right holds only a single
low-stakes control (settings). Never put the primary CTA up top.

**Grid & rhythm:** 8pt grid (4pt only for intra-component nudges). Screen margin
24dp. Spacing *semantics* (which gap means what): `8` related · `12` label↔control ·
`16` within group · `24` group↔group · `32` minor section · `48` hero isolation ·
`64+` max breathing. **Optical alignment over mathematical** (center the hourglass by
visual mass, align text to glyph edge). Single column is the default. **3–5
meaningful elements per screen.**

### Per-screen skeletons
- **Home** = editorial top (greeting/subline, left) → **centered hero on glow** →
  action cluster bottom (quiet stats · mode selector · **Begin** pill).
- **Session** = chrome nearly gone → enlarged centered hero + tabular timer +
  optional intention → one **Start/Stop** pill low, secondary action text-only.
- **Setup** = stacked single-column groups (intention field · duration capsules ·
  soundscape), 24dp apart, left-aligned → sticky **Begin** pill at bottom.
- **Stats** = the *only* screen with a grid (bento) and no action band: a large
  headline-metric tile + asymmetric 2-col tiles (bigger tile = more important).
- **Settings** = pure single-column list, hairline-separated rows (not cards),
  section labels + 32dp gaps; destructive items mid-list, never in the thumb zone.

**Bento/cards stance:** bento for **Stats only**. Home & Session are single-focus
(no cards). Setup uses fields/rows; Settings uses hairline rows. Never a card in a
card.

---

## 11. Shape & form language

**"Curves carry the calm; the hourglass sets the curve."** Rounded forms read as
calm/human and are processed faster; sharp corners read as tension. We lean rounded,
but *deliberately tuned*, not bubbly.

1. **The hourglass silhouette is the master shape** — its pinched-waist opposed
   curve gives the UI its vocabulary: smooth curvature, no hard angles, the pill as
   signature.
2. **Pill = primary action + live progress only** (Begin/Start-Stop, timer ring) —
   the shape equivalent of "accent is punctuation."
3. **Capsule (small pill) = a choice** (duration/soundscape chips) — quieter, no
   accent fill.
4. **Soft-rect containers** — `sm 12` fields/chips · `md 16` default surface ·
   `lg 20` large tiles/sheets/hero plates. **0px corners forbidden.**
5. **Circle = singular/live/ambient** — settings tap target, status dots, radial
   progress (not for actions).
6. **One curvature family per screen** — never drop a sharp element into a rounded
   layout.

---

## 12. Interaction principles (UX laws, applied)

- **Hick's** — one primary action per screen; setup choices ≤4 preset chips behind a
  sheet, never a grid of options on launch.
- **Fitts's** — the hero is large and thumb-reachable; the CTA is ≥56dp in the
  bottom zone; secondary controls are small and cornered.
- **Tesler's / smart defaults** — the app absorbs complexity: last-used duration
  pre-selected, auto-resume, no required config. Happy path to focus = **one tap**.
- **Doherty** — every tap responds <100ms; the flip starts on touch-down, not
  release; no spinner for local (offline) actions.
- **Peak-End** — spend the polish budget on the two highest-ROI moments: entering
  flow (the peak) and the **completion** screen (the end). Payload first
  ("You focused 25 minutes"), forward action last.
- **Zeigarnik / Goal-Gradient** — an interrupted session offers a quiet "Resume —
  4:12 left"; the falling sand *is* felt progress.
- **Recognition over recall** — pre-highlight prior choices; show presets/recents;
  never make the user type or remember.
- **Progressive disclosure** — first run shows only "begin"; customization, stats,
  advanced settings live one layer down.
- **Aesthetic-Usability caution** — our polish buys goodwill but can *mask*
  friction; test flows on their own merit.

---

## 13. Workflow & screen states

**Session ritual arc** (each a distinct calm state): set intention (lightweight,
skippable, ceremonial) → flip (one gesture, instant feedback) → struggle/flow
(immersive, minimal chrome) → **complete** (serene resolution, gentle haptic,
calm-celebratory — never confetti) → recover (soft optional next step).

**Good vs bad friction:** delete setup friction; **keep** the brief
intention/breath moment — it's a feature. **Confirmation vs undo:** prefer
undo/resume over "Are you sure?"; reserve modals for truly irreversible actions.
**Interruption:** persist session state on every interruption; offer low-friction
resume, never force restart.

**Six states every screen designs for:**
- **Empty** — never blank; teach + invite. **New user → never show "0m / 0 days"**
  (demotivating); show warm framing ("Your focus story begins with one flip").
- **Loading** — offline v1 ≈ no real loading; prefer instant transitions over
  spinners; calm low-contrast shimmer only if unavoidable.
- **Error** — plain kind language, recovery action inline, no codes; treat each
  error as a design failure to eliminate.
- **Success** — completion is the flagship; smaller successes get quiet inline
  confirmation, never an interrupting toast.
- **First-use** — only "begin"; one gentle coach hint that fades.
- **Offline** — the default, not an error; never surface "no connection" in v1.

---

## 14. Navigation model

**Single-screen hub, NOT bottom navigation.** Hourglass's destinations (Focus hub,
Stats, Settings) aren't co-equal; a persistent bottom bar would add chrome and
dilute the single action. Flow: **Home hub** → Setup (bottom sheet) → Session
(full-screen takeover) → Completion → Recovery → back to hub. Stats reached via a
small deliberate affordance; Settings via the corner gear. Honor platform
back/dismiss (Android edge-back, swipe-down to dismiss sheets). The session
takeover must always show a calm visible exit — never trap the user.

---

## 15. Iconography

**Interim: Flutter built-in Material icons (rounded variants, e.g.
`Icons.settings_outlined`, `Icons.check_rounded`).** Plain `IconData`, always
compatible, rounded enough to fit. **Phosphor was the chosen set but is currently
deferred** — `phosphor_flutter` 2.1.0 subclasses `IconData`, which became a
`final` class in our Flutter version, so it won't compile. Revisit when Phosphor
ships a compatible release, or adopt `material_symbols_icons` (Rounded, OFL) as
the branded set. Either way the *rules* hold regardless of set:

Rounded style to match "warm precision." Outline by default, filled only for
selected/active states. Default icon **24dp** (20 dense, 28 emphasis), always
inside a **≥48dp** touch target. Color via tokens (`textSecondary` resting,
`accent`/`textPrimary` active). Icons are chrome — they recede. One weight per
screen.

---

## 16. Shape & layout consistency tokens

`const`, alongside `HgRadius`/`HgSpacing` (don't vary per skin):

- **Radius:** `sm 12` (fields/chips) · `md 16` (containers) · `lg 20`
  (tiles/sheets) · `pill 999` (primary action, live progress, capsules, circular
  targets). Pill reserved for primary/live + small single-select capsules only.
- **Touch targets:** every interactive hit area ≥ **48dp** regardless of visual size.
- **Icon sizes:** 20 / 24 (default) / 28.
- **Layout:** screen margin 24 · bento tile gap 12 · tile padding 16 · action
  clearance ≥16 from bottom inset.
- **Coherence rules:** one curvature family per screen · pill=primary/live,
  capsule=choice, soft-rect=container · ≥48dp hit areas · one shared left edge (24),
  center only hero + the single bottom CTA · primary action always in the bottom
  thumb zone, reading content up top.
