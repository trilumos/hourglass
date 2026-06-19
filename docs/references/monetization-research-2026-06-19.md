# Monetization — Competitive Research (2026-06-19)

> Deep-research pass (search → fetch → adversarial verify → synthesize; 24 sources,
> 101 claims, 25 verified, 17 confirmed / 8 killed) on monetization models, tier
> structures, pricing, trials, and dark-pattern avoidance for indie focus /
> productivity / wellness apps — to pressure-test **Sustain's** planned model.

## 1. Verified findings

**Models:** the category is overwhelmingly **freemium-with-subscription or
hybrid**; pure subscription dominates the advanced/AI segment; lifetime exists in
simpler apps. Real, current prices (2025–26 snapshots, re-verify before publish):
- **Rize** — subscription-only, **no lifetime**: $9.99/mo (annual) … $28.99/mo Pro.
- **Session** — subscription-only: **$4.99/mo or $39.99/yr**, 7-day trial, no lifetime.
- **Flow (Pomodoro)** — freemium, Pro **from $1.49/mo** (annual) — category floor.
- **RescueTime** — freemium (free-forever Lite) + subscription, no lifetime.
- **Habitica** — hybrid: free base + gems from **$0.99** + sub up to **$47.99/yr**.
- **Opal** — freemium Free vs Pro.

**Free vs paid line (validates Sustain's split):** core timer + basic stats +
default look stay **free**; **advanced analytics, scheduling, app/website
blocking, focus-enforcement, cloud sync, integrations, and history depth** are
gated. Notably **Opal gates "Focus Score History" to Pro** while keeping the
daily Focus Score free — a direct precedent for *keep the score free, gate its
trend/history*.

**Billing cadence:** productivity is the **monthly outlier — 77% of subscription
revenue is monthly** (vs Health & Fitness 68% annual). → **offer monthly
prominently; don't bury it.** (RevenueCat State of Subscription Apps 2026.)

**Hard paywall vs freemium:** hard paywalls convert **~5× better early**
(~10.7–12.1% vs ~2.1–2.2% download-to-paid) and ~8× revenue/install at 14 days —
**BUT the edge is early-window only; one-year retention converges**, and a case
study saw **+75% LTV after REMOVING a hard paywall**. Conversion% ≠ LTV. → don't
hard-paywall the free core loop; freemium is fine for LTV.

**Annual retention:** cheap annual plans retain **up to 36% at one year vs 6.7%
for high-priced monthly**. → discounted annual + keep prices low. (Caveat:
confounds price with billing cycle.)

**Trials:** match usage cadence (**3-day for daily-use**, 7-day weekly); **reverse
trials** (premium first, then drop to free) exploit loss aversion; card-required
converts ~2.5–3× higher than no-card (but that figure is B2B SaaS). Sustain is
daily-use → a **3-day or reverse trial** fits; no-card/opt-in is more respectful
but converts lower.

**Dark patterns:** FTC/ICPEN 2024 — **~76% of 642 subscription apps used ≥1 dark
pattern, ~67% multiple.** → a **no-ads, no-trap, easy-cancel** stance is a
*genuine differentiator*, not just ethics.

**Two-tier precedents:** real two-tier models (e.g., Rize Basic/Pro/Business)
split by **escalating capability/value** (more AI/insights, seats), gap ~2–4× —
**not by cosmetics.** → Sustain's Pro↔Plus must map to an obvious value
escalation (Plus = ongoing services) or it feels arbitrary.

## 2. Assessment of Sustain's planned model

**Direction is sound and ethically well-positioned** (no ads, privacy-first,
RevenueCat). Specific tweaks the data supports:

1. **The biggest risk = running BOTH a Pro subscription and a Plus subscription**
   → confusing ("which do I buy?"). Fix: make **Plus a strict superset that
   *includes* Pro** (a Plus member never needs to also buy Pro), and present them
   as two clear doors: **Pro = own the on-device app** (monthly/yearly/**lifetime**),
   **Plus = membership for ongoing services** (sync, blocking, training, full
   store; subscription-only). Marketing/paywall must make Plus ⊇ Pro obvious.
2. **Lifetime price too low.** Pro lifetime $19.99 = **2× yearly**; typical
   lifetime is **3–5× yearly**. Bump to **~$24.99–29.99 (~3× the $9.99 yearly)**.
3. **Pro monthly $1.99 / yearly $9.99** — low but defensible as an indie wedge
   ($1.49 Flow is the floor); $9.99 yearly ≈ 58% off monthly is a healthy anchor.
4. **Plus monthly $4.99 / yearly $29.99 (~50% off)** is sensible; keep Plus
   clearly out-valuing Pro at every interval.
5. **Themes $1.99–2.99 à la carte** is standard + ethical. Keep cosmetics
   **earned-or-bought; avoid loot-box/gacha.**
6. **Trial:** offer a **3-day or reverse trial on Plus**; keep it no-card to stay
   user-respecting (or A/B a hard paywall given the 5× data) — but **never**
   hard-paywall the free core loop.
7. **Monthly must be visible** (productivity buyers skew monthly), with annual
   discounted as the anchor and lifetime as the indie-friendly "own it" option.

## 3. Caveats & open questions (data that did NOT survive verification)
- **India ₹ / Play Store local price tiers / PPP discounts** — the India median
  claim was **refuted**; *no reliable India-pricing data survived.* Set ₹ tiers
  empirically in Play Console (local price points) — open question.
- **Category median monthly/annual price** — both median claims **refuted**; treat
  RevenueCat medians as directional, not absolute.
- **Forest's exact model** (iOS one-time vs Android) — contested, unconfirmed.
- Reverse-trial / opt-in-vs-opt-out conversion numbers come from **B2B SaaS** —
  ordering holds, absolute numbers may not transfer to consumer mobile.
- Whether Plus should be a true superset vs two separate tiers — needs
  user-testing, not desk research.

## Sources (verified)
RevenueCat State of Subscription Apps 2025 + 2026 (productivity) + freemium-tier
blog; Rize pricing; Opal "why pay"; RescueTime pricing (Jibble); Zapier Pomodoro
roundup; Habitica vs Streaks (DailyHabits); Adapty trial-conversion; FTC dark-
patterns study (TechCrunch); Perkins Coie click-to-cancel; Adapty/Maxio/Hubifi
tiered-pricing; IndieHackers subscription-vs-one-time threads. *(8 claims killed
in verification, incl. all India-pricing and category-median figures.)*
