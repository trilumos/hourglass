# Sustain Web — Handoff: Setup LOCKED → build the Session screen

> **Read this first in the new chat.** It carries the full state so you can continue without
> re-deriving. Setup is done and locked; the next job is the **session screen**.
>
> Canonical strategy: [`2026-07-17-sustain-platform-strategy-design.md`](2026-07-17-sustain-platform-strategy-design.md).
> Setup build reference: [`2026-07-23-web-setup-build-spec.md`](2026-07-23-web-setup-build-spec.md) (🔒 locked).
> W1 scope: [`2026-07-22-sustain-web-w1-first-push-design.md`](2026-07-22-sustain-web-w1-first-push-design.md).

---

## 0. Hard rules (do not violate)

- **Never run the dev-browser MCP** (chrome-devtools navigate/screenshot/click) **without asking.**
  For "show me / run it": **start the static server and hand over the URL** — the founder opens it.
  Serve with `python -m http.server 8000` from `site/` → `http://localhost:8000/setup.html`.
- **Ponytail** (laziest-that-works) governs all code; **research-first** on anything versioned/API/
  pricing/policy; **latest stable versions**; cite official docs.
- **git/GitHub = always the `trilumos` account**, never ask. Commit only when the founder asks.
- **Aesthetic bar = Awwwards SOTM**; "too plain" is a valid rejection. Beauty must never cost speed.
- **Spacing principle** (memory `web-spacing-principle`): one scale, proportional, geometric, equal
  gutters, never congested nor marooned.
- **No-browser-testing**: the founder tests visuals himself.

## 1. Where things stand

- The web build is **plain static files in `site/`** (no framework, no build step). Astro migration
  is later. `web/` is Flutter's own folder — do not use it.
- **`site/setup.html` — the Setup screen — is BUILT & LOCKED.** Self-contained (inline CSS + JS).
- **`site/js/plan.js`** — DOM-free `SessionPlan` port (Flow/Pomodoro/Custom/Endless math), 15 self-tests
  (`node site/js/plan.js --test`). **Reuse this verbatim for the session timer.**
- **`site/assets/plates/*.jpg`** — 6 phase plates (compressed placeholders; founder regenerates ≥2560px).
- **`site/assets/audio/`** — real ambience files + `CREDITS.md` (provenance).
- **Everything is uncommitted** (branch `web-w1-timer`). Offer to commit at the founder's word.

**Nav flow (locked):** Home → *Begin Focus* → **Setup** → *Begin* → **Session** → *End* → **Setup**
(not Home). Home hero + the Home→Setup train transition are **not built yet** (deferred). In `setup.html`,
Back and Begin are **nav stubs** (visual only) — wire them when Home/Session exist.

## 2. Setup screen — what's built (for reference; it's locked)

**Layout — the constellation, geometry LOCKED (`:root` tokens, `overflow:hidden` enforces it):**
Sound (left) · **Timer (centre, wider: `--main-w = --sq × 1.28`)** · Themes (right). `--sq` is the
shared panel height; side panels flex equal and match it. Four equal gutters (`padding-inline == gap`).
Mode chooser floats above centre; Begin anchored page-bottom; **Focused today** = a typographic line
top-centre above the modes (reads `localStorage.sustain.focusedToday`, daily reset, `Plan.fmt`).

**Internal scale:** everything inside a panel derives from `--sq` (type on a 1.25 modular scale,
`--t-xs…--t-2xl`, `--t-num` for the hero number; `--ctrl-y/x`, `--r-inner`). This is why nothing looks
tiny in a big panel — see the research pass recorded in git-less notes / the build spec.

**Plate rule LOCKED (site-wide):** `object-fit:cover; object-position:50% 50%` — the plate never
shifts/zooms between screens. Setup adds a **noticeable softening blur** ("thin layer of glass"):
`.scene { filter: blur(5px) saturate(.96); inset:-14px }` (the inset only bleeds past edges so the blur
has no border; geometry unchanged). `.scrim` is a faint glass-sheen tint. **`backdrop-filter` did NOT
render in this stacking context — use a direct `filter` on `.scene`, not the scrim.**

**Timer (centre):** 4 modes, sliding pill, no Endless toggle. Big bold **white** number is the hero,
`⊖ number ⊕`, white description under it. Hybrid steppers (click-step, hold-to-ramp 400ms, click-to-type,
at-limit dim). **Pomodoro = ONE view, 3 settings** (Focus / Break / Blocks + preset chips 25/50/90;
long break = 3× short; no duration/blocks duality). **Custom = 3 settings** with a *By count / By interval*
chip. Both show a **session strip** (proportional focus/rest bars). Value boxes: primary is a wide box,
two supporting boxes pair beneath (2 rows). Endless = a plain prose line (no fake control tiles).

**Sound (left):** 4 world-ambience tokens (Sand · Ocean · Shore breeze · Seabirds), **selected = solid
white** (same language as chips). One master **Volume** (default **100%**, audio-tapered `(pos/100)^2.5`).
A **mixer button** by the volume opens a popover with **per-sound sliders — only for SELECTED sounds**,
live. **"Listen now"** toggle (setup is otherwise silent). See §3 for the audio engine.

**Themes (right, scrolls inside — thin scrollbar):** big Seascape preview, **Select-theme disabled**
(only world), time-of-day circles (Follow-my-day + 6 phases; picking previews the plate), sun/moon &
timer-display toggles with live descriptions, **Advanced settings** → centred sheet (cycle builder +
timeline preset-first, timer position, numeral style/scene-blur as W2-dimmed).

## 3. Audio system (built, works — reuse for Session)

- **Web Audio, not `<audio loop>`** (gapless). Files are the founder's **byte-identical originals**
  (`sand.m4a`, `ocean.mp3`, `breeze.mp3`, `birds.mp3`). No re-encoding — that caused codec "birdies".
- **Encoder whistles notched at playback** (`TONE_HZ`), per-source **low/high-pass** (`LOWPASS_HZ`,
  `HIGHPASS_HZ`) — never by re-encoding the files.
- **Crossfade-stacking loop** (`XFADE`, sine-window): sand stacks at 40% (3 layers) to cancel its level
  swing; ocean/breeze use a long simple joint.
- **Seabirds** don't loop as a bed — they run continuously with a **volume tide** (`BIRD_TIDE`
  = `[peak, faint, periodSec]`, uniform all day, ~12s swell/gap).
- **Three gain layers:** `SOUND_GAIN` (calibrated, K-weighted ITU-R BS.1770), `SOUND_VOL` (user mixer),
  `DUCK` (masking-aware: **sand ducks −14 dB under ocean**, breeze dips under ocean; live glide).
  `baseGain(id) = SOUND_GAIN × userMult × duckFactor`. A **limiter** on the output prevents peaks
  clipping. Current gains: sand 30 · ocean 2.2 · breeze 0.40 · birds 8.0.
- **No music layer.** Binaural + music slot were removed (see §4).

## 4. Money model — CHANGED this session (locked in strategy §6.1.3 / §6.1.4)

- **In-house music DROPPED** (not deferred to a tier). Can't own/sell AI music; royalty-free forbids
  resale; Lyria unreliable. `docs/lyria-music-prompts.md` is **shelved**.
- **Own-music = a free Spotify EMBED iframe** (never the Web Playback SDK; never paywalled; never
  "mix Spotify with our sound"). Not built yet — a W1 free follow-up.
- **The only sound money rule:** *You never buy a sound — you buy a world, and its sounds come with it.*
  A paid world ships its own soundscape; owned sounds play in any scene; no à-la-carte sound sales.
  This is also the licence guard (we only ever *integrate*, never sell a standalone file).
- Otherwise the model is unchanged: **Subscriptions rent features; only a one-time purchase owns
  one-time goods** (§6.1.1). Web cosmetics = worlds/scenes à-la-carte or a web lifetime bundle. Sync is
  the only honest recurring thing. W1 web = **$0, zero billing code.**

## 5. NEXT: the Session screen — what to build

Brainstorm it first (superpowers:brainstorming), then build in `site/session.html` (+ reuse `plan.js`).
Requirements from the strategy + W1 first-push §4.3–4.4:

- **The signature view:** `[min] · 🏺 · [secs]` — the hourglass is the divider; **numbers hidden by
  default, fade in on hover / mouse-move.** Honour the Setup **timer-display** setting (Always · Every
  5 min · On hover · Never) and **position** (Above · On the glass · Below).
- **The animated hourglass scene is `web-prototype/hybrid.html`** (locked: 6 plates, 24h crossfade,
  sun/moon, sand physics driven by `S.prog`). Port it in; the session ticker sets `S.prog =
  elapsed / segmentDuration` and the sand renderer already turns that into falling sand. Setup's static
  softened plate is NOT this — session uses the live scene.
- **Timer engine (the real unbuilt product):** one ticker; elapsed from **wall-clock timestamps**
  (`Date.now() - startTs - totalPausedMs`), not accumulated rAF ticks (must stay correct when the tab is
  backgrounded). Segments come from `plan.js buildPlan(st)` (focus/rest list). Rest segments auto-advance
  with a soft cue; **Endless**: user triggers breaks, glass drains→flips→refills.
- **Controls:** Start / Pause / Reset; on completion a gentle cue, **increment `localStorage.
  sustain.focusedToday`** (the Setup ring/line reads it — `{date, min}`, daily reset), calm done-state,
  start-again. Minimal chrome; the hourglass is the hero, controls fade.
- **The day-cycle runs off the real local clock** (already in hybrid.html), orthogonal to session
  progress: clock drives sky, session drives sand.
- **End → returns to Setup** (not Home). Carry mode/duration/sound/theme selections across (Setup already
  holds this state; decide how to pass it — shared module or query/localStorage).
- **Type = MUJI / Jost only**, same as Setup. Same spacing principle.
- Deferred (still W1, later): `/stage` chrome-less fullscreen (+`?record=1` for OBS), PiP, share links,
  flip-to-start ritual (first push uses a simple Begin).
- **Verification:** keep `plan.js --test`; add a timer check that elapsed-from-timestamps matches expected
  across a simulated background gap (the accuracy rule). Keep the 6 scene check scripts if you port scene
  logic (`web-prototype/check-*.py|js`).

## 5.5 Pre-Astro audit (done 2026-07-25) — fixed + migration checklist

**Fixed in `setup.html` during the audit (visually identical, more robust):**
- **Removed a latent bug:** `.stage>*{ position:relative; z-index:1 }` was overriding the background
  layers' `position:absolute` (equal specificity, later in source), so `.scrim/.vign/.grain` collapsed
  to 0-height and rendered nothing — the plate filled the viewport only *by accident* (first-child img).
  Removed the dead overlay layers + the blanket rule; the scene is now explicitly `z-index:0` and content
  layers above via its own z-index. **This is why the earlier scrim `backdrop-filter` blur never showed.**
- **Absolute asset/script paths** (`/assets/...`, `/js/plan.js`) — relative paths 404 when the page is
  served at a route like `/setup`. Works under both the current static server and Astro `public/`.
- `--fill` slider fallback 55% → 100% (matches the default); two stale code comments corrected.

**Astro migration checklist (do these when porting — not bugs today, but will bite):**
1. **Asset paths** are now absolute (`/assets`, `/js`). Put `site/assets/**` and `site/js/plan.js` under
   Astro `public/` (or import). If the site is served under a base path, set Astro `base` and prefix.
2. **`plan.js` is a global-attach script** (`window.Plan`) loaded via `<script src>` before the inline
   IIFE. Prefer converting to an **ES module** (`export default Plan`) and `import` it; drop the manual
   `?v=5` cache-buster (Astro content-hashes).
3. **The page script is one big inline IIFE** with page-level listeners (`window.error`, `document.click`,
   `window.resize`) and per-sound `setInterval` pumps + a `setInterval`-driven audio scheduler, **with no
   teardown**. Fine for a classic MPA (full page nav tears it down). **If you use View Transitions or
   client-side routing, add cleanup** (remove listeners, `clearInterval`, `AudioContext.close()`), e.g.
   in an `astro:before-swap` handler or an island's unmount.
4. **Self-host Jost** (e.g. `@fontsource/jost`) instead of the Google Fonts `<link>` — perf + privacy;
   the aesthetic bar cares about speed.
5. **Scope the CSS.** It's all global right now (fine as one page). In Astro use a scoped `<style>` or a
   component stylesheet so it doesn't leak into Home/Session — but keep the `:root` tokens global (shared).
6. **Optional a11y polish** (not blockers): mode chooser could use `role=tablist`/`aria-selected`; the
   advanced `role=dialog` sheet has Esc-close but no focus trap / focus-on-open; mini-seg buttons lack
   `aria-pressed`. Add when componentizing.
7. **Edge case:** `.focused-today` (top) and the mode chooser can crowd on a wide-but-short viewport
   (e.g. 1200×500). The mobile fallback is width-based (@≤720px), not height-based. Revisit responsive.

**Audited clean (no action):** the Web Audio engine (gapless loop, crossfade-stacking, bird tide, 3-layer
gain + duck + limiter, missing-file soft-fail), the timer/plan math (15 tests), stepper hold/type-to-edit,
the mixer popover (delegated events, selected-only, live), the error surface (`showErr` + `window.onerror`).

## 6. Open / deferred (not blockers)

Home hero + Home→Setup train transition · Spotify embed (free) · live location-based day schedule
(Follow-my-day uses a clock→phase default now) · mobile responsive (setup has a rough column fallback
@≤720px) · plate regeneration ≥2560px (founder action) · extra worlds/sounds + web commerce (W2).
