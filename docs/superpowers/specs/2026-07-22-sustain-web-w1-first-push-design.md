# Sustain Web W1 — First-Push Design Spec (2026-07-22)

> **Status:** 🟢 Design brainstormed & founder-approved 2026-07-22. Ready for `writing-plans`.
>
> **What this is:** the concrete design for the **first shippable version of the website** — a free
> focus timer built on the locked living-painting scene. It builds directly on:
> - [`2026-07-17-sustain-platform-strategy-design.md`](2026-07-17-sustain-platform-strategy-design.md) — the canonical platform/money strategy.
> - [`2026-07-19-sustain-web-w1-handoff.md`](2026-07-19-sustain-web-w1-handoff.md) & [`2026-07-18-...`](2026-07-18-sustain-web-w1-handoff.md) — the built, locked scene (`web-prototype/hybrid.html`).
>
> This doc **refines** the platform strategy in two places (both recorded in §2): it decouples web
> monetization from app Sync, and it settles the cross-platform data model. Where they differ on those
> points, **this doc wins**; everywhere else the platform strategy stands.

---

## 1. The first push — scope

**Ship a free, beautiful, deployable focus-timer site on the scene we already built.** Its only jobs
(unchanged from the strategy): **rank on SEO, and convert to app installs.** Zero billing, zero accounts,
zero server-stored data.

**In:** the living-painting scene (done) · a real timer with 4 modes · the signature session view ·
`/stage` fullscreen · a scroll landing with the persistent hourglass · SEO · a tasteful install CTA · an
optional external tip link.

**Out (deliberately):** billing, accounts, Sync, progress/score, PiP, embed, share links, soundscapes
(see §6 for what's fast-follow vs W2).

---

## 2. Money & data model — settled this session

The model is coherent as **three products with three different jobs.** "Pro" is *not* stretched across
both platforms — the web tier is never called "Pro."

| Product | Job | Where it's bought | What it gives |
|---|---|---|---|
| **App Pro** | **Growth** | app (Play/RevenueCat) | full progress system (Focus Score, Stamina, Insights, streaks) + app themes |
| **Web Scenes** | **Beauty** | web (MoR, W2a) | scene packs, 3D glass, customization, custom upload — **no** progression |
| **Sync** | **Continuity** | either (W2b) | one focus history across app + web, + permanence |

**The three-line story:**
- Buy **App Pro** → the full progress system + app themes (less *visual* customization than web).
- Buy **Web Scenes** → the beauty/customization, no progression.
- Buy **Sync** → what you do on web is **scored and folded into your one history, viewed in the app.**

**Data rules (settled):**
- **Web never shows the analytics** — Focus Score numbers, Insights, Stamina stay **app-only**. That
  absence is the install hook. Web *may* show the **beautiful Sediment** (W2b, via Sync) but never the
  numbers.
- A **synced web session gets a Focus Score computed** (score is a pure function of the session record)
  and counts toward progress — **read in the app, not on web.** (Resolves the old open thread.)
- **W1 web is anonymous + local-only.** It records nothing server-side and touches the app not at all.
- **Purchases never cross-unlock.** App Pro + Sync earns a web visitor their **sessions recorded +
  Sediment** (via their account) — but web still renders **free-tier**; web cosmetics stay a **separate**
  purchase. Logging into web syncs data; it unlocks nothing visual.

### 2.1 Web free/paid split — decided
Governed by the locked rule: **the free tier must feel complete and premium — it's the best ad.** So the
entire living-painting Sea scene *with its circadian day cycle* is free; paid is *more* beauty and *deeper*
customization, never the core.

**Free forever** (much of it locked as never-paywallable, strategy §3): all 4 timer modes incl. Endless ·
the **base Sea scene + full circadian day cycle** · session view + all timer-visibility settings · **share links / share cards / embed** · **`/stage` (+`?record=1`)** · **PiP** · local
"focused today" · **basic soundscapes + 2-layer mixing** · install CTA · optional tip link.

> **Turning the hourglass off is not a W1 feature** — the empty hourglass is *baked into each plate*; we
> render only the sand, so there's no glass to toggle. It stays a never-paywall item (§3) *if* it ever
> becomes possible, which would need a separate hourglass-less plate per scene — deferred.

**Paid (W2a — "web sells beauty"):** additional **scene packs** beyond Sea (Garden, Mountain, City…) ·
**weather packs** sold à-la-carte (rain, storm, snow… each bought separately, unless a theme bundles its
own) · **custom background upload** (headline paid feature; **capped at 3 uploads/user** — also caps the
egress cost centre, §6.2) · **full soundscape mixer** (unlimited layers + premium sounds) · **hourglass
customization** (shapes, sand-flow styles) · animated/premium scenes.

> **No 3D glass hourglass.** The current baked-plate + rendered-sand hourglass is the *only* hourglass
> everywhere. A true-3D glass preset is **deferred indefinitely** — revisited only if the product grows
> enough to hire a team for full scenes + a 3D hourglass. (Supersedes the 3D-glass items in the platform
> strategy §5/§8/§12.)

> **Circadian is a property of a theme, not a sellable feature.** A day cycle means fully tuning that
> world's sun/moon path, horizon crossing, and phase plates — real per-theme build + testing work — so
> circadian is decided **per theme at build time**, never sold or toggled on its own:
> - A **full-circadian theme** (like the free **Sea**) has the day cycle **built in**. Sea being circadian
>   is what gives every visitor the day-cycle experience **free** — consistent with §3's "never paywall
>   circadian."
> - A **single-timeframe theme** (e.g. a fixed **Night**) has **no circadian** at all.
>
> It's **never surfaced to the user as a named feature** — just how a given scene behaves over the day, or
> doesn't.

**The granular boundary (decided):**
- **Scenes** — **Sea is the one free scene; every additional scene is a paid pack.** (A second scene can
  be promoted to free later as a seed — trivial.)
- **Sound** — basic loops + 2-layer mixing free; full mixer + premium sounds paid.
- **Hourglass** — the one mascot design free; shapes / sand-flow styles paid. (No 3D glass — deferred
  indefinitely, above.)

Exact pack pricing / **tier composition** (what's in which tier/bundle) is a **W2a** call informed by real
traffic — not pinned now. The *boundary* above is.

### 2.2 Roadmap refinement — web monetization is decoupled from app Sync
The platform strategy gated all of "W2" on app Sync shipping. That coupling was wrong. Only **Sediment-on-web**
and **web-sessions-scoring-into-the-app** need app Sync. The cosmetic paywall needs none of it. So the old
"W2" splits into two independently-shippable pieces:

- **W2a — Web commerce (independent of the app):** shared Firebase Auth (web stands it up first; the app
  joins the *same identity* at v1.3 — the "one Firebase project" rule §4 holds), a Merchant-of-Record,
  entitlements, storage for uploads → the cosmetic paywall.
- **W2b — The Sync bridge (needs app v1.3):** Sediment-on-web + web sessions scored into history.

**Consequence:** web and app roadmaps are decoupled — web's paywall can advance on its own merits.
**Two guardrails:** (1) decoupled ≠ cheap — W2a is still the billing long-pole (auth + MoR + entitlements +
storage + privacy policy); (2) sequence it **after W1 runs free and shows ranking/install signal** —
paywall-before-traffic is the lofi.co mistake regardless of Sync.

---

## 3. Theming — the scene is a reusable template
Founder decision: the living-painting scene is the template for **all** future themes. Same hourglass, same
sill; only the world behind it changes (Sea → Garden → Mountain → River → Room → City…). This *is* the W2
rendering thesis (§12 of the strategy), arrived at independently.

- **A theme = up to 6 pixel-aligned phase plates + a JSON config** (sea/glass masks, per-phase sand-shadow
  grade, day schedule). The locked primitives (sand, stream, glass outline, sun/moon) are shared and never
  re-tuned. **Sea is theme #1** (done, in `web-prototype/plates-phases/`).
- **Adding a theme later = content + light tuning, no code:** generate the plates (ChatGPT), bake the empty
  hourglass at the *identical* pixel position (the glass must never move), retrace masks, retune the sand
  shadow grade.
- **Lever:** a theme may be **full-circadian** (6 plates, day cycle) or **fixed-time** (1 plate, e.g. a
  night city) — the latter is ~6× cheaper when a scene only reads at one time of day.
- **Honest cost note:** the per-theme work is art + tuning, not code — real but modest. The fiddly part is
  the pixel-locked empty-hourglass bake (the reason the current 6 plates are integer-aligned to 0px).

Build the first push **data-driven** (theme = plates + config) so this stays true.

---

## 4. First-push build design

### 4.1 Sequencing — two phases (matches the handoff's 6.1 → 6.2)
- **1a — Timer in `web-prototype/hybrid.html`.** Keep the fast localhost + GPU loop and the **6 check
  scripts**. This is where the only real risk lives — *does a countdown feel right against the falling
  sand?* — so prove it before any migration.
- **1b — The Astro site.** Scaffold Astro + one **React island** for the scene/timer canvas; port the
  locked scene in (values intact, check scripts move with it); build the scroll landing, `/stage`, SEO, tip
  link, install CTA; compress the ~2 MB plates; deploy.

### 4.2 The timer engine (the actual unbuilt product)
- **Reuse the app's model *shape* in JS** (port the idea, not the Dart): a session is a list of
  **focus/rest segments** driven by one ticker. The app's pure model lives in
  [`lib/session/session_plan.dart`](../../../lib/session/session_plan.dart).
- **Four modes = four segment lists** (the strategy's named set):
  - **Flow** — one focus segment.
  - **Pomodoro** — focus / short-rest, long rest every 4.
  - **Custom** — user-set work + break lengths.
  - **Endless** — one open focus segment, break whenever the user says; the glass **drains → flips →
    refills** (matches the app), counting total focus. (Chosen over count-up, which reads less like an
    hourglass.)
- **Accuracy (non-negotiable):** elapsed is computed from **wall-clock timestamps**
  (`Date.now() - startTs - totalPausedMs`), *not* accumulated ticks — so it stays correct when the tab is
  backgrounded/throttled. `requestAnimationFrame` is for rendering only. (A focus timer that drifts in a
  background tab is broken. OBS Browser-Source isn't throttled, but a normal user's tab is — timestamps fix
  both.)
- **Wiring:** the ticker sets `S.prog = elapsed / segmentDuration`; the locked sand renderer already turns
  `S.prog` into falling sand. The current manual `prog` slider becomes a **dev-only debug** control (behind
  the existing lock group).
- **The day-cycle keeps running off the real local clock** (already built) — orthogonal to session
  progress: the clock drives the sky, the session drives the sand. A 4-hour session watches the sun move; a
  25-min Pomodoro barely shifts.
- **Controls & completion:** Start / Pause / Reset. On completion — a gentle cue, increment "focused
  today," a calm done-state, start-again. Rest segments **auto-advance** by default with a soft cue
  (Endless: the user triggers breaks).
- **Flip-to-start ritual** (§7.1) is polish — the first push uses a simple **Begin**; flip-to-start can
  follow.

### 4.3 Session UI over the scene
- The signature **`[min] · 🏺 · [secs]`** view — the hourglass is the divider between minutes and seconds;
  **numbers hidden by default, fade in calmly on hover / mouse-move.**
- **Timer-visibility setting:** *always show · flash every N min · hidden, show on hover.*
- Minimal chrome: pick mode + duration before start; during the session the hourglass is the hero and
  controls fade away.
- **Local "focused today"** counter — `localStorage` only, no history, no account, nothing to migrate.

### 4.4 `/stage`
- Chrome-less fullscreen focus view (the fade session view, no setup UI).
- `+ /stage?record=1` — a quality preset for OBS **Browser Source** → YouTube Live.

---

## 5. Verification
- **Keep all 6 scene check scripts running** through both phases (they each exist because a real bug
  shipped): `check-wiring.py`, `check-schedule.js`, `check-glow.py`, `check-bed.js`, `check-stream.py`,
  `check-pile.js`, plus `node --check` on the extracted module. Do not weaken them to make a change pass.
- **Add one timer check:** given a start time and a paused interval, `elapsed`/`S.prog` computed from
  timestamps matches expected within tolerance across a simulated background gap (proves the accuracy rule).

---

## 6. Not in the first push

**Fast-follow (still W1, still free):** soundscapes (blocked on founder sourcing royalty-free/CC0 audio +
CREDITS) · PiP (Document Picture-in-Picture) · embeddable widget · share preset links.

**W2a (web commerce, independent of app):** paid scene packs · à-la-carte weather packs (rain/storm/snow) ·
custom background upload (max 3/user) · full sound mixer · hourglass shape/flow customization · accounts +
MoR + entitlements. *(No 3D glass — deferred indefinitely.)*

**W2b (needs app v1.3 Sync):** Sediment on web · web sessions scored into the app's history.

---

## 7. Open threads (captured — none block the first push)
1. **App 2D-vs-scenic revamp.** Lean: keep the loved 2D painter as the free default (it's proven, low-end
   safe, and the uncanny-valley risk §14 is real), sell scenic as à-la-carte buyables in the existing theme
   store. Deserves its own brainstorm — it touches the live rated app.
2. **Web tier composition + combined/cross-grade pricing + whether Lifetime includes Sync.** All W2a
   billing — what's in which tier/bundle is brainstormed when we build W2a, with real traffic. The 3-family
   × 3-period matrix was considered and set aside as too heavy.
3. **Founder actions:** buy the domain (`sustaintimer.com` recommended) · pick an audio source for
   soundscapes.

---

*Next step: `writing-plans` for the first push — 1a (timer in `hybrid.html`) then 1b (the Astro site).*
