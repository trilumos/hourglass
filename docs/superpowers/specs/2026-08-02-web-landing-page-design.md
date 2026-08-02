# Sustain web — the scroll landing page (design)

> ⚠️ **PARTLY SUPERSEDED the same day it was written.** §1–§3 (the two jobs, the day sweep, the spine,
> "content on both flanks", no invented proof) still hold. **§4–§7 do not**: the built landing is a **PINNED
> STORY**, not a scrolling page — the background never changes and only text chapters cross-fade. The
> founder rejected the scrolling version on sight, along with its full-screen scrim, blur over the art and
> glass card grid. **The live design is master spec §4.2 + §4.3 — read that, not this.** Kept as the record
> of what was tried and why it was dropped.
>
> Companion to the master spec `2026-07-29-sustain-web-master-spec.md` (§4 page architecture, §13 perf,
> §14 aesthetic bar). This designs the **full landing page below the hero** — the last piece of W1 before
> deployment.

## 1. What this is

The landing page is the marketing page the hero already sits on top of. Its **only two jobs** (master §1):
**rank on SEO** and **convert visitors to app installs**. It is not a second tool and not a new world — it is
**content scrolling through the one living world that is already mounted**.

## 2. The three decisions (founder, 2026-08-02)

1. **Scroll drives the day.** Top of page = the viewer's **real local time** (live, unchanged). Scrolling
   sweeps the scene clock **+12 reference hours, wrapping**, so every visitor rides 3–4 phases whenever they
   arrive: a 9 AM visitor gets midday → sunset → twilight → night; an 11 PM visitor gets night → pre-dawn →
   sunrise → midday. Scrolling back to the top restores `setDay('follow')`.
2. **Six sections:** hero (unchanged) → How it works → The living world → Science → Get the app → FAQ + footer.
3. **Content flanks the hourglass on BOTH sides.** The hourglass is the **spine** of the page; every section
   below the hero puts content in a left column and a right column with the hourglass in the centre gutter.
   *The hero is exempt* — its approved lower-left composition stands, and its empty right side is deliberate
   (founder: "we don't have anything to put on the right side so we kept it empty").

## 3. Legibility model

The hero's model (no shadows/halos, a soft plate tint doing the work) does not survive four different skies
with text on both flanks. Below the hero:

- **The scene recedes.** A scrim ramps in over the first viewport of scroll to ~50% dark plus a 2 px blur on
  `#frame` — enough that copy is clean over any sky, light enough that the day change still reads. The scene
  is never fully hidden; the sky change IS the page's motion.
- **Quiet glass panels** (`.glass-quiet`, the existing token) carry the copy blocks. Glass stays an **accent,
  not the foundation** (master §14) — panels are used where text sits over busy scene detail (the right flank
  has cliffs, blossom and lanterns), not as a wall of frosted boxes.
- No text shadows or halos anywhere (the founder rejected those on the hero; the rule holds site-wide).

## 4. Layout — the hourglass as spine

```
grid-template-columns: 1fr var(--hg-w) 1fr
```

`--hg-w` is published by the scene: `fit()` already computes the displayed frame width `DW`, so it sets
`--hg-w = DW * HG_FRAC` on `:root` (`HG_FRAC ≈ 0.27` — the glass silhouette spans ~0.134 of the plate width
around axis `S.cx = 0.4989`, the wooden posts and plinth ~0.234; 0.27 adds clearance). The frame is centred
horizontally and the axis sits at ~49.9%, so symmetric columns are correct to within a pixel.

This makes the gutter track the hourglass **exactly** at every viewport instead of guessing with `vw` — which
matters because the plate is cover-fit, so on tall/narrow windows the hourglass is a much larger fraction of
the screen than on wide ones.

**Collapse rule:** below the point where the flanks stop being usable (the hourglass eats the width on
portrait phones), sections become a **single column** over a heavier scrim, content stacked above/below the
hourglass rather than beside it. Exact breakpoint is set in the responsive pass, not guessed here.

## 5. The sections

### 5.1 How it works — "Focus is a ritual, not a countdown."
**Left — the four steps:** Choose your block · Name the intention · Begin, and stay · Recover properly.
**Right — the four modes,** one line each: **Flow** (one long block; the hard first minutes are the work) ·
**Pomodoro** (25 and 5, longer rest every fourth) · **Custom** (your own lengths) · **Endless** (one block on
repeat, counting down, until you stop).

### 5.2 The living world — "The sky moves with your day."
**Left:** the timezone → real sunrise/sunset math (7 PM in Mumbai has the sun on the water; 7 PM in Berlin
does not); six hand-painted skies crossfading across the day; sun and moon on real arcs, never sharing the
sky. **Right:** the sand is the session — it falls in real time and freezes when you pause; or hold one light
and watch a single hour play out across the whole session; everything runs in the browser, nothing uploaded.

### 5.3 Science — "Why blocks beat willpower."
Four attributed findings, two per flank, each linked to the source. **No overclaiming** — the section closes
with the honest line: *"Sustain isn't a study. These are the findings the design is built on."*

1. **Switching has a cost** — Leroy (2009), *attention residue*: leaving a task before it feels finished
   leaves part of your attention on it, and the next task measurably suffers.
2. **Train in bouts** — Ericsson et al. (1993): elite performers practise in bouts of roughly 60–90 minutes
   with deliberate rest between, not in marathons.
3. **Ride the wave** — Kleitman's basic rest–activity cycle: alertness runs in roughly 90-minute waves;
   blocks and breaks work with that rhythm instead of against it.
4. **Say what you'll do** — Gollwitzer (1999), *implementation intentions*: naming a specific plan raises
   follow-through sharply over intention alone. This is what Sustain's one-line intention is for.

### 5.4 Get the app — "The web timer is the practice. The app is the progress."
**Left:** everything here is free forever — four modes, the whole living world, no account, no ads.
**Right:** what the app adds — Focus Score & Stamina · streaks and full history · Insights · strict sessions
and notifications — then the official Play badge.
**No numbers.** The app has few installs yet (founder, 2026-08-02); no ratings, install counts, or
testimonials ship until they are real.

### 5.5 FAQ + footer
Native `<details>/<summary>` (no JS) plus a **JSON-LD `FAQPage`** block so the answers are eligible for
Google's snippet treatment. Questions target real search intent: is it free · account needed · what is Flow ·
Pomodoro vs one long block · does it work on a phone · does the timer survive a background tab (yes —
wall-clock, master §7) · why the scene changes · iOS.

Footer: brand, Play link, **Privacy** and **Terms**, contact (`trilumos.app@gmail.com`), copyright.

## 6. Legal pages (folded in — unblocks a P0)

`docs/launch-founder-actions.md` §3 lists hosting `docs/legal/privacy-policy.md` + `terms-of-service.md` at
public URLs as a **P0** launch action. The site is the natural host: `/privacy` and `/terms` ship as Astro
markdown pages with a shared minimal layout (no scene, no JS), footer-linked. Two real indexable URLs, and the
Play Console privacy-policy field gets a permanent home.

## 7. Technical shape

- **Scroll → day:** one rAF-throttled scroll handler calling the existing `SustainScene.setDayHour(h)`.
  No new scene rendering code; the API already crossfades plates and moves sun/moon to an arbitrary hour.
- **Scroll lock:** `html,body{overflow:hidden}` today. Scrolling is enabled **only on Home**; entering
  `#setup`/`#session` re-locks it and resets to the top, and leaving a session returns to a top-of-page Home.
- **Reveals:** one `IntersectionObserver` toggling `.in`. No animation library, no GSAP.
- **Nav anchors:** `How it works · Science · FAQ` become real in-page targets. Fixes a live bug — anchor
  clicks currently reach the hash router and fire a pointless View Transition; the controller will skip the
  transition when the resolved screen has not changed.
- **Plates:** all six textures are loaded eagerly at init today (`scene.js:64`), which violates master §13
  ("load one plate, not six"). The scroll sweep needs all six eventually, so the fix is to load the
  **current** plate eagerly and kick the other five **after `reveal()`** — LCP is unaffected and the initial
  payload drops.
- **Budget unchanged:** LCP < 2.5 s, CLS ≈ 0 (master §13). The landing adds static HTML/CSS and roughly two
  dozen lines of JS.

## 8. Out of scope here

The SEO **content pages** (`/pomodoro-timer`, `/lofi-co-alternative`, guides — master §3.1) remain a later
pass; this is the one landing page. `/stage`, PiP, share links stay deferred (master §16).
