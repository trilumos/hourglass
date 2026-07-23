# Sustain Web — Focus flow handoff (2026-07-23, evening)

> Continues [`2026-07-23-sustain-web-hero-handoff.md`](2026-07-23-sustain-web-hero-handoff.md) (hero is LOCKED at v22).
> Everything below is committed. Mockups regenerate from `web-prototype/gen_*.py` into the
> gitignored companion dir, so nothing depends on a session surviving.

## Nav model (founder-locked)

```
Home (landing) --Begin Focus--> Setup --Begin--> Session
      ^                          |                 |
      +-------- Back ------------+                 |
                 ^                                 |
                 +---------- End ------------------+   (End returns to SETUP, not Home)
```

## The generators

| File | Produces | State |
|---|---|---|
| `gen_hero_mockup.py` | the landing hero | **LOCKED v22** |
| `gen_transition.py` | Home → Setup → Session + train transitions | correct **nav**, but only a **first-pass** setup panel |
| `gen_setup.py` | the real app-parity setup screen | correct **panel**, but **no Home** (standalone) |

## NEXT SESSION — step 1: merge the two mocks

Lift out of `gen_setup.py` and into `gen_transition.py`: the app-parity panel, the floating
mode chooser, the glass back button, the iridescent Begin button, and the whole plan-math
`SCRIPT`. Then **delete the `#resumeBtn` "Begin Focus" pill** — it is standalone-mock
scaffolding (there was no Home to go back to), *not* a design element. Result: one prototype
that is the entire flow.

## Motion (locked)

- **Train slide, right → left**, `0.62s`. Outgoing exits left, incoming follows from the right.
- Each state (`hero` / `setup` / `session`) is **ONE full-frame `view-transition-name` group**.
  This is what stopped the blur boxes flashing as hard masked rectangles — grouped, they
  rasterize *with* their text. Do not split them back out.
- Root (scene + vignette + grain) has `animation:none` — identical across states, so freezing
  it prevents flicker.
- **Entrance keyframes must animate `translate`, never `transform`** — `.right`/`.dock` use
  `transform:translate(-50%)` to centre, and a transform keyframe overrides it (loads low, snaps).
- Sliding groups escape `.hero`'s `overflow:hidden` because named groups are promoted to a flat
  tree at the document root. **Cosmetic to the boxed mockup only** — a non-issue once the hero
  is full-viewport. `nested ::view-transition-group` is the fix if a bounded box is ever needed.

## Setup screen — sourced from the app, not invented

Ported from `lib/ui/setup_screen.dart` + `lib/session/session_plan.dart`: same hierarchy
(intention → total time → focus time → configuration), same controls, labels, hints, presets,
step increments and ranges. `SessionPlan.*` is a faithful JS port, so the big duration and the
cadence subline are computed from a real plan.

- **Modes:** Flow / Pomodoro / Custom are the app's, unchanged. **Endless is a new web-only 4th mode.**
- **Stamina is OMITTED** (Pro-only, founder-excluded). This orphaned one clause in the app's calm
  Flow subline ("…finish it to hold your stamina, pass it to grow") which was dropped. The
  >90 min caution is kept verbatim.
- **Type: MUJI-minimal** — one quiet neutral sans (Jost). No serif, no italic, no display face.
  **This rule also applies to the session screen.**

## ⚠️ Two materials now exist — make this intentional

| Surface | Material |
|---|---|
| Landing / hero | light frost, `blur(5px)`, `1px rgba(255,255,255,.18)` rim |
| **Setup** | **dark** `#35353566`, `blur(20px)`, hairline **double** rim `inset 0 0 4px -2px #ffffff55, 0 0 4px -2px #ffffff55` |

The setup material was founder-supplied and **contradicts two rules learned during the hero work**
(recorded in the hero handoff §3: "dark-tinted glass muddies the scene", "heavy blur 14–26px is
wrong"). It is correct *here* — the landing sells the scene *through* the glass; setup is a working
surface where the scene should recede. But when the design system is locked, this split must be
written down deliberately, not left to look like drift.

Begin button uses the iridescent "Refract" treatment (Simey's CodePen, after Wojciech Zieliński),
adapted: Jost not Amaranth, container-query sizing, and `translate:-50%` preserved through
`:active` (the original's `:active` would snap a centred button off-centre).

## Still unresolved

1. **Endless toggle vs. Endless mode.** The three app modes were ported *exactly*, so the app's
   "Endless flow" **toggle** came along (on Flow, and Custom with 0 breaks) and now coexists with
   the new Endless **mode**. Not identical: the toggle keeps a *goal* and runs past it; the mode has
   **no goal**. Keep both, or drop the toggle?
2. **`timer.js` is out of alignment.** It models endless as a mode but has no `pomoEntry` /
   custom-schedule options, so it cannot yet express the ported setup. Align it once (1) is settled.
3. Session screen is still first-pass (MUJI type rule not yet applied to it).
4. Then: full landing page, then Phase 1b Astro build.
5. Carried over: per-phase adaptive scrim (left-third luminance midnight 22 / sunset 99 / midday 129);
   location source for the sunrise/sunset schedule; **founder action — regenerate plates at ≥2560px**.
