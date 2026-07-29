# Sustain Web — MASTER SPEC (single source of truth)

> **Status:** 🟢 **CANONICAL / MUST-READ.** This is the one doc that holds the **full context** of the
> Sustain **web** version — purpose, architecture, features, workflow, decisions, current build state, and
> the remaining path to production. It **consolidates** every prior web spec (listed in §20). Read this
> **first** before any web work.
>
> **Standing rule (also in `CLAUDE.md` + memory):** For any web task, read this spec first. **Before asking
> the founder a question, check here and the prior specs (§20) — if it's already decided, apply it and say
> "clarified from `<spec>`"; only ask when it's genuinely unaddressed.**
>
> **This is a LIVING document.** Anything decided, changed, or completed about the web version — **anything at
> all** — gets written into the relevant section here **in the same task**, and logged in §22 (changelog).
> The spec is never allowed to drift behind the code.
>
> **Conflict order of truth** (from `docs/README.md`): (1) the code, (2) `feature-roadmap.md`,
> (3) `project-context.md`, (4) the latest dated spec. For **web specifically**, this master spec is the
> latest dated roll-up — where an older web spec disagrees, this wins; where this is silent, the cited
> source spec governs.

---

## 0. NORTH STAR — the product is ONE living world (do not drift)

The website's purpose is to render a **living world**: a scene alive with **subtle, continuous motion** — sun,
moon, water glitter, drifting light, the day cycle, the falling sand. **That world IS the product.** The
**timer / setup / session are states layered *into* the one continuous world** — never separate pages with a
scene pasted behind them.

- `web-prototype/hybrid.html` and the separate `site/setup.html` + `site/session.html` pages were
  **prototypes to prove the scene's physics and confirm the idea** — scaffolding to make it concrete, **not
  the deploy shape.**
- The Astro build **mounts the living-world scene once and NEVER re-mounts it** (§4); Home(hero) → Setup →
  Session are overlays/transitions *within* it.
- **Drift signal:** if any decision starts splitting the world across re-mounting pages, or treats the timer
  as the primary thing with the scene as a backdrop, **stop** — that's the drift the founder flagged
  (2026-07-29). The scene is primary; the UI lives inside it.

## 1. What the web version is

A **free, beautiful, deployable focus-timer website** built on the "living-painting" sea scene. Its **only
two jobs**: **rank on SEO**, and **convert visitors to app installs**. (Platform strategy §8, W1 first-push §1.)

- **Anonymous, local-only, zero server** in W1 — no billing, no accounts, nothing stored server-side.
- **Web = funnel + feature lab** (strategy §5): deploys with no store review, so experiments ship here first
  and winners graduate into the app.
- **The absence of analytics is the install hook** — Focus Score / Insights / Stamina stay **app-only**;
  web never shows the numbers. (First-push §2.)

## 2. Platform split & phasing

**Web-only** (never in app): scenes / 3D glass / weather / custom upload, PiP, share links, embed, `/stage`.
**App-only** (never on web): notifications, foreground service, strict sessions, Sediment/Sync/Intention
(first), home-screen widgets. **Both**: the timer + all modes incl. Endless. (Strategy §5.)

| Phase | What | Money |
|---|---|---|
| **W1 — the funnel** *(current)* | Free timer on the living scene: landing + setup + session + `/stage`, SEO, install CTA. | **100% free** |
| **W2a — web commerce** *(indep. of app)* | Scene packs, weather packs, custom upload (max 3/user), full sound mixer, hourglass shapes; accounts + Merchant-of-Record + entitlements. | à-la-carte + lifetime |
| **W2b — the Sync bridge** *(needs app v1.3)* | Sediment on web + web sessions scored into the app's one history. | via Sync |
| **W3 — social** | The Collective · Focus room. | — |

**Money model** (three products, three jobs — first-push §2): **App Pro** = progress system + app themes;
**Web Scenes** (W2a) = beauty/customization, no progression; **Sync** (W2b) = one history across app+web.
Purchases never cross-unlock. Web tier prices are set at W2a with real traffic, not now.

## 3. Tech & architecture

- **A fresh Astro build.** Ships **zero JS by default**; public pages (landing, timer, `/stage`) are
  static/SSR real HTML. **Explicitly NOT Flutter-web** (multi-MB, invisible to Google, non-native — fatal
  for a funnel). (Strategy §9, design-decisions §1.)
- **Islands use no UI framework (no React/Vue).** The timer + audio + UI are vanilla JS. *(Decided
  2026-07-29; the first-push spec's "one React island" is superseded — no UI framework needed.)* **The scene
  island, however, uses Three.js (WebGL)** — see the rendering stack in §6. "Vanilla islands" means no React,
  not no Three.
- **Ports the keepers, doesn't rewrite:** the **locked scene renderer** + **`timer.js`/`plan.js`/
  `session-timer.js`** from `web-prototype/` and the **polished `site/setup.html` + `site/session.html`**
  screens become Astro components/islands. (Design-decisions §1, session-design §2.)
- Build the Astro/GSAP/Three scaffold from **current official docs** (Iron Rule — this stack moves fast;
  never build it from memory).
- **"One living world" ≠ "one URL" (SEO reconciliation, 2026-07-29).** SEO needs *many* real, SSR'd,
  keyword-targeted URLs (`/`, `/pomodoro-timer`, `/hourglass-timer`, `/lofi-co-alternative`, `/stage`, …) —
  a single-URL site ranks for only one term cluster and shows thin content (weak for a funnel). The
  living-world **continuity is delivered client-side**: Astro **View Transitions (`ClientRouter`)** + the
  scene island marked **`transition:persist`** keep the WebGL world mounted while content swaps, so a *user*
  feels one continuous world (never re-mounts — §0 holds) while a *crawler / hard-load* of any URL gets a
  full, separate, indexable HTML page. Crawlers see many optimized pages; humans see one world. The §0
  "never re-mount" rule is about the **user's journey (Home→Setup→Session)**, not "the whole site is one HTML
  file." *(Verify the exact `transition:persist` directive against Astro 7 docs at wire time.)*

### 3.1 SEO landing pages (later pass — decided 2026-07-29)

The interactive tool is **one page** (correct — a running-timer screen is not a search target). SEO strength
comes from a **small set of focused content pages** around it, each a real SSR URL Google indexes and ranks
separately. They are **not new tools or copies** — each targets one phrase with genuinely unique, useful
content and then launches the **same** living-world tool.

**Three kinds:**
1. **Mode / use-case pages** — same tool preconfigured, wrapped in keyword content. e.g. `/pomodoro-timer`
   (what Pomodoro is, why 25/5, a short FAQ for featured snippets) with the tool embedded, **preset to
   Pomodoro**; `/aesthetic-study-timer` (calm-study framing, opens on a calming mode).
2. **"Alternative" pages** — capture orphaned/competitor searches, e.g. `/lofi-co-alternative` (lofi.co shut
   down May 2024).
3. **Guides / small blog** — informational articles (`/guides/how-to-focus`, `/guides/what-is-the-pomodoro-
   technique`) that answer searched questions and link into the tool.

**Hard rule:** each page needs **genuinely unique, useful content** — thin pages that just re-embed the tool
under a new heading are "doorway pages" Google ignores/penalises. This is real writing work → the later pass.
**Scope:** start with **3–5 high-intent pages + 2–3 guides**, grow by what ranks. **Does not block W1** — ship
the one-page app first, add these after.

**The "Start" button flow (locked):** a landing page **already hosts the living world** behind its content.
Its tool button does **not** load a separate setup page — it triggers the **Hero → Setup transition
in-place** (scene persists, never re-mounts; §0/§4), landing on **Setup preconfigured to that page's mode**
(one tap from Begin). That click is also the **audio-unlock gesture**, so ambient + start bell play when the
session begins — starting from a landing page sidesteps autoplay entirely. Default target = **Setup** (keeps
the sounds/theme/intention choices); an optional "quick start → straight to session" can come later.

## 4. Page architecture & workflow (LOCKED)

**One shared first viewport is the base for both the landing page and the timer. The scene + hourglass are
mounted once and NEVER re-mounted.** (Design-decisions §3.)

1. **Hero** — full-bleed sea scene + persistent hourglass (sand ~40%) + navbar + "Sustain" wordmark + a
   **Focus** affordance. Hero direction **B1 "Editorial, warm serif"** (Cormorant Garamond, cream #f4ead6,
   soft left→right scrim), title sitting in the sky's negative space (Ma) so it frames the hourglass.
2. **Click Focus** → navbar / hero title / landing content **dissolve**; **scene + hourglass stay live**.
   The site becomes the timer. (Native `@starting-style` + `transition-behavior: allow-discrete` for chrome;
   **View Transitions API** for the larger change; the hourglass canvas is never touched.)
3. **Timer setup** — focused-today/stats panel **left**, glass **setup panel right**, back-to-home
   affordance. All panels glass.
4. **Session** — big floating Apple-glass numbers around the hourglass ("looking out a window at the
   hourglass on the sill, numbers floating in the air behind it").
5. **End → back to setup → back to home.**

> **This no-re-mount transition is also the audio fix.** Browsers block audio until the first gesture on a
> page; a full page navigation resets that. Because Hero→Focus→Session is **one continuous document**, the
> Focus tap's audio unlock carries all the way through — the start bell + ambient sound at session start
> without a second gesture. *(This is why the static two-file version has the "silent until you tap the
> session page" problem, and why the Astro unification resolves it.)*

## 5. The living scene (the free centrepiece)

- **Locked plate rule (site-wide, never changes):** the plate `inset:0; background: cover; position 50% 50%`,
  fills the viewport, no transform/zoom — **identical on Home, Setup, Session.** (Setup-build-spec §0.5.)
- **A theme = up to 6 pixel-aligned phase plates + a JSON config** (sea/glass masks, per-phase sand-shadow
  grade, day schedule). Locked primitives (sand, stream, glass outline, sun/moon) are shared, never re-tuned.
  **Sea is theme #1** (`web-prototype/plates-phases/`). Adding a theme later = art + tuning, no code.
  (First-push §3.)
- **Circadian day cycle runs off the user's REAL local clock** (default), **orthogonal to session progress**:
  the clock drives the sky/sun/moon; the session drives the sand. A 4-hour session watches the sun move; a
  25-min Pomodoro barely shifts. (First-push §4.2.)
- **Location-based schedule — DECIDED 2026-07-29: `Timezone → representative coords → SunCalc math`.** Read
  the browser timezone (`Intl.DateTimeFormat().resolvedOptions().timeZone`), map to a representative lat/long,
  compute **real regional sunrise/sunset** by math (no API, no server, no permission prompt, privacy-clean).
  An **optional "use my exact location"** Geolocation upgrade can come later. This **replaces the hardcoded
  hour bands** (the known-wrong bit — twilight showed at 22:06). (Design-decisions §6; location source was
  the open decision, now closed.)
- **Theme-progression chooser** (already built in `setup.html`, presets in `CYC_PRESETS`): **Follow my day**
  (live clock — default) · **Hold one light** (fixed phase) · **Into the night** (sunset→twilight→midnight) ·
  **A whole day** (full-day pass: pre-dawn→…→midnight across the session) · **custom** sequence. The chosen
  mode **takes effect when the session begins**; hero + setup always show the **real current-time plate,
  live**, and it persists across landing → Focus → setup. (Design-decisions §4/§5.)
- **Circadian is a property of a theme, not a sellable feature** — a full-circadian theme (Sea) has the day
  cycle built in (free for everyone); a single-timeframe theme (e.g. a fixed Night) has none. Never sold or
  toggled by name. (First-push §2.1.)

## 6. The hourglass

- The **one mascot everywhere** — a faithful port of the app's 2.5D canvas sand painter
  (`lib/hourglass/hourglass_painter.dart`), rendered sand over the baked plate. **No 3D glass hourglass —
  deferred indefinitely.** Turning the hourglass off is not a feature (the empty glass is baked into each
  plate; only the sand is rendered). (First-push §2.1, strategy §5.)
- **Session hourglass — DECIDED 2026-07-29: LIVE rendered sand.** The session shows **real falling sand
  driven by the timer** (`S.prog = elapsed / segmentDuration`), sky on the live day cycle, floating glass
  numbers around it. This **graduates** the "live animated scene" that session-design §10 deferred for the
  static prototype into the Astro build, and it's §4.1's core risk to prove — *does the countdown feel right
  against the falling sand?* (The static-plate + CSS-numeral look in the current `session.html` prototype was
  a shortcut and is superseded for the Astro session.)

### 6.1 Scene rendering stack (verified from `web-prototype/hybrid.html` code, 2026-07-29)

The locked scene renderer is **layered**, and reproducing it exactly on the deploy site **requires Three.js**:

- **WebGL layer (Three.js `r0.170`)** — a full-screen-quad **fragment shader** renders the **plate image
  texture + sun + moon + celestial lighting + old-anime water glitter**. This is the piece that *cannot* be
  reproduced with plate images + 2D canvas; it's why W1 needs Three.js.
- **Sand layer (Canvas 2D)** — the hourglass falling-sand painter (`sandCv.getContext('2d')`), driven by
  `S.prog`.
- **Refraction + film grain (Canvas 2D)** — glass refraction (`willReadFrequently`) and grain overlay.

**Deploy/perf note:** render the plate **also** as a preloaded `<img>`/CSS background so it is the fast LCP,
then mount the WebGL scene over it and **defer-init** after first paint (Three.js is bundled by Vite as an npm
dep, not the CDN importmap `hybrid.html` uses; verify the current `three` version at build time). This keeps
LCP = the plate and the WebGL glitter/sun/moon as progressive enhancement, honouring §13.

## 7. The timer engine (BUILT)

`site/js/plan.js` (`window.Plan`) + `site/js/session-timer.js` — pure, DOM-free, **15 + 13 assertions green.**

- **Four modes = four segment lists:** **Flow** (one focus segment) · **Pomodoro** (focus/short-rest, long
  rest every 4) · **Custom** (user work+break) · **Endless** (one open focus; glass drains→flips→refills,
  counting total focus). (First-push §4.2.)
- **Wall-clock accurate:** elapsed = `Date.now() - startTs - pausedTotalMs`, **never** accumulated rAF ticks
  (must survive a backgrounded/throttled tab); rAF only *reads* elapsed to paint. Timed modes count **down**
  the current segment; Endless counts **up**.
- **Segment auto-advance** with a soft cue + brief label ("Break · 5 min"); Endless breaks are user-triggered
  and cycle-reset uses the **fade-through-black flip**.

## 8. Session behaviours (BUILT this cycle — app parity)

All in `site/session.html`:
- **Pause foolproofing:** wall-clock cap **3 min + 15 s grace**, then auto-abandon; **ambient muted while
  paused**; glass "Paused" overlay (scene+timer blur, chrome stays sharp).
- **Give-up** → frosted confirmation popup (keeps the session live behind it — correct); confirm → end.
- **Hard-reload guard:** a `sessionStorage['sustain.armed']` one-shot flag; on a reload the session is over →
  a frosted "session over → return to Setup" overlay; the timer/audio never start (early return). Back-nav
  guard (`history.pushState`/`popstate` + `beforeunload`) so a session is never abandoned by mistake.
- **Count actual focus ≥ 2 min**, including on give-up (`focusedSoFarMin()` sums only focus segments;
  `commitFocus` credits once, ≥2 min; app parity).
- **Screen Wake Lock** (`navigator.wakeLock`, re-acquired on `visibilitychange`).
- **Intention** (from Setup) shown quietly at top-centre; **idle-fade** hides chrome + numbers + intention
  only **while running** (they stay put when paused); reveal on pointer-move.
- **Ritual bell cues** (`cue_bell.mp3`, ~0.55 vol) at session **start / end / break-start / break-end**.
- **Break-audio hush:** ambient drops to ~15% during a rest segment, restores on focus (tunable `BREAK_DUCK`).

## 9. The audio engine (BUILT)

Ported Web-Audio engine (setup ↔ session identical): `AudioContext` → master gain + brickwall limiter;
per-sound `BufferSource` **crossfade-stacking gapless loops**; per-sound mixer + master volume; K-weighted
`SOUND_GAIN`; bird tide LFO; missing-file soft-fail; autoplay unlock on first gesture. Sounds: **Sand / Ocean
/ Breeze / Seabirds.**

- **Dynamic sand↔ocean SIDECHAIN — 2026-07-29** (both `setup.html` + `session.html`): an envelope-follower on
  the ocean tap ducks a `sandDuck` gain in real time, so sand recedes on each wave crest and rises in each
  lull — replaces the old static `DUCK sand:{ocean:0.20}`. Tunables `SC_LO/HI/DEPTH/SMOOTH`. Sand base gain
  trimmed 30→26.
- **Sound is basic/free in W1** (basic loops + 2-layer mixing); **full mixer + premium sounds are W2a.**
  **No in-house music**; **Spotify embed is a free convenience, never a sellable feature.** (Strategy
  §6.1.3/§6.1.4.) Soundscapes-beyond-basic are a **fast-follow** (blocked on the founder sourcing CC0 audio +
  CREDITS). (First-push §6.)

## 10. The setup screen (BUILT, geometry LOCKED)

`site/setup.html`: **app-parity modes and settings, minus Pro** (no Focus Stamina etc.). One **Begin** button.
**Panel geometry is founder-locked** (setup-build-spec §0.6). Holds: the 4 timer modes, sounds + mixer,
**Intention**, **Focused-today**, the **number-look** controls, and the theme-progression chooser. Common
controls visible; **one Advanced sheet** for power controls.

## 11. The number treatment (numeral controls — BUILT)

The five user controls, all persisted, both pages (numeral-controls §2):
- **Position/Mode:** Horizon · Middle · Ledge · Top (each snaps to locked geometry in
  `web-prototype/timer-modes.json`; supersedes the old Above/On-glass/Below control).
- **Fill:** solid · glass · outline.
- **Font:** Serif (Newsreader) · Jost.
- **Colour:** round preset swatches + custom picker.
- **Separator:** colon · dot · none (per-mode rules: Middle/Ledge = none; Top/Horizon = colon|dot).
- **Auto-contrast** (`setTone` + `sampleBg`) lifts numerals toward white on dark plates.
- **Setup split:** Position/Fill/Font in the **Themes panel**; Colour/Separator in **Advanced settings**.
  (Session settings has no Themes/Advanced split — one sheet.) Self-hosted overlap-removed woff2 fonts.

## 12. Data flow & persistence

- **`localStorage['sustain.session']`** — the full Setup config (mode + durations, sounds + volumes,
  theme/phase + progression, timer visibility, number look, intention). Setup **persists on Begin**; Session
  **reads on load**, `buildPlan`s, applies look/phase/sounds, auto-starts (v1). **End → Setup** re-reads it so
  selections persist. Standalone fallback default = `{mode:'flow', flowMin:25}` if absent.
- **`localStorage['sustain.focusedToday']`** — `{date, min}`, daily reset; the "Focused today" line.
- **`sessionStorage['sustain.armed']`** — one-shot, set on Begin, consumed on session load → reload detection.
- **localStorage caveats** (memory `web-build-sequence`): device-local, **not** cross-device (that's paid
  Sync); incognito clears on close; Safari ITP can evict after ~7 days without a visit — treat local prefs as
  **best-effort convenience; the app/Sync is the source of truth.**

## 13. Performance budget (HARD — "don't be Flocus")

(Design-decisions §7, strategy §9.) Measured with Chrome DevTools MCP, **from day one, not retrofitted**:
- Scene plate is the **LCP element**: convert ~2 MB PNGs → **AVIF/WebP, < 200 KB**; `<link rel=preload>` +
  `fetchpriority=high`; **never lazy-load it**.
- **Load one plate, not six** — current phase eager, adjacent phase prefetched for the crossfade, rest never.
- **LQIP blur-up** (<5 KB inline) for instant paint, holds layout so **CLS ≈ 0.**
- **Astro ships zero JS by default**; scene/timer as islands. **Budget: LCP < 2.5 s, CLS ≈ 0.**

## 14. Aesthetic bar (standing)

Beautiful **anime-style** site; **target = Awwwards Site of the Month**; **"too plain" is a valid rejection**
(memory `web-aesthetic-principle`). **Beauty must never cost speed.** Glass = **accent, not foundation**
(`backdrop-filter: blur() saturate()` + 1px light edge + contrast backing; avoid Safari-flaky SVG refraction;
`prefers-reduced-transparency` fallback). Unified grade + film grain over the whole frame so UI and scene read
as one image. **Ma (間)** — negative space as an active element. **Spacing principle** (memory
`web-spacing-principle`): one scale, equal gutters, proportional/geometric — never congested nor marooned.
Don't pair Cormorant with Inter/Roboto/Arial/Space Grotesk (banned as overused).

## 15. What's free vs paid (the boundary — first-push §2.1)

**Free forever (W1, much of it never-paywallable):** all 4 modes incl. Endless · the **base Sea scene + full
circadian day cycle** · session view + all timer-visibility settings · share links / cards / embed · `/stage`
(+`?record=1`) · PiP · local "focused today" · **basic soundscapes + 2-layer mixing** · install CTA · tip link.
**W2a paid ("web sells beauty"):** extra scene packs · à-la-carte weather packs · custom upload (max 3/user) ·
full sound mixer · hourglass shapes/flow · animated/premium scenes. **No 3D glass — deferred indefinitely.**

## 16. Out of scope for W1 / deferred

Billing · accounts · Sync · progress/score/analytics (**app-only** — the absence is the hook) ·
soundscapes-beyond-basic (fast-follow) · flip-to-start ritual (v1 auto-starts). PiP / embed / share links are
**free but fast-follow**, not the first push.

## 17. Current build state (2026-07-29)

- **`site/`** — the polished **static prototypes** of the designed screens: `setup.html` + `session.html`
  (inline CSS/JS, no build), `js/plan.js` + `js/session-timer.js` (tested), `assets/` (plates, fonts, audio
  incl. `cue_bell.mp3`). These carry the audio engine, timer, theme-progression chooser, numeral controls,
  and all session behaviours (§8). Setup geometry is locked. **These are the migration source, not throwaway.**
- **`web-prototype/`** — the **theme lab (permanent):** `hybrid.html` (locked scene renderer), `timer.js`,
  `scene.html`, `living.html`, `number-lab.html`, the **6 scene check scripts** (`check-wiring.py`,
  `check-schedule.js`, `check-glow.py`, `check-bed.js`, `check-stream.py`, `check-pile.js`), plates.
- **No Astro project exists yet** (`web/` is only the Flutter web scaffold). **Phase 1b is unstarted.**

## 18. The path to the Astro build (Phase 1b) — remaining work

> **Founder build order (2026-07-29):** build **Home (hero) → Setup → Session** first — the connected,
> working web app with the living sky + rendered sand + audio-carry — and let the founder test that. The
> **full scroll landing page + SEO depth** come in a **later pass**, not now.

1. **Scaffold Astro** from current official docs; vanilla islands; asset paths under `public/`.
2. **One shared viewport** (§4): Hero → Focus dissolve → Timer → Session, **scene + hourglass never
   re-mounted** (View Transitions + `@starting-style`). This delivers the audio-carry fix.
3. **Port the keepers:** the rendered-sand scene renderer (live) · `plan.js`/`session-timer.js` (→ ES
   modules) · the setup + session screens (→ scoped components) · the audio engine.
   - **Scene port = VERBATIM, plumbing-only changes (2026-07-29).** `hybrid.html`'s fragment shader (sun/moon/
     glitter) and sand physics are finely hand-tuned; copy them **exactly**. Change only: three importmap →
     npm `import`; `<script type="x-shader">` tags → inline template-string constants; asset paths →
     `/plates-phases/*`, `/plates/moon-tex.png` (public/); the `#ui` **debug sliders' default `value=`s
     become baked-in locked constants** (drop the panel, or keep it dev-only); the `#session-ui` basic timer
     is dropped (real Setup/Session drives the scene). Adapt three `r0.170→0.185` colour-management APIs if
     needed. Verify it renders identically **before** exposing the scene API (`setProgress`, phase/time) and
     layering the UI.
4. **Wire LIVE rendered sand** in the session (hourglass driven by `S.prog`) + **moving sun/moon on the real
   clock** (§6).
5. **Location schedule:** timezone→coords→SunCalc, replacing the hardcoded hours (§5).
6. **Landing:** scroll narrative with the **persistent hourglass** (never re-mounted), hero B1, then SEO —
   `<title>`/meta/**OpenGraph**, `sitemap.xml`, `robots.txt`, **Google Search Console** (DNS verify); target
   terms incl. "lofi.co alternative."
7. **`/stage`** (+`?record=1` OBS preset).
8. **Perf:** compress plates → AVIF/WebP, preload + LQIP, budget measured (§13).
9. **Migration checklist (handoff §5.5):** absolute asset paths → `public/`; `plan.js` → ES module (drop
   `?v=` cache-buster); **add teardown for View Transitions** (remove listeners, `clearInterval`,
   `AudioContext.close()` in `astro:before-swap`/island unmount — the page script is one big inline IIFE with
   no teardown today); self-host Jost; scope the CSS (keep `:root` tokens global); a11y polish
   (`role=tablist`/`aria-selected`, focus-trap the dialog, `aria-pressed`).
10. **Verify:** keep all **6 scene check scripts** + the timer test running through the migration; don't weaken
    them to pass. Founder verifies on-device (Iron Rule).

## 19. Decisions locked 2026-07-29 (this session)

- **Location source** = timezone → representative coords → SunCalc (no prompt; optional Geolocation upgrade later).
- **Session hourglass** = live rendered sand (per spec), superseding the static-plate prototype look.
- **Islands = no UI framework (no React).** BUT **Three.js IS required** for the scene island (the sun/moon/
  glitter/lighting are a WebGL shader in `hybrid.html` — verified from code; §6.1). Corrects an earlier wrong
  call to drop Three.
- **Dynamic sand↔ocean sidechain** replaces the static duck (both pages); **sand base gain 30→26.**
- **Session engine parity:** count actual focus ≥2 min incl. give-up · Screen Wake Lock · break-audio hush ·
  ritual bell cues.

## 20. Source specs consolidated here (design record)

- `2026-07-17-sustain-platform-strategy-design.md` — canonical platform/money/phases (supersedes 07-11).
- `2026-07-18` / `2026-07-19-sustain-web-w1-handoff.md` — the living-painting scene (built, locked).
- `2026-07-22-sustain-web-w1-first-push-design.md` — W1 scope, money, theming, timer engine.
- `2026-07-22-website-design-decisions.md` — page architecture, living-sky modes, location schedule, perf.
- `2026-07-23-web-setup-screen-design.md` · `2026-07-23-web-setup-build-spec.md` — setup design + locked geometry.
- `2026-07-25-web-session-handoff.md` — setup-locked handoff + pre-Astro migration checklist.
- `2026-07-26-web-session-screen-design.md` — session screen v1 (static prototype) design.
- `2026-07-28-numeral-controls-design.md` — the five number-look controls + Themes/Advanced split.
- `2026-07-11-sustain-web-design.md` — ⚪ superseded by the 07-17 strategy; kept as history.

## 21. Open threads (non-blocking)

- Web tier composition + pricing → decided at **W2a** with real traffic (first-push §7.2).
- App 2D-vs-scenic revamp → its own future brainstorm (first-push §7.1).
- Founder actions: buy the domain (`sustaintimer.com` recommended); source CC0 soundscape audio;
  plate regeneration ≥2560px.

---

## 22. Changelog (append on every web change)

- **2026-07-29** — Master spec created (consolidates all web specs). Locked: location = timezone→coords;
  session hourglass = live rendered sand; vanilla islands (no React). Shipped this cycle: dynamic sand↔ocean
  sidechain (setup + session), sand base gain 30→26, ritual bell cues, session-engine parity (focus ≥2 min
  incl. give-up, Wake Lock, break-audio hush), frosted popups, hard-reload guard, give-up confirm,
  idle-fade-while-running, Intention-at-top. Founder build order: Home(hero)→Setup→Session first, full landing
  later.
- **2026-07-29 (SEO)** — Clarified in §3: "one living world" ≠ "one URL". SEO gets many SSR'd keyword URLs;
  the scene persists across them via Astro View Transitions + `transition:persist`. §0 "never re-mount" =
  the user's journey, not a single-HTML-file site. Scaffold built clean (Astro 7.1.5, static). Scene assets
  (6 plates + moon-tex) + `timer.js` moved into `web-astro/`.
- **2026-07-29 (north star)** — Added **§0 North Star**: the product is ONE living world; timer/setup/session
  are states layered into the single continuous scene, never re-mounting pages. The prototypes were scaffolding
  to prove the idea. Founder flagged drift toward separate per-page builds — corrected. Verified current stack:
  **Astro 7.1.5, three 0.185.1, Node 24.10.**
- **2026-07-29 (correction)** — **Three.js IS required for W1** (scene island). Verified from
  `web-prototype/hybrid.html`: sun/moon/glitter/celestial-lighting are a Three.js `r0.170` WebGL fragment
  shader; only the sand + refraction + grain are 2D canvas (§6.1). Reverses the earlier "drop Three.js"
  recommendation. Three rides in the scene island (landing stays zero-JS, plate stays LCP, WebGL defer-inits).
