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

1. **Hero** — full-bleed sea scene + persistent hourglass (sand ~40%) + a **Focus** affordance.
   **REDESIGNED 2026-07-30 (founder-approved, element-by-element) → "Composition A: left editorial."**
   Chrome adapted from the founder's mockup, executed over the live painting:
   - **Nav:** slim floating **glass pill** (`.glass-quiet`) — ⧗ hourglass glyph + "Sustain" (Playfair Display)
     left · **in-page smooth-scroll anchors** `How it works · Science · FAQ` (NOT separate pages; targets are
     stub sections until the full scrolling-landing pass) · a **Get the app** glass pill right. *(This reverses
     the earlier "no-box, text-only nav" — the mockup pill wins. Themes link dropped: only one theme exists.)*
   - **Lede — grouped in the LOWER-LEFT** (Lovable-caliber proportion, tuned 2026-07-30): two-line **Playfair
     Display** headline **"Train your focus. / Transform your life."** (sized to *clear* the centred hourglass,
     never overflow into the glass) → **one-line** Jost support → **solid light "Begin Focus"** (the Focus
     affordance) + **glass "Get it on Google Play."** *(Eyebrow chip dropped as clutter.)*
   - **Focused today:** quiet Jost line under the buttons, **shown only to returners** (today's focus > 0),
     so first-timers never see a sad "0m."
   - **Legibility = NO text shadows/halos** (they read as an ugly crisp outline) **+ a soft bluish plate tint**
     doing the work: darkest in the lower-left behind the text, clearing toward the bright top-right (Lovable).
     Type sized against the **viewport (vw)**, not a container (fixes the old cqi/16:9-card "too big" balloon).
     *(The rotating sky quote was tried then removed — clutter over the busy scene.)*
   - **Motion:** on load, chrome **fades in** (opacity + gentle up-drift + subtle de-blur, staggered; centred
     elements keep their `translateX(-50%)` through the fade). The **scene breathes** — a slow ~60 s zoom
     in→hold→out→hold loop on `#frame` (transform only; `fit()` owns left/top; disabled under reduced-motion).
     Files: `web-astro/src/components/Home.astro`, `SceneWorld.astro` (`#frame` breathe).
   - *(The old "B1 warm-serif, soft left→right scrim, giant Sustain wordmark" hero is superseded.)*
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

### 4.2 The landing page = a PINNED STORY — BUILT 2026-08-02 (design: `2026-08-02-web-landing-page-design.md`)

**Nothing on the page moves.** The scene, its bottom tint, the film grain and the nav are **constant the whole
way down** — founder's words: *"like a ppt with the same background throughout, only text is changing."*
Scrolling only cross-fades text chapters and advances the day. `src/components/Landing.astro`, controller in
`index.astro`. *(An earlier version scrolled real content over the scene with a full-screen scrim + blur. The
founder rejected it outright — that shape is dead, do not reintroduce it.)*

- **Hard rules (founder, 2026-08-02):** nothing may sit on the hourglass or the centre column · **no
  full-screen scrim, no blur over the art, no darkening layer** · the nav must not change on scroll · the
  scene "breathing" zoom stays a free-running CSS loop and is **not** scroll-linked (tried, rejected).
- **Chapters.** Hero is chapter 0; five more (How it works · The living world · Why it works · Questions ·
  Get the app). Each is one statement plus **at most three short points, never paragraphs**. Heading on one
  flank, points on the other, **both on grid-row 1** so they sit on the same line, sides swapping per chapter.
- **Motion is sequential, not a crossfade:** the old text rises away and fades out first, then the new text
  rises up from below (`--out` enter delay = exit duration), so two chapters never share the screen.
- **Section snap.** One `.stop` per chapter (`0.75svh` each, last `100svh`) with `scroll-snap-type: y
  mandatory` + `scroll-snap-stop: always`: every chapter is a hard stop and a fling can never skip one. An
  earlier JS-damped follow was removed — that easing *was* the unwanted momentum. `svh` not `dvh` (a mobile
  URL bar would slide the snap points mid-gesture), and the controller **measures** the stop's real height
  rather than deriving it from `innerHeight`.
- **Scroll drives the day.** Top = the viewer's **real local sky**; scrolling sweeps the scene clock **+12
  reference hours, wrapping**; back at the top it returns to `setDay('follow')`.
- **Legibility (the only permitted devices):** the hero's `.vign` is now **symmetric** (both bottom corners,
  each dying out by ~76% of its own box so they never stack over the hourglass), plus a wide low-peak
  **scrim** behind the heading block and a **glass plate** behind the points. WCAG 1.4.3 needs 4.5:1 for body
  and 3:1 for large display type; text over imagery has exactly three legitimate remedies (scrim, blur,
  panel) and blur-over-art is banned, so scrim + panel it is. No text shadows or halos anywhere.
- **Blur must never pop in.** An element with `opacity < 1` becomes a **Backdrop Root**, so any fading
  ancestor makes a descendant's `backdrop-filter` sample an empty group and snap to full blur only when
  opacity hits exactly 1. **Never animate opacity above a `backdrop-filter` element.** The plate animates its
  **blur radius** and tint instead; the fade lives on leaf content.
- **Headings fill the flank.** Each written line is a `<span>` that cannot re-wrap, sized from the flank
  width against the longest line's character count (`--n` per chapter):
  `min(clamp(30px,4.6vw,76px), 100cqw / (n * 0.52))`. `text-wrap: balance` is **wrong** here — it optimises
  for even line *lengths* and narrows a headline into four short lines.
- **The hourglass is the SPINE.** `grid-template-columns: 1fr var(--hg-w) 1fr`; `--hg-w` and `--hg-axis` are
  published by `scene.js fit()` (`HG_FRAC = 0.27`; axis from the frame's real `offsetLeft`, since the axis is
  at `S.cx = 0.49885`, not 50%, and `innerWidth` includes a scrollbar that a percentage does not).
  **The hero is exempt** — its empty right flank is deliberate.
- **Interactivity goes on `.say`/`.tell`, never on `.ch`** (which is `inset:0`): an active chapter with
  `pointer-events:auto` is a full-viewport shield that swallows every nav click beneath it.
- **The footer is the one thing that really scrolls:** a blurred `50svh` sheet that rises over the bottom of
  the scene at the end, with brand, section links, legal/contact and the disclaimer. Not a chapter.
- **No invented proof.** No ratings, install counts or testimonials until they are real (founder: the app has
  few installs yet).
- **Scroll lock:** Home scrolls; `#setup`/`#session` add `:root.lock-scroll` (+ `scroll-snap-type:none`) and
  reset to the top, and entering them restores the live day. The scrollbar is hidden site-wide (nothing
  visibly scrolls, and it keeps `innerWidth` equal to the layout viewport so overlays and the scene share one
  coordinate space).

### 4.3 Responsive / mobile rules (BUILT 2026-08-02)

- **Nav:** below 820 px the links become a **burger** drop panel; under 400 px the "Get the app" pill drops
  (the panel and the hero button both still offer it).
- **Landing portrait:** the spine turns **vertical** — statement centred in the sky at the top, points low on
  the deck; the glass itself stays clear. The heading scrim re-centres.
- **Setup portrait** (founder-specified order): focused-today → back (corner) + mode chooser (centred) →
  **Timer → Themes → Sound → Begin**, all **in flow** in one vertical scroll. Also: `--sq` drove the whole
  locked geometry off container **height** only, which asked for a 691 px `--main-w` on a 390 px screen; it is
  now also capped by the available width. Desktop/tablet geometry is unchanged (height still wins), so the
  founder-locked proportions hold.
- **Session portrait:** **Top placement only** (`applyNum` forces it; the placement row is hidden in both
  sheets, and the user's real choice is restored on rotate). Numerals are normally plate-relative
  (`cqh`/`cqw` of `#frame`), and on portrait the plate is cover-cropped to ~4× the screen width, so the locked
  `--gap:3cqw` / `15cqh` computed the pair off both edges: portrait re-expresses them in viewport units.
- **`hover` timer visibility = `always` on `(hover: none)`.** It is the default, and a touch device fires no
  `mousemove`, so the numerals could never appear on a phone at all.
- **Touch targets:** ≥44 px on coarse pointers (Session `#gear`/`#breakBtn`, Setup steppers), applied only to
  coarse pointers so the desktop look is untouched.
- **SEO:** canonical + OpenGraph + `SoftwareApplication` JSON-LD in `index.astro`, `public/robots.txt`,
  hand-written `public/sitemap.xml`, and a real `og-cover.jpg` (1200×630, generated by `gen-assets.mjs`).
- **`/privacy` + `/terms`** ship as markdown pages under a plain `Doc.astro` layout (moved out of
  `docs/legal/`, now covering the web version too) — this closes the P0 in `launch-founder-actions.md` §3.

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

### 5.1 Plate framing & fit — LOCKED (iron rule, 2026-07-29)

A plate's framing decides whether `object-fit: cover` keeps the hourglass + ledge on every window. Locked:

**Seascape (current theme).** Deploy plates = `assets/plates/*.jpg` (**1600×901**, AR ≈ 1.776 / 16:9). The
hourglass sits cap ~28% → base ~88% — a tight ~12% margin below — so the scene uses **`SCENE_OY = 0.72`**
(cover-crop biased toward the bottom) so the ledge/base is never cut; the excess trims off the top sky. Note:
`assets/plates` and the older `web-prototype/plates-phases/*.png` are the **same image at different
resolutions** (identical composition), so the coded sand aligns to either — no re-trace when switching.

**New themes — generate plates to THIS spec so cover-fit just works (no per-theme bias needed):**
- **Aspect ratio 16:9** for every plate. Generate at **2560×1440**; export compressed **AVIF/WebP < 200 KB**
  for deploy (§13). Same AR across all themes so the fit rule never changes.
- **Hourglass centred horizontally** (axis at 50% width).
- **Crop-safe vertical zone:** the hourglass (top cap → base) **plus its ledge** must sit inside the central
  band — **≥ 20% sky above the top cap** (sun/moon + crop headroom) and **≥ 18% ground/ledge below the base**.
  So the hourglass+ledge occupies ~the central **60%** of the height. Built this way, the theme renders
  correctly at **`SCENE_OY = 0.5`** (true centre) on any window from ~4:3 to ~21:9 — no cutting.
- **Pixel-locked hourglass:** the empty hourglass occupies the **exact same pixels across all 6 phase plates**
  (0 px residual — integer-align pass), so the coded sand never shifts when the sky crossfades between phases.
- Keep sun/moon/horizon/sea features **consistent across the 6 phases** (the schedule + shader assume shared
  geometry).

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
7. **`/stage`** (+`?record=1` OBS preset). ✅ **BUILT 2026-08-02** — `src/pages/stage.astro`: chrome-less
   fullscreen scene reusing the SAME scene island (no second render engine), `noindex`, params
   **`record` and `stopstream` only** — the session is configured on the real Setup screen, not by URL.
   *(Corrected 2026-08-02: `flow` / `loop` / `phase` / `timer` were listed here but were replaced by the
   `eabfb05` rewrite. **Nothing anywhere reads session config from the URL**, which is why video descriptions
   cannot deep-link a preset yet.)* Capture guide: `docs/obs-stage-streaming-guide.md`
   (Browser Source only — Window/Display Capture screen-scrapes a throttled tab, strategy §10).
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
- ~~Founder actions: buy the domain~~ → **✅ `sustaintimer.com` SECURED 2026-08-02 (Hostinger).** Remaining:
  source CC0 soundscape audio; plate regeneration ≥2560px.
- **URL→`cfg` preset reader** — needed so video descriptions can deep-link the exact session that produced
  them (the "video is the ad" half of strategy §10). Nothing reads config from the URL today.

---

## 22. Changelog (append on every web change)

- **2026-08-03b (deep-link lands on Setup; /stage `uniform` Pomodoro; Month-1 list from search volume)** —
  **Deep link fixed:** params were being applied **invisibly**. `index.astro`'s `screen()` treats any hash
  that is not `#setup`/`#session` as Home, so a link carrying only query params seeded Setup and then
  dropped the visitor on the hero. The deep-link block now ends with `location.hash='setup'`, running before
  index's controller reads the hash, so its first paint is already Setup.
  **⚠️ `/stage` ONLY — `uniform` Pomodoro (founder's call; user-facing is LOCKED).** The founder's screenshot
  caught `hours=4` producing **3h50m**: `pomodoroPlan` drops the trailing break AND makes every 4th break
  long (`pomoBreak x 3`), so **50/10 and 25/5 can NEVER hit a round hour** — every "2-Hour"/"4-Hour" title
  in the roadmap was a lie. Fixed with a `uniform` flag: **no long break + keep the trailing break**, so
  total = `blocks x (focus + break)` and 50/10 x N is exactly N hours. Set **only** by
  `st.uniform = documentElement.classList.contains('stage')` — and only `stage.astro` ever adds that class,
  so the user-facing plan takes the identical path it always did. **Locked by 4 self-test assertions**
  (`norm(50,10,4)===230`, `norm(50,10,5)===310`, normal ends on FOCUS, uniform ends on BREAK) — 25 assertions
  pass. plan.js's documented self-test command was also stale (web-astro is `type:module`, so the file cannot
  be run as `.js`); header now carries the working `node -e` form.
  **Roadmap regenerated from the SHIPPED plan.js**, never hand arithmetic — which also fixed a second silent
  bug: the earlier chapter timestamps assumed uniform breaks and were wrong for any video with 4+ blocks.
  **Month 1 = 30 videos chosen from search volume** (vidIQ 2026-08-03): **`study with me` 2,533,520/mo — 6x
  `pomodoro timer`** — so titles now LEAD with it; `2 hour timer` 204,296; `study with me 4 hours` 44,753;
  `60 minute timer` 33,037. **Midnight earns its slots on data**: `study with me late night` 6,242/mo; the
  bell-only rows on `study with me no break no music` 4,388/mo. Month 2 is explicitly a **holding list, not
  a plan** — re-cut from Month 1 Analytics. Generator asserts **every row is an exact round hour** and that
  no combination repeats (it caught 4 bad Month-2 rows: 30/10 and 60/10 at 4 blocks).
  **Directory browse order fixed** — rows varied `sound` fastest, so scrolling from 0 gave 16 near-identical
  rows. Axes reordered so cosmetics vary slowest and duration/time-of-day/sound vary fastest; total
  unchanged at 905,748,480.
  **Deployed:** `sustain-directory.pages.dev` and `sustain-web.pages.dev` are live (Pages, folder deploys —
  the branch name is metadata only; `--branch main` is required or the deploy files as *Preview*). Preview
  URLs sit two levels deep and their cert lags a minute behind the deploy — that is the transient
  `ERR_SSL_VERSION_OR_CIPHER_MISMATCH`, not a misconfiguration. **Both need a redeploy** to pick up the
  deep-link landing fix and the directory reorder. Runbook: `docs/deploy-runbook.md`.

- **2026-08-03 (`/stage` is now the whole edit; countdown tick; deploy runbook; subs = a gate, not a KPI)** —
  **`/stage` intro + outro cards BUILT.** Begin → recording starts → **intro card 10 s** over the blurred
  scene → **3·2·1** → session → **thank-you card 7 s** → fade to black → `stopRecording`. Nothing is cut
  together afterwards — what OBS captures IS the finished video. Both cards **write themselves from `cfg`**
  (`cfg.totalMin` added at Begin, computed where `Plan` lives), so no copy is ever typed per video: mode /
  interval / duration / light / sounds all render themselves. The config line doubles as the **on-screen
  relevance signal** the algorithm reads in the first seconds.
  **Founder feedback applied same session:** the intro was **too wordy** — cut from five blocks to
  brand + config line + **one** sentence + a one-line disclaimer (`inHow`/`inGreet` and the now-dead `WORDS`
  table deleted). Countdown confirmed working on device.
  **Countdown tick added** — `SustainAudio.tick()`, **synthesised** (880→440 Hz sine, fast exponential decay,
  gain 0.22), deliberately not a sample: no asset to source, no licence, stays 100% ours per strategy §4.
  Ticks on 3·2·1; the **bell stays reserved for the clock actually starting**, so the two sounds mean
  different things on tape.
  **Fullscreen toast fixed** — `requestFullscreen()` makes the browser print *"To exit full screen, press
  Esc"*, which landed on the intro card **on tape**. Now **skipped under `?record=1`**: inside an OBS Browser
  Source it was always a no-op (the source already renders 1920×1080), so skipping costs nothing. Capturing a
  real browser window instead? **Press F11 before Begin.**
  **Deep-link params in use:** `mode work break blocks hours min phase cycle sound vis place fill font sep
  sunmoon color`; `sound=` empty means bell-only. `astro.config.mjs` `site:` **set to
  `https://sustaintimer.com`** now the domain exists (canonical/OG/sitemap use their own per-page `SITE`
  constant, so this is for tooling that reads `Astro.site`). Build clean, `dist/` ≈ 8.4 MB, 4 pages.
  **`docs/deploy-runbook.md` written** — exact ordered steps: `wrangler login` → move DNS Hostinger→
  Cloudflare (registration stays at Hostinger; **flags the MX/SPF trap** — nameserver changes move ALL DNS
  and can break email) → `wrangler pages deploy dist --project-name sustain-web` → custom domain + www→apex
  301 redirect rule → directory as a **separate** Pages project → GSC **Domain property** via TXT in
  Cloudflare DNS + submit `sitemap.xml`. All founder-run: `wrangler login` is interactive OAuth.
  **⚠️ Strategy correction (founder, and correct):** **subscribers are a GATE, not a growth metric.** Revenue
  is **RPM × views**; subs earn nothing and the algorithm ranks per video on satisfaction/relevance. §13's own
  data proves it — Study Pomodoro: 98,246 views/video on 47,300 subs at **+0.2%** sub growth. The lone
  exception is the YPP gate: **under 1,000 subs, views earn exactly $0.** So the Shorts track is a one-time
  lock-pick — **~2/week until 1,000 subs, then stop entirely.** §8 updated.

- **2026-08-02c (deep link BUILT; combination directory BUILT; monthly wave loop; vidIQ competitive scan)** —
  **Deep link shipped** in `Setup.astro`: `/?mode=pomodoro&work=50&break=10&hours=4&phase=sunset&sound=ocean`
  seeds the Setup screen (mode, interval, blocks/hours, time-of-day, cycle, sounds, vis/place/fill/font/sep/
  sunmoon, colour). **Params only SEED — the visitor still sees Setup and still presses Begin**, so nothing
  auto-starts and audio keeps its user gesture. Implemented by **clicking the real controls** rather than
  re-implementing them, so `renderTimerDesc` / `applySepForMode` / `setSunMoon` / `applyScene` / the cycle
  re-render all stay correct for free; only plain numbers touch `st`. `font` takes friendly aliases
  (`serif`/`jost`) because the real value is a CSS stack. `sound=` **empty is meaningful** (bell-only).
  Also `cfg.totalMin` is now written at Begin (computed where `Plan` lives) for the coming `/stage` intro card.
  Build clean. **This closes the blocker that descriptions could not deep-link a preset.**
  **`tools/video-directory/index.html`** — self-contained 17 KB page, no dependencies, no network, `noindex`.
  Holds **every combination of every Setup control** without storing them: each combination is a
  **mixed-radix index** decoded on demand. **905,748,480 combinations** (452,874,240 reachable in Setup — it
  forces separator=none at middle/ledge; 226,437,120 recordable — `hover`/`never` are unusable in a capture).
  *The earlier “6.7M” figure counted a smaller axis set.* Verified: index↔config round-trips exactly over
  200k random samples, closed-form validity counts match Monte-Carlo to <0.2%, and filtered subspaces
  enumerate uniquely with no scanning. Virtual-scrolled; ticks in `localStorage` with JSON export/import.
  **Monthly wave loop:** *Export next month* takes the first 30 unmade+recordable matches of the current
  filter and writes `wave-YYYY-MM.md` — a day-numbered table **plus an end-of-month review checklist**
  (which axis won; low impressions = relevance/targeting vs high impressions + low CTR = thumbnail; real RPM;
  subs per 1,000 views). Filter → shoot → tick → review → re-filter. **Discipline: judge the AXIS, not the
  video — compare like-aged cohorts only**, since §2's curve makes a 3-week-old upload at 400 views on-plan.
  Deploy is founder-run (`wrangler login` is interactive OAuth):
  `npx wrangler pages deploy tools/video-directory --project-name sustain-directory` — keep it a **separate
  Pages project** from `sustaintimer.com`.
  **vidIQ competitive scan:** the niche is **growing and entry is viable** — Work Mode Audio +54%/mo subs,
  Power Hour Focus +37%, Focus Room +32%, GooDuck +23%, all at 5–20K subs; **faceless is the norm** (4 of the
  fastest risers). **The subscriber bottleneck is confirmed in data:** Study Pomodoro averages 98,246 views/
  video on 47,300 subs at **+0.2%** monthly sub growth — people use the tool and leave. Adjacent segment
  noted for later: **classroom timers** (`classroom timer` 6,986/mo).
  **⚠️ STILL OWED:** the `/stage` intro (10 s) + thank-you (7 s) cards the founder specified — auto-written
  from `cfg`, over the blurred scene, before the 3-2-1 and in place of the bare fade-to-black.

- **2026-08-02b (video roadmap + metadata contract; domain secured; bell audible; cadence → daily)** —
  **`docs/youtube/video-roadmap.md`** — **Wave 1: 94 videos, every config decided, tickable**
  (regenerate: `node docs/youtube/gen-roadmap.mjs`). Phases A–F, one row per capture
  carrying mode/interval/duration/breaks, light, sun&moon, numeral placement/fill/font/separator/colour,
  per-sound volumes + master, finished title, per-video tags, and a video-ID column; Phase A ships
  ready-to-paste descriptions with **computed chapter timestamps**.
  **Cadence revised UP to one capture/day (~30/month)** in the same session: the reason for every-other-day
  was that titling/uploading do not automate — the roadmap now ships finished titles, budget-fitted tags and
  computed-chapter descriptions, so desk work collapses to *configure, upload, paste, tick*.
  **Scoping — the space is real and enormous.** Counting only genuine product differences
  (`interval 7 × duration 6 × time-of-day 9 × sound 16 × timer-display 2`), **one theme = 15,552 videos**;
  with the cosmetic axes multiplied back in (×432) it is **6.7 million**, i.e. **43 years at one a day**.
  So Wave 1 is a **publish order through a reservoir**, not the catalogue; Wave 2 is written from Phase A–B
  Analytics, and `5 min` display opens a full parallel catalogue there. Wave 1 is cut to 94 by two rules: an axis multiplies **only if people search it**
  (placement/fill/font/separator have **zero** volume), and multiplying by invisible axes is *literally* the
  inauthentic-content policy's *"minimal variation"* wording — a **monetization risk, not just waste**. Those
  axes are **rotated** for variety at zero catalogue cost. **Uniqueness is enforced, not assumed** — the
  generator throws on any repeated config tuple, and caught a real duplicate on first run (Phase E re-adding
  a bell config Phase A already held); the key spans every axis so future waves self-check. `Hover`/`Never` timer visibility are unusable in a
  recording (no mouse / hides the product) — every row is `Always`. Numeral colour is chosen **per light**
  (charcoal is invisible at midnight; moving sequences are restricted to Ivory/Gold).
  **Workflow changed on founder's call: one capture = one video.** The bell-only twin (splitting one
  recording into two SKUs) is dropped — it doubles titling/uploading, the scarce resource, while captures are
  unattended. No-music videos are **their own rows**. Capture guide §6b demoted to OPTIONAL.
  **`/stage` bell CONFIRMED audible** in a Browser Source — pressing Begin inside the source *is* a user
  gesture, so §6's "never receives one" holds only for a source you never interact with. No post-mux needed.
  **Domain `sustaintimer.com` SECURED (Hostinger)** — closes handoff blocker #1; canonical/sitemap/robots
  already assumed it. Deploy still needs `wrangler login`.
  **Metadata contract:** YouTube **"pulls" per viewer** rather than testing on a cohort; of Engagement /
  Satisfaction / **Relevance**, only **Relevance** is ours to write (title, description, transcript,
  **on-screen text in the first seconds**). **Category = Education** (brand-safe, ~$5–15 RPM vs much lower
  for Music) and **Made for kids = No** (yes ⇒ no personalised ads, contextual pays **50–80% less**, comments
  off). Tags are low-weight by YouTube's own docs (misspellings/ambiguity) — Upload defaults already use
  **353/500 chars**, so each row's extra tags are generated to fit the remaining **147**, rotating one
  **non-English** term (the one thing a tag adds that an English title cannot; `ポモドーロタイマー` = 272k/mo,
  and Timer Palette's top videos tag in 8+ languages).
  **⚠️ Two code findings.** (1) **§18.7 is stale** — it lists `/stage` params `record / flow / loop / phase /
  timer`, but only `record` and `stopstream` exist; the `eabfb05` rewrite replaced the rest. (2) **No page
  reads session config from the URL** (`URLSearchParams` appears 3×, none of them config; config lives in
  `localStorage.cfg`), so **descriptions can only link the bare domain** — the deep-linked preset that the
  "video is the ad" thesis depends on **does not exist yet.** Small feature; worth building before the
  catalogue grows, since descriptions are painful to retrofit across 95 videos.
  **Product opportunity:** relevance counts on-screen text in the first seconds, but our lead-in is a wordless
  3-2-1 on a near-silent video with no transcript — showing `50 / 10 · 4 HOURS · SUNSET` during the lead-in
  would fix it honestly. **Founder call — touches the `/stage` look.**

- **2026-08-02 (YouTube channel strategy — strategy §10's "never revenue" is REVISED)** — Research +
  strategy written to `2026-08-02-youtube-channel-strategy-design.md`. **The §10 tension flagged in the
  session handoff is resolved with evidence: "marketing, never income" is true for LIVESTREAMS and false for
  VODs.** A livestream serves one pre-roll per viewer (College Music: 38M watch-minutes → ~$1,300 lifetime);
  a VOD ≥8 min carries **mid-rolls**, and this niche averages **2–4 h view duration** vs a ~7 min platform
  average. The founder's reference channel **Timer Palette** (`@timer.palette`, vidIQ 2026-08-02): created
  2025-02-10, **73.3K subs, 14.47M views, 592 videos, ~$3,273/month, ~$2.47 RPM**, 2 uploads/day, **zero
  Shorts**. §10 and `docs/obs-stage-streaming-guide.md` §8 both updated; the guide's default workflow flips
  from **YouTube Live → record-locally-then-upload**.
  **The finding that governs everything:** their biggest video had **649 views at 2.5 months** and **2.67M at
  13.5 months** — ignition at ~5.5 months, then compounding. ~50 of 592 videos carry ~85% of views. **This is
  a library that ignites late, not a hit business; the channel cannot be judged before month 6.**
  **Algorithm (2026):** five separate systems; **viewer satisfaction has overtaken raw watch time**, and
  **session contribution** leads for long-form — a 2–4 h timer is an unusually good fit, and **repeat views**
  (people re-run the same timer daily) are the format's superpower. **Search is our primary surface**
  (`pomodoro timer` 415K/mo, `study with me` 2.53M/mo) — so `hourglass timer` (4K/mo) is the *differentiator,
  not the query*.
  **Risk:** the **inauthentic content** policy (renamed 2025-07-15) demonetises templated/mass-produced
  uploads. Our defence is that `/stage` captures a **real-time render that never repeats a frame** — so
  **never re-upload a render**, never use unowned music, keep the OBS project files as provenance, and carry
  an originality declaration in the channel description.
  **Product implication for the web build:** `/stage`'s catalogue axes are the content grid — interval ×
  length × **time-of-day** (ours alone; nobody else's timer has a moving sky) × audio. Every description
  links the exact preset URL that produced the video.
  **Founder decisions, all resolved same day:** (1) **channel is branded Sustain and already live —
  `@SustainTimer`**; (2) **audio = both, sequenced** — ship bell-only + ocean now, add our own synthesised
  brown/pink/white noise beds once the pipeline is proven (`brown noise for studying` = 199K/mo, and §6.1.4
  ships no music, so we generate rather than license); (3) **cadence = one capture every other day**
  (~30 uploads/month with the bell-only twin — half Timer Palette's rate, so expect later ignition).
  **Capture guide gained §3b/§3c/§6b:** Recording tab settings (**CQP 18, not CBR** — CBR is for streaming;
  our frame is nearly all gradient, which is where banding shows), a pre-flight test-capture checklist, and
  the **two-audio-track trick** — record once with the bell on Track 1 and the ambient bed on Track 2, then
  `ffmpeg -c copy` splits one capture into two upload-ready SKUs. This scales to the phase-2 noise beds with
  **no extra capture time**. **Untested and flagged:** whether the session bell is audible at all inside an
  OBS Browser Source (§6 says no user gesture; §4's Begin click may supply one) — founder verifies on-device.
  **One correction worth carrying:** do **not** copy Timer Palette's *"AI was not used"* declaration — our
  plates **are** AI stills (strategy §12), so that would be false. Our honest and stronger claim is that each
  video is a **real-time capture of our own render engine** — no loop, no slideshow, no session recorded twice.

- **2026-08-02 (`/stage` = real Setup + chrome-free session; cycle apply; the "5 min" option was inert)** —
  `/stage` reworked from URL params to **the same app minus the session chrome**: configure on the real Setup
  screen, Begin → fullscreen + `obsstudio.startRecording()` → blurred **3-2-1 lead-in** → bell → session with
  no UI → **fade to black** → `stopRecording()`. `SustainScene.restartSession(freeze)` added so the block
  starts at EXACTLY its full length (pause/resume kept the ~80 ms before the pause landed, so 25 min began at
  24:59). Session gains a `STAGE` flag (no nav guard, no `beforeunload`, no duplicate start bell).
  **Cycle apply:** the builder and the presets now edit a **draft**; "Use this sequence" is disabled while it
  matches what will run, and Begin serialises the **applied** cycle so unapplied edits cannot run silently.
  The Themes panel names the cycle in use.
  **The "5 min" timer option did nothing** — mapped to `'always'` behind a `// 5min→always for v1` shortcut
  while its description promised "surfaces briefly every 5 minutes, then fades away". Implemented as `flash`
  (show at start, fade ~4.2 s, repeat every 5 min, anchored to session start); `setTimerVis` now recognises
  it instead of falling through to `always`. **This class of bug — a control that lies about what it does —
  is invisible to change-scoped audits; a UI-contract audit is owed on the Session sheet and the modes.**
  Also: Setup's `.themes-scroll` declared only `overflow-y`, and a `visible` axis computes to `auto` when the
  other is not — hence a stray horizontal scrollbar; `--sq` capped 640→600 px so entering fullscreen no
  longer grows the panels. Guide: `docs/obs-stage-streaming-guide.md` (Browser Source only, encoder settings,
  Page-permissions=ALL, and the Windows "logs out" symptom that is actually **locking**).

- **2026-08-02 (`/stage` BUILT + OBS capture guide; scroll scrubbed to position; sunset accuracy)** —
  **`/stage`** (§18.7, first-push §4.4, strategy §10) ships as `src/pages/stage.astro`: a chrome-less
  fullscreen view reusing the **same** scene island ("the site is the studio; we do not build a second render
  engine"), `noindex`, with `record` / `stopstream` params *(as built; the `flow`/`loop`/`phase`/`timer`
  params named in this entry were superseded by the `eabfb05` rewrite)* and a long looping focus
  block so the sand always falls. Capture guide added at `docs/obs-stage-streaming-guide.md` — **Browser
  Source only**, never Window/Display Capture (that screen-scrapes a throttled background tab, the cause of
  the freeze/black-screen glitch), plus current encoder settings (NVENC AV1 8000 Kbps / H.264 9000, CBR,
  2 s keyframe) and the honest note that `/stage` does not start scene audio because a Browser Source never
  gets a user gesture.
  **Scroll:** the story is now **scrubbed to scroll position** — each chapter's `--o`/`--y` are written per
  frame from the same value that moves the sun, so text and sky are one signal instead of two systems; snap
  softened `mandatory`→`proximity` (mandatory yanked from anywhere, which is what felt chopped) while
  `scroll-snap-stop:always` still prevents skipping; day span 12 h→6 h so the light drifts rather than jumps.
  **Footer** was rendering *under* the artwork: `.runway`'s `position:relative; z-index:0` created a stacking
  context that trapped the footer's `z-index:8` below the fixed scene.
  **Sunset accuracy:** removing the on-load geolocation prompt left only timezone→representative coords, and
  `Asia/Kolkata` = `[23.5, 80.0]` is ~9° east of Rajkot (~37 min of sunset). Now the Permissions API is
  queried and exact location is used **only when already granted** — no prompt, so §5's rule holds.

- **2026-08-02 (Landing REBUILT as a pinned story + full responsive/mobile pass)** — The scrolling-page
  landing was rejected by the founder ("no design, no UI/UX… just ugly") and replaced with a **pinned story**
  (§4.2): the background never changes, only text chapters cross-fade while the day advances. Chapters are one
  statement + ≤3 short points on a glass plate, flanks swapping, both blocks on the same grid row. Section
  **scroll-snap** (mandatory + `stop:always`) replaced a JS-damped follow whose easing was the unwanted
  momentum; runway shortened to `0.75svh`/chapter (890→375 svh of scrolling). Footer became a blurred `50svh`
  sheet that genuinely scrolls up. Design skills consulted per the founder (impeccable, ui-ux-pro-max,
  modern-web-guidance) — their bans on glass-as-default, identical card grids and cards-as-the-lazy-answer
  named exactly what was rejected.
  **Root-cause fixes (each explains a symptom the founder reported):** *(1)* **blur popped in late** — an
  ancestor with `opacity < 1` is a **Backdrop Root**, so a fading parent makes `backdrop-filter` sample an
  empty group until opacity hits exactly 1; the fade moved to leaf content and the plate animates its blur
  **radius**. *(2)* **flipped chapters looked staggered** — grid auto-placement never moves backwards, so
  `.say` taking column 3 pushed `.tell` into row 2; both pinned to `grid-row:1`. *(3)* **burger stopped
  opening after the hero** — `.chapters` at z-index 6 with an `inset:0` active chapter was a full-viewport
  click shield; interactivity moved to `.say`/`.tell`. *(4)* **text looked washed out** — chapters at z-index
  4 sat *under* the hero's `.vign`/grain; raised to 6. *(5)* **headings broke into four lines** —
  `text-wrap:balance` optimises for even line lengths; replaced with non-wrapping line spans sized from the
  flank width and a per-chapter `--n`. *(6)* **scroll cue read off-centre** — the hourglass axis is `S.cx`
  (49.885%), not 50%, and `innerWidth` includes a scrollbar the percentage does not; `--hg-axis` is now
  published from the frame's real `offsetLeft` and the scrollbar is hidden.
  **Mobile (§4.3):** burger nav; Setup restacked to the founder's order with `--sq` capped by width (it asked
  for a 691 px column on a 390 px screen); Session forced to **Top** numerals with viewport-unit geometry
  (plate-relative units put them off both edges); **`hover` visibility now means `always` on `(hover:none)`,
  which is why a phone showed no timer at all**; 44 px touch targets on coarse pointers; snap stops in `svh`
  with the stop height **measured**, not derived from `innerHeight`.
  Also: the symmetric hero `.vign` (both flanks) is now the standing legibility bed.

- **2026-08-02 (Landing page BUILT + SEO + legal pages; two real bugs found)** — Full scroll landing shipped
  (§4.2; design doc `2026-08-02-web-landing-page-design.md`): five bands flanking the hourglass **spine**
  (`--hg-w` published by `fit()`), **scroll sweeps the day +12 reference hours** from the viewer's real local
  sky, `.deep-scrim` + `scene-deep` blur for legibility, native-`<details>` FAQ with `FAQPage` JSON-LD,
  footer. Hero **unchanged** (its empty right flank is deliberate). SEO: canonical/OG/`SoftwareApplication`
  JSON-LD, `robots.txt`, `sitemap.xml`, generated `og-cover.jpg`. `/privacy` + `/terms` moved out of
  `docs/legal/` into the site (now covering the web version), closing the launch P0.
  **Bug 1 — unprompted location request:** `scene.js` called `preciseSunTimes()` (→
  `navigator.geolocation.getCurrentPosition`) **on load**, throwing a permission prompt at every visitor —
  against §5's locked "timezone→coords, no permission prompt" decision and fatal for landing-page conversion.
  Removed from load; kept as `SustainScene.useExactLocation()` for the opt-in control §5 defers.
  **Bug 2 — all six plates loaded eagerly** (~960 KB before first paint), violating §13's "load one plate,
  not six": plates now load **on first use**, and `reveal()` warms the rest **after** first paint.
  Also: dropped the unused JPG/PNG source plates from `public/` (deploy −1.3 MB).

- **2026-08-01 (Break screen + endless block-loop + day-cycle retune + nav — session handoff)** — See
  `2026-08-01-session-handoff.md` for the full state. Highlights: **Break** is now its own blurred screen
  (BREAK + floored countdown + End break; no pause/Break button, scene numerals hidden, audio muted, never
  pausable) in all modes. **Endless** redesigned to loop a chosen block (25/5, 50/10, 90/15, 52/17) counting
  DOWN, breaks on the break screen (no stopwatch). **Day-cycle** retuned to real astronomy: twilight ~1.1 h,
  sun glow dies ~19.5 ref, moon rises after glow (19.7) / sets before dawn (4.6) — never coincident; warped to
  real sunset via SunCalc (fixes twilight-at-9-PM). **Single picked phase** now drifts through the FULL phase
  window (`PH_SPAN`) stretched over the whole session (witness sunrise/sunset happen), and the phase pick no
  longer gets overridden by live-follow. **Nav**: Setup Back→Home; back/swipe never re-enters a spent session;
  guard hardened vs double-back. **Defaults**: sounds OFF, timer On-hover. Repo decluttered to `_internal/`.

- **2026-08-01 (Session/Setup integration audit + fixes; day-night timing; endless redesign)** — Founder-found
  integration/UX bugs (engine math was fine; these were wiring/defaults): **break countdown floated**
  (`remainingSec % 60` not floored → added `mmss()`); **pause + Break buttons showed during a break** (now
  only End break); **sounds defaulted ON** → all OFF; **specific time-of-day was ignored** (default
  `cfg.cycle.preset='follow'` overrode the pick → `buildCycle` honors `followDay/phase`); **Setup Back** used
  `history.back()` (could land on a spent `#session`) → always Home; **back/swipe re-entered a spent session**
  → any back-nav into an un-armed `#session` bounces Home (reload still shows the ended popcard; in-session
  guard unchanged + hardened with a 2-deep buffer vs double-back); **timer visibility default → On hover**.
  **Break = its own screen** (blurred, "BREAK", floored countdown, End break; no hourglass, no sound). **Break
  button** = skip to your next scheduled break (honest focus credit via truncation); **End break** = end the
  rest early. **Day-night timing** (was twilight-glow at 9 PM): reference twilight shortened to end ~19.5
  (night ~1.1 h after sunset, not 2 h); `SUN_ALT` glow dies by 19.5; `PH_HOUR` twilight → 19.0; **moon**
  window rises 19.7 (after glow) / sets 04:36 (before dawn glow) so sun & moon never coincide. **Single picked
  phase now WITNESSES the phase**: it drifts across the phase's window (`PH_SPAN`) over the WHOLE session
  (a 5 h "sunrise" = pre-dawn→sun-up→into-midday over 5 h), not a frozen mid-point. **Endless redesigned**:
  the open-block/manual-flip is gone; the user picks one of **4 blocks (25/5, 50/10, 90/15, 52/17)** which
  **loops forever counting DOWN**, its break using the break screen; exit = "End". Circular favicon
  (`favicon-round.png`). Engine regression 5/5 + endless-loop/skip-break tests green.

- **2026-08-01 (Repo declutter + project README + session-state status)** — Web-only reorg (founder: don't
  touch `web-astro/` or the Flutter app, move-not-delete): moved the 8 loose root items — `site/`,
  `web-prototype/`, `tools/`, `icon images/`, `plates without hourglass/`, `FGS Proof/`, `APP DESCRIPTION`,
  `skyline-matte (1).png` — into a single **`_internal/`** folder via `git mv` (140 renames, history preserved,
  nothing deleted). Verified: pubspec assets + web-astro are self-contained (no refs to the moved dirs), so
  both builds are unaffected (web build re-run green). Updated `CLAUDE.md` (design refs now `_internal/site/` +
  `_internal/web-prototype/`), added `_internal/README.md`, and rewrote the root **`README.md`** as the full
  project doc (structure of every folder/key file, features, workflow, session states, build/run). **Session-
  state gaps flagged (not yet built):** (a) Endless **flip** should let the elapsed timer *continue* while only
  the sand refills (currently resets, like session.html) — needs to decouple the sand visual from elapsed;
  (b) **break audio-duck** (hush ambient on breaks) not yet ported to `SustainAudio`. Session-end / pause /
  give-up / popcards / guard all confirmed working.

- **2026-08-01 (Session in-depth browser audit — fixed dead buttons, sheet styling, Setup corruption)** — Ran a
  real Chrome-DevTools walkthrough (Home→Setup→Session, every control, console). Bugs found + fixed:
  (1) **ID collision** — the session sheet reused Setup's element IDs (`tokens`/`vol`/`volPct`/`mixRows`/
  `swatches`/`tod`); Setup renders first, so `getElementById` returned Setup's, and the session's `buildTokens`/
  `buildTod` overwrote Setup's Sound + Time-of-day on every load → namespaced all to `sess*`. (2) **Dead
  pause/give-up/gear** — two overlapping click-blockers: Astro's **dev toolbar** (z-index 999999) over the
  bottom-centre pause button (disabled via `devToolbar:{enabled:false}` so dev matches prod), and an
  **invisible `.sheet-scrim`** because Astro scopes `.session-screen > *{pointer-events:auto}` to a higher
  specificity than `.sheet-scrim{pointer-events:none}` → dropped the container `pointer-events:none`/`> *`
  pattern (children interactive by default; closed overlays keep their own `none`). (3) **Unstyled sheet
  controls** — the tokens/scene-tiles/mixer are built with `createElement`, so they never get Astro's scope
  attribute → moved their styles to a `<style is:global>` block prefixed `.session-screen`; also fixed the
  Scene captions to Setup's labels ("Follow my day"/"Pre-dawn"…) and restored the gear's `class="frost"`.
  (4) **Reload popcard** — `begin()` bailed on `!SustainScene` before the armed check; reordered so the armed
  one-shot shows the session-over popcard first (retry-starts once the scene loads). (5) Console cleanups:
  favicon (`/brand-icon.png`), preload crossorigin (matched `#themeImg` to the anonymous plate fetch),
  aria-hidden focus (blur a hidden screen's focused descendant in the controller). Verified in-browser: pause
  freezes + "PAUSED" overlay + gold ring, give-up confirm, gear opens a fully-styled sheet, Setup uncorrupted.

- **2026-08-01 (Session page — COMPLETE port of session.html: paused overlay, settings sheet, audio, chrome)** —
  Finished the full session to match the locked `session.html`. **Chrome** (session.html positions): `#gear`
  top-left, `#giveup` top-right (quiet uppercase), `#pause` bottom-centre frost circle (play/pause swap + gold
  paused ring), `#intentTop` top-centre, `#flipBtn` (endless) above pause; all idle-fade via `.session-screen.active`
  (wake on pointer, held while paused). **Paused overlay** `#paused`: backdrop-blur scrim + "Paused" + grace
  line, tap-to-resume, audio muted while paused. **Settings sheet** (`#gear` → frost sheet, ported from
  Setup): Sound (tokens + master vol + per-sound mixer), Timer (vis), Number-look (place/fill/font/separator
  with the per-mode rule enforced/colour swatches+picker), Scene (time-of-day grid with plate thumbnails +
  auto-contrast) — every control live-drives `SustainScene` (number look/day/vis) or `SustainAudio` (sound) and
  persists to `localStorage`. **Audio**: new shared `src/scene/audio.js` (`window.SustainAudio`) — the LOCKED
  Setup mixer graph (gapless crossfade loops, K-gains, tone-notch, ocean→sand sidechain, bird tide) + a soft
  `cue_bell` ring at start / each break / end; imported via `scene.js`. Setup now stops its **preview** mix on
  leave (no double audio) and no longer forces `setDay('follow')` when entering the session. **Wake lock** kept
  through the session. **Dev-server note:** heavy component edits can leave Astro's dev HMR serving stale
  scoped CSS (looked "unstyled") — a dev-server **restart** is the fix, not a browser reload.

- **2026-08-01 (Session Phase C — chrome + back-proofing, fixes the "stuck focusing" leak)** — Ported the
  decided session chrome from `session.html` into `Session.astro`, adapted to the hash-routed SPA. **Navigation
  guard** (the bug fix): on session start `guardActive=true` + `history.pushState('#session')`; a `popstate`
  (Back/swipe) re-pushes `#session` and shows the toast *"Use Give up to end your session"* — a running session
  can no longer be backed/hash-routed out of by accident (so it can't leave a half-live "focusing" state on
  Setup). `beforeunload` warns on reload/close. Guard is cleared ONLY by an intentional exit (`exitToSetup`);
  it is NOT armed in `?tune` mode. **Armed one-shot** now shows the **session-over popcard** ("This session has
  ended → Back to Setup") on a reload/stale/direct entry, instead of the earlier silent redirect. **Popcards**
  (deep-glass frost + scrim, ported CSS): give-up confirm ("Give up this session?" Keep going / Give up),
  completion ("Well done · you focused Xm" Again / End), session-over. **Give-up** quiet corner control.
  **Pause cap**: 3 min + 15 s grace → auto-end (app parity), with a live grace toast. **Completion/segment
  poll** watches `SustainScene.sampleSession()` for `done` (→ done popcard) and focus↔break changes (→ toast).
  Chrome idle-fades after ~4 s, wakes on interaction, holds visible while paused. Still TODO: Phase D in-session
  settings sheet; focus-credit ≥2 min parity + audio bell cues live in the session.

- **2026-08-01 (Session numerals — geometry LOCKED + tuner made opt-in)** — Founder perfected and locked the
  per-mode `size`(cqh)/`dy`(%) in `NUM_DEF` (scene.js): **horizon 13 / −3.5, middle 20 / +5, top 15 / +2.5,
  ledge 20 / +8** (X/gap/tb-top unchanged). The baked `NUM_DEF` is now authoritative for all sessions — the
  `localStorage['sustain.numTune']` override applies **only** in tuner mode (`window.__numTuneMode`), so stale
  tuning can't diverge shipped numbers from the lock. **Tuner is now opt-in via `?tune`** (e.g.
  `…/?tune#session`): removed from the site/production, but kept for backend tuning of future themes/plates
  (mode buttons + Size + Vertical-nudge sliders + Copy JSON). Not present in a normal session.

- **2026-08-01 (Session numerals — per-mode separator rule + steady session scene)** —
  **Separator is per-mode** (from `number-lab.html applySepForMode`, was being ignored): Middle/Ledge force
  `none` (the hourglass glass is the divider between the wide-flanked numbers); Top/Horizon use the user's
  `colon|dot` and **can never be none**. `scene.js` now tracks the user's pick in `numSep` and `applyNum` sets
  `data-sep` via `sepForPlace(place)`, so switching modes (incl. the tuner) always gets a legal separator. This
  fixes horizon showing an empty centre gap when the cfg default `sep:'none'` leaked through. **Session scene
  is now steady**: `:root.session-active #frame { animation:none; transform:none }` stops the breathing
  zoom during a session (held zoomed-out) so the hourglass/numbers don't drift; Home still breathes.

- **2026-08-01 (Session numerals — per-mode geometry restored + live dev tuner for size & vertical nudge)** —
  Founder is re-perfecting numeral geometry against THIS build's plate framing (the lab values don't map 1:1).
  **Each mode keeps its OWN designed X/position** (restored byte-for-byte from `number-lab.html` /
  `timer-modes.json`): horizon sits wide-left (`--dx -30%`, `--hg-cx 50%`, gap 3cqw), top/middle/ledge flank
  the hourglass axis (`--hg-cx 49.79%`) at their own gaps and vertical bands. `scene.js` `NUM_DEF` holds the
  full geometry `{size, dy, gap, tbtop, hgcx, dx}` per mode; `applyNum(place)` writes it (X/gap/tb-top locked)
  plus the tuned `size`/`dy`, and selects the active place so the occluder follows. **Live tuner** (localhost
  only; `⧗ tune`, bottom-right of a session): mode buttons + **Vertical-nudge** (`dy`, ±60%) and **Size**
  (cqh) sliders — the ONLY two editable axes; X never moves — writing through
  `SustainScene.editNum(place,size,dy)` to `localStorage['sustain.numTune']`, which overrides `NUM_DEF` (tuned
  values persist + apply in normal sessions). Panel shows a live JSON of all four modes with Copy/Reset; once
  perfected these get baked into `NUM_DEF`. *(Correction of the earlier same-day attempt that wrongly unified
  X and moved horizon.)* Occlusion logic (corrected per `number-lab.html`): **glass occludes every mode,
  horizon adds the sea, ledge has no cut** (numbers rest on the ledge).

- **2026-08-01 (Session screen — Phase B: numeral styling per cfg + self-hosted overlap-removed fonts)** —
  Ported the LOCKED `session.html` numeral system into the scene. `#nums` wraps `#mm`/`#sep`/`#ss` inside
  `#frame` (now `container-type:size` so numerals size in `cqh` like session.html's `#scene`); the numbers
  flank the hourglass axis (`--hg-cx`=`S.cx` 49.885%) so a wider font grows outward while inner edges hold.
  **cfg-driven look** via `SustainScene.setNumStyle(cfg)`: font, colour, `data-fill` (solid / glass /
  **outline** hollow-stroke), `data-sep` (colon / dot / none), and the byte-for-byte **LOCKED per-place
  geometry** (`NUM_LOCKED`: size/gap/weight 550/stretch + `--dx`/`--dy` fine offset) for the 4 placements
  (horizon / middle / top / ledge). **Auto-contrast** ported from `session.html setTone` (a dark chosen
  colour lifts toward white on dark plates only) — `bgLuma` estimated per phase (`PH_LUMA`) and blended live
  each frame off the day cycle (throttled). **Fonts:** copied the 10 **overlap-removed** (`fontTools
  removeOverlaps`) static woff2 from `site/assets/fonts/` → `web-astro/public/assets/fonts/` and self-host the
  550 weights as numeral-only families **`NumSerif`/`NumSans`** — the clean single-contour glyphs are why the
  outline fill's `text-stroke` doesn't double (Google variable faces would). Rest of the site keeps its Google
  faces (Home's Jost 300 unchanged); widened the Google URL to add upright Newsreader (popcard titles) + Jost
  600 (Setup).

- **2026-08-01 (Session screen — depth occlusion: numbers pass behind the hourglass / sea / ledge)** —
  Ported the locked depth effect over the LIVE WebGL scene. Layer stack inside `#frame`: plate `#glitter` (0)
  → `#nums` (1) → **`#occ` occluder** (2) → `#sand` (3, on top so grains still read inside the glass). Each
  frame (session only) `#occ` **copies the live `#glitter` render** and keeps only a silhouette via
  `destination-in` — so it matches the plate exactly (crossfade, sun/moon, glitter), which a static CSS
  plate-copy could not. The silhouette mattes come from the scene's **own `maskCv` channels** — **G = glass**,
  **R = sea** — the same mask the shader composites with, so occlusion tracks the founder's re-traced
  hourglass (not the older `hourglass-matte.png`); ledge = a hard bottom-11.3% cut. Matte per placement:
  middle/top → glass, horizon → sea, ledge → ledge. Mattes rebuild with the mask (`buildOccMattes` in
  `drawSand`); cleared on `endSession`. `WebGLRenderer` now `preserveDrawingBuffer:true` so the per-frame
  `drawImage(glitterCv)` readback is reliable across GPUs. **Founder to verify on-device:** the occluder
  alignment/readback, the `#frame` `container-type:size` (numeral sizing), and the `#sand`-on-top reorder.

- **2026-08-01 (Session screen — Phase A: engine wired to the shared scene)** — Discovered `scene.js`
  **already owns** the session engine (`createSession()` from `lib/timer.js` driving `S.prog` sand +
  `#mm`/`#ss` numerals + `updateSessionUI`/`applyVis`/`bumpFocusedToday`/completion), so the Session screen
  **drives that engine from the Setup `cfg`** rather than porting `session.html`'s separate `SessionTimer`.
  **Plan reconciliation:** Setup builds plans with `plan.js` as `[{kind, min}]`; the engine wants
  `[{kind, dur(sec)}]` — added `session.setPlan(plan, mode)` to `timer.js` to run an external plan verbatim,
  and `Session.astro` converts (endless → a slow 45-min visual cycle the engine loops). **Scene API** extended:
  `SustainScene.startSession(plan, endless)` / `togglePauseSession()` / `endSession()` / `sampleSession()` /
  `setTimerVis(v)`. Numerals are gated on `:root.session-active` (SceneWorld) so they only appear in-session
  (never on Home hover). New `src/components/Session.astro` (rendered in `index.astro`): on `#session` it reads
  the `armed` one-shot (stale/refresh → home), consumes `cfg`, sets the day phase (`followDay`→'follow'),
  vis, and starts the session; shows the **intention line** + a **frost pause/play button**. Numeral
  styling per cfg (place/fill/font/colour/sep/auto-contrast) = **Phase B**; break/give-up/session-over
  popcards = **Phase C**; in-session settings sheet = **Phase D**.

- **2026-07-31 (Setup fully integrated over the persistent scene — Phases 1–5)** — Ported the LOCKED
  `site/setup.html` into `web-astro/src/components/Setup.astro` over the shared live scene (its static plate
  stripped). **Navigation:** one continuous document; **hash routes** (`/#setup`, `/#session`) via a controller
  in `index.astro`, so **Back / swipe-back work** (popstate/hashchange) and refresh can't 404. Screen swaps use
  the **View Transitions API** (cross-fades snapshots → the frost panels' backdrop-filter can't first-paint-pop).
  Setup **glass-blurs the scene** (`:root.setup-active #frame`). **Phases:** (1) transition + shell; (2) timer
  plan via `plan.js` (public/js/, `window.Plan`) — modes/durations/readout/canvas, mode pill positioned by a
  **pure-CSS index** (no measurement); (3) Themes drive the scene through a new **`window.SustainScene`** API
  (`setDay(phase|'follow')`, `setSunMoon`) — time-of-day previews on the scene, Back restores the live clock;
  number-look + cycle builder are session config; (4) the full **Web Audio mixer** (tokens, per-sound volumes,
  Listen-now; gapless crossfade loops, loudness gains, tone-notch, ocean→sand sidechain, bird tide; files in
  public/assets/audio/); (5) **Begin** builds the full `cfg` → `localStorage['sustain.session']` +
  `sessionStorage['sustain.armed']`, then `#session` (Home+Setup dissolve, scene un-blurs — placeholder for the
  Session UI). **Astro-scoping gotcha:** JS-`innerHTML` elements don't get the scoped hash, so all injected
  controls are styled via a global block scoped under `.setup-screen`. Also fixed the plate preload crossorigin
  (match three.js anonymous CORS). Next: the **Session screen** (port `site/session.html`, consume `cfg`).

- **2026-07-31 (location-based day cycle + whiter moon)** — Implemented spec §5's `timezone → coords → SunCalc`:
  `src/scene/geo.js` maps the browser IANA timezone to representative coords (compact table + offset/mid-lat
  fallback) and returns today's real local sunrise/sunset via **SunCalc** (installed; imported CJS-interop as
  `import * as … ; const SunCalc = ns.default || ns` — plain default-import fails under rolldown). `scene.js`
  keeps the tuned schedule as a **reference day** (sunrise 6:00, sunset ≈18:24) and a **`warpTime()`**
  piecewise-stretches the viewer's real day onto it, so plates + sun + moon all shift to the region with no
  re-tuning. `SEG` retuned so the midday→sunset golden build starts **~1.5 h before sunset** (≈5 PM for India).
  The moon's arc lives entirely in the reference NIGHT, so post-warp it can **never coincide with the sun/glow**
  (true per-night moonrise + phases remain an optional follow-up, would drop the always-full moon). **Moon
  recoloured whiter/cooler**: `uMoonWarm`/`moonWarm` 0.55→0.15, disc pure white, glow lightened
  (`moonGlowCol #cfe4ff→#e0efff`, `moonFarCol #6f8fd0→#9db6e4`). *(Lab `hybrid.html` unchanged — sync if
  re-tuning there.)*

- **2026-07-30 (CRITICAL: day cycle was frozen at noon — fixed)** — The live scene never actually followed the
  clock. The lab's `bind('phase', …)` runs its callback **once on init** (that's how `bind` works), and that
  callback sets `S.live = 0` + `S.daytime = 12`, so the deploy sat at **noon forever** (the blur-up placeholder
  showed the correct current phase, but the WebGL scene did not — the tell that exposed it). Fix: force
  `S.live = 1` after the lab binds run, before the render loop starts (deploy only; the lab UI that would
  re-disable it is hidden). The circadian sun / moon / plate cycle now tracks the real local clock as designed.

- **2026-07-30 (day schedule redesigned — proper per-plate windows)** — The old `SEG` was lopsided (midday
  held 08:45→16:42; pre-dawn only ~0.3 h). New full-day schedule (`scene.js` `SEG` + the LQIP/preload map in
  `index.astro`, kept in sync): **midnight 22:00→04:15 · pre-dawn 05:00→05:30 · sunrise 06:15→07:15 · midday
  08:45→15:00 · sunset 17:30→18:45 · twilight 19:45→21:00**, each with a smooth crossfade between (midday→sunset
  is a long **15:00–17:30 golden build**). `SUN_ALT` re-curved so the sun descends naturally after the 12:45
  peak (~0.52 height at 16:00) and sets into the sea ~18:20 — late afternoon now reads as late afternoon, not
  noon. Also fixed: the blur-up placeholder used a wrong hour-guess (flashed sunset ~16:00) — now uses the exact
  SEG segment phase. *(Lab `hybrid.html` still holds the old schedule; sync it if re-tuning there.)*

- **2026-07-30 (Home perf + load choreography + brand assets)** — "Advanced-engineer" pass. **Assets:** plates
  recompressed JPG→**WebP** (~1.7 MB → ~956 KB), moon PNG→WebP (390→83 KB) via `web-astro/gen-assets.mjs`
  (sharp; kept for regen). **No black screen:** a tiny base64 **blur-up LQIP** (auto-gen `src/scene/lqip.js`)
  shows the current phase instantly; the real **WebP plate is preloaded** (`fetchpriority=high`) and the scene
  reveals the moment that plate is decoded (`reveal()` in the loop, 3 s backstop), then the chrome fades in.
  Layering: `#lqip` (blur-up) → `#stage` (WebGL, fades in) → hero. **Tab-return flash fixed:** breathing zoom
  pauses on `visibilitychange`; loop `dt` clamped so the day-cycle/sand don't lurch after a hidden tab.
  **Brand:** nav symbol = the real **app icon** (`public/brand-icon.png`); Play button = the **official Google
  Play badge** (exact asset `public/google-play-badge.svg`, sized to the Begin-Focus button; guidelines folder
  gitignored). Nav = **wider floating island** (space-between), symbol clears the sun. Bottom tint eased (dark
  to the horizon, then fades up); halos already gone. Reveal motion = fade-up (no blur jank).

- **2026-07-30 (Home hero — Lovable-parity tuning + a global-CSS bug fix)** — Iterated the redesign against a
  Lovable reference the founder shared. **Root-cause fix:** the lab's `<style is:global>` in `SceneWorld.astro`
  had bare `button{width:100%}` / `input` / `textarea` / `label` rules **leaking onto every real button**
  (Home's CTA rendered full-width); scoped them all to `#ui`/`#session-ui` so they can't bleed into
  Home/Setup/Session. **Overlay:** headline + wordmark → **Playfair Display** (sturdier than the thin Cormorant);
  support forced to **one line**; content **grouped lower-left**, headline sized to **clear the centred
  hourglass**. **Legibility reworked:** dropped all halos/text-shadows (crisp-outline look the founder
  disliked) in favour of a **soft bluish plate tint** (darkest lower-left, clearing top-right). **Sky quote
  removed.** **Motion:** load **fade-in** (opacity + drift + de-blur, staggered; centred nav keeps its
  `translateX(-50%)`) and a slow **scene "breathing" zoom** (~60 s in→hold→out→hold on `#frame`, reduced-motion
  off). Files: `Home.astro`, `SceneWorld.astro`, `index.astro` (fonts).

- **2026-07-30 (Home hero REDESIGNED — "Composition A: left editorial")** — Founder pivoted off the v22 port
  (nav box, oversized cqi type, midday legibility) to a research-backed, award-lane redesign, brainstormed and
  **confirmed element-by-element** (impeccable + frontend-design). Chrome adapted from the founder's mockup:
  floating **glass-pill nav** (⧗ Sustain · in-page smooth-scroll `How it works · Science · FAQ` · Get-the-app
  pill; reverses the old text-only nav; Themes dropped) · eyebrow chip · two-line Cormorant headline
  **"Train your focus. / Transform your life."** · Jost support · **solid "Begin Focus"** + glass "Install on
  Play Store." Extras kept restrained: rotating Newsreader quote **lifted into the clear top-centre sky** (never
  the busy right side) and a **returners-only** "Focused today" line (hidden at 0). Halos for legibility;
  **type sized in vw, not cqi** (fixes the balloon). Full rewrite of `web-astro/src/components/Home.astro`;
  scene untouched; §4.1 updated. Nav anchor targets are stubs until the scrolling-landing pass.

- **2026-07-29 (plate fit + iron rule)** — Deploy scene switched to session's `assets/plates/*.jpg` (same
  image as `plates-phases` at lower res → sand stayed aligned, ~236 KB perf win, ledge-safe framing).
  Fill = `object-fit: cover` via a JS-positioned frame; vertical crop anchor **`SCENE_OY = 0.72`** (biased
  low so the ledge/hourglass base is never cut). Added **§5.1 — the LOCKED plate framing/fit iron rule**
  (seascape config + the 16:9 / central-60% / ≥20% sky / ≥18% ledge / pixel-locked spec for new themes).

- **2026-07-29 (glass outline re-locked + lab ergonomics)** — Founder re-traced the glass silhouette in the
  lab to fix the bottom pile reading as "out of the glass" (the issue was **Z-depth**, not X/Y — a floorLift
  attempt was tried and reverted as wrong). New `LOCKED_NODES` synced into both `hybrid.html` and the deploy
  `scene.js`; **outline LOCKED**, no persp change needed. Lab gained an **Edit-outline** toggle (S.dbg edit
  mode + timer controls hidden) and the same hide-controls-on-hover as the deploy. Depth lever documented:
  `S.persp` (the "Pile top-view (ellipse)" slider) sets the pile's forward bulge (`yC + rCone*k`).

- **2026-07-29 (living world in Astro)** — Ported `hybrid.html` into `web-astro/` (Astro 7.1.5): verbatim
  shaders (`src/scene/shaders.js`) + verbatim module (`src/scene/scene.js`, plumbing-only) + `SceneWorld.astro`
  (markup + CSS, lab UI hidden). Builds to a static site; dev server renders the WebGL sun/moon/glitter +
  canvas sand. **`scene.js` now diverges from `hybrid.html`** (deploy-specific behaviour below) — `hybrid.html`
  stays the look-tuning lab.
- **2026-07-29 (sand made session-driven)** — Founder feedback fixes in `scene.js`: the falling stream is now
  driven by a **session sand-clock**, not the wall clock — it **freezes mid-air on pause** (pile already froze
  via prog), **onsets from the neck** on each focus start (a `headFall` ceiling grows the stream downward over
  one fall-period; scatter ramps with it) instead of flashing full, and **starts immediately on Begin** (gate
  changed from `prog>0.001`, which cost ~1.5 s on long sessions, to "focus active"). The living sky keeps
  running on `tSec`. Basic controls now hide and reveal on mouse-move/tap (temp, with `#session-ui`).

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
