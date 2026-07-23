# Sustain Web — handoff: move to a real site (2026-07-23, night)

> **Read this first, then [`2026-07-23-web-setup-screen-design.md`](2026-07-23-web-setup-screen-design.md).**
> That doc holds the full research and every design decision, row by row. This one holds the plan,
> the state of the tree, and the traps.

---

## 1. Order of work (founder-locked)

1. **Build the website** — plain static files. *Not* the Python mock generator.
2. **Merge the home screen and the setup screen** into that site (Home → Setup, Back → Home).
3. **Then design the setup screen fully** — this is where the next chat starts.
4. Later: the session screen, then the full flow Home → Setup → Session → Setup → Home.

**Plain static now, Astro later.** Real `.html` / `.css` / `.js` files served by any dev server.
The design is still moving and the founder wants changes visible instantly, without a build step.
Porting into Astro (Phase 1b) happens once the screens are settled — the files carry over.

## 2. Why we abandoned the mock pipeline

`web-prototype/gen_*.py` emit HTML/CSS/JS as Python strings into a gitignored dir, served by the
superpowers brainstorm companion. It cost a full session:

- **No console, no DevTools.** A crash took three rounds to find; the founder found it in seconds by
  opening inspect-element. That asymmetry is the whole argument.
- **Every fix was regex surgery on code that was never run.** Three generations of dead sound code
  and a duplicated event handler accumulated *invisibly* until the parser complained.
- **The companion silently corrupts content** (§5).

`gen_setup.py` was reverted to its last commit — it was broken, and patching it further made it
worse. Nothing is lost: everything it contained is specified in the design doc.

## 3. State of the tree

| Path | State |
|---|---|
| `docs/superpowers/specs/2026-07-23-web-setup-screen-design.md` | **committed** — the full spec. The source of truth |
| `web-prototype/gen_hero_mockup.py` | hero **LOCKED v22** — the visual reference to port from |
| `web-prototype/gen_setup.py` | reverted to last commit; **superseded**, do not extend |
| `web-prototype/gen_transition.py` | nav model + train-slide transitions; **reference only** |
| `web-prototype/hybrid.html` | hourglass scene, 24h cycle, sun/moon, sand physics — **port this** |
| `web-prototype/timer.js` | 25 tests; out of alignment (§6.1) |
| `web-prototype/plates-phases/*.png` | six phase plates: pre-dawn, sunrise, midday, sunset, twilight, midnight |

## 4. Decisions locked this session

### 4.1 Nav
`Home --Begin Focus--> Setup --Begin--> Session`. **Back** from Setup returns Home; **End** from a
session returns to **Setup**, not Home. Train slide right→left, 620 ms, each screen one group.

### 4.2 The setup screen
- **Constellation:** tall centre panel flanked by two side panels, all full height. Sound left,
  Theme right. Wide rectangles — narrow full-height columns read as "long ears"; small squares were
  worse still, because the controls ended up hidden.
- **Everything visible, one disclosure level.** No expand glyphs, no sheets. Hiding the scene
  customisation behind an icon was explicitly rejected.
- **The centre panel never changes size, for any mode.** Subline reserves 2 lines; inapplicable
  controls are disabled-but-visible; read-only readout buttons use `visibility:hidden` to keep their
  box. The control area is a fixed-height *canvas each mode composes into*, not a shared row budget.
- **A value is drawn exactly once.** The mode's primary duration **is** the big readout and is
  stepped there — a second card repeating it caused both duplicate labels and a live desync.
  Primary: Flow→`flowMin`, Custom→`customWork`, Pomodoro·duration→`pomoTarget`.
  Pomodoro·blocks and Endless have **no** primary (derived) → readout is read-only.
- **Steppers are hybrid** (NN/g): click the number to type it, hold −/+ to ramp after 400 ms, step
  size stated in the label. Our ranges are 31–47 presses end to end, which disqualifies a plain stepper.
- **Endless toggle dropped** — Endless is its own mode; the toggle was a second near-identical idea
  and a show/hide row, which the fixed-size rule forbids.
- **Begin is frosted glass**, not iridescent. The Refract treatment is deleted.
- **Type: MUJI-minimal, Jost only.** No serif, no italic, no display face. Applies to session too.
- **Scene is softened** behind the panels: `blur(3px) saturate(.96)` + `rgba(6,8,16,.12)`. Subtle —
  two heavier settings were rejected.
- Mode chooser is large, wide, with a **sliding** pill (fail-safe: the active mode carries its own
  pill in CSS until JS measures).

### 4.3 Sound — **not a mixer**
Faders, a master bus and a preset rack were rejected outright: *"the user is not a DJ and neither our
website a music website."* The control is: **pick your sounds, set one volume.**
- Six sounds: Sand · Waves · Rain · Wind · Fire · Room. `Sand` is the hourglass's own voice — the one
  channel no competitor has.
- **Setup is silent.** The landing page runs a live ambient loop (mutable); setup plays nothing. The
  chosen sound starts on Begin.
- Volume must be **audio-tapered** (`gain = (pos/100)^2.5`) — perceived loudness is logarithmic, and
  a linear slider makes the top half useless.

### 4.4 Scene / Theme
- **Light:** *Follow my day* (default, real clock, including mid-session) or one of six phases, shown
  as **round crops of the real plate art** cropped from the left sky so the hourglass stays out.
- **Sun & moon** toggle. **Weather** (W2). **Timer display**: show `Always · Every 5 min · On hover ·
  Never` (already locked in the platform strategy) and position `Above · On the glass · Below`.
- **Cycle** — pick 2–8 lights in order, then `Once` (spans the session) or `Loop` by **cycles**
  (`T/(n·C)`), **minutes** (literal, may truncate) or **breaks** (one phase per focus block). A
  timeline preview draws the actual session in each phase's real average sky colour.
  Endless has no total → Once and by-cycles disabled *with a stated reason*, never hidden.
- **Live preview, immediate apply, no Save button** — mixing autosave with a Save button makes it
  unclear when anything saved.

### 4.5 Paywall (founder-decided)
- **Six sounds free, at most two mixed at once.** More sounds and deeper mixes are Plus.
- **`Sand` is exempt from the two-layer count** — charging a free slot for the thing that *is* the
  product reads as petty. Free = Sand + any two.
- Limits are **stated in place**, never enforced silently; Plus items are shown and priced, never
  hidden behind a lock icon.
- **Never meter time, sessions, or the timer.** Noisli's 1.5 h/day cap is the anti-pattern.
- **One world free and fully featured**; extra worlds are the only cosmetic sold (à-la-carte +
  lifetime bundle), mirroring the app's colour-theme model.
- **Never host music** — nobody in the category does, licensing is why. Spotify/YouTube embed in W2.

> Recorded so it is not relitigated: the research argued for giving *all* sound away (the myNoise
> play) and monetising worlds only. The founder chose the lofi.co shape. Both are defensible; the
> `Sand` exemption is the guard against the limit feeling mean.

### 4.6 Motion
200 ms standard · 300 ms sheets/inter-screen · 260 ms pill slide · 550 ms scene preview ·
**~6 s in-session light change** (ambient, felt not seen) · 620 ms train slide.
ease-out entering, ease-in exiting, ease-in-out between states of one element.
**Digits never fade** — they are `tabular-nums`, update in place, and fading them on every step
would strobe. Wording changes fade; numbers don't. `prefers-reduced-motion` collapses all of it.

## 5. Traps

1. **The brainstorm companion corrupts `$$`.** It injects content with `String.replace()`, where
   `$$`, `` $` ``, `$'`, `$&` and `$1`–`$9` are escapes. A `const $$ =` helper became `const $ =`,
   collided, and killed the entire script with a SyntaxError — the page rendered as static markup
   defaults and merely looked "empty". Moot once we serve real files, but **never** put those
   sequences in companion content.
2. **A silent init failure looks like an empty design.** Wrap init in try/catch and print the error
   into the UI. Without that, every JS-driven value falls back to its markup default and the screen
   reads as a bad layout rather than a crash.
3. **`.s-row { align-items:center }` collapsed the centre panel.** Centring the row stops the panel
   stretching; `flex:1` + `min-height:0` inside an auto-height column then resolves to zero and
   `overflow:hidden` clips it away. Stretch the row; let the side panels opt out with `align-self`.
4. **`conic-gradient(… , colour 0)`** — a unitless `0` is an invalid stop position and drops the whole
   gradient. Always give both stops explicit percentages.

## 6. Still open

1. **`timer.js` is out of alignment** — it models endless as a mode but has no `pomoEntry` or
   custom-schedule options, so it cannot express the ported setup. Align it now the toggle is dropped.
2. Session screen is first-pass; the MUJI type rule is not applied to it yet.
3. Per-phase adaptive scrim (left-third luminance: midnight 22 / sunset 99 / midday 129).
4. Location source for the sunrise/sunset schedule.
5. **Founder action — regenerate plates at ≥2560px.**

## 7. First moves next session

1. Scaffold `web/` — `index.html`, `setup.html`, `css/`, `js/`, plus whatever static server the
   founder prefers. No build step.
2. Port the **locked v22 hero** out of `gen_hero_mockup.py` into real files, and the hourglass scene
   out of `hybrid.html`.
3. Wire Home → Setup with the train slide, then build the setup screen against §4.2–4.4.
4. Design work resumes on the setup screen — that is what the founder wants to work on.
