# Sustain

**A calm focus timer that moves with your day.** Sustain is a cross-platform focus-timer product built around
a research-backed *Flow Cycle* methodology and a living anime-seaside aesthetic. It ships as a native **Flutter
app** (Android on the Play Store; iOS/desktop targets present) and a **web version** (an Astro single-page
"living painting" that doubles as the top-of-funnel and a full in-browser timer).

- **App** (`lib/`, `android/`, `ios/`, …): the full product — timer engine, themes, monetization, notifications,
  analytics, streaks, insights.
- **Web** (`web-astro/`): the production Astro site — one persistent WebGL seascape with Home → Setup → Session
  layered over it, its own timer + audio engines.
- **`_internal/`**: our working files — LOCKED design references, prototypes/labs, source art, tools. Not shipped,
  not imported by any build.
- **`docs/`**: specs, roadmap, brand/design language, launch + monetization guides.

---

## Project structure

```
hourglass/                          ← repo root
│
├── lib/                            ═══ FLUTTER APP (Dart) ═══
│   ├── main.dart                   app entry
│   ├── app/                        app shell, routing, theme wiring
│   ├── session/                    session/timer engine (flow-cycle plan, run state)
│   ├── hourglass/                  hourglass physics + painter (sand simulation)
│   ├── hourglass_preview_main.dart standalone hourglass preview entry
│   ├── preview/                    dev preview screens
│   ├── ui/                         screens + widgets (home, setup, session, insights, settings, paywall)
│   ├── domain/                     domain models (plan, focus score, streak, entities)
│   ├── data/                       persistence, repositories, backup/restore
│   ├── audio/                      in-app sound (ambience, cue bells)
│   ├── notifications/              opt-in engagement + in-session foreground-service live timer
│   ├── billing/                    RevenueCat monetization (Pro / Plus, à-la-carte themes)
│   ├── content/                    static content (Sustain 101, copy)
│   └── data/ …                     (color themes, insights PDF report, etc.)
├── test/                           app tests (~280+ passing)
├── assets/                         app runtime assets (audio/, fonts/) — declared in pubspec.yaml
├── android/ ios/ macos/ windows/ linux/   Flutter platform targets
├── web/                            Flutter's own web-build target (favicon, icons, manifest)
├── pubspec.yaml  pubspec.lock  analysis_options.yaml  .metadata   Flutter project files
│
├── web-astro/                      ═══ PRODUCTION WEB (Astro + Three.js) ═══
│   ├── astro.config.mjs            Astro config (dev toolbar disabled — it overlapped the pause button)
│   ├── package.json                deps: astro, three, suncalc
│   ├── gen-assets.mjs              one-off: source plates → WebP + blur-up LQIP
│   ├── src/
│   │   ├── pages/index.astro       the ONE page: mounts the scene once + Home/Setup/Session; hash router;
│   │   │                           font @font-face; LQIP preload; favicon; nav controller
│   │   ├── components/
│   │   │   ├── SceneWorld.astro    scene markup (#stage>#frame> #glitter,#nums,#occ,#sand) + numeral CSS
│   │   │   ├── Home.astro          landing hero (v22): nav pill, headline, Begin Focus + Play badge
│   │   │   ├── Setup.astro         setup screen: mode/plan, sound mixer, themes, number-look, Begin→cfg
│   │   │   └── Session.astro       running timer: numerals over the hourglass, pause + paused overlay,
│   │   │                           gear→settings sheet, give-up/done/session-over popcards, nav guard,
│   │   │                           endless flip, wake lock; ?tune = dev number-tuner
│   │   ├── scene/
│   │   │   ├── scene.js            WebGL living scene: plate day-cycle, sun/moon, sand painter, glitter,
│   │   │   │                       occluder, numeral geometry/tone; exposes window.SustainScene
│   │   │   ├── shaders.js          GLSL vertex/fragment shaders
│   │   │   ├── geo.js              location → real sunrise/sunset (SunCalc) for the warped day clock
│   │   │   ├── audio.js            shared Web-Audio engine → window.SustainAudio (mix + bell cues)
│   │   │   └── lqip.js             generated base64 blur-up placeholders
│   │   └── lib/timer.js            session plan/timer math (createSession: configure/start/pause/sample)
│   └── public/
│       ├── js/plan.js              plan builder (flow/pomodoro/custom/endless → [{kind,min}])
│       ├── plates-phases/*.webp    6 day-phase seascape plates
│       ├── plates/moon-tex.webp    moon texture
│       ├── assets/fonts/*.woff2    self-hosted overlap-removed numeral faces (NumSerif/NumSans)
│       ├── assets/audio/*          ambience (sand/ocean/breeze/birds) + cue_bell
│       ├── brand-icon.png  google-play-badge.svg
│
├── docs/                           ═══ SPECS & DOCS ═══
│   ├── README.md                   docs map
│   ├── feature-roadmap.md          future hub (order-of-truth #2)
│   ├── project-context.md          product context (#3)
│   ├── superpowers/specs/2026-07-29-sustain-web-master-spec.md   WEB SOURCE OF TRUTH (read first)
│   ├── brand-design-philosophy.md  design-language.md
│   ├── launch-founder-actions.md   play-console-revenuecat-setup-guide.md  references/
│   │   (legal/ moved 2026-08-02 → web-astro/src/pages/privacy.md + terms.md, hosted at /privacy + /terms)
│
├── _internal/                      ═══ OUR WORKING FILES (not shipped) ═══
│   ├── site/                       LOCKED design references (session.html, setup.html, home.html) — web-astro is ported from these
│   ├── web-prototype/              prototypes / labs (number-lab.html, hybrid.html, timer-modes.json)
│   ├── icon images/                source app-icon art
│   ├── plates without hourglass/   source seascape plate art
│   ├── tools/gen_sound_cues.py     tool script
│   ├── FGS Proof/                  foreground-service proof video (Play Console)
│   ├── APP DESCRIPTION             draft store description
│   └── README.md                   index of the above
│
├── CLAUDE.md                       agent project instructions (read the web master spec first)
├── README.md                       this file
└── .gitignore  .metadata  .claude/
```

---

## The web version — how it works

One HTML document (`index.astro`) mounts the WebGL seascape **once** and never re-mounts it; **Home → Setup →
Session** are states layered over that single living scene. Navigation is hash-routed (`#setup`, `#session`) with
the View-Transitions API for cross-fades, so Back/refresh behave and a static host never 404s.

- **Home** — the landing hero over the live current-time scene (the hourglass, sun/moon, and day-phase plate all
  follow the viewer's real local clock via SunCalc-warped time). "Begin Focus" → Setup.
- **Setup** — pick a mode (Flow / Pomodoro / Custom / Endless) and plan, an ambient **sound mix** (previewable),
  the **time-of-day** and **number look** (placement / fill / font / separator / colour). "Begin" writes the
  config to `localStorage`, arms a one-shot flag, and → Session.
- **Session** — the timer runs on the shared scene: the hourglass **sand drains** to the plan, big numerals sit
  around the glass (occluded *behind* it per placement), and the chrome is quiet: ⚙ settings (a live sheet
  mirroring Setup), Give up (top-right), Pause (a frost circle, bottom-centre). A **navigation guard** stops
  accidental back/reload out of a live session; reload shows a "session has ended" card. Ambient audio plays the
  chosen mix with a soft bell at start / breaks / end.

### Session states
| State | Behaviour |
|---|---|
| Focus / break | Plan segments run inline; a "Focus"/"Break" toast + bell cue on each boundary |
| Pause | Blurred "PAUSED" overlay, tap-to-resume, 3 min cap + 15 s grace → auto-end; audio muted |
| Give up | Confirm popcard → credits focus, returns to Setup |
| Complete | "Well done · you focused Xm" → Again / End |
| Session over | On reload/stale entry (armed one-shot spent) → "Back to Setup" |
| Endless flip | Fade-through-black, refill the hourglass (see *Remaining* below) |

---

## Build & run

**Web** (from `web-astro/`):
```
npm install
npm run dev        # http://localhost:4321
npm run build      # → dist/
```
The `?tune` query on a session (`/?tune#session`) opens a localhost-only number-tuner for perfecting numeral
size/position on new plates.

**App** (Flutter, from repo root): `flutter pub get`, then `flutter run` (or build per platform).

---

## Current state & remaining (web)

**Done & verified in-browser:** the full Home → Setup → Session workflow; locked numeral geometry + depth
occlusion + overlap-removed fonts; live settings sheet (sound / timer / number-look / scene); pause + paused
overlay; give-up / done / session-over popcards; nav guard; shared audio engine with bell cues; the location-
aware day/night cycle.

**Remaining / known refinements:**
- **Endless "flip"** currently *resets* the count (as the original `session.html` did); the intended behaviour is
  the elapsed timer **continues** while only the hourglass sand refills — a small engine change to decouple the
  sand visual from elapsed time.
- **Break audio-duck** — hush the ambient mix on breaks (the app does this; not yet ported to `SustainAudio`).
- Landing page scroll-through (day→night), self-hosted fonts perf pass, SEO/deploy, and stripping the remaining
  hidden lab UI from `SceneWorld.astro`.

The web **source of truth** is `docs/superpowers/specs/2026-07-29-sustain-web-master-spec.md` (§22 changelog
tracks every change). Design references live in `_internal/site/` and `_internal/web-prototype/`.
