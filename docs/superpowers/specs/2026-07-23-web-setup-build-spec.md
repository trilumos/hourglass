# Sustain Web — Setup screen BUILD spec (reconciled, 2026-07-23)

> **STATUS: 🔒 BUILT & LOCKED 2026-07-25 (founder).** `site/setup.html` is the shipped setup screen.
> Do not redesign it; only bug-fix. Next work is the **session screen** — see
> [`2026-07-25-web-session-handoff.md`](2026-07-25-web-session-handoff.md).
>
> The authoritative build reference for the setup screen. Reconciles the two committed docs that
> disagreed, and records the founder rulings made this session. Research rationale lives in
> [`2026-07-23-web-setup-screen-design.md`](2026-07-23-web-setup-screen-design.md); the plan/traps in
> [`2026-07-23-web-build-handoff.md`](2026-07-23-web-build-handoff.md). **Where any older doc conflicts
> with this one on the points below, this one wins.**

---

## 0. Contradictions resolved this session

| Point | Older doc said | **Locked now** |
|---|---|---|
| Layout | setup-screen-design: card→sheet (2 disclosure levels) | **Constellation** — 3 full-height frost panels, Sound · Timer · Themes |
| Disclosure | build-handoff: "no sheets, nothing behind an icon" | **Common controls visible; ONE advanced sheet** for power controls (founder revision) |
| Sound | setup-screen-design: 6-layer mixer + master + presets | **Picker, not mixer** (build-handoff), and **scoped to the sea** (this session) |
| Sound set | 6 generic (Sand/Waves/Rain/Wind/Fire/Room) | **Sand · Ocean · Shore breeze · Seabirds** — the Seascape world's own ambience |
| Sound model | one shared pool with a 2-layer cap | **Ambience ships with the world, unlimited, never capped.** No music layer (dropped 2026-07-25); own-music = free Spotify embed |
| Paywall (W1) | 2-layer free cap + Plus sounds | **None in W1** — W1 is $0 with zero billing code |
| Endless | toggle coexisted with mode | **Toggle dropped** — Endless is only a mode |
| Begin | iridescent "Refract" | **Frosted glass** |

## 0.5 LOCKED: the plate rule (decided once, site-wide, never changes)

Founder ruling: *"The alignment or position or zoom of the bg plate should never change throughout
the site ever. NEVER CHANGE. So decide once fully. Then stick to it."*

Taken verbatim from the home hero (`gen_hero_mockup.py:114`) and applied identically on
**Home, Setup and Session**:

```css
.scene{ position:absolute; inset:0; width:100%; height:100%;
        object-fit:cover; object-position:50% 50%; }
```

**No `transform`, no `scale`, no `filter`, no `object-position` override — anywhere, in any state,
including reduced-transparency/reduced-motion media blocks.** Because the rule is byte-identical on
every screen, the plate cannot shift, zoom or re-crop as the user navigates.

Rejected and not to be re-attempted: `object-fit:contain` (letterboxes — black bars on a wide
window), a blurred scaled copy behind to fill those bars (*"too much blur"*), and any `scale()`
bleed to hide blur edges (that IS the zoom). If the crop on ultrawide windows is ever a problem, the
fix is **wider source plates**, never a CSS transform. Scene softening on Setup stays on the
`.scrim` OVERLAY (`backdrop-filter`), never on the image.

## 0.6 LOCKED: panel geometry (founder-locked — never changes again)

Founder ruling: *"lock this, for the panel sizes. Anything in future we add, or remove, the panel
sizes will stay the same always."*

```css
--gutter:  clamp(14px, 2.4cqi, 46px);   /* edge↔panel AND panel↔panel — all four identical */
--sq:      clamp(320px, 64cqh, 640px);  /* shared HEIGHT of all three panels */
--main-w:  calc(var(--sq) * 1.28);      /* centre panel width — wider than tall */
--modes-w: 78%;                          /* mode chooser, as a share of the centre panel */
```

- Centre panel: `--main-w` × `--sq`. Sound + Themes: `flex:1` (equal to each other) × `--sq`.
- Row is `padding-inline:var(--gutter)` + `gap:var(--gutter)` → all four gaps equal by construction.
- **`.panel { overflow:hidden }` enforces the lock.** Adding or removing any control must never
  change a panel's size. Content adapts to the panel — fit it, or scroll it inside
  (`.themes-scroll` is the pattern) — the panel never adapts to the content.
- Mode chooser floats above the centre panel (absolute, out of flow); Begin is anchored to the page
  bottom. Neither may affect panel geometry.

## 1. Spacing principle (standing rule — see memory `web-spacing-principle`)

Appropriate, proportional, geometric. **One `--gutter` token** drives the four horizontal gaps
(edge→Sound = Sound→Timer = Timer→Themes = Themes→edge, **all equal**) and the vertical breathing.
Side panels equal each other; **centre ≈ φ (1.6×) a side panel**. Internal pad scales with the panel;
inside a panel the locked 2.5× proximity ratio holds (related tight, groups apart). Never congested,
never marooned in blank space.

## 2. Files (fresh `site/`, no build step)

```
site/setup.html   markup + inline <style> + page wiring <script>
site/js/plan.js   ported SessionPlan math (pure, reusable; home/session reuse it) + --test block
site/assets/plates/*.jpg   6 phases compressed ~1600px (placeholders; regen ≥2560px later)
```

Full-viewport root, `container-type` so `cqi` sizing works. Background = **static softened plate**
(`blur(3px) saturate(.96)` + `rgba(6,8,16,.12)` + vignette + grain) — the animated hourglass scene port
is deferred. Frost material: `#35353566`, `blur(20px)`, hairline double rim.

## 3. Panels

**Timer (centre, fixed size):** floating mode pill (Flow·Pomodoro·Custom·Endless); Intention input;
Readout as primary stepper (label · `⊖ big# unit ⊕` · 2-line subline); per-mode control canvas
(Flow quick-picks / Pomodoro segment+cards / Custom segment+2 cards / Endless 3 tiles). Hybrid steppers:
click# to type, hold to ramp after 400 ms, at-limit dim to 30%, derived totals hide buttons
(`visibility:hidden`). Plan math ported from `gen_setup.py` (drop the endless toggle + endlessRow).

**Sound (left):** header · round tokens — **selected = solid white**, the same selection language as the
mode chooser and every chip (no level rings, no progress-bar look) · one master volume, audio-tapered
`(pos/100)^2.5` · **"Listen now"** toggle (setup is silent; this is the only way to hear it here).
Seabirds uses an inline gull SVG, not a text glyph.

**Sound model (locked 2026-07-25 — platform strategy §6.1.3):** these four are the **Seascape world's
ambience**; they ship inside the world, are free, and **all four play at once — never capped**. **There
is no music layer** — the in-house music slot + binaural synth (built 2026-07-24) were **removed**. Music
is dropped entirely, not deferred: users get their own music via a **free Spotify embed** (§6.1.4). More
sounds only ever arrive by **buying the world that carries them** — never à-la-carte.

**Audio engine (built, live):** real files served **byte-identical to the founder's originals** (`sand.m4a`,
`ocean.mp3`, `breeze.mp3`, `birds.mp3` in `site/assets/audio/`). Web Audio, not `<audio loop>` (gapless).
Per-source gains are **K-weighted (ITU-R BS.1770)**, not RMS. Crossfade-stacking loops each sound with no
seam; sand stacks at 40% (3 layers) to cancel its level swing. Encoder whistles (ocean 13→now 19 kHz
source, etc.) are notched **at playback**, never by re-encoding. Seabirds run continuously with a slow
time-of-day **tide** on their level (loud at dawn/dusk, near-silent at midnight). Provenance in
`site/assets/audio/CREDITS.md`.

**Themes (right):** big theme preview (Seascape); **Select-theme button DISABLED** (only world exists);
time-of-day = circular phase crops + Follow-my-day + Time; toggles (sun&moon, timer show-mode);
**Advanced settings** → centred sheet over setup (rest dimmed) holding cycle builder + timeline,
numeral styles, timer position, scene blur (W2 items shown/dimmed).

## 4. Motion & type
MUJI / **Jost only**. 200 ms standard · 260 ms pill · 300 ms sheet · 550 ms scene preview. Digits never
fade (tabular-nums, in place); wording crossfades. `prefers-reduced-motion` collapses all.

## 5. Deferred (flagged, not silent)
Home hero port + Home→Setup train transition · live location-based schedule (Follow-my-day uses a default
plate; phase crops preview live) · animated hourglass-scene port · Spotify embed (free, §6.1.4) ·
world-switching · mobile responsive stack.

## 6. Verify
`node --check js/plan.js` + `node js/plan.js --test` asserting totals/subline across all 4 modes and the
break-squeeze guard (never < 5 min focus/chunk).
