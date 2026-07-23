# Sustain Website — design decisions in progress (2026-07-22)

> **Status:** 🟡 Live design session. Companion mockups in `.superpowers/brainstorm/` (gitignored).
> Pairs with [`2026-07-22-sustain-web-w1-first-push-design.md`](2026-07-22-sustain-web-w1-first-push-design.md)
> (scope/money/theming) — this doc holds the **UI/UX + scene-schedule** decisions made after it.

---

## 1. The pivot (locked)

The Phase-1a timer UI built into `hybrid.html` was a **functional prototype only** — founder rejected it
as website UI ("just pasted basic functions on top of the theme"). Split now:

| | |
|---|---|
| **`hybrid.html`** | **The theme lab. Permanent.** Where we author + tune new theme plates (Garden, City…). Keeps its manual controls and test schedule. Untouched by website work. |
| **The website** | A **fresh Astro build.** Ports the locked scene renderer + `timer.js`, then adds its own designed UI, full-bleed scaling, and a real location-based schedule. |

**`timer.js` is the keeper** from Phase 1a — pure, DOM-free, 25 assertions green. The website imports it.

## 2. Standing bars (both mandatory, neither traded)

- **Aesthetic:** beautiful anime-style site; **target = Awwwards Site of the Month.** "Too plain" is a
  valid rejection. Anything that raises feel/mood/vibe is welcome. (Awwwards scores Design 40 · Usability
  30 · Creativity 20 · Content 10, and separately judges a11y, semantics/SEO, responsive, motion, WPO.)
- **Performance:** **FAST and beautiful** — explicitly "not like Flocus," which the founder found unusably
  slow. See §6.

## 3. Page architecture (locked)

**One shared first viewport** is the base for both the landing page and the timer:

1. **Hero** = full-bleed sea scene + persistent hourglass (sand draining ~40%) + navbar + "Sustain" title
   + a **Focus** affordance. Nothing below it yet.
2. **Click Focus** → the navbar, hero title and landing content **dissolve**; the **scene + hourglass stay
   live and are never re-mounted**. The site becomes the timer.
3. **Timer layout:** focused-time/stats panel **left**, glass **setup panel right**. All panels glass.
   Plus a **back-to-home** affordance.
4. **Session:** big, beautiful **floating Apple-glass numbers** behind/around the hourglass — "like looking
   out a window at the hourglass on the sill, with numbers floating in the air behind it."

**Hero direction: B1 — "Editorial, warm serif" (founder-chosen).** Left-weighted title block sitting in the
scene's open sky/sea negative space, so it frames the hourglass instead of covering it. Title in an elegant
warm **serif (Cormorant Garamond)**, warm cream (#f4ead6) tuned to the sky, **atmospheric scrim** (soft
left→right gradient) instead of a boxy drop shadow. Rejected: centered (A), immersive-minimal (C), and the
sans variant (B2 — "too plain").
*Note: `frontend-design` bans Inter/Roboto/Arial/Space Grotesk as overused — pair Cormorant with something
with character instead.*

## 4. Setup panel (to design)

- **App-parity modes and settings, minus Pro features** (no Focus Stamina etc.). Everything else the app's
  setup offers stays. *(This supersedes the earlier "four simplified modes" call — the web setup now mirrors
  the app's configuration depth.)*
- **Plus a theme-progression chooser** — the user picks how the scene behaves **during the session**:
  - a **fixed** time-of-day plate (day · night · twilight · sunrise · sunset · midnight…), **or**
  - **live clock** (default), **or**
  - a **dynamic arc** (e.g. "sunrise → midnight", or a full midnight→midnight cycle).
- Sound, customization and all config live here too. **One Begin button.**

## 5. Theme persistence rule (locked)

- The **hero and the setup screen always show the user's real current-region-time plate** (live), and it
  **persists** across landing → Focus → setup.
- The chosen theme mode only takes effect **when the session begins**. Default = **live clock**, i.e. the
  scene keeps transitioning with the user's real time during the session.

## 6. The location-based day/night schedule (to build — website only)

The current hardcoded schedule is **wrong** (showed twilight at 22:06). It must be anchored to the user's
**real regional sunrise/sunset**. Founder's windows, using their region as the worked example
(sunrise 06:15, sunset 19:31):

| | |
|---|---|
| **Sunrise plate** | SR−0:30 → SR+1:30 (05:45 → 07:45) |
| **Sun visibly rising** | SR → SR+1:00 (06:15 → 07:15) |
| **Sunrise → Day crossfade** | SR+1:00 → SR+1:30 (07:15 → 07:45), fully day at the end |
| **Sunset plate** | ~SS−0:30 → ~SS+0:30 (19:00 → 20:00) |
| **Twilight** | 20:00 → 21:15 |
| **Midnight + moonrise** | from 21:15 |

**Open decision:** where the location comes from (browser Geolocation opt-in vs timezone→representative
coordinates vs IP lookup), and whether moonrise uses real lunar ephemeris or is night-anchored. Sunrise/
sunset itself is pure math from lat/long + date (no API needed).

**This is new website code — `hybrid.html`'s locked schedule and `check-schedule.js` are NOT touched.**

## 7. Performance plan (the "don't be Flocus" rules)

- Scene plate is the **LCP element**: convert ~2 MB PNGs → **AVIF/WebP**, target **<200 KB**;
  `<link rel="preload">` + `fetchpriority="high"`; **never lazy-load it** (CSS background images are
  discovered late — preload is mandatory).
- **Load one plate, not six** — current phase eager, adjacent phase prefetched for the crossfade, rest never.
- **LQIP blur-up** (<5 KB inline placeholder) for instant paint, holds layout so CLS ≈ 0.
- **Astro ships zero JS by default** — static landing, scene/timer as islands.
- **Budget enforced from day one**, measured (Chrome DevTools MCP), not retrofitted: **LCP < 2.5 s, CLS ≈ 0**.

## 8. Craft techniques adopted (researched)

- **Glass:** approximate Apple Liquid Glass with `backdrop-filter: blur() saturate()` + 1px light edge +
  contrast backing + faint inner highlight. Full SVG refraction (feDisplacementMap/feTurbulence) is
  **Safari-flaky and GPU-costly** — avoid. Glass is an **accent, not the foundation**. Include a
  `prefers-reduced-transparency` solidify fallback.
- **Contrast over a moving sky:** "barrier layer" under glass or a ~30% film behind text; WCAG 4.5:1.
- **Full-bleed:** `background-size: cover` at 100vw/100vh — this is the fix for the founder's left/right gaps.
- **Focus transform:** native — `@starting-style` + `transition-behavior: allow-discrete` for the chrome
  dissolve; **View Transitions API** for the larger landing→timer change. The hourglass canvas is simply
  never touched.
- **Ma (間)** — Japanese negative space as an *active* element, not leftover. This is exactly why hero B
  works: the text sits in charged empty sky.
- **Unified grade + film grain over the whole frame** — the cheapest, biggest lever for making UI and scene
  read as one image (already in the platform spec §12 as the VFX comp trick).

## 9. Tooling installed this session

`chrome-devtools-mcp` (real perf measurement) · `context7` (current library docs — serves the latest-docs
iron rule) · `modern-web-guidance` (current web practices) · `accesslint` (WCAG 2.2 audit).
**Requires a Claude Code / VSCode restart to load.**

## 10. Immediate next steps

1. **Elevate B1** to award level — pair Cormorant with a character sans (not Inter), unified grain + grade,
   soft light bloom behind the title, refined nav/CTA/wordmark, entrance motion, deliberate ma.
2. Then, in order: **the Focus transform** → **the setup panel** → **the session numbers**.
3. Settle the **location source** for the schedule (§6).
4. Then spec + `writing-plans` for the Astro build (Phase 1b).
