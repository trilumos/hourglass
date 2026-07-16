# Sustain — Feature Roadmap & Version Checklist

> Single source of truth for **what ships in v1**, **what's v1.2**, and **what's v2** — and the home
> for all future planning. If a future idea lives in a design spec, give it a one-line entry here and
> link the spec, so plans stop being scattered.
> Created 2026-06-22 (founder request) so we're clear after publish on where to pick up.
> Pairs with `docs/v1-launch-checklist.md` (the pre-publish store/security/legal audit) and
> the version split in `docs/project-context.md` (Roadmap, LOCKED 2026-06-17).
> **See [`docs/README.md`](README.md) for the full documentation map** (which spec is current vs
> shipped vs future). Detailed future research lives in `docs/superpowers/specs/future/`.

---

## V1 — shipping to the Play Store

### Done & locked
- [x] **Core focus engine** — Flow Block, Pomodoro, Custom modes; tap-to-control time; breaks + auto-advance; Flow "Keep going" (re-drain the block) + endless toggle + "run until I end".
- [x] **Focus Score** (0–100 ramp, recent-10 avg, Flow-Block-only) + suggested next Flow length.
- [x] **Focus Stamina** (personalized length) + **Focus Average** — both **Pro**.
- [x] **Home** — greeting, hourglass hero (ambient idle fall), stat row (Focus · Avg · Today · Streak), Begin, mode selector.
- [x] **Setup / Intention** — duration-first, all three modes, soundscape slot (sound deferred — see v1.2).
- [x] **Session screen** — hourglass focus, milestone rewards, break advance, completion.
- [x] **Onboarding** — 5-screen first-run (4 teach beats + name/photo profile), gate + migration guard.
- [x] **Profile / Account + DB** — Drift, `uuid`/`updatedAt` schema (sync-ready for v2).
- [x] **Insights** — merged Activity+Analytics: lifetime Records, consistency heatmap, focus-over-time, when-you-focus (time-of-day + weekday), by-mode donut; warm explanatory copy; interactive charts.
- [x] **Color Themes** — Sand (free) + premium themes (Aurora flagship); à-la-carte (`theme.<id>`) or bundled in Pro; live whole-app preview.
- [x] **Monetization** — entitlement engine (RevenueCat + Play Billing), Pro tiers (Yearly → Monthly → Lifetime), paywall, `ProGate`; à-la-carte themes; **no theme cart** (Pro Lifetime = own-all bundle).
- [x] **Data safety** — manual backup/restore (versioned JSON, merge by uuid) + export split (CSV history, PDF Focus Report on Insights).
- [x] **Strict sessions** (anti-pause-abuse) — leaving (running or paused) ends the block after a grace; free = 3 pauses/3-min cap, Pro = unlimited/10-min cap; pure `StrictRules`.
- [x] **Notification system** — opt-in engagement (focus reminder / daily quote / streak nudge, default OFF) + in-session foreground-service live notification + **sounding grace pushes** (pause cap, 15s grace, 30s leave grace, block-ended) from the main isolate via exact alarms + **streak 1-day grace** + exact per-session duration. **Session bell sounds done.**
- [x] **Guide** — "How it works" / Sustain 101 chapter guide.
- [x] **Privacy** — zero third-party analytics/telemetry in v1.

### Remaining before publish — ✅ v1 is PUBLISHED (verified 2026-07-11)
- [x] **Pomodoro / Custom "continue"** — SHIPPED (verified in code: `SessionController.repeatPlan`/`addBlock`/`extendNow` + session-screen UI at completion and near-end nudge, Pro-gated via `allowContinue`).
- [x] **Launch hardening** — DONE (founder confirmed; real release keystore in place — `android/key.properties`).
- [ ] **At publish: snapshot the v1 code** into a frozen folder for live hotfixes (see *Release process* below).

---

## V1.2 — first post-launch update

- [ ] **Background soundscapes** — ambient session audio (sand, water, etc.) during focus; picker in Setup/Settings; free-vs-Pro split (à-la-carte like themes). *Signature "sand" loop is the hard sourcing problem (royalty-free / CC0 + CREDITS.md). Deferred from v1 (founder, 2026-06-22).*
- [ ] **Focus currency + optional rewarded ads** — earn currency per completed session (scaled by completion); spend on themes/cosmetics; **user-initiated** rewarded ads (Forest-style, never auto-played) to save a streak/session or top up. Keeps Pro as "unlock everything". (Founder: V1.2.) *Full design + the brand tension (we currently promise "no ads") + competitor study (Regain/Forest/Opal): [`specs/future/2026-06-24-future-versions-research.md`](superpowers/specs/future/2026-06-24-future-versions-research.md). Decide ads vs coins-only before building.*
- [ ] **Native MediaStyle notification** — the "Spotify-shaped" larger branded session notification (big hourglass artwork + colorized background + round controls). Needs Kotlin MediaSession + MediaStyle (~1 focused day + device testing). Parked from the rich-standard pass (founder, 2026-06-22).
- [ ] **Sand-fall origin realism** (polish) — sand originates from a natural converging neck/aperture with a believable funnel/pile-collapse, not a flat line. Touches the locked hourglass painter — confirm before changing the locked look.

---

## V2 — built post-launch, shipped as traction grows

- [ ] **Level / Progression system** — Focus Score → 100 = collectible hourglass + share card + theme unlock + reset + harder next level; collection + level history on Profile. (+ progressive difficulty, streak effects pulling score down, honesty/anti-idle checks.)
- [ ] **Cloud auth + sync** — Google Sign-In + backup/sync (schema already sync-ready).
- [ ] **Home-screen widgets.**
- [ ] **Break-time activities** — sudoku, meditation, breathing, light exercise.
- [ ] **Spotify connect** — focus music during sessions.
- [ ] **Focus Wrapped** — Spotify-Wrapped-style personalized recap (yearly/seasonal): top stats, milestones, hours focused, streaks, share cards. *Brainstorm later.*
- [ ] **Notes / journal** — in-app per-session reflections.
- [ ] **Picture-in-Picture mini-session** — Home-button keeps the session live in a floating hourglass window.
- [ ] **PC / web versions** with real site/app blocking + monitoring (the actual work-verification) + an allow-list of permitted apps (Pro pillar).

---

## Adjacent product — Sustain Web (separate ecosystem)

- 🟡 **Sustain Web** — the website timer: marketing funnel + feature playground + its own paywall.
  **Completely separate accounts/billing from the app (no cross-sync, ever).** Design LOCKED 2026-07-11 →
  spec: [`superpowers/specs/2026-07-11-sustain-web-design.md`](superpowers/specs/2026-07-11-sustain-web-design.md).
  Ship complete in one launch (~a month); Web Plus $3.99/mo · $23.99/yr · $49.99 lifetime.

---

## Release process — v1 hotfix vs v1.2 development

At v1 publish, **snapshot the entire published codebase into a separate frozen folder** (e.g. a sibling
`hourglass-v1-live/`). That folder is the live Play Store build:
- Post-launch **minor errors/faults** → fix directly in the snapshot folder, rebuild, and push the patch to
  the Play Store (a v1.0.x update) — keeping the live app healthy.
- The **main repo continues as v1.2** development, undisturbed by hotfixes.
- Periodically reconcile: fold any v1 hotfixes into the v1.2 main line so they aren't lost.

*(Git alternative if preferred later: a `v1.0` release branch/tag instead of a folder copy — same intent,
cleaner history. Folder copy chosen by founder for direct, simple patching.)*
