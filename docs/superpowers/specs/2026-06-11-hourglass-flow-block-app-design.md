# Hourglass — Design Spec (v1 "The Ritual")

**Date:** 2026-06-11
**Status:** Approved design → ready for implementation planning
**Working title:** Hourglass (final brand name TBD before launch — see Open Items)

---

## 1. Vision & positioning

Hourglass is a study/focus app built around a single opinionated idea: **stop selling a prettier countdown; build the user's actual ability to focus over time.**

The crowded, un-winnable fight is "the prettiest timer." The open, winnable fight is **the app that trains your focus** — a category nobody owns, and one the hourglass metaphor is perfect for, because an hourglass is a vessel that visibly grows.

**Positioning line:** *Train your focus like an athlete, recover like one too.*

**Category reframe:** not "a timer" — **focus training** (the "Strava/Duolingo for focus" framing).

The aesthetic, calm, tactile, screenshot-worthy experience from the original concept is preserved — but it is the *surface*, not the *moat*. The moat is the method + the craft.

## 2. The method we coin — "The Flow Block"

A session walks the user through the real flow cycle:

**Set intention → Flip → Struggle → Flow → Recovery.**

The user's sustainable block length is their **Focus Stamina**, which grows over time toward the ~90-minute flow-block ideal. Pomodoro and custom timers exist as **on-ramps**; the Flow Block is the signature/hero mode.

### 2.1 Scientific grounding (Flow Research Collective — Rian Doris / Steven Kotler)

The method is grounded in flow science, which gives it credibility and a vocabulary the target audience already trusts.

- **The Flow Cycle has four phases: Struggle → Release → Flow → Recovery.** You must move through all four to return to flow.
  - **Struggle** is a cortisol/norepinephrine state that literally "makes you squirm." This is where most people quit. *Naming it as an expected, temporary phase is our signature reframe.* The heaviest sand falls first.
  - **Release** is the hand-off: pushing past the edge triggers a **dopamine release** that pops you into flow.
  - **Flow** is the effortless, high-performance state. Lasts ~90 minutes (ultradian cycle).
  - **Recovery** is mandatory and **active** — under-stimulating, phone-free. "Resensitize, not detox."
- **Challenge–skill balance (the flow channel):** flow lives just above current skill (boredom if too easy, anxiety if too hard). As skill grows, challenge must rise to stay in the channel → **this is why Focus Stamina grows.**
- **Long blocks beat short ones:** the science favors **90–120 min uninterrupted blocks**; the interruption tax is ~15 min to reload focus. A 25-min Pomodoro ends right as flow should begin → Pomodoro is the on-ramp, not the destination.
- **Active recovery is the differentiator:** recovery must be calm and phone-free ("boring breaks" — starve the brain of dopamine). Every other timer app fails here by letting users doomscroll their break.
- **Environment design beats willpower** (their "ADT — Attention Deficit Trait" framing) → justifies distraction protection and the protect-the-block mechanic.

### 2.2 Honesty constraints (non-negotiable, part of the trust that builds a movement)

- We do **not** claim Doris/Kotler "attack Pomodoro" by name — no such quote exists. We present the Pomodoro critique as *our* flow-science-informed stance.
- The "4% rule" and "500% productivity / 2× learning" figures are heuristics / marketing-grade, **not** lab constants. We don't present them as measured fact.
- The beginner stamina ramp ("start small, grow toward 90 min") is general attention-training practice, **not** an FRC claim. The 90-min target is FRC-grounded; the ramp is our approach.

## 3. Target audience

- **Primary:** students ~15–25 (studygram / studytube) who treat studying as something to make beautiful, value calm and craft over feature lists, and share the tools they use.
- **Secondary:** young professionals / remote workers wanting a gentle, attractive deep-focus tool.

## 4. Scope

### 4.1 v1 — "The Ritual" (this spec)

Goal: nail the **emotional core** — the ritual that makes someone say "this is different" — and nothing else.

**In:**
- The hourglass + falling sand visual (stunning, lightweight — see §8).
- Flip-to-start gesture.
- "Set your intention" step (one clear goal per block).
- Hero **Flow Block** mode with the four phases surfaced gently; **Pomodoro + custom** timers as on-ramps.
- **Auto-continue ("endless flow")** toggle (see §6.2).
- **Phone-free Boring Break** (Recovery) — on by default, toggleable.
- **Protect-the-block** mechanic (positive reframe of "don't leave") — toggleable.
- Signature sand sound + 3–4 soundscapes (sand, rain, café, brown noise).
- **Focus Stamina** (simple v1 — see §7).
- Lightweight stickiness: daily streak, focus time today/week, sessions completed.
- **Share cards** — auto-generated, beautiful, sized for IG/TikTok.
- Dark / AMOLED mode. Fully offline. Local data only.

**Out (with target phase):**
- Premium subscription + RevenueCat → **P2**
- Collectible skins/sand library (v1 ships a small tasteful set) → **P2**
- Advanced stats (charts, calendar heatmap, subject tags) → **P2**
- Soundscape mixer → **P3**
- Accounts + cloud sync (Firebase Auth/Firestore) → **P3**
- Widgets / lock screen → **P3**
- Social / co-study, physics-grade grain simulation → **P4**

### 4.2 Roadmap

**P1 Ritual** (this spec) → **P2 Identity & Money** (skins library, advanced stats, share-card variety, premium) → **P3 Ecosystem** (sync, widgets, mixer) → **P4 Best-in-class** (social, physics-grade sand, the movement).

Every v1 decision must leave room for P2–P4 without rework (e.g., skins are data-driven from day one).

## 5. Platform & tech stack (locked)

- **Android first**, published to Play Store (Google dev account in hand). iOS later, revenue-funded (Mac needed only to compile/ship; coding done on Windows).
- **Framework:** Flutter + Dart — chosen because the app is a bespoke animated visual (Flutter draws every pixel; best path to a gorgeous, smooth hourglass) and gives one codebase → Android now, iOS later for free.
- **State:** Riverpod.
- **Local data:** Drift (SQLite).
- **Audio:** just_audio + audio_session (gapless loops).
- **Analytics / crash:** Firebase Analytics + Crashlytics (from day one — we need usage data to chase traction).
- **Pre-chosen for later:** RevenueCat (P2 subscriptions/IAP across stores), Firebase Auth + Firestore (P3 sync).

## 6. The v1 session loop (the heart)

1. **Home** — the hourglass at rest, calm. Today's focus time + streak (small). A single "Begin." Mode selector (Flow Block / Pomodoro / Custom).
2. **Set intention** — "What's this block for?" (one line) → confirm length (Flow Block *suggests* a length from current stamina; Pomodoro presets; custom) → pick a soundscape.
3. **Flip** — a tactile flip gesture starts it; the screen goes full and quiet.
4. **Struggle** — a single soft line early ("The first few minutes are the hard part — stay with it."), then it fades to silence. Sand falls.
5. **Flow** — near-zero chrome: sand + sound + a tiny pause control. **No countdown numbers by default** (calm); tap to faintly reveal time if wanted.
6. **Protect-the-block** — if the user leaves the app, a gentle-but-real consequence (sand spills / block breaks), framed as protecting flow, not punishment. Toggleable.
7. **Completion** — planned time completes → behavior depends on Auto-continue (§6.2). On end: soft chime, glass settles, "50 minutes focused." Session logged, streak ticked, stamina updated.
8. **Boring Break** — calm, phone-free Recovery screen with a proportional break timer and a nudge to look away / walk / breathe. On by default, toggleable. *Contrarian signature.*
9. **Share card** — optional, auto-generated card ("50 min focused · Day 7 · [skin]") sized for IG/TikTok.

### 6.1 Phase engine

A domain-layer state machine drives phase transitions: `SetIntention → Struggle → Release → Flow → (loop if auto-continue) → Recovery → Done`. Phase boundaries (e.g., Struggle duration) are time/proportion based and tunable. The Struggle reframe and the calm transitions are presentation reactions to phase state.

### 6.2 Auto-continue ("endless flow") toggle

- **ON (endless flow):** planned time completes → soft "you hit your goal" chime → if the user does **not** press End, the hourglass auto-flips and the session continues seamlessly, looping until the user stops. **All focus time is recorded** (planned + every continued minute — the overflow is the best time and counts toward stats and stamina). Boring Break happens when the user finally ends.
- **OFF (fixed block):** planned time completes → chime → session ends on its own. **Records exactly the planned length.** Then flows into Recovery.
- An **abandoned** block (left / protect-the-block broken before completion) is **not** recorded as a completed session (tracked separately for the user's own honesty, not counted as focus time).
- Applies to Flow Block / Custom modes. Pomodoro keeps its own work/break cadence.

## 7. Focus Stamina (v1 — simple)

- Track a rolling **sustainable block length** derived from recent completed sessions.
- After successful blocks, gently **suggest a slightly longer next block** (progressive overload toward the ~90-min ideal) — never forced.
- Surface it as a simple, encouraging "your focus is growing" indicator (not a heavy dashboard — that's P2).
- Stored as a single current value in settings + derivable history from the sessions table.

## 8. Hourglass art direction (intent now, pixels later)

**The bar:** better than any hourglass animation currently online — minimalist and premium, never cheap or generic.

**The intent:** a **fluid-like body** in the top chamber that, as it falls, **breaks into a fine spray of tiny particles** like sand; the bottom chamber fills. The sand level **is** the progress indicator. AMOLED-true blacks, soft grain texture, a refraction highlight, gentle ambient shimmer.

**Technical approach:** a `CustomPainter` draws the glass (vector) + chamber fills driven by session progress; the neck stream is a **lightweight particle effect** (a few dozen grains / a fluid-to-grain spray), **not** a cellular-automata physics simulation. Must stay smooth on mid-range Android. Driven by an `AnimationController` synced to elapsed time; survives pause/resume.

**Decision deferred to a prototyping step during P1 build:** try several styles (fluid-to-grain spray, particle density, color, glow) side by side and pick the default. We decide *the bar* now, the *pixels* then.

**Skins are data** (glass shape, sand color, palette) from day one so the P2 collectible library is just more rows.

## 9. Architecture (Flutter — feature-first + clean layers)

- **Presentation** — screens/widgets; state via Riverpod.
- **Domain** — pure Dart, no Flutter imports, fully testable: the phase-engine state machine, stamina logic, session rules.
- **Data** — Drift repositories, settings, audio.
- **Services** — `TimerService` (phase engine + ticking), `AudioService` (just_audio, gapless loops), `LifecycleService` (detects backgrounding for protect-the-block), `HourglassPainter` (the visual), `ShareCardService` (renders a widget to image).

Built so P2–P4 (skins library, premium, sync) slot in without rework.

## 10. Data model (Drift / local-only in v1)

- **sessions** — id, startedAt, mode (flowBlock/pomodoro/custom), intention (text), plannedSec, actualFocusSec, completed (bool), abandoned (bool), autoContinue (bool), soundscape, skinId.
- **settings** — boringBreak on/off, protectBlock on/off, autoContinue default, theme, default mode/soundscape, current Focus Stamina value.
- Streak, daily/weekly focus time, sessions completed, and stamina history are **derived** from `sessions` via queries — `sessions` is the single source of truth.

## 11. Non-functional requirements

- **Offline-first:** all v1 features work with no network; data is local.
- **Performance:** smooth (target 60fps) hourglass on mid-range Android; lightweight particle budget.
- **Calm by default:** minimal chrome, no anxiety-inducing countdown numbers unless requested.
- **Battery/lifecycle:** sessions survive pause/resume and app backgrounding (within the protect-the-block rules).
- **Privacy:** v1 stores nothing off-device except anonymous analytics/crash data.

## 12. Open items (not blockers for v1 build)

1. **Final brand name + method name** — "Hourglass" is a working title (hard to own/trademark/rank for). Lock a more ownable brand name and finalize the method name ("The Flow Block") before launch.
2. **Hourglass visual style** — prototyping step during P1 build (§8).
3. **Soundscape sourcing** — record/license the signature sand sound + 3–4 high-quality loops.
4. **Exact Struggle-phase duration / proportion** and copy tone — tune during build.

---

*This spec defines v1 only. P2–P4 are directional and will get their own spec → plan → implementation cycles.*
