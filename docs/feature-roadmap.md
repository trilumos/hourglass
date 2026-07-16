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

### ✅ v1 is PUBLISHED — live on Play (verified 2026-07-11; Product Hunt launch 2026-07-17)

`pubspec.yaml` = **1.0.0+5**. The pre-publish audit ([`v1-launch-checklist.md`](v1-launch-checklist.md))
is **complete and historical** — keep it as the record of what was gated, not as a todo list.

- [x] **Pomodoro / Custom "continue"** — SHIPPED (verified in code: `SessionController.repeatPlan`/`addBlock`/`extendNow` + session-screen UI at completion and near-end nudge, Pro-gated via `allowContinue`).
- [x] **Launch hardening** — DONE (founder confirmed; real release keystore in place — `android/key.properties`).
- [ ] **🚩 Snapshot the published v1 — STILL OUTSTANDING, and it's a live risk.** The app is live and
  **no tag or snapshot exists**, so there is no record in this repo of which commit is on Play — a hotfix
  today would ship whatever is in `master`. Note `9474281 "backup"` touched `lib/`/`android/` **after** the
  `1.0.0+5` bump in `25f1b98`, so `master` may not equal the shipped build. **Only the founder knows which
  commit was built.** Resolution: a `v1.0.0+5` **git tag** on that commit (the *Release process* section
  below already offers this as the cleaner alternative to a folder copy — and it's free, since we push to
  GitHub anyway).

### Business status (2026-07-17)
- **Zero Pro buyers so far.** This is a *window*, not a permanent state — see the platform-strategy spec
  §6.5 for the live paywall-copy problem it lets us fix cleanly.

---

> **⚠️ Restructured 2026-07-17.** The version split below was re-cut by the platform-strategy brainstorm.
> **Canonical source for scope, phases, brand and money across BOTH products:**
> [`superpowers/specs/2026-07-17-sustain-platform-strategy-design.md`](superpowers/specs/2026-07-17-sustain-platform-strategy-design.md).
> It supersedes the 07-11 web spec and **reverses** its "separate ecosystems, no sync ever" decision.

## V1.2 — the polish release *(small, ships fast)*

- [ ] **Background soundscapes** — ambient session audio (sand, water, etc.) during focus; picker in Setup/Settings; free-vs-Pro split (à-la-carte like themes). *Signature "sand" loop is the hard sourcing problem (royalty-free / CC0 + CREDITS.md). Deferred from v1 (founder, 2026-06-22).* **BLOCKED on founder sourcing audio.**
- [ ] **Native MediaStyle notification** — the "Spotify-shaped" larger branded session notification (big hourglass artwork + colorized background + round controls). Needs Kotlin MediaSession + MediaStyle (~1 focused day + device testing). Parked from the rich-standard pass (founder, 2026-06-22).
- [ ] **Sand-fall origin realism** (polish) — sand originates from a natural converging neck/aperture with a believable funnel/pile-collapse, not a flat line. Touches the locked hourglass painter — confirm before changing the locked look.

---

## V1.3 — the big one *(the recurring engine)*

- [ ] **Cloud Sync** — Firebase auth + sync (schema already sync-ready; `backup_service.dart` already merges by uuid). **One Firebase project shared with web.** Requires privacy-policy + Play Data Safety updates.
- [ ] **🏺 Sediment** — every completed session lays a layer in a vessel you keep forever (thickness = duration, colour = theme, texture = focus score). Replaces Levels; absorbs Insights visualization and the share card. *The centrepiece — see the platform-strategy spec §7.*
- [ ] **Intention** — one line before you flip, recorded with the stratum. *Absorbs the old Notes/journal item.*
- [ ] **♻️ Sustain Sync** billing — ~$2.99/mo · ~$19.99/yr. **No lifetime Sync, ever.** Existing Pro Lifetime holders get it free forever.

> **Why v1.2 and v1.3 split:** v1.2's soundscapes are blocked on an *asset-sourcing* action, MediaStyle and
> sand realism are days, and Cloud+Sediment is weeks. Two shippable releases beat one stalled one.

---

## V2 — built post-launch, shipped as traction grows

- [ ] **Home-screen widgets.**
- [ ] **Picture-in-Picture mini-session** — Home-button keeps the session live in a floating hourglass window.
- [ ] **Focus Wrapped** — built as **a view of your sediment**, not a separate system.

---

## ❌ CUT (founder-approved, 2026-07-17)

Removed from the roadmap by the platform-strategy brainstorm. Rationale in the spec §11.

- ~~**Focus currency + optional rewarded ads**~~ — contradicts "no ads, ever"; at current volume earns pennies while costing the brand position that makes people trust us.
- ~~**Level / Progression system**~~ — Sediment *is* the progression, natively. Levels unlocking cosmetics gives away what we sell.
- ~~**Spotify connect**~~ — requires the user to hold Spotify Premium; real OAuth/API cost for what our own soundscapes serve.
- ~~**Break-time activities**~~ (sudoku, meditation, breathing) — a second app bolted inside the app.
- ~~**Leaderboard**~~ — client-computed scores are user-editable; also a pure anxiety mechanic. Replaced by **The Collective** (web).
- ~~**Browser extension**~~ — Document PiP already gives a floating always-on-top hourglass from the web page.
- ⏸ **PC / web with site/app blocking + monitoring** — **deferred, not cut.** A separate product with its own store review, permissions story, and maintenance.

---

## Adjacent product — Sustain Web (funnel first, money later)

- 🟢 **Sustain Web** — phased, **free at launch**. One Firebase project + one account + one dataset shared
  with the app; **separate purchases** (the Forest model). Design LOCKED 2026-07-17 →
  [`superpowers/specs/2026-07-17-sustain-platform-strategy-design.md`](superpowers/specs/2026-07-17-sustain-platform-strategy-design.md).
  - **W1 — the funnel** *(next, ~1 month, FREE)*: landing page (persistent-hourglass scroll), timer + all modes, ported 2.5D hourglass, colours + circadian, basic soundscapes, PiP · share links · embed · `/stage`, local "focused today", SEO. Zero billing code — its jobs are **rank** and **convert to install**.
  - **W2 — the scenic engine** *(after app Sync)*: depth-map photoreal dioramas, 3D glass hourglass, weather modules, custom background upload, full mixer, rare moments, accounts, Sediment on web. Money turns on (à-la-carte cosmetics + lifetime bundle).
  - **W3 — social**: The Collective, Focus room.

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
