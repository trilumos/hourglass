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

### 1.1 Leaving the app (the core fix)

Leaving the app (`AppLifecycleState.paused`/`inactive`) ends the block whether it
was **running or paused** — with a short grace so accidental switches and
incoming calls don't unfairly kill a session.

- On background: record `backgroundedAt`; freeze the session (no focus accrues
  while away). This freeze does **not** consume a manual-pause (see 1.2).
- On return (`resumed`):
  - elapsed ≤ **15 s** → restore the prior state (a running block resumes; a
    manually-paused block stays paused). Block survives.
  - elapsed > 15 s → the block **ends** (abandon → recorded as given-up, with
    whatever focus was banked before leaving, per the existing recording rule).
- If the user never returns, the block stays frozen until they reopen the app
  (then it ends per the rule); a force-kill is already handled by the 8-s
  checkpoint safety net (records focus-so-far as given-up).
- Applies to all modes; **preview mode stays fully exempt.**

### 1.2 Manual pause (the in-app pause button)

Pause stays **free** but disciplined; Pro is lenient.

| | Free | Pro |
|---|---|---|
| Pauses per session | **2** | **Unlimited** |
| Max single pause (auto-acts) | **3 min** | **10 min** |

- **Pause count:** after a free user spends their 2 pauses, the pause control is
  disabled and shows a calm Pro nudge ("You've used your 2 pauses — Pro gives
  unlimited pauses"). The session keeps **running** (we never end a block just
  for *wanting* to pause again).
- **Pause duration:** a single pause that exceeds the cap ends the block
  (abandon) — staying paused that long means you walked away. A gentle line
  explains it. (Pro's 10-min cap is a safety stop, not a discipline lever.)
- Limits are keyed off `entitlementsProvider.pro`. Pause count resets per
  session.

### 1.3 Copy & feel (calm, not punitive)

- Grace return prompt is reassuring, e.g. a brief "Come back to keep your block"
  state on return-too-late, not a scolding.
- Pro nudges are quiet upsells (tap → paywall), consistent with the rest of the
  app. Never block the *core* loop; only the *leniency* is gated.

### 1.4 Deferred (recorded, not built now)

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
  (premium, smaller). Pricing unchanged (LOCKED): Monthly ₹149/$4.99, Yearly
  ₹799/$29.99, Lifetime ₹1,499/$59.99. Pause-leniency becomes another concrete
  Pro benefit listed on the paywall.
- No code change to entitlements/pricing — purely paywall presentation order +
  benefit copy (add "Unlimited, longer pauses" to the Pro benefits list).

## Architecture / where it lives

- **`SessionController`** (domain, pure): owns the rules. Add `pauseCount`,
  pause-cap + count limits (injected, so free/Pro and the durations are
  parameters — testable without Flutter), an `onLimitHit`/state for "out of
  pauses", and a `leftAt`/grace check API. Keep audio/entitlement out of the
  domain — the UI passes in the limits (like it already passes `onCue`).
- **`SessionScreen`**: wires the limits from `entitlementsProvider.pro`, drives
  the lifecycle grace (background timestamp + on-resume check), renders the
  pause button states + the Pro nudge + the grace return state.
- **Paywall screen**: reorder tiers + add the pause benefit. No billing changes.

## Testing

- Controller unit tests (pure, fake ticker): leave-while-running and
  leave-while-paused both end the block after grace; return-within-grace
  survives; free pause count caps at 2 then blocks (session keeps running);
  pause-duration cap ends the block; Pro params give unlimited + 10 min.
- Widget: pause button disables + shows the upsell after 2 (free); grace return
  state renders; preview mode exempt from all rules.
- Paywall widget: tier order + pause benefit present; Lifetime still shown.
- Serial `flutter test --concurrency=1`; `flutter analyze` clean.

## Out of scope / non-goals

- App allow-list (deferred, §1.4). No change to pricing or the entitlement
  engine. No change to the free *core* loop (Flow/Pomodoro/Custom, score,
  streak, stats stay free). Grace/limits never apply to theme preview.
