# Sustain Web — Setup screen: Timer, Sound, Scene

> Continues [`2026-07-23-web-flow-handoff.md`](2026-07-23-web-flow-handoff.md) and
> [`2026-07-17-sustain-platform-strategy-design.md`](2026-07-17-sustain-platform-strategy-design.md).
> Hero is LOCKED at v22. This is the complete design of the setup screen — panel by panel,
> row by row, state by state — with the research each decision rests on.

---

# PART 0 — Research basis

## 0.1 Competitors: what they give away, what they charge for

| Product | Free | Paid | Price |
|---|---|---|---|
| **Flocus** | timer modes, to-dos, stats, *some* themes + sounds | **all** themes/sounds, custom themes, playlists, Spotify/YT/Apple/SoundCloud | **$9/mo** |
| **Focusfloo** | everything — 20+ wallpapers, sounds, **own-audio upload**, streaks | — (free in beta) | free |
| **LifeAt** | limited spaces | hundreds of video backgrounds | ~$8/mo |
| **lofi.co** *(dead May 2024)* | **2 artworks, 3 sounds** | 13+ illustrations, 12+ mixable sounds | freemium |
| **Noisli** | 28 sounds, **1.5 h/day cap** | unlimited | $1.99 iOS |
| **myNoise** | **300+ soundscapes, 10 sliders each — all of it** | donations | free |
| **Endel** | 4 soundscapes | rest + spatial audio + artist collabs | $6.99/mo · $49.99/yr · ~$90 LT |
| **Tide** | trial only | full | $4.99/mo · $49.99/yr |

**Reads.** (1) The category paywall is uniformly *"more scenes + more sounds"* — copying it puts us
in a crowd. (2) myNoise proves depth can be free and still win; its one named weakness is *the
interface* — that is the opening. (3) Noisli meters the exact thing the user came to do; never that.
(4) lofi.co is dead and still searched for — an unclaimed audience. (5) **Nobody hosts music.**
Licensing is why; Flocus embeds Spotify/YouTube instead. We do the same.

## 0.2 Interaction research → hard rules

| Finding | Source | What it forces here |
|---|---|---|
| Steppers suit **small ranges and minor adjustment from a sensible default**; 1→50 is "excessive clicking" | NN/g | Our ranges (15–480 by 15 = **31 presses**) disqualify a pure stepper |
| Fix is the **hybrid text-field stepper** — type *or* step, plus **long-press to ramp** and arrow keys | NN/g | Click any number to type it; hold −/+ to ramp after 400 ms |
| **State the step and the unit explicitly** | NN/g | Every stepper card shows its step (`· 15m`) |
| Steppers are right for **coarse intervals** (5/10/30 min) | Eleken, Mobbin | 5-minute Flow steps, 15-minute Custom steps |
| **`tabular-nums` for any changing number** — proportional digits shift the layout | CSS/type research | Every numeral on this screen |
| **Segmented control: 2–5 options**, one line, short labels | Setproduct, Michelin DS | All segmented controls here are 2–4. Weather (5) uses chips instead |
| **Radio/visible lists ≤ 5–6**, dropdown beyond | Cieden, UX Planet | Light picker is 7 but **visual thumbnails in a grid**, not a list — the "tall list" failure doesn't apply |
| **Progressive disclosure: more than two levels has low usability** | NN/g | Square card (L1) → sheet (L2). **Never a third.** Forces the cycle builder to become a *rail section inside* the Scene sheet, not a sheet of its own |
| Disclosure labels must be **concrete, not "More"** | NN/g | Rails read `World / Light / Cycle / Weather / Timer` |
| **Proximity: related 4–8 px, unrelated 24–32 px** — spacing alone communicates grouping; cuts cognitive load ~42% | NN/g, Gestalt | Formal spacing scale in §1.3 |
| **Motion: 200 ms standard, 300 ms inter-screen, >400 ms feels slow**; ease-out entering, ease-in exiting, ease-in-out between states; scale duration to distance | Material | Full motion table in PART 5 |
| **Perceived loudness is logarithmic** — linear sliders make the top half useless | Microsoft Win32 audio | All volume sliders are audio-tapered (§3.4) |
| Appearance settings: **live preview, immediate apply**; don't mix autosave with a Save button | Setproduct, Primer | Scene has **no Save** — every change applies instantly. "Done" is navigation, not saving |

## 0.3 Environment landmine (recorded so it is not re-hit)

The brainstorm companion injects content via `String.replace()`. In a replacement string, `$$`,
`` $` ``, `$'`, `$&` and `$1`–`$9` are **escapes**. A `const $$ =` helper was silently rewritten to
`const $ =`, colliding with the real `$` and killing the entire script with a SyntaxError — the
screen rendered as static defaults and looked merely "empty". **No `$`-adjacent sequence may appear
in generated content.** Helpers are named `qs` / `qsa`. The generator verifies this on every build.

---

# PART 1 — Principles

## 1.1 The governing rule

**The centre panel never changes size, for any mode.** Everything else follows from this. No mode may
grow the panel, no control may appear or disappear in a way that reflows, and nothing may scroll
inside the glass.

Consequences:
- The cadence subline **always reserves two lines**, so Pomodoro's long-break line cannot push down.
- Controls that don't apply are **disabled and still visible**, never hidden — hiding reflows.
- Read-only readout buttons use `visibility:hidden`, which keeps their box.
- The control area is a **fixed-height canvas each mode composes into** — not a shared row budget.
  A shared budget was the first attempt and made every mode cramped.

## 1.2 The value-drawn-once rule

**A value appears exactly once.** The primary duration of a mode *is* the big readout, and it is
stepped there. A second card repeating it was both redundant (`BLOCK LENGTH` printed twice) and a
place for the two copies to disagree — which is exactly what happened.

| Mode | Primary (steppable on the readout) | Readout label |
|---|---|---|
| Flow | `flowMin` | BLOCK LENGTH |
| Pomodoro · duration | `pomoTarget` | TOTAL TIME |
| Pomodoro · blocks | **none** — total is derived | TOTAL TIME (read-only) |
| Custom | `customWork` | TOTAL TIME |
| Endless | none — `∞` | NO SET END |

## 1.3 Spacing scale (Gestalt proximity)

| Token | Value | Used between |
|---|---|---|
| `--sp-tight` | `0.35cqi` | a label and its own control |
| `--sp-in` | `0.85cqi` | controls inside one group |
| `--sp-group` | `2.2cqi` | one group and the next |
| `--sp-zone` | `4.5cqi` | the three constellation panels |

The gap between groups must always be **≥ 2.5×** the gap within a group. That ratio is the whole
mechanism; absolute values can be tuned freely as long as it holds.

## 1.4 Materials

One material on this screen: the founder-supplied dark frost —
`#35353566`, `blur(20px)`, `inset 0 0 4px -2px #ffffff55, 0 0 4px -2px #ffffff55`.
Deliberately different from the landing's light 5 px frost: the landing sells the scene *through*
glass; setup is a working surface where the scene recedes.

Behind everything, the scene is softened by `blur(3px) saturate(.96)` + `rgba(6,8,16,.12)` — present,
but no longer asking for attention.

## 1.5 Type

MUJI-minimal. **Jost only** — no serif, no italic, no display face. Numerals `tabular-nums lining-nums`.
The scene carries the beauty; the controls stay silent. Same rule applies to the session screen.

---

# PART 2 — The Setup panel (centre)

Fixed size. Three zones, top to bottom, separated by `--sp-group`.

## 2.1 Zone A — Intention

| Row | Content | Notes |
|---|---|---|
| A1 | `INTENTION` — 0.2em tracked caps, 60% opacity | `--sp-tight` below |
| A2 | Free-text input, no box, 1px bottom rule | Placeholder *"What are you focusing on?"* |

**States.** Rest: rule at `rgba(255,255,255,.2)`. Focus: rule warms to `rgba(234,202,120,.75)`,
200 ms. No validation, no counter — it is a note to yourself, and it may be empty.

## 2.2 Zone B — Readout *(the primary control)*

| Row | Content |
|---|---|
| B1 | Mode label — `BLOCK LENGTH` / `TOTAL TIME` / `NO SET END` |
| B2 | `⊖`  **big number + unit**  `⊕` |
| B3 | Cadence subline — **two lines always reserved** |

**B2 anatomy.** Digits at `clamp(30px,4.7cqi,66px)`, weight 200, `tabular-nums`, ink `#fdf6e6`.
Units (`h`, `m`, `min`) at ~22% of the digit size, 55% opacity, subordinate. The `⊖`/`⊕` are hairline
circles at `clamp(24px,2.9cqi,40px)`, sitting `--sp-in` from the number so the number owns the centre.

**Interactions.**
- Click `⊖`/`⊕` → step by the mode's increment.
- **Hold** → ramps at 90 ms intervals after a 400 ms delay.
- **Click the number** → becomes a numeric input, pre-selected. `Enter` commits, `Esc` reverts,
  blur commits. Value clamped to range on commit.
- **At a limit**, the spent button drops to 30% opacity and stops responding. It never disappears.
- **Derived totals** (Pomodoro·blocks, Endless): both buttons go `visibility:hidden` — box kept,
  number stays centred, panel height unchanged.

**B3 states.** Normal `#EACA78`. Caution `#F0A98C` — used only for the app's verbatim >90 min line.
The subline crossfades (200 ms) **when its wording changes**, not when a digit changes.

## 2.3 Zone C — Control canvas *(fixed height, per mode)*

### Flow
| Row | Content |
|---|---|
| C1 | Hint — *"Step the length above, or pick one."* |
| C2 | Six quick-picks in a 3×2 grid: 15 / 25 / 30 / 45 / 60 / 90 min |

Divergence from the app, flagged: the app has fixed presets plus a dashed `+5` escape chip. The
readout stepper reaches any length, so the escape chip is deleted — it was the one scrap of UI that
made this mode look unfinished.

### Pomodoro · by duration
| Row | Content |
|---|---|
| C1 | `Set by` — segmented **Duration / Blocks** (heading inline on the row) |
| C2 | Hint — *"Set the focus time above — we split it into blocks with rests."* |
| C3 | Wide stepper card: **SPLIT INTO BLOCKS** — 1…12 |

### Pomodoro · by blocks
| Row | Content |
|---|---|
| C1 | `Set by` — segmented **Duration / Blocks** |
| C2 | Hint — *"Pick a classic work/break length and how many blocks."* |
| C3 | Wide stepper card: **FOCUS BLOCKS** — 1…16 |
| C4 | Four ratio chips: 25/5 · 50/10 · 52/17 · 90/15 |

Readout is read-only here; the total is computed from blocks × ratio.

### Custom
| Row | Content |
|---|---|
| C1 | `Break schedule` — segmented **By count / By interval** |
| C2 | Hint — varies by sub-mode |
| C3 | Two stepper cards side by side: **BREAKS** \| **BREAK LENGTH** *(or* **BREAK EVERY** \| **BREAK LENGTH***)* |

Guard, ported from the app: a break may never squeeze focus below 5 min per chunk. Attempting it
is a no-op with the `⊕` dimmed.

### Endless
No numbers to set, so the canvas carries meaning rather than a paragraph — three tiles:

| `∞` | `◎` | `↻` |
|---|---|---|
| **No goal** | **Break freely** | **It refills** |
| nothing to reach | whenever you say | drains, flips, again |

### Stepper card anatomy (used in C3/C4)
```
┌──────────────────────────────┐
│ BREAK LENGTH           · 1m  │  label, and the step stated (NN/g)
│   ⊖        10m         ⊕     │  value at clamp(17px,2.15cqi,32px), weight 200
└──────────────────────────────┘
```
Same numeral language as the readout, one size down — the panel has exactly one way to draw a number.
`⊖`/`⊕` inside a card are hairline only, never a second frosted slab on top of a frosted card.

---

# PART 3 — Sound

**Sound is a mixer, not a picker** — the myNoise lesson, in an interface people will keep open.

## 3.1 Square card (L1) — the 80% case

| Row | Content |
|---|---|
| S1 | `SOUND` + expand glyph (right) |
| S2 | Six round tokens, 3×2, label beneath: **Sand · Waves · Rain · Wind · Fire · Room** |
| S3 | Current preset name — click cycles the built-in presets |

**The ring around each circle is its level.** There is no separate on/off state to fall out of sync:
a layer at zero *is* off. Click toggles between zero and its last level. `Sand` is the hourglass's
own voice — the one channel no competitor has.

## 3.2 Sheet (L2)

| Row | Content |
|---|---|
| M0 | `←` · **SOUND** · current mix name · **Preview** toggle (right) |
| M1 | `MIX` — six free layers in two columns: name / slider / value |
| M2 | Plus layers, same rows, dimmed, suffixed `· Plus`: Thunder, Café, Birds, Stream, Bowls, Vinyl, Traffic, Snowfall |
| M3 | `PRESETS` — chips; presets exceeding the free mix are labelled `· Plus` |
| M4 | `MASTER` — slider + mute |

## 3.3 Silence

**Setup plays nothing.** The landing page runs a live ambient loop (mutable); setup is where you are
in control, and the research on that is the founder's, not a paper: *"we need feel and mood, but we
need silence too."* The **Preview** toggle is opt-in, defaults off, and is the only way sound is
heard on this screen. The chosen mix starts on Begin.

## 3.4 Audio taper *(implementation rule)*

Perceived loudness is logarithmic. A linear slider makes the upper half do nothing and the lower half
jump ~10 dB per pixel. Sliders therefore report a 0–100 position, and gain is
`(pos/100)^2.5` (≈ −60 dB at the bottom, 0 dB at the top). Every 10 slider points must feel like the
same loudness change wherever the handle sits.

## 3.5 Paywall *(founder-decided)*

- **Six generic sounds free**, and **at most two mixed at once**.
- **`Sand` is exempt from the two-layer count** — it is the hourglass's own voice, not an add-on.
  Free = Sand + any two.
- Exceeding the limit is **stated in place** (the preset row becomes *"2 sounds free · more with
  Plus"* for 2.2 s, then restores). Nothing moves; nothing is blocked silently.
- Plus presets **show their name and refuse to apply** — visible, priced, never hidden.
- **Never meter time or sessions.** Noisli's 1.5 h/day is the anti-pattern.

> Recorded so it is not relitigated: the research argued for giving all sound away (the myNoise play)
> and monetising worlds only. The founder chose the lofi.co shape — a small free set plus a mix limit.
> It is the category norm and defensible; the `Sand` exemption is the guard against it feeling mean.

---

# PART 4 — Scene

**A scene answers: what does the world look like while I focus?**

## 4.1 Square card (L1)

| Row | Content |
|---|---|
| T1 | `THEME` + expand glyph |
| T2 | Six round tokens — **circular crops of the real plate art**, cropped from the left sky so the hourglass stays out of them |
| T3 | `Follow my day` — the default |

Clicking any light **previews it live**: the plate crossfades behind the glass in 550 ms.

## 4.2 Sheet (L2) — five rails

Rails are concrete nouns, never "More" (NN/g): **World · Light · Cycle · Weather · Timer**.
The cycle builder is a *rail*, not a sub-sheet — a third disclosure level is where users get lost.

### Rail 1 — World *(W2; one world exists)*
Grid of world cards, each its own art, each with a **⛶ that opens it full-screen** so you can look
before choosing. Unowned worlds show their art dimmed with a quiet price — **never a lock icon**.
A world = one six-phase plate set. Only *Sea* exists; the renders in `claude images to give/` are
ideation, not plate sets.

### Rail 2 — Light
| Row | Content |
|---|---|
| L1 | `Follow my day` — full-width, the default. Real clock drives the phase, including mid-session |
| L2 | Six round thumbnails with labels |
| L3 | `Sun & moon` — segmented **Show / Hide** |

### Rail 3 — Cycle
| Row | Content |
|---|---|
| Y1 | `SEQUENCE` — chosen lights as removable chips, each with its phase colour |
| Y2 | Palette — the six lights, click to append (max 8, repeats allowed) |
| Y3 | `Change` — segmented **Once / Loop** |
| Y4 | `Loop by` — segmented **Cycles / Minutes / Breaks** *(only when Loop)* |
| Y5 | `Repeat` or `Change every` — stepper *(depends on Y4)* |
| Y6 | `THIS SESSION` — **the timeline**, drawn in each phase's real average sky colour |
| Y7 | Key — `Midday 30m · Midnight 30m · …` |

**Advance rules** — sequence `P` (length `n`), session total `T`:

| Rule | Each phase lasts | Notes |
|---|---|---|
| **Once** | `T / n` | Spans the session exactly |
| **Loop · cycles** `C` | `T / (n·C)` | Always lands on the session end; no arithmetic for the user |
| **Loop · minutes** `M` | `M` | Literal; the final phase truncates |
| **Loop · breaks** | one phase per focus block | Advances at each break — the light change *becomes* the signal a block ended |

**Edge cases (decided).** Endless has no `T`: *Once* and *by cycles* are **disabled with a stated
reason**, minutes and breaks work. Flow/Endless have no breaks: *by breaks* disabled with a reason.
A sequence of one means "hold one light" — Once/Loop stays visible but disabled. Repeats allowed.
Changing session duration afterwards: Once and by-cycles re-derive silently; by-minutes keeps `M` and
may truncate; by-breaks re-derives. No warning, no dialog.

### Rail 4 — Weather *(W2)*
`Clear · Rain · Snow · Fog · Storm` as chips (5 exceeds the segmented limit), an **Intensity** slider,
and **Follow my real weather** — the strategy doc's *"your city rains, your garden rains."*

### Rail 5 — Timer display
| Row | Control | Options | Phase |
|---|---|---|---|
| D1 | `Show the timer` | **Always · Every 5 min · On hover · Never** | W1 — locked in the platform strategy |
| D2 | `Position` | **Above · On the glass · Below** | W1 |
| D3 | `Numeral style` | style swatches | W2 |
| D4 | `Scene blur` | slider — 0 = full scene, max = only the hourglass | W2 |

## 4.3 No Save button

Every Scene control **applies immediately with live preview**. Research is explicit that mixing
autosave with a Save button makes it unclear when anything is saved. `←` and `Done` are navigation.

---

# PART 5 — Motion

Nothing changes state without a transition. Durations follow Material: 200 ms standard, 300 ms
inter-screen, nothing over 400 ms except deliberate ambience.

| What | Duration | Easing | Why |
|---|---|---|---|
| Hover / selection colour | 200 ms | `ease` | Standard state change |
| Mode-pill slide | 260 ms | `cubic-bezier(.4,0,.2,1)` | Same element between states → ease-in-out; travels distance |
| Control canvas crossfade (mode change) | 200 ms | `cubic-bezier(.4,0,.2,1)` | Standard |
| Readout crossfade (mode change only) | 200 ms | same | Bundled with the canvas |
| Cadence subline (wording change) | 200 ms | `ease-out` | Entering content |
| Sheet open / close | 300 ms | `ease-out` / `ease-in` | Inter-screen |
| Scene preview crossfade | 550 ms | `cubic-bezier(.4,0,.2,1)` | A control answering a click, but the subject is ambient |
| **In-session light change** | **~6 s** | linear | Ambient — felt, never seen |
| Train slide between screens | 620 ms | `cubic-bezier(.5,0,.2,1)` | Locked in the flow handoff |

**The one deliberate exception: digits do not fade.** They are `tabular-nums` and update in place
without shifting; fading them on every step would strobe. Wording changes fade, numbers don't.

`prefers-reduced-motion` collapses every duration above to ~0.01 ms and disables the pill slide.

---

# PART 6 — Build order

| Phase | Setup panel | Sound | Scene |
|---|---|---|---|
| **W1 — all free** | constellation, fixed panel, readout stepper, hybrid typing + ramp, 5 mode canvases | six-layer mixer, master, presets, log taper, 2-layer free cap | Light rail, Cycle rail + timeline, Timer show/position |
| **W2 — money on** | — | saved mixes, Plus layers, Music embed | Worlds + full-screen peek, Weather + real weather, numeral styles, scene blur |

# PART 7 — Deltas this design forces on what is already built

1. **Cycle builder demotes from a sheet to a Scene rail** — it is currently disclosure level 3, which
   NN/g says loses users. Rails become `World · Light · Cycle · Weather · Timer`.
2. **Volume sliders need the audio taper** — currently linear.
3. **Spacing needs the 2.5× ratio** — the panel currently uses one uniform gap between all rows.
4. **At-limit stepper buttons must dim to 30%** — currently they clamp silently.
5. **Sheet transitions to 300 ms; mode pill to 260 ms** — currently 220 ms and 340 ms.
6. **`prefers-reduced-motion` block** is not yet in the setup generator.

# PART 8 — Still open

1. `timer.js` models endless as a mode but has no `pomoEntry` / custom-schedule options, so it cannot
   yet express the ported setup. Align it now that the Endless toggle is dropped.
2. Session screen is still first-pass; the MUJI type rule is not yet applied to it.
3. Carried over: per-phase adaptive scrim; location source for the sunrise/sunset schedule;
   **founder action — regenerate plates at ≥2560px**.
