# Session handoff — Sustain web, 2026-08-02

Continue from here. The web **source of truth** is `2026-07-29-sustain-web-master-spec.md` (read it first;
§4.2/§4.3 and the §22 changelog carry the detail). This doc is the current state, what is blocked, and the
brief for the next session.

Branch `web-w1-timer`, all work committed and pushed (`58d023f`). Build clean, dev server on `:4321`.

---

## 1. What shipped today

### The landing page — a PINNED STORY (not a scrolling page)
The first attempt scrolled real content over the scene with a full-screen scrim and glass cards. The founder
rejected it outright. **That shape is dead — do not reintroduce it.** What is built now:

- The scene, its bottom tint, the grain and the nav are **constant the whole way down** ("like a ppt with the
  same background throughout, only text is changing"). Scrolling only cross-fades text and advances the day.
- **Scrubbed to scroll position:** each chapter's `--o`/`--y` are written per frame from the same value that
  moves the sun. Text and sky are one signal, not two systems.
- **Section snap:** `proximity` + `scroll-snap-stop: always` — every chapter is a stop, but without
  `mandatory`'s hard pull (which read as "chopped into sections").
- Five chapters, each one statement + **at most three short points**, heading on one flank and points on the
  other, sides swapping. **Nothing ever sits on the hourglass.**
- Footer is the one thing that genuinely scrolls: a blurred `50svh` sheet that rises at the end.

### Responsive / mobile
Burger nav; Landing's spine turns vertical in portrait; Setup restacked to the founder's order
(focused-today → back + modes → Timer → Themes → Sound → Begin); Session forced to **Top** numerals with
viewport-unit geometry; 44 px touch targets on coarse pointers.

### `/stage` — the studio (spec §18.7)
The **same app minus the session chrome**. Configure on the real Setup screen, press Begin, and:
1. fullscreen + `window.obsstudio.startRecording()`
2. scene blurs, **3-2-1 countdown** (engine parked at zero elapsed, so the numerals show the FULL length)
3. bell rings, session starts at exactly its configured length
4. runs with no UI at all, then **fades to black** and calls `stopRecording()`

Capture guide: `docs/obs-stage-streaming-guide.md`.

### Cycle "Use this sequence"
The builder and the presets now edit a **draft**; Begin serialises the **applied** cycle. The button is
disabled while they match, enabled the moment anything changes, and the Themes panel names the cycle in use.

### SEO + legal
Canonical/OG/JSON-LD, `robots.txt`, `sitemap.xml`, generated `og-cover.jpg`. `/privacy` and `/terms` moved
into the site — this **closes the P0** in `launch-founder-actions.md` §3.

---

## 2. Root causes fixed (each explains a symptom the founder reported)

These are worth knowing because several are non-obvious and will bite again:

| Symptom | Actual cause |
|---|---|
| Blur "loads late", visible as two screenshots | An ancestor with `opacity < 1` is a **Backdrop Root** — a fading parent makes `backdrop-filter` sample an empty group until opacity hits exactly 1. **Never animate opacity above a `backdrop-filter` element.** |
| Flipped chapters vertically staggered | Grid auto-placement never moves backwards: `.say` taking column 3 pushed `.tell` into row 2. Both pinned to `grid-row: 1`. |
| Burger stopped opening after the hero | An `inset: 0` active chapter with `pointer-events: auto` is a full-viewport click shield over the nav. |
| Text washed out | Chapters sat at `z-index: 4`, *under* the hero's `.vign`/grain. |
| Headings breaking into four lines | `text-wrap: balance` optimises for even line *lengths* and narrows the block. |
| Scroll cue off-centre | The hourglass axis is `S.cx` (49.885%), not 50%, and `innerWidth` counts a scrollbar that percentages do not. |
| Setup never scrolled on mobile | `overflow-y` was set inside an `@container` block — **a container query cannot style the container itself.** |
| Themes/Sound collapsed on mobile | `flex: 1 1 0` becomes a *height* basis in a column with no free space to grow into. |
| Setup had a horizontal scrollbar | Declaring only `overflow-y` makes the other axis compute from `visible` to **`auto`**. |
| Setup panels grew in fullscreen | `--sq` is driven by `64cqh`; cap lowered 640→600 px so a windowed 1080p browser is already at the cap. |
| Phone showed no timer at all | Timer visibility defaults to **On hover**, and a touch device never fires `mousemove`. |
| Sunset ~40 min early | Timezone→representative coords: `Asia/Kolkata` = `[23.5, 80.0]`, ~9° east of Rajkot. Now uses exact location **only when already granted** (Permissions API — no prompt, so spec §5 holds). |
| Plate downloaded twice | A CORS preload can never be reused by the no-CORS fetch a CSS `background-image` makes. |
| 25 min started at 24:59 | Pause/resume keeps the ~80 ms before the pause lands. `restartSession()` resets the clock instead. |

Also fixed: an **unprompted geolocation request on every page load** (against spec §5), and **all six plates
loading before first paint** (against spec §13).

### A UI-contract audit is now owed on every screen

The **"5 min" timer option did nothing** — it was mapped to `'always'` behind a `// 5min→always for v1`
shortcut while its own description promised "surfaces briefly every 5 minutes, then fades away". Now
implemented (`flash`: shows at start, fades after ~4.2 s, repeats every 5 min, anchored to session start).

The lesson is the audit *type*, not this one bug. Every audit so far has been **change-scoped** — "is what I
just wrote correct?" — which structurally cannot catch an option that was wired wrong earlier and has been
lying ever since. **A contract audit is different: for every control in the UI, does it do what its own
label and description claim?**

Swept during this session (Setup → `cfg` → scene):

| Control | Verdict |
|---|---|
| `timershow` | ❌ **was broken** (`5min`→`always`) — fixed |
| `sunmoon` | ✅ consumed by `Session.astro:456` |
| `place` / `fill` / `font` / `sep` / colour | ✅ consumed by `setNumStyle` |
| `cycChange` / `cycBy` / sequence | ✅ consumed via `cfg.cycle` at `Session.astro:373`, now applied-gated |
| `autoContrast` | ⚠️ hardcoded `true` in Setup; only the Session sheet can change it. Not a false claim (Setup advertises no control), but worth a decision |

**Still unswept: the Session settings sheet and the timer modes.** Do the same pass there before launch.

---

## 3. Blocked — needs the founder

1. **Cloudflare Pages deploy.** Needs (a) the exact domain — everything currently assumes
   `sustaintimer.com` for canonical/sitemap/robots — and (b) `wrangler login`, an interactive browser OAuth.
   Suggested: ship `noindex` first, test on a real phone against a real URL, then lift it.
2. **On-device verification** of the story feel, the mobile pass and `/stage` (Iron Rule). None of the mobile
   work is device-verified; it is code-level reasoning about geometry, units and touch minimums.

---

## 4. Next session — the brief the founder asked for

> "Setup OBS for the best video recording of session, and the YouTube strategy and algorithm research and
> brainstorm to make YouTube another source of income. I want to grow my channel of these aesthetic ambient
> timer videos."

**Reference point the founder gave:** the channel **TimerPalette** — simple Pomodoro/timer videos, roughly a
year old, reportedly ~$3,000/month. Research it properly: upload cadence, video lengths, thumbnail/title
patterns, whether the revenue is AdSense or something else, and what its actual traffic sources are.

**The tension to resolve, honestly.** Strategy §10 currently says the opposite of what the founder now wants:
it treats YouTube as **customer acquisition at ~$0 CAC, never revenue**, citing 24/7 lofi livestreams serving
only one pre-roll per viewer (College Music: 38M watch-minutes → ~$1,300 lifetime). **TimerPalette is not a
livestream** — it is discrete VODs, which monetise completely differently (multiple mid-rolls per view,
repeat sessions, strong search intent). That difference may well invalidate §10's conclusion **for VODs while
leaving it true for livestreams.** Work that out from evidence, then update strategy §10 either way rather
than letting the spec and the plan disagree.

**Starting points:**
- `/stage` already produces the footage, and now auto-starts/stops the recording and fades to black.
- `docs/obs-stage-streaming-guide.md` has the encoder settings and the Windows lock fixes.
- Every video description should link the exact preset that produced it — the video is the ad.

---

## 5. How to run

`cd web-astro && npm run dev` → `http://localhost:4321`. `/stage` for the capture surface, `?tune` on a
session for the numeral tuner. **Restart the dev server after heavy component edits** — Astro's HMR serves
stale scoped CSS and it looks like the styles vanished (this bit twice today).
