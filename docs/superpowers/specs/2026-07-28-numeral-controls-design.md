# Sustain Web — Numeral Controls (Fill + Setup reorg) — Design Spec

> Status: brainstormed & approved 2026-07-28. Next: implementation plan (writing-plans).
> Builds on the locked session screen (`site/session.html`, commits …7fd0970 + cleanup d78c06a) and
> `site/setup.html` (number-look controls added in Task 8). No changes to `plan.js`/`session-timer.js`.

---

## 1. Goal

Finish the timer-numeral controls: expose the **Fill** option (the real feature the "Numeral style" mock
stood in for), organise the five numeral controls across Setup's **Themes panel** and **Advanced settings**,
and delete the two mock teasers plus a dead timer left on the Setup page.

## 2. The five user controls (all real, all persisted, both pages)

| Control | Values | cfg field | Notes |
|---|---|---|---|
| Position | Horizon / Top / Middle / Ledge | `place` | locked geometry per `timer-modes.json` |
| **Fill** *(new — exposes existing engine)* | Solid / Glass / Outline | `fill` | `#scene[data-fill=…]`; default `solid` |
| Font | Serif (`'Newsreader',serif`) / Jost (`'Jost',sans-serif`) | `font` | |
| Colour | hex, auto-contrast on by default | `color` | auto-contrast picks tone; picker is the override |
| Separator | Colon / Dot / None | `sep` | per-mode rule: Middle/Ledge forced `none` |

**Fill is already engineered** in `site/session.html`: `#scene[data-fill="solid"|"glass"|"outline"]` render
rules exist (solid = auto-contrast lift; glass = translucent liquid-glass; outline = overlap-removed stroke
fonts). Today `#scene` is pinned `data-fill="solid"`. This work *exposes* it — no new rendering engine.

## 3. Setup organisation (Themes panel vs Advanced settings)

- **Themes panel** (headline look, set at a glance): **Position · Fill · Font**.
- **Advanced settings** sheet (fine-tune): **Colour · Separator**.

Rationale: Position/Fill/Font are the three at-a-glance character choices; Colour lives in Advanced because
auto-contrast (default on) already picks the tone, so the picker is an override; Separator is a small detail.
Keeps the Themes panel to three clean choices instead of five crowding it.

The **Session ⚙ settings panel keeps all five together** in its Number-look section (it's a dedicated settings
sheet — no Themes/Advanced split there). The split applies to the **Setup page only**.

## 4. Persistence & wiring

- Add `fill` to the `cfg` object (default `'solid'`). `site/session.html` `applyLook(cfg)` sets
  `S.dataset.fill = cfg.fill`. Setup's Begin serialises `cfg.fill`. All existing round-trip guarantees
  (Setup→Session, session ⚙ live-apply + `saveCfg`) extend to `fill` unchanged.
- Session ⚙ Number-look: add a **Fill** segmented control (Solid/Glass/Outline) → `cfg.fill` →
  `applyLook(cfg)` → `saveCfg()`.

## 5. Removals / cleanup (Setup page)

- Delete the **"Numeral style · soon"** mock (the swatch teaser) — replaced by the real Fill control.
- Delete the **"Scene focus blur · soon"** mock (disabled slider) — **not a planned feature**; dropped.
- Remove the **dead 900 ms `textContent` reset** in the `#begin` handler (moot after `location.href` navigates).

## 6. Build order (design & test in the session first, then Setup)

1. **Session ⚙ Fill** — add the control + `cfg.fill` + `applyLook` `data-fill` wiring, so the founder can
   flip Solid/Glass/Outline live on-device across the phases before it's locked into Setup.
2. **Setup** — add Fill, apply the Themes/Advanced split (move Colour + Separator into the Advanced sheet),
   serialise `cfg.fill` on Begin, delete both mocks + the dead timer.

## 7. Testing

- `node site/js/plan.js --test` (15) and `node site/js/session-timer.js --test` (13) stay green (untouched).
- Founder verifies on-device (Iron Rule): the three fills across phases; the Setup Themes/Advanced layout;
  the Setup→Session round-trip carries `fill`.

## 8. Non-goals

Scene focus blur (dropped). Any new numeral rendering (fill engine already exists). Home↔Setup↔Session
workflow wiring + local-preference persistence (separate roadmap step, later).
