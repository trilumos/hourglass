# Numeral Controls (Fill + Setup reorg) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose the timer-numeral **Fill** control (Solid/Glass/Outline) in the session ⚙ and in Setup, reorganise Setup's five numeral controls across the Themes panel and the Advanced sheet, and delete two mock teasers plus a dead `Begin` timer.

**Architecture:** Pure HTML/JS edits to two self-contained pages (`site/session.html`, `site/setup.html`). The Fill rendering engine already exists (`#scene[data-fill="solid|glass|outline"]` CSS in session.html) — this work only exposes a control and threads `cfg.fill` through the existing config plumbing. No changes to `plan.js` / `session-timer.js`.

**Tech Stack:** Plain HTML/CSS/JS (ES2019, no framework, no build), `localStorage['sustain.session']` config.

## Global Constraints

- **No build step / no new dependency.** Edit the two self-contained pages only.
- **cfg contract:** `fill` value is one of `'solid' | 'glass' | 'outline'` (default `'solid'`). It must round-trip Setup→Session and session-⚙-live-edit exactly like the other look fields, using the same code paths.
- **Visual consistency:** reuse each page's OWN existing control language — session uses `.chips[data-k]` rows; Setup uses `.sec` + `.mini-lbl` + `.mini-seg[data-seg]`. Do NOT invent new styles.
- **Per-mode separator rule stays intact:** Middle/Ledge force `sep='none'` (session `applySepForMode`, Setup `applySepForMode` via `segState`). Moving controls between panels must not break the place↔sep link (it's keyed on `segState`/`cfg`, not DOM proximity).
- **Setup Themes/Advanced split (this plan's reorg):** Themes panel = Position, Fill, Font. Advanced sheet = Colour, Separator.
- **git/GitHub = trilumos.** Commit after each task. `plan.js`/`session-timer.js` node `--test` suites (15 / 13) must stay green (they're untouched — just confirm). Founder verifies visuals on-device (Iron Rule).

---

## File structure

- **Modify** `site/session.html` — add the Fill control to the ⚙ Number-look section; thread `cfg.fill` through `applyLook` + the chip handler + the default + the initial-selection reflect. (Task 1)
- **Modify** `site/setup.html` — add a Fill `data-seg="fill"` control; move Position/Fill/Font `.sec` blocks into the Themes panel; keep Colour/Separator in the Advanced sheet; delete the two mock `.sec.w2` blocks; serialise `cfg.fill` on Begin; add `fill` to `segState`; remove the dead 900 ms `Begin` timer. (Task 2)

---

### Task 1: Session ⚙ — expose the Fill control (Solid/Glass/Outline)

**Files:**
- Modify: `site/session.html`

**Interfaces:**
- Consumes: existing `applyLook(cfg)`, the `.chips[data-k]` click delegate, `saveCfg()`, `selChips(k,val)`, and the `#scene[data-fill=…]` CSS (already present).
- Produces: `cfg.fill` (`'solid'|'glass'|'outline'`) applied live via `S.dataset.fill` and persisted.

- [ ] **Step 1: Add `fill` to the fallback default cfg**

In `site/session.html` (~line 369) add `fill:'solid'` to the default object:
```javascript
|| { mode:'flow', flowMin:25, place:'middle', fill:'solid', phase:2, sounds:[], vol:100, soundVol:{sand:100,ocean:100,breeze:100,birds:100}, sep:'none', font:"'Newsreader',serif", color:'#ffffff', vis:'always', followDay:true, autoContrast:true };
```

- [ ] **Step 2: Make `applyLook` set the fill**

In `applyLook(cfg)` (~line 587) add one line (default to `'solid'` so an older saved cfg without `fill` still renders):
```javascript
    S.dataset.fill = cfg.fill || 'solid';
```

- [ ] **Step 3: Add the Fill chip row to the ⚙ Number-look section**

After the `data-k="font"` chips row (~line 334), add a Fill row (same `.chips` pattern):
```html
    <div class="chips" data-k="fill" style="margin-bottom:var(--sp-in)">
      <button class="chip" data-v="solid">Solid</button><button class="chip" data-v="glass">Glass</button
      ><button class="chip" data-v="outline">Outline</button>
    </div>
```

- [ ] **Step 4: Handle the Fill chip + reflect initial state**

In the `.chips[data-k]` click delegate (~line 844), add a branch alongside `font`:
```javascript
      else if(k==='fill'){ cfg.fill=v; applyLook(cfg); }
```
And in the initial-selection reflect (~line 881, next to `selChips('font', cfg.font);`), add:
```javascript
  selChips('fill', cfg.fill || 'solid');
```

- [ ] **Step 5: Verify (node suites unaffected) + founder check**

Run `node site/js/session-timer.js --test` (13) and `node site/js/plan.js --test` (15) — both still green (untouched; confirm). Self-review: the Fill row toggles `#scene[data-fill]` live; a reload with a saved `cfg.fill` reflects the chosen chip; older cfg without `fill` defaults to Solid. Founder verifies the three fills across phases on-device.

- [ ] **Step 6: Commit**

```bash
git add site/session.html
git commit -m "feat(web): expose numeral Fill (solid/glass/outline) in session settings"
```

---

### Task 2: Setup — add Fill, promote Position/Fill/Font to Themes, keep Colour/Separator in Advanced, drop mocks + dead timer

**Files:**
- Modify: `site/setup.html`

**Interfaces:**
- Consumes: `segState` (generic `.mini-seg` click delegate stores `segState[seg]=v`), the Begin handler's `cfg` assembly, `applySepForMode()`.
- Produces: `cfg.fill` serialised on Begin (matching Task 1's session consumer).

- [ ] **Step 1: Add `fill` to `segState`**

In `segState` (~line 1004) add the field:
```javascript
  var segState={ sunmoon:'show', timershow:'always',
    place:'middle', fill:'solid', font:"'Newsreader',serif", sep:'none',   // number-look picker
    cycChange:'once', cycBy:'cycles' };
```
(The generic `.mini-seg` delegate at ~line 1031 already does `segState[seg]=btn.dataset.v`, so a `data-seg="fill"` control needs no new handler.)

- [ ] **Step 2: Build the three Themes-panel numeral `.sec` blocks (Position, Fill, Font)**

Insert these into the Themes panel, right before the Advanced button (`<button class="advanced-btn" id="advBtn">` ~line 535), inside `themes-scroll`. Position + Font are the existing blocks moved up; Fill is new:
```html
      <div class="sec">
        <span class="mini-lbl">Number placement</span>
        <div class="mini-seg" data-seg="place" style="margin-top:.5em">
          <button data-v="horizon">Horizon</button><button class="on" data-v="middle">Middle</button
          ><button data-v="ledge">Ledge</button><button data-v="top">Top</button>
        </div>
      </div>
      <div class="sec">
        <span class="mini-lbl">Numeral fill</span>
        <div class="mini-seg" data-seg="fill" style="margin-top:.5em">
          <button class="on" data-v="solid">Solid</button><button data-v="glass">Glass</button
          ><button data-v="outline">Outline</button>
        </div>
      </div>
      <div class="sec">
        <span class="mini-lbl">Numeral font</span>
        <div class="mini-seg" data-seg="font" style="margin-top:.5em">
          <button class="on" data-v="'Newsreader',serif">Serif</button><button data-v="'Jost',sans-serif">Jost</button>
        </div>
      </div>
```

- [ ] **Step 3: Remove the moved blocks + the two mocks from the Advanced sheet; keep Colour + Separator**

In the Advanced sheet's Number-look region (~lines 580-617): DELETE the **Number placement** `.sec` (582-588) and **Numeral font** `.sec` (589-594) — they now live in the Themes panel — and DELETE both mock blocks: **Numeral style** `.sec.w2` (608-613) and **Scene focus blur** `.sec.w2` (614-617). KEEP the **Separator** `.sec` (595-601) and **Number colour** `.sec` (602-606). Update the section comment (580-581) to reflect that only Colour + Separator remain here (placement/fill/font moved to the Themes panel).

- [ ] **Step 4: Serialise `cfg.fill` on Begin**

In the Begin handler's cfg assembly (~line 1278, next to `cfg.place = segState.place;`) add:
```javascript
    cfg.fill = segState.fill;                                        // solid|glass|outline
```

- [ ] **Step 5: Remove the dead 900 ms Begin timer**

In the `#begin` click handler, delete the moot reset line (~line 1270) — it never fires because `location.href='session.html'` unloads the page first:
```javascript
    setTimeout(function(){ b.textContent='Begin'; },900);
```
(Leave the `this.textContent='Focusing…'` line — it shows briefly before navigation.)

- [ ] **Step 6: Verify (node suites unaffected) + founder check**

Run `node site/js/plan.js --test` (15) — still green (untouched; confirm). Self-review: `segState.fill` toggles via the generic delegate; Begin's `cfg` now carries `fill`; the per-mode separator rule still works (place in Themes still drives `applySepForMode` which updates the Separator buttons in Advanced); no dangling references to the deleted mock ids/classes. Founder verifies on-device: Themes panel shows Position/Fill/Font; Advanced shows Colour/Separator; Setup→Session round-trip carries `fill`.

- [ ] **Step 7: Commit**

```bash
git add site/setup.html
git commit -m "feat(web): Setup numeral Fill + Themes/Advanced control split, drop mock teasers"
```

---

## Self-Review

**Spec coverage:** spec §2 Fill control → Task 1 (session) + Task 2 Step 2/4 (setup). §3 Themes/Advanced split → Task 2 Step 2-3. §4 persistence (`cfg.fill`) → Task 1 Steps 1-2-4, Task 2 Steps 1-4. §5 removals (2 mocks + dead timer) → Task 2 Steps 3, 5. §6 build order (session first, then setup) → Task order. §7 testing → each task's verify step. All covered.

**Placeholders:** none — every step names the exact file location and the literal code/markup to add or delete.

**Type consistency:** `cfg.fill` ∈ `{solid,glass,outline}` produced by Setup Begin (Task 2 Step 4) and by the session chip handler (Task 1 Step 4), consumed by `applyLook` → `S.dataset.fill` (Task 1 Step 2), matching the pre-existing `#scene[data-fill="solid|glass|outline"]` CSS. `segState.fill` (Task 2 Step 1) feeds Begin. Consistent.

## Notes for the implementer

- Fill's rendering is already built — do NOT touch the `#scene[data-fill=…]` CSS; only expose/thread the control.
- Moving the `.sec` blocks between panels is markup relocation; keep them byte-identical except where noted. The founder verifies the Themes-panel layout on-device (Iron Rule) — build it clean; placement/spacing is the founder's to confirm.
