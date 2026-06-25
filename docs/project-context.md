# Hourglass — Project Context & Memory

> Durable context for this project. Kept **in the project folder** (per founder preference — never in the C-drive `.claude` user folder).
>
> **Navigation:** [`docs/README.md`](README.md) is the documentation map (which spec is shipped vs
> future vs superseded). **Future planning is consolidated in [`feature-roadmap.md`](feature-roadmap.md)**
> — that is the canonical "what's next" list. The **"Open follow-ups"** and **"Roadmap"** sections
> lower in *this* file are a historical record: several items there are now **shipped** (onboarding,
> monetization, themes, data backup, notifications, Pomodoro/Custom continue) — trust the roadmap +
> the code for current status. The **locked decisions / confirmed rules** sections remain
> authoritative. (The app is now named **Sustain**; "Hourglass" survives only as the visual motif and
> some old filenames.)

## Founder / working preferences
- Solo founder, hopes Hourglass becomes a real company and full-time income ("big break").
- Self-describes as **non-technical** — wants me to lead with expertise and recommend a clear default rather than hand over abstract option lists. Present concrete, pre-filtered choices.
- Develops on **Windows**; Android dev/build works there. iOS deferred until a Mac + Apple dev account are affordable from revenue.
- Bootstrapping — prefers **free tools** until there's traction. Values honesty/integrity (no overclaiming) as part of the brand.
- **Save all project context/memory inside this project folder**, not in `C:\Users\...\.claude\...`.

## Repo & git workflow (founder, standing)
- **GitHub remote:** `origin` → `https://github.com/trilumos/hourglass.git` (branch `master`). Auth via Git Credential Manager (already authenticated on this machine).
- **STANDING RULE: whenever something is "locked" / approved by the founder, commit it and `git push origin master`.** Keep the remote current with locked work. (Founder requested this 2026-06-15 after locking the hourglass visual.)

## Design mandate (founder, standing) — premium / buttery-smooth / no-friction
Every screen must feel **premium, minimal, flow-state, and buttery-smooth** — no nonsense, no friction, no clutter. Motion is a feature: soft transitions, ~60fps verified on device, isolated repaints. The founder expects to **iterate the UI heavily** (color palette, button shapes, positions) — so ALL styling must flow from **centralized design tokens** (one theme file: colors, typography, spacing, shape, motion) and never be hardcoded per-screen, making restyles cheap. When building UI, lean on the `frontend-design` / `impeccable` skills for quality. **Why:** the aesthetic-study audience shares beautiful tools; craft IS the moat. **How to apply:** tokens-first, reusable restyleable widgets, verify smoothness on a real device, default to calm/minimal over feature-dense.

## What Hourglass is
A study/focus app positioned as **focus training** ("Train your focus like an athlete, recover like one too"), NOT "a prettier timer." Core invented method: **The Flow Block**, grounded in Flow Research Collective science (Rian Doris / Steven Kotler).

A session runs **Set intention → Flip → Struggle → Flow → Recovery**. Signature differentiators: surfacing the **Struggle phase** as expected/temporary, and a **phone-free "Boring Break"** (active recovery). **Focus Stamina** grows the user's sustainable block length toward the ~90-min ideal. Pomodoro/custom timers are on-ramps.

## Locked decisions
- **Flutter + Dart**; **Android first** (Play Store, founder has Google dev account); iOS later, revenue-funded.
- Stack: Riverpod, Drift (SQLite), just_audio. Pre-chosen for later: RevenueCat (P2), Firebase Auth/Firestore (P3).
- **NO Firebase Analytics/Crashlytics in v1 (founder, 2026-06-18, LOCKED).** Ships with zero third-party analytics/telemetry for the cleanest privacy story (no data collected → nothing to leak, no consent/GDPR burden). Revisit post-launch only if genuinely needed. (Supersedes the earlier "Firebase Analytics/Crashlytics" stack pick.) One of the 3 launch decisions — **settled**.
- Royalty-free soundscapes for now.
- **Brand / app name = "Sustain" (founder, 2026-06-18, LOCKED).** Replaces the generic working title "Hourglass" (saturated + un-trademarkable — confirmed: many "Hourglass" timer apps incl. a near-identical "Hour Glass: Focus & Timer"). Meaning: *"sustain your focus, stay in flow."* Clean in the focus-app space, accessible, and **dual-tongue safe** (no bad Hindi/Gujarati meaning). Chosen after a long search — Kairos/Telos (taken: Telos Focus&Habit app), Drishti (too hard for Western tongue), Mettle (taken: men's-focus app), Tenax (registered TM incl. India + Tenax AI/CRM apps), Sisu (≈ "su-su"/pee in Hindi — childish), Dheer (≈ "kheer" rhyme) all rejected. **One of the 3 launch decisions — settled.** ("Hourglass" stays only as the **visual/icon motif**, not the name.)
  - **Signature tagline = "Train your focus like an athlete." (founder, 2026-06-18, LOCKED.)** Stays as the tagline / positioning line wherever the brand appears (store, onboarding promise screen, site). Store framing: **"Sustain — Train your focus like an athlete."** ("Stay in flow" / "Focus & Flow" are secondary copy, not the primary line. Avoid baking "Focus/Flow" into the name itself — `SustainFlow`/`SustainFocus` are taken + lean ESG.)
  - **NAMING RULE (founder, 2026-06-18):** screen every candidate name against **Hindi & Gujarati** (the founder's tongues) for childish / food / negative connotations, not just English. The founder is the final judge of tongue-feel. The founder considers store-name duplication a non-issue; trademark + a domain (e.g. `sustain.app`) are the parts worth protecting later.
  - **Rename = folded into the Onboarding build (spec locked 2026-06-18):** swap display name + wordmark + store listing + in-app "Hourglass" strings (home wordmark, Settings "Hourglass 1.0.0", etc.) → "Sustain". Keep the `lib/hourglass/` painter + class names + the `hourglass.sqlite` DB filename (visual motif + no data breakage).
  - **Package id CHANGED → `com.trilumos.sustain` (founder, 2026-06-18, LOCKED — supersedes "keep `com.trilumos.hourglass`").** Done pre-launch (the only clean window; applicationId is permanent after first publish). Founder accepts the test-device data won't migrate (test-only). Touches `build.gradle.kts` (namespace + applicationId), `MainActivity.kt` (move package dir + `package` line), iOS `project.pbxproj` bundle ids. No Firebase/google-services/deep-link/Dart coupling to the id. Uninstall old `com.trilumos.hourglass` from the test device to avoid a duplicate icon.
- **Technique name = "Flow Block" → user-facing "Flow" (founder, 2026-06-18, LOCKED — supersedes the "Flow Block" label).** All USER-FACING "Flow Block" text becomes **"Flow"** (mode-selector chip "Flow" beside Pomodoro/Custom; prose "Flow" / "Flow sessions"; the unit stays lowercase "block", e.g. "your first block"; Focus Score = "last 10 Flow sessions"). **Code identifiers stay `SessionMode.flowBlock`/`SessionPlan.flowBlock`** (internal only). Folded into the Onboarding build. (The earlier "Flowmodoro" analysis still stands — do NOT use Flowmodoro: it's a generic term used by live competing apps, un-trademarkable, and tethers the brand to Pomodoro.)
- **Onboarding (V1 item #3) = LOCKED 2026-06-18.** Spec: `docs/superpowers/specs/2026-06-16-onboarding-screen-design.md`. First-run only, skippable, offline. **5 screens:** 4 teaching beats (philosophy → Flow/struggle/flow-state → phone-free recovery → Focus Score + "Pomodoro/Custom are training wheels, Flow is the moat" + pointer to Settings → How it works) + 1 **profile screen** that captures **name + optional photo** (reuses the existing crop-avatar flow). Gated on a new `onboardingComplete` settings bool; a **migration guard** silently skips onboarding for any install that already has sessions or a profile name. **Overrides the research's "defer name / ask block length"** — onboarding IS profile generation (name + photo), and does NOT ask block length. Guide page retitled **"How it works"** (was "How Hourglass works"; "How Sustain works" reads awkwardly since *sustain* is a verb).
- Hourglass visual = fluid-to-fine-particle spray, minimalist/premium, lightweight (no grain physics in v1); exact style prototyped during build.

## Honesty constraints (baked into the product)
- Don't claim Doris/Kotler attack Pomodoro by name (no such quote). The "4% rule" and "500% productivity" figures are heuristics, not lab constants. The beginner stamina ramp is our approach, not an FRC claim.

## Key documents
- **Design Language (LOOK/FEEL SOURCE OF TRUTH): `docs/design-language.md`** — our own branded style ("Warm Precision"): semantic color tokens (Sand light+dark), themes×modes model, Fraunces+Inter type system, spacing/radius/motion, voice & greeting personality, anti-patterns, and the Flutter token architecture (ThemeExtension). All screens build to this. Synthesized 2026-06-15 from category + Vercel/Geist + theming research.
- Design spec: `docs/superpowers/specs/2026-06-11-hourglass-flow-block-app-design.md`
- Plan 1 (Foundation & Core Domain): `docs/superpowers/plans/2026-06-11-hourglass-v1-foundation.md`
- Roadmap: v1 "The Ritual" (P1) → P2 money/skins/stats → P3 ecosystem (sync/widgets/mixer) → P4 best-in-class (social, physics-grade sand).

## Status (2026-06-15)
Design approved. v1 split into 3 plans: **P1 Foundation — DONE & reviewed SHIP-READY** (30 tests pass); **P2 Session UI & Hourglass — IN PROGRESS** (foundation tasks done; hourglass visual DONE & LOCKED; screens not yet built); P3 Stickiness & Share. See "Continuation" section at the bottom for exactly where to pick up.

Foundation built (subagent-driven, two-stage reviews): pure-Dart domain (`lib/domain/`: enums, PhaseEngine, computeRecordedFocus, SessionRecord, StaminaCalculator, StatsCalculator) + Drift data layer (`lib/data/`: AppDatabase with Sessions/Settings tables using `storeDateTimeAsText: true`, SessionRepository, SettingsRepository). Engineering mandate from founder: act as senior engineer, leave no bugs or security/privacy/legal holes; security work scales by phase (real rigor lands at P2 payments / P3 sync).

## Accounts decision (2026-06-13) — LOCKED
v1 is **offline-first, no accounts, no cloud**. All data on-device. Rationale: fastest to ship, zero backend cost, and — per founder's data-leak/legal concern — the best way to never leak user data is to never collect it (no privacy policy / GDPR / breach liability burden for a solo non-technical founder). **Optional Google Sign-In + cloud backup/sync is the HEADLINE of Plan 3 (P3)** — offered as an opt-in benefit ("sign in to back up & sync across devices"), never a gate. Architecture already supports this (clean local repos; Firestore pre-chosen). Founder chose this over "accounts now" and "offline + local export."

## First-open user flow (offline v1) — the canonical UX
1. **Splash** (1–2s, branded — hourglass forms/sand settles). *(Plan 3)*
2. **Onboarding — 3 calm skippable screens, first run only** *(Plan 3)*: the promise ("Train your focus like an athlete"), the method (Struggle→Flow→Recovery, "focus grows over time"), the twist (phone-free Boring Break). Ends "Begin your first block." No email/account/permission nags.
3. First-run **defaults set locally**: dark/AMOLED, Boring Break on, protect-the-block on, auto-continue off, classic skin, sand soundscape.
4. **Home** (every open): hourglass at rest, single "Begin", today 0m, streak 0, mode selector; one-time hint "Flip to start your first Flow Block."
5. **Set intention** → starter suggestion 25 min (no history yet) → pick soundscape.
6. **Flip** → full/quiet → **Struggle** line → fades → **Flow** (sand+sound; protect-the-block if they leave).
7. **Completion**: chime → "25 minutes focused" → streak→1, session logged, next suggestion 30 min.
8. *(Plan 3)* **Boring Break/Recovery** → then another block or done; *(Plan 3)* optional **share card**.
9. **Return**: opens skip onboarding → Home shows totals/streak, suggests slightly longer block; over time streak + suggested length grow (hourglass "grows" with them). All on-device, instant, no login until P3 opt-in.

Note: v1 needs **no special permissions** (sessions run foreground; protect-the-block requires foreground anyway). Keeps the privacy story clean.

## Carry-forward into Plan 2 (from final review — DO NOT lose these)
- **Android release signing:** `android/app/build.gradle.kts` still signs release with the DEBUG keystore (scaffold default). Must create a real keystore + `android/key.properties` (gitignored) before any Play release.
- **`android:allowBackup="false"`** (or backup rules) in AndroidManifest — the focus-history SQLite is privacy data; default auto-backup should be disabled for a privacy-first app.
- **DB lifecycle:** wire `AppDatabase.open()` to a Riverpod provider that calls `db.close()` on dispose.
- **Android toolchain setup needed before building APK:** accept licenses (`flutter doctor --android-licenses`), set up an emulator/device. (Flutter SDK lives at `D:\Dev\tools\flutter`.)
- Already handled defensively in P1: stats ignore `abandoned` even if `completed` (guard test added); `.gitignore` excludes keystores/`google-services.json`/`GoogleService-Info.plist`/`.env`/etc.; `getInt` hardened against malformed values.
- **Hourglass visual = prototyping step** at the start of P2 (try fluid-to-particle styles, pick default). Keep it lightweight (no grain physics in v1). — ✅ DONE & LOCKED (see below).

---

## Roadmap — V1 ship plan + V2 (LOCKED 2026-06-17)
> Founder confirmed this sequence 2026-06-17. Supersedes the older roadmap ordering in handoffs.

**V1 (ship to Play Store):**
1. **Profile / Account + DB** (foundation) ✅ — spec: `docs/superpowers/specs/2026-06-17-hourglass-profile-account-db-design.md`.
2. **Analytics** ✅ **LOCKED 2026-06-18 (shipped as the "Insights" page; founder reviewed on-device & approved)** — spec `docs/superpowers/specs/2026-06-18-hourglass-insights-analytics-design.md`, plan `docs/superpowers/plans/2026-06-18-hourglass-insights-analytics.md`. **DECISION (founder, locked):** Activity + Analytics were **merged into ONE page** ("Insights") — same data, one destination. Order: lifetime Records → Consistency heatmap → Week/Month/All toggle → Focus-over-time → When-you-focus (time-of-day + day-of-week) → By-mode donut. Pure `AnalyticsCalculator` (TDD) + `analyticsProvider`/`analyticsRangeProvider`; charts via **fl_chart** (token-driven). `ActivityScreen` deleted; Profile shows one "Insights" row.
   - **Warm explanatory copy** (founder-requested): each section has a plain-language descriptor + a personalized insight line from real data (peak time of day, strongest weekday, go-to mode, days active). Voice per design-language §6 (warm, no emoji). `lib/ui/insights_copy.dart` (pure, tested).
   - **Interactive + rich upgrades** (founder-requested "more interactive/user-friendly/rich"): tappable bars w/ on-brand readout line (`BarReadoutChart`, replaced `FocusTrendChart`/`RhythmBars`); period comparison line (`+18% vs last week`, `previousWindowTotal`); donut center = period total + tappable segments; Records hero pair (Total focus + Current streak large) over a secondary grid (`StatTile.large`).
   - Also this session: Settings version tag → absolute bottom; **Profile scrolls only when content overflows** (LayoutBuilder + ConstrainedBox(minHeight) + Column(stretch) — responsive to large font/zoom). **147 tests green, analyze clean, pushed (e43879a).** New dep: `fl_chart`.
3. **Onboarding** ✅ **DONE & LOCKED 2026-06-19 (founder reviewed on-device).** 5-screen first-run (4 teach beats + name/photo profile), `onboardingComplete` gate + migration guard, hero drains 10%→50% per page then drains-to-100% + flips into Home; buttery transitions. Folded in: Hourglass→**Sustain** + Flow Block→**"Flow"** user-facing renames, guide retitled **"How it works"**, package id → **`com.trilumos.sustain`** (pre-launch). Spec/plan in `docs/superpowers/{specs,plans}/2026-06-{16,18}-*onboarding*`.
   - **Also locked this session (founder, 2026-06-19):** (a) **Sub-2-min Flow records NOTHING** (no streak/Today/history/score) — keep-rule centralized in `SessionFinalizer.persist` (returns null below threshold); **Pomodoro/Custom still record any focus >0s**. Completion screen shows a note when a Flow end is <2 min. (b) **Average-focus metric** (mean focused time per session, **all modes**) shown on Home stat row (Focus·Avg·Today·Streak) + Insights Records + explained in guide + onboarding. (c) **Home hourglass = ambient idle fall** (continuous fall, full top, NO bottom pile) behind a gated `ambient` flag — other screens unchanged. (d) **Hourglass sand now funnels to the central aperture** (no flat line at the neck; stays above the neck).
4. **Some Themes** (theme system + a few themes).
5. **Monetization** — brainstorm + decide what's paid (calm / no dark patterns).
→ **Ship V1 to the Play Store.**

**No Level/Progression system in V1.** Profile shows real working stats now; Levels + collection land in V2.

**V2 (built post-launch, shipped as traction grows):**
- **Level / Progression system** (+ themes; score→100 = collectible + share card + theme unlock + reset + harder; resolve ramp-vs-reset math).
- **Cloud auth + sync** (Google Sign-In + backup/sync; `uuid`/`updatedAt` schema already sync-ready; free tier confirmed sufficient at launch scale — see the Profile/DB spec's cost review).
- **More monetization**, **home-screen widgets**, and **break-time activities** (sudoku, meditation, exercise, breathing exercises).
- **Spotify connect** (focus music during sessions) and a **notes / journal** feature (in-app journaling, e.g. per-session reflections) — both V2 (founder, 2026-06-19; tiers TBD, lean Plus for Spotify / Pro for journal). Full monetization model + feature→tier→release map lives in `docs/superpowers/specs/2026-06-19-monetization-and-v1-paid-tier-design.md`.
- **Picture-in-Picture mini-session (V2; founder, 2026-06-19):** pressing the phone's Home button during a live session keeps the session running and shows the falling hourglass in a floating mini-window (PiP) so the user sees progress while in another app. Feasibility: Android supports a custom PiP view (PiP Activity + platform channel, or a plugin) — straightforward on Android; iOS PiP is video-only so it needs a workaround (e.g. render the hourglass to a video layer) or may be Android-first. Tier TBD (lean free, it's core-loop UX). Must keep the wakelock + session-state persistence already in place.
- **Focus currency + optional rewarded ads (V1.2 idea; founder, 2026-06-20):** earn an in-app
  "focus currency" per completed session, scaled by completion rate; spend it to unlock themes (alongside the
  cash à-la-carte path) and other cosmetics. Plus **optional, user-initiated** rewarded ads (Forest-style:
  never auto-played) to **save a streak / save a session** or top up currency. Strong fit — rewards the core
  behavior (focusing), gives non-payers a path to themes (boosts engagement + theme attach), and adds
  non-coercive ad revenue that matches Sustain's calm/no-dark-patterns ethos. Tradeoffs to design: currency
  economy + balancing so it doesn't cannibalize Pro/à-la-carte; AdMob (or similar) SDK adds Play Data-Safety +
  privacy disclosures; themes become earnable not just purchasable (revenue-model impact). Keep Pro as the
  "unlock everything + analytics" tier. Target V1.2 (founder said add it then if it's a good idea — it is).
- **Focus Stamina + Focus Average are PRO everywhere (founder, 2026-06-20, CONFIRMED + implemented).** Free
  tier: Focus Score, Today, Streak, sessions, themes (Sand + à-la-carte), consistency heatmap, and a plain
  default Flow length. Pro unlocks: the **personalized Stamina length** + Stamina chip in Flow setup, the
  **Avg** stat on Home, the **Avg session** record in Insights, and the Insights depth-band analytics.
  Implementation: Home `_StatRow` hides Avg when not pro; `setup_screen` gates the stamina chip/personalization
  on `entitlementsProvider.pro` (free → `_defaultFlowMin`, no chip); Insights RECORDS "Avg session" tile shows
  a Pro upsell (tap → paywall) when free. **Why:** strengthens the Pro value prop; keeps a healthy free tier;
  fixes the prior leak (free users got a personalized stamina length while stamina analytics were Pro).
- **NO theme cart — Pro Lifetime IS the "pay once, own all" bundle (founder, 2026-06-20, CONFIRMED).**
  Google Play Billing charges ONE fixed-price product per transaction (digital IAP must use Play Billing; no
  dynamic-sum/multi-item checkout), so a cart that sums arbitrary themes into one charge is impossible. Decided
  against a cart and against per-theme bundle SKUs. Instead: single theme = à la carte (`purchaseTheme`, one
  payment, that theme); to "own many," push **Pro Lifetime** (one payment → all 8 themes forever + analytics).
  A subtle upsell line on each locked theme sheet says Pro unlocks every theme in one payment. (Production Buy
  already launches the real Google Play checkout; the instant grant is debug-only — no code change needed.)
- Keep adding features; ship V2 when traction is good.
- **Data backup/restore + export split LOCKED (founder, 2026-06-20).** v1 data-loss safety net (full
  cloud sync + auth stays V2). **Manual backup/restore:** `BackupService` exports ALL on-device data as one
  versioned JSON (sessions w/ uuids, settings, profile + avatar base64, theme prefs); restore **MERGES by
  uuid** (never deletes) and is offered via a prominent Settings → "Your data" section (export shares via
  `share_plus`; import picks via `file_selector` — NOT `file_picker`, which pins `win32 ^5` and collides with
  `share_plus`'s `^6`). Onboarding tells the user data is on-device + backable up; the clear-data dialog nudges
  "back up first." **Export split:** raw **CSV** (session history) lives on the **History** screen header;
  **Insights** exports a detailed **PDF Focus Report** (`lib/ui/insights_pdf.dart` + pure tested
  `lib/domain/focus_report.dart`). The PDF is a 14-section, data-scaling narrative report (grows 1pg→5-7pg with
  history; every section gated so nothing renders empty/fabricated; Focus Score/Stamina hidden until real Flow
  data; Stamina + avg session Pro-gated). **Ships fontless** (built-in Helvetica + ASCII-safe text → real bold,
  every glyph renders; `_ascii()` folds InsightsCopy em-dashes/minus at the render edge). Founder said "lock
  this." Future option (not committed): embed a Unicode TTF (Geist) for em-dashes/brand font if desired.
- **Strict sessions (anti-pause-abuse) + paywall featuring LOCKED (founder, 2026-06-22).** Spec:
  `docs/superpowers/specs/2026-06-22-strict-sessions-and-monetization-design.md` (Forest-researched). Closes the
  abuse where you pause → use phone → resume free. **Leaving the app (running OR paused) ends the block** after a
  grace; the prompt is a **local push notification** (`flutter_local_notifications`) because the user is outside
  the app. Numbers: **leave-while-running grace 30s; free = 3 pauses/session, 3-min cap; Pro = unlimited, 10-min
  cap; pause-cap grace 15s** (revealed only at the cap). Free out-of-pauses → quiet Pro nudge (session keeps
  running). Domain stays pure: `StrictRules` (free/Pro) + `SessionController.pauseLimit`/`suspend()`; UI
  orchestrates timers/lifecycle/notifications; preview fully exempt. **Monetization: keep ALL Pro tiers** (pricing
  still LOCKED) but the paywall **features Yearly → Monthly → Lifetime** (Lifetime = premium "own it forever") +
  lists "unlimited, longer pauses". Allow-list of permitted apps = a deferred future Pro pillar. Needed
  Android core-library desugaring + `POST_NOTIFICATIONS`.

## Confirmed rules / decisions (DO NOT break — recheck whenever touching related code)
> **Meta-rule (founder, 2026-06-16):** When the founder confirms something / gives a rule or decision, RECORD it here. Whenever I touch anything related to a recorded rule, RE-READ the rule first. If a new request contradicts a recorded rule, STOP and CONFIRM with the founder before changing it. Never assume — always confirm.

- **Pricing LOCKED — USD-ONLY (founder, 2026-06-25; supersedes the earlier ₹/$ dual tiers).** Standard
  premium theme **$1.99**; **Aurora** flagship **$3.99** (lowered from $4.99 on 2026-06-25); Pro **Monthly
  $4.99**, **Yearly $29.99** (Best value), **Lifetime $59.99** (hero — own every theme forever). Set the
  **USD** price in Play Console and let Play **auto-convert** to local currencies — do NOT hand-set ₹ (or
  other) per-country tiers. Global leads with Yearly; Lifetime is the hero. Prices are NEVER hardcoded
  (fetched live from RevenueCat/Play, shown in the user's local currency) — this is the founder's Play
  Console + RevenueCat setup input. **TODO (founder): update `theme.aurora` to $3.99 in Play Console (the
  app shows the live price).** Full rationale + funnel math in
  `docs/superpowers/specs/2026-06-19-monetization-and-v1-paid-tier-design.md` (Pricing section; ₹ figures
  there are historical). No dark patterns: à-la-carte themes are owned forever; subs say "access while
  subscribed."

- **Motion rule (founder, 2026-06-20, CONFIRMED).** The **session screen** must have NO moving/animated/
  changing elements except the **hourglass** (it is the one intentional motion; protect focus). ELSEWHERE
  (home, themes, settings, insights, onboarding) subtle motion/animation IS allowed — gradients, transitions,
  tasteful living touches — **but only if it stays buttery smooth.** It must never make the app clunky,
  glitchy, or buggy. If a motion can't be guaranteed smooth on the low-RAM device, don't add it. Applies to the
  advanced-theme-styles work (gradients yes; animated/aurora only off the session screen and only if smooth;
  no neumorphism). Validate against this AND the perf/smoothness bar.

- **Optimize, never change functionality (founder, 2026-06-20, CONFIRMED).** When asked to make the app
  faster/smoother/better (perf, transitions, visuals, refactors), the changes must be **behavior-preserving**:
  no feature, flow, logic, or core functionality may change. Only quality improves (const/RepaintBoundary/
  .select/ListView.builder/animation curves/memoization, color palettes, copy). The theme redesign changes
  only hex VALUES, not the theme system. If an "optimization" would alter behavior, STOP and confirm first.
  Validate every such change against this AND [[the iron rule]] before shipping.

- **⚖️ THE IRON RULE (founder, 2026-06-20, CONFIRMED — the standard ALL work is validated against).**
  Division of labor: **the founder owns on-device testing** — visuals, seamlessness, how it looks/feels to
  users. **I own building it properly: no errors, no logic problems, no ignored edge cases, no
  inconsistencies, no foolish mistakes.** No bug or glitch may stay. Everything must be **smooth and working
  end to end** with **no privacy, security, or logical issues anywhere in the workflow.** **Never assume —
  always confirm with the founder first** before deciding anything ambiguous; "build as you see fit" applies
  only to implementation detail, not to scope/UX/product decisions. Every change, before I call it done, is
  validated against this rule. **Why:** the founder verifies the experience; I am accountable for everything
  internal being genuinely correct, so his testing finds a working app, not my mistakes. **How to apply:**
  ship only self-verified work (analyze clean + serial tests green + edges reasoned through + no
  privacy/security/logic gaps); when anything is unclear or assumed, stop and ask. This subsumes and is the
  canonical statement of the "Division of responsibility" rule below.

- **Hourglass falling sand MUST match the bulb sand colour (founder, 2026-06-19, CONFIRMED).** The falling-sand grains and the sand piled in the bulbs are the same material and must **never** look like different colours, in any theme/skin. **Why:** in light theme the grains were a separate deep-caramel value while the pile was a lighter tan, which looked wrong. **How to apply:** `HourglassSkin.grainColor` is a computed getter that returns `sandColor` (not a separate field) so the two can't diverge; any new skin only sets `sandColor`. Don't reintroduce a standalone grain colour. (`lib/hourglass/hourglass_skin.dart`.)
  - **Falling-sand particle look LOCKED (founder, 2026-06-19, APPROVED):** fine, dense spray of small round
    grains (`grainCount = 80`, radius ~0.4–1.0px tapering as they fall) — NOT thick streaks/threads. Any
    apparent choppiness is debug-APK frame drops, not the design (smooth in release). Don't change the
    particle style without founder confirmation. (`lib/hourglass/hourglass_painter.dart`.)

- **Division of responsibility (founder, 2026-06-19, CONFIRMED).** The founder's job is to verify the app
  works **seamlessly** on-device and confirm UX/feel. **I own ALL internal correctness:** code, structure,
  workflows, logic, consistency, edge cases, bugs, glitches, errors — nothing internal is "the founder's to
  catch." Ship only work that is genuinely correct and self-verified (analyze clean + tests green + reasoned
  through edge cases), so his verification finds a working app, not my mistakes. **Quality bar is MAXIMUM** —
  especially anything users see or pay for (e.g. the color themes must be **THE BEST possible**: research-
  backed, premium, tuned on-device; no half-effort). Use the `impeccable` skill for user-facing UI.

- **Device/mobile verification is the FOUNDER's job (founder, 2026-06-18, CONFIRMED).** Do NOT take screenshots, drive the app over adb (`input tap`/`screencap`), or otherwise navigate the phone to "verify" the UI — the founder checks on-device himself and reports back. **Why:** it wastes turns/tokens and he prefers to see and feel the UI personally. **How to apply:** my loop ends at code written + `flutter analyze` clean + `flutter test` green + committed/pushed (+ APK built/installed only if/when he asks). Then hand off and let him review on the device.

- **Pomodoro has TWO entry modes with opposite fixed/flex behavior (founder, 2026-06-16, RESOLVED).**
  - **By blocks** = classic Pomodoro: **block length is fixed** (ratio chips 25/5, 50/10, 52/17, 90/15), the user picks the **count**, and the **total flexes**. Long break every 4th.
  - **By duration** = **flowmodoro / variable blocks**: the user's **focus time is exact and never changes**; the app **splits it into N equal variable-length blocks** (block length = focusTime ÷ N, NOT locked to 25/50) with **auto rests ~5:1** (rest ≈ block ÷ 5). The user picks the focus time + the number of blocks; the total is derived. This eliminates the earlier rounding-bucket confusion (every focus-time change is exact). No fixed ratio chips in this mode. (Builder: `SessionPlan.flowmodoro(totalFocus, blocks)`.)

- **Flow Block "Focus Score" system (founder, 2026-06-16, CONFIRMED).** Flow Block's signature differentiator / reason to be the default.
  - **Focus Score = round( sum of last-10 Flow Block sessionScores ÷ 10 ), range 0–100.** Divisor is ALWAYS 10 → a **ramp** (one perfect early session ≈ 10, not 100; reaches 100 only after ~10 strong sessions), then a rolling recent-10 average. **100 = LEVEL UP** (see revised reward model below). **Flow-Block-only.** A "current ability" number (good sessions raise it, give-ups lower it). Headline on Home. (Suggested next Flow length stays a separate recent-completed-length estimate.)
  - **Per-session points → 0–100 `sessionScore`:** `rawPoints = base(chosen) × completion² + overflow × overflowRate`; `base(L) = L + L²/100` (depth bonus); `completion = min(actual/chosen,1)` squared (partial penalized hard); `overflow` = min past chosen; `overflowRate = (1+chosen/100) × 1.5` (grit reward). Then `sessionScore = clamp(round(rawPoints / base(60) × 100), 0, 100)` (60-min completed = 100 anchor). Counts only if focused ≥ 2 min. Constants (D=100, exp 2, 1.5×, anchor 60) tunable.
  - **Give up** option in-session: ending early → low completion fraction → low points → pulls the average down (the willpower cost). Pushing past → overflow bonus → raises it.
  - **Recording rule CHANGE (supersedes the old "abandoned = 0"):** every Flow Block end — completed, given-up, or app-left/protect-the-block — records the **actual focused length if ≥ 2 min** (else uncounted). This feeds the Focus Score, Today total, and streak. (Pomodoro/Custom keep prior behavior; the score is Flow-only.)
  - **Reward model REVISED 2026-06-16 (founder, CONFIRMED — supersedes the old "1 collectible per completed block"):** collectibles are **milestone** rewards, NOT per-session. A session only earns **points** toward the overall score. When the **overall Focus Score reaches 100 → LEVEL UP:** grant **one hourglass collectible + a share card**, **unlock the next app theme** (some themes kept locked behind levels → "veteran/experienced" progression), **reset score to 0**, next level **harder**. Completion screen (current build) shows **Focus Score (count-up) + points earned this session** — NO per-session "collected" language.
    - **OPEN MATH (don't assume — confirm when building Levels):** "reset to 0" conflicts with a rolling last-10 average (a strong user climbs back to ~100 instantly). Resolve at the Level milestone (reset the window / progress-bar-vs-ability split / harder per-level scaling).
  - **Hourglass LOTTERY / gacha (founder, 2026-06-16, FUTURE VERSION — recorded):** each level completion grants a **wrapped** hourglass; **unwrapping** it reveals a **random themed** hourglass (each future theme has its own hourglass art → the collectible represents the theme). Builds anticipation; **rarity tiers** RPG-style (some themes very luck-based/hard, like rare game skins); **festival/seasonal themes** (Christmas, Halloween) to drive repeat use. Keep it free/earned (no paid loot-box dark patterns). Full design + drop-rate/dupe/pity questions in the Focus Score spec.
  - **Roadmap (later phases, recorded — not this build):** **Level/Progression system** (score→100 = collect + share card + theme unlock + reset + harder difficulty; needs the theme system first) → **progressive difficulty** (decaying weights / harder scaling) → **share card** → **streak effects** (broken streaks pull the score down at higher levels) → **honesty/anti-idle checks** → **PC/web versions with site/app/application blocking + monitoring** (the real work-verification) → **Profile screen** (collection + level history). On phone-only v1, work can't be verified; defense = protect-the-block + the score being a private, self-only number.
  - **Break advance is a USER SETTING (founder, 2026-06-16, CONFIRMED):** support BOTH auto-advance (default) and tap-to-continue between segments; user chooses in **Settings** (not the setup screen). Break screen shows a note that it's changeable.
  - **Keep screen awake during a session + dim chrome after idle (founder, 2026-06-16, CONFIRMED).** Uses wakelock_plus.
  - **÷10 ramp RE-CONFIRMED (founder, 2026-06-16):** a single weak session (e.g. scores 1) shows Focus Score 0 (1÷10 rounds to 0). Keep it — it's the intended ramp; one strong session never jumps to 100.
  - **"Keep going" on completion (founder, 2026-06-16, CONFIRMED):** a fixed Flow Block runs to length → enters `completed` state (not finished) → completion screen offers **Keep going** (drain the SAME block again, hourglass flips & refills, focus accumulates, overflow rewards score) or **Done**. The pre-set Endless toggle stays for never-stop-from-start. ONE record per block (persist on first completion via row id, then `reviseRecordedFocus` on extend — never a second row). Scoped to single-focus Flow Block; Pomodoro/Custom still `finished`.
  - **Hourglass FLIPS on every new focus block (founder, 2026-06-16, CONFIRMED):** begin, after each break, and on Keep going — whenever a block starts anew (3D rotateX). Sand level eases smoothly (per-frame exponential smoothing in HourglassView; the 1s clock no longer steps) and snaps on flip/reset. Pile-impact "scatter" grains are fine + ballistic + scale with pile size. Falling-sand grain color is per-skin (visible on light paper). Timer reveal is large and sits ABOVE the hourglass. Ambient halo behind the hourglass.

## Open follow-ups (don't lose)
- **Hourglass sand-fall ORIGIN is a flat fixed line (founder, 2026-06-18, REMINDER to improve).** The sand currently begins falling from a fixed horizontal line at the top chamber. Make it **realistic** — sand should originate from a natural converging aperture/neck (a point, with a believable funnel/pile-collapse at the source), not a flat horizontal edge. Touches the LOCKED hourglass visual (`lib/hourglass/hourglass_painter.dart`); confirm before changing the locked look. Polish item, not a launch blocker.
- **V1 LAUNCH CHECKLIST created (founder, 2026-06-18):** see `docs/v1-launch-checklist.md` — the full pre-Play-Store audit (security, legal/privacy, responsiveness, compatibility, UI/UX, monetization, store requirements). Work through it before publishing.
- **Recording rule UPDATED (founder, 2026-06-17, CONFIRMED — supersedes "non-flow abandon = 0"):** EVERY mode now records its actual focused time on any end (completed, given-up, force-killed) so it appears in Today's focus + session history. Flow Block still ignores sub-2-min ends. Only the **Focus Score** is Flow-Block-only (the score provider filters mode==flowBlock & ≥120s). Continuous 8s checkpoint now covers all modes (so a force-kill still logs the focus done).
- **Profile / Account + analytics + history (founder, 2026-06-17) — DECISIONS MADE; design brainstorm to continue in a NEW chat (this one got too long).**
  Confirmed so far:
  - **Account scope = "Local now, sync-ready schema":** single on-device profile in the local Drift DB (no login/servers yet), BUT design IDs/schema so a future cloud sync is a clean add-on (stable IDs, `updatedAt` on rows, a `profile` row that could later map to a server user).
  - **Profile holds user data:** name, **profile image** (user can upload their own; reused later in the **share card**). An editable **Profile page** + an "update profile" affordance.
  - **Profile screen v1 shows:** headline stats (Focus Score, level, total focus, streak, sessions), **session history list**, **analytics/charts**, and **collection** (hourglasses/themes/levels — placeholder until Levels exist).
  - **Separate pages to build:** Analytics page; Session History page; **per-session summary** when you tap a session in history; **Focus Score page** (the score as the hero/primary number up top, with a description of how it's calculated below).
  - Still to brainstorm: exact schema (profile table + aggregates vs derived), analytics metrics/charts, image storage approach, navigation/entry points. DO the brainstorming-skill design pass → spec → plan → build.
- **Continue/extend for Pomodoro & Custom (founder, 2026-06-17, decided shape — NEEDS BUILD):** on completion AND as a near-end nudge, offer **"Add another block" with an editable length** (default the plan's block length), repeatable indefinitely. Multi-segment, so engine needs appendable segments + a completed-but-extendable state for these modes. Big engine change — build carefully next. Add a continue option on completion for these modes too — but WITH config: extend by a specific amount, repeat the current configuration again, or a "+5"-style quick increment (like other apps). Flow Block already has Keep going (drain same block again) + the "don't stop" endless toggle + the "Run until I end" setting. Pomodoro/Custom are multi-segment so "continue" is more involved (repeat the whole plan? add one more block? add a flat extension?). Design before building.
- **Monetization / paywall brainstorm (founder, 2026-06-16).** Decide what sits behind a paywall and how the app earns **good revenue without feeling like a cheap money-grab**. Must respect the calm/premium brand + no-dark-patterns stance. Consider: free core focus loop vs. premium (advanced stats, extra themes/soundscapes, PC/web blocking, cloud sync, the lottery/collectibles cosmetics), one-time vs. subscription, ethical cosmetic gacha (earned not paid), festival/seasonal theme drops. Brainstorm properly (use brainstorming flow) before deciding.
- **Brainstorm enhancing FLOW BLOCK (founder, 2026-06-16)** so it's genuinely the mode people choose *over* Pomodoro/Custom (even with all their features) — the signature, differentiated method. Do this after the Pomodoro/Custom multi-segment engine is built. Ideas to explore: stamina progression made tangible, the Struggle→Flow framing, adaptive suggestions, streaks/grow-the-hourglass, "protect the block", etc.
- **Brainstorm enhancing FLOW BLOCK (founder, 2026-06-16)** so it's genuinely the mode people choose *over* Pomodoro/Custom (even with all their features) — the signature, differentiated method. Do this after the Pomodoro/Custom multi-segment engine is built. Ideas to explore: stamina progression made tangible, the Struggle→Flow framing, adaptive suggestions, streaks/grow-the-hourglass, "protect the block", etc.
- **Partial-credit for multi-segment sessions:** currently abandon/end-before-completion records ZERO focus (Plan-1 protect-the-block rule). For Pomodoro/Custom, completing some blocks then stopping should arguably credit the focus done. Decide when building the Session screen + recovery.
- **Full RESPONSIVENESS audit across every screen (founder, 2026-06-16).** Test on many mobile sizes (small → large/tablet), and across OS **font-size settings** (extra-small → extra-large / bold text) and **display zoom / large display-size** settings. Users run XL fonts + zoomed screens; nothing may overflow, clip, or break. Approach: prefer scrollable/flexible layouts, honor `MediaQuery.textScaler` (don't hard-cap unless needed), test with `textScaleFactor` 0.85–1.5+ and small viewports, fix RenderFlex overflows (already hit several on Setup). Do a dedicated pass after the core screens exist.
- **Brainstorm a daily TASK LIST feature AFTER core screens** (founder, 2026-06-16), inspired by **FlowStack** (apps.apple.com/us/app/flowstack-focus-task-timer/id6739469633): users build a daily task list and do tasks one-by-one in focus/flow blocks; "smash multiple tasks in one focus sprint"; save tasks/routines as **templates** (a Library); per-task flexible timer + "flow state" continue; completion summary ("Session Complete! 7 tasks, 170 min"); stats (tasks completed today, time today, streak). Likely adds a Library/templates screen + task context into Setup/Session; revisit/edit screens after the ritual is built. Fits our Flow Block methodology (tasks → blocks).
- **Review `github.com/ever-works/awesome-time-tracking` AFTER the core screens are built** (founder, 2026-06-16). It lists many time-management practices/techniques + tools; check which match or complement our Flow Block methodology (could inform modes, features, or positioning). Deferred until Setup/Session screens are done.
- **Hardcoded greeting name "Deep"** in `lib/ui/widgets/greeting_line.dart` (`_name`). Placeholder until Plan 3 onboarding captures the user's real name into settings; then read it from there. (Founder asked to note this 2026-06-15.)
- **Home top-right gear → full Settings page (future).** Currently the gear opens a small light/dark/system bottom sheet (interim). Plan: point it at a proper **Settings page** that hosts theme switching, **Profile access**, and more. The **Profile** then holds analytics/stats and other things. Other pages (stats dashboard, recovery, etc.) need entry points too — **brainstorm placement/accessibility when we build them** (don't just bolt on buttons). (Founder asked to note this 2026-06-15.)

## CONTINUATION — pick up here in a new session (updated 2026-06-15)

### What's DONE and committed (branch `master`)
- **P1 Foundation** — `lib/domain/` + `lib/data/`, fully tested (30 tests green). Reviewed ship-ready.
- **P2 logic** — `lib/app/` (Riverpod providers, theme, app shell — `home:` is a placeholder Scaffold), `lib/session/` (`SessionConfig`, `Ticker`, `SessionState`, `SessionController`, `SessionFinalizer`). All tested (38 tests green at last count).
- **P2 hourglass visual — LOCKED** (commit `8fbfaa9`): `lib/hourglass/` (`hourglass_skin.dart`, `hourglass_painter.dart`, `hourglass_view.dart`, `hourglass_preview.dart`) + `lib/hourglass_preview_main.dart` (standalone preview entrypoint with a drain slider). The founder approved and **locked** this look after long on-device iteration — do NOT change it without being asked. Key choices already settled: andyfitz 2-layer parallax liquid top (light back / base front, ~1.4× speed apart, Catmull-Rom rendered); thin hole-width gravity sand-fall (~30 fine matte grains, phase² acceleration, no glow); two-phase pile; reduced fill so top/bottom never merge; wave fades flat near empty.

### Dev environment (all set up, don't redo)
- **Flutter 3.44.2** at `D:\Dev\tools\flutter` (on PATH). Dev on Windows; build via `flutter build apk` / preview on device.
- **Android licenses accepted** (had to run the SDK's `sdkmanager --licenses` directly with `SKIP_JDK_VERSION_CHECK=1` + JDK 21 — `flutter doctor --android-licenses` mis-detects Java 21).
- **Low-memory Gradle fix is committed** (`android/gradle.properties`: `-Xmx1536m`, kotlin in-process, no parallel) — the template's `-Xmx8G` crashed the daemon on this ~16GB/<5GB-free machine. Don't revert it.
- **Real Android phone** used for preview: Vivo **V2521**, Android 16, id `10MG18FQQG0008L`. `adb` at `C:\Users\morni\AppData\Local\Android\Sdk\platform-tools\adb.exe`.

### How to preview the hourglass on the phone (the loop used all session)
```
export PATH="/d/Dev/tools/flutter/bin:$PATH"; export JAVA_HOME="/c/Program Files/Java/jdk-21"; export MSYS_NO_PATHCONV=1
ADB="/c/Users/morni/AppData/Local/Android/Sdk/platform-tools/adb.exe"
flutter build apk --debug -t lib/hourglass_preview_main.dart
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk
"$ADB" shell am start -n com.trilumos.sustain/.MainActivity
# screenshot (note MSYS path quirk): screencap to /sdcard then pull to a C:/ path
"$ADB" shell screencap -p /sdcard/s.png; "$ADB" pull /sdcard/s.png "C:/Users/morni/AppData/Local/Temp/s.png"
```
(`adb shell input tap 300 1518` taps the drain slider; screen stays awake via `svc power stayon usb`.)

### NEXT (Plan 2 remaining) — see `docs/superpowers/plans/2026-06-13-hourglass-v1-session-ui.md`
Build the screens that USE the locked `HourglassView` + the `SessionController`:
1. **Home screen** (Task 6): calm landing, `HourglassView(progress:0)` at rest, Begin, mode selector, today/streak from a stats provider. Then point `lib/app/app.dart` `home:` at it (replace the placeholder).
2. **Setup/Intention screen** (Task 7): intention + duration (stamina-suggested) + soundscape → builds a `SessionConfig`.
3. **Session screen** (Task 8): wires `SessionController` (real `PeriodicTicker`) to `HourglassView(progress: elapsed/planned)`, surfaces the Struggle line, pause, protect-the-block (lifecycle), completion.
4. **Audio** (Task 4): `just_audio` soundscapes — needs sourcing royalty-free CC0 loops + a CREDITS.md (deferred; signature "sand" sound is the hard one).
5. **Wire `SessionFinalizer`** into the session-complete + abandon paths (Task 9 step 5).
6. **Verify on device** (Task 10), then Plan 3 (Recovery/Boring-Break screen, stats dashboard, settings, share cards, optional sign-in/cloud-sync) + the release-security carry-forward items above.
