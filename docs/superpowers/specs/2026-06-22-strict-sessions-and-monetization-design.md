# Strict Sessions + Monetization Refinement — Design

**Date:** 2026-06-22
**Status:** Approved in brainstorm (founder), pending spec review → plan.

## Goal

Make a focus session *mean something* — you can't pause, use your phone, and
resume with no consequence. Close the abuse loophole, make pause a disciplined
tool (limited for free, lenient for Pro), and reorder the paywall to feature
subscriptions while keeping Lifetime. Grounded in research of Forest, Flora,
Opal, one sec, Session (see brainstorm notes): Forest gates *pause* behind Pro
and gives free users zero pauses; we are deliberately **more generous** (free
gets limited pauses), and we add a short grace window that the market shows
users expect (instant-kill-on-leave is a documented 1-star complaint class).

## Background — the current behavior (and the loophole)

- `SessionController` has `pause()` / `resume()` (freezes the sand) and
  `abandon()` (ends the block, recorded as given-up).
- `didChangeAppLifecycleState`: **only** abandons when leaving the app while
  `status == running`. The instant the user hits **pause**, that guard is false,
  so they can background the app, use their phone, return, and resume with no
  penalty. **That gap is the abuse.**
- Theme **preview** sessions are exempt from all of this (they record nothing).

## Part 1 — Strict session rules

### 1.1 Numbers (final)

| | Free | Pro |
|---|---|---|
| Pauses per session | **3** | **Unlimited** |
| Max single pause (cap) | **3 min** | **10 min** |
| Leave-while-**running** grace | **30 s** | 30 s |
| Pause-**cap** grace (after the cap) | **15 s** | 15 s |

All limits are keyed off `entitlementsProvider.pro`; pause count resets per
session. **Preview mode is fully exempt** from every rule below.

### 1.2 The prompts live in PUSH NOTIFICATIONS (the key insight)

The grace windows happen while the user is **outside** the app, so the "come
back" prompt **cannot** be in-app UI — it is a **local push notification**
(`flutter_local_notifications`). The notification both warns them and is the way
back (tapping it reopens the app to the live session). In-app states are still
shown for the moments the user *is* looking at the screen.

- New dependency: **`flutter_local_notifications`** + Android 13+ runtime
  **`POST_NOTIFICATIONS`** permission (requested gracefully; if denied, the grace
  logic still runs on return — they just don't get the external nudge).
- Notifications are **scheduled** so they fire even if the OS suspends or kills
  the app while backgrounded. Each grace notification is cancelled if the user
  returns in time.

### 1.3 Leaving the app while RUNNING (didn't pause)

The strictest path — they bailed without using a pause.

- On background while running: **immediately show** a notification — *"Come back
  to keep your block — you have 30 seconds."* Start a **30 s** grace.
- Return (tap the notification or reopen) within 30 s → the block **resumes**
  running; the notification is cancelled.
- 30 s elapses (or the app is killed) → the block **ends** (given-up, banking the
  focus done before leaving). Enforced on return by comparing elapsed time; a
  force-kill is already covered by the 8-s checkpoint safety net.

### 1.4 Manual pause — and pausing-then-leaving

Pausing is deliberate, so it earns the full pause budget (the cap), not just the
30 s leave-grace.

- **Count:** Free gets **3** pauses/session. After the 3rd is used, the pause
  control is disabled with a quiet Pro nudge (*"You've used your 3 pauses — Pro
  gives unlimited pauses"*). The session keeps **running** — we never end a block
  just for *wanting* to pause again. Pro is unlimited.
- **Duration + the cap grace:** a pause may last up to the cap (**3 min** free /
  **10 min** Pro), whether the user stays in-app or leaves. When the pause
  **reaches the cap**:
  1. Show a notification — *"Your pause is up — return within 15 seconds to keep
     your block."* (and the same prominent state in-app if they're looking).
  2. Start a **15 s** grace, revealed **only now** (a pause under the cap never
     shows a countdown — it's calm until the cap is hit).
  3. Return within 15 s → the block **resumes** running (the pause is over).
  4. 15 s elapses → the block **ends** (given-up).

### 1.5 Copy & feel (calm, not punitive)

- Notification + in-app copy is reassuring and brief ("Come back to keep your
  block"), never a scolding. Tapping the notification deep-links to the session.
- Pro nudges are quiet upsells (tap → paywall). Never block the *core* loop; only
  the *leniency* is gated.

### 1.6 Deferred (recorded, not built now)

- **Allow-list of permitted apps** (open music/maps mid-session without ending
  the block) — across Forest/Opal/Focus Plant this is the single most-paywalled
  leniency feature and a strong future **Pro pillar**, but it needs app-blocking
  / usage-access permissions. Earmarked for a later release, not this spec.

## Part 2 — Monetization: keep Lifetime, feature subscriptions

Decision: **keep all three Pro tiers**, but reorder/emphasize the paywall so
Monthly/Yearly lead and Lifetime reads as a premium "own it forever" option.

- Rationale: the "lifetime → complacency" worry is unfounded — Pro doesn't gate
  the core focus loop, so owning it forever doesn't reduce *why* someone focuses;
  sunk-cost nudges *more* use, not less. The real trade-off is recurring revenue
  vs conversions, and Lifetime is a major conversion path (subscription fatigue,
  India-first; Forest itself is one-time). Removing it likely costs revenue, not
  improves retention.
- **Paywall order:** Yearly (featured, "best value") → Monthly → Lifetime
  (premium, smaller). ~~Pricing unchanged (LOCKED): Monthly ₹149/$4.99, Yearly
  ₹799/$29.99, Lifetime ₹1,499/$59.99.~~ **⚠️ SUPERSEDED 2026-07-17 → Monthly
  ₹89/$2.99 · Yearly ₹549/$19.99 · Lifetime ₹1,299/$49.99. See
  [`2026-07-17-sustain-platform-strategy-design.md`](2026-07-17-sustain-platform-strategy-design.md)
  §6.1.2 — subs lost themes (Lifetime-exclusive now), so they got cheaper; Lifetime
  became a founding price to be raised later.** Pause-leniency becomes another concrete
  Pro benefit listed on the paywall.
- No code change to entitlements/pricing — purely paywall presentation order +
  benefit copy (add "Unlimited, longer pauses" to the Pro benefits list).

## Architecture / where it lives

- **`SessionController`** (domain, pure): owns the *rules* (counts, caps, the
  grace math). Add `pauseCount`, the count + cap + grace durations (injected as
  params, so free/Pro values are testable without Flutter), an "out of pauses"
  state, and a grace/away check API. Audio/entitlement/notifications stay out of
  the domain — the UI passes the limits in (exactly like it already passes
  `onCue`) and reacts to controller state.
- **Notification service** (new, `lib/audio/`-style sibling, e.g.
  `lib/session/session_notifications.dart`): a thin wrapper over
  `flutter_local_notifications` — `graceReminder(kind, deadline)` schedules/shows
  the "come back / pause's up" notification and `cancel()` clears it. A no-op
  impl for tests + a `FLUTTER_TEST` guard provider, mirroring `SoundCuePlayer`.
- **`SessionScreen`**: wires limits from `entitlementsProvider.pro`; on
  background, freezes + fires the right notification (30 s leave grace, or the
  pause-cap grace) and records `awayAt`; on resume, applies the grace decision
  (resume vs end) and cancels the notification; renders the in-app pause-button
  states, the Pro nudge, and the cap countdown.
- **Android manifest / permissions:** add `POST_NOTIFICATIONS` (Android 13+),
  request at the right moment (first session, not at launch). Notification tap
  re-opens to the running session.
- **Paywall screen**: reorder tiers + add the pause benefit. No billing changes.

## Testing

- Controller unit tests (pure, fake ticker): leave-while-running ends after the
  30 s grace, returns-in-time survives; a manual pause past the cap triggers the
  cap grace then ends after 15 s; free pause count caps at **3** then blocks
  (session keeps running); Pro params give unlimited + 10 min.
- Notification service: the no-op/`FLUTTER_TEST` path is used in tests (no real
  notifications); the wrapper schedules/cancels for the right kind+deadline.
- Widget: pause button disables + shows the upsell after 3 (free); cap countdown
  + grace states render; preview mode exempt from all rules.
- Paywall widget: tier order (Yearly→Monthly→Lifetime) + pause benefit present;
  Lifetime still shown.
- Serial `flutter test --concurrency=1`; `flutter analyze` clean. Verify the
  `flutter_local_notifications` Android build (like the audio plugins).

## Out of scope / non-goals

- App allow-list (deferred, §1.6). No change to pricing or the entitlement
  engine. No change to the free *core* loop (Flow/Pomodoro/Custom, score,
  streak, stats stay free). Grace/limits never apply to theme preview.
