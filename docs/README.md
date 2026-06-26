# Sustain — Documentation Map

> **Start here.** This is the index for everything in `docs/`. It tells you, at a glance, what's
> **shipped**, what's **planned**, and what's just **reference**, so you never have to guess which of
> the many specs is current.

## The one rule for resolving conflicts

Specs were written over weeks and the product evolved, so older specs describe earlier ideas (e.g. the
original spec still calls the app "Hourglass" and describes a 3-screen onboarding that later became 5).
**When documents disagree, the order of truth is:**

1. **The app's actual behaviour** (the code) — the real source of truth.
2. **[`feature-roadmap.md`](feature-roadmap.md)** — the canonical list of what's shipped vs v1.2 vs v2.
3. **[`project-context.md`](project-context.md)** — durable decisions & locked rules.
4. **The latest dated spec** on a topic beats an earlier one.

Earlier specs are kept as a **design record** (why we built it this way), not as current instructions.

---

## Current working docs (read these)

| Doc | What it is |
|-----|-----------|
| [`feature-roadmap.md`](feature-roadmap.md) | **Canonical roadmap** — what ships in v1, v1.2, v2. The home for all future planning. |
| [`project-context.md`](project-context.md) | Durable project memory: founder preferences, locked decisions, standing rules. |
| [`design-language.md`](design-language.md) | Look/feel source of truth ("Warm Precision") — tokens, type, motion, voice. |
| [`brand-design-philosophy.md`](brand-design-philosophy.md) | Distilled brand/design DNA (colours, type, motif, anti-patterns) — for generating on-brand visuals/assets. |
| [`v1-launch-checklist.md`](v1-launch-checklist.md) | Pre-publish gating: security, legal, store, a11y, perf. |
| [`play-console-revenuecat-setup-guide.md`](play-console-revenuecat-setup-guide.md) | Ops: Play Console + RevenueCat setup steps. |
| [`launch-founder-actions.md`](launch-founder-actions.md) | The founder's launch to-do list. |
| [`legal/privacy-policy.md`](legal/privacy-policy.md) · [`legal/terms-of-service.md`](legal/terms-of-service.md) | Deployed legal docs. |

## Active work

| Doc | Status |
|-----|--------|
| [`superpowers/plans/2026-06-24-app-wide-audit-plan.md`](superpowers/plans/2026-06-24-app-wide-audit-plan.md) | 🔵 Pre-launch audit checklist. |
| [`superpowers/plans/2026-06-25-app-audit-findings.md`](superpowers/plans/2026-06-25-app-audit-findings.md) | 🔵 Findings + fixes from the audit. |

---

## Design specs — `superpowers/specs/`  (✅ all SHIPPED unless marked)

These describe **features that are now in the app**. They're the design record; for "what it does
today," trust the code + roadmap.

| Spec | Feature | Notes |
|------|---------|-------|
| [2026-06-11 flow-block-app-design](superpowers/specs/2026-06-11-hourglass-flow-block-app-design.md) | ✅ Original v1 vision | Foundational. Pre-rename ("Hourglass") & pre-monetization — **details superseded** by later specs; keep for history. |
| [2026-06-15 home-screen-additions](superpowers/specs/2026-06-15-home-screen-additions-design.md) | ✅ Home screen | |
| [2026-06-16 session-engine](superpowers/specs/2026-06-16-session-engine-design.md) | ✅ Multi-segment engine | |
| [2026-06-16 flow-block-focus-score](superpowers/specs/2026-06-16-flow-block-focus-score-design.md) | ✅ Focus Score | Also holds the **Levels/lottery** ideas → now tracked as V2 in the roadmap. |
| [2026-06-16 onboarding-screen](superpowers/specs/2026-06-16-onboarding-screen-design.md) | ✅ Onboarding + Sustain rename + package switch | |
| [2026-06-17 profile-account-db](superpowers/specs/2026-06-17-hourglass-profile-account-db-design.md) | ✅ Profile / DB | Schema is sync-ready for V2 cloud. |
| [2026-06-18 insights-analytics](superpowers/specs/2026-06-18-hourglass-insights-analytics-design.md) | ✅ Insights page | |
| [2026-06-19 enhanced-insights](superpowers/specs/2026-06-19-enhanced-insights-design.md) | ✅ Pro Insights depth | |
| [2026-06-19 reuse-session-config](superpowers/specs/2026-06-19-reuse-session-config-design.md) | ✅ Session reuse | |
| [2026-06-19 entitlement-engine](superpowers/specs/2026-06-19-entitlement-engine-design.md) | ✅ Entitlements + paywall | |
| [2026-06-19 color-themes](superpowers/specs/2026-06-19-color-themes-design.md) | ✅ Themes (Sand + 8) | |
| [2026-06-19 monetization-and-v1-paid-tier](superpowers/specs/2026-06-19-monetization-and-v1-paid-tier-design.md) | ✅ Pricing & model | Holds locked pricing; later refined by the strict-sessions spec. |
| [2026-06-22 strict-sessions-and-monetization](superpowers/specs/2026-06-22-strict-sessions-and-monetization-design.md) | ✅ Anti-pause-abuse + paywall featuring | **Refines** the 06-19 monetization paywall. |
| [2026-06-22 notification-system](superpowers/specs/2026-06-22-notification-system-design.md) | ✅ Notifications + FGS | Native MediaStyle notif deferred to v1.2. |

### `superpowers/specs/future/` — 🟡 not built

| Spec | Status |
|------|--------|
| [2026-06-24 future-versions-research](superpowers/specs/future/2026-06-24-future-versions-research.md) | 🟡 Research & options (coins/ads economy + competitor study). **Not decided** — input for a future brainstorm. See the roadmap's V1.2/V2 sections. |

---

## Implementation plans — `superpowers/plans/`  (✅ all DONE)

Step-by-step build plans, all executed. Kept as a record of how each feature was built.

- ✅ [2026-06-11 v1-foundation](superpowers/plans/2026-06-11-hourglass-v1-foundation.md)
- ✅ [2026-06-13 v1-session-ui](superpowers/plans/2026-06-13-hourglass-v1-session-ui.md)
- ✅ [2026-06-17 profile-account-db](superpowers/plans/2026-06-17-hourglass-profile-account-db.md)
- ✅ [2026-06-18 insights-analytics](superpowers/plans/2026-06-18-hourglass-insights-analytics.md)
- ✅ [2026-06-18 onboarding-rename](superpowers/plans/2026-06-18-sustain-onboarding-rename.md)
- ✅ [2026-06-19 entitlement-engine](superpowers/plans/2026-06-19-entitlement-engine.md)
- ✅ [2026-06-20 color-themes](superpowers/plans/2026-06-20-color-themes.md)
- 🔵 [2026-06-24 app-wide-audit-plan](superpowers/plans/2026-06-24-app-wide-audit-plan.md) · [findings](superpowers/plans/2026-06-25-app-audit-findings.md) (active)

---

## Reference material — `references/`  (📚 background research, not specs)

- [vercel-geist-design](references/vercel-geist-design.md) — design-system study.
- [insights-analytics-research](references/insights-analytics-research-2026-06-19.md)
- [monetization-research](references/monetization-research-2026-06-19.md)

---

## Where future planning lives (so it stops being scattered)

All forward-looking work is consolidated under **[`feature-roadmap.md`](feature-roadmap.md)**
(v1.2 + v2). The detailed thinking behind individual future ideas lives in:
- **Coins / ads economy + competitor features** → [future-versions-research](superpowers/specs/future/2026-06-24-future-versions-research.md)
- **Levels / progression / hourglass lottery** → the "future" sections of [flow-block-focus-score](superpowers/specs/2026-06-16-flow-block-focus-score-design.md)
- **Cloud sync, widgets, Spotify, journal, PiP, break activities** → roadmap V2.

If you add a new future idea, **put a one-line entry in the roadmap** and link the detail spec — don't
bury it inside an unrelated spec.
