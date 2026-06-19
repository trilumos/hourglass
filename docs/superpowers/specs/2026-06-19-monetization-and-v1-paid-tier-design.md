# Monetization Model & v1 Paid Tier — Design Spec (Sustain)

> **Status:** Model + v1 scope LOCKED by founder 2026-06-19 (brainstormed this
> session). This spec defines (1) the **durable monetization model** for Sustain
> and (2) the concrete **v1 paid tier** to build and ship. It supersedes the
> open "Monetization" item in `project-context.md` and the launch-checklist §9.
> Subsequent builds it references (the cosmetic Store engine; enhanced Pro
> Insights analytics) get their own specs.

---

## 1. Principles (non-negotiable)

- **Free core, always.** The focus loop (Flow/Pomodoro/Custom, unlimited),
  Focus Score, streak, basic stats, the default Sand look, and the session
  ritual are never paywalled.
- **No ads, ever.** Make it a brand promise. Ads fight a focus app's whole value
  and would break the no-telemetry privacy story.
- **No dark patterns.** Conversion comes from *wanting* premium, never from
  degrading the free experience.
- **Lifetime is offered only for zero-ongoing-cost (on-device) things → Pro.
  Anything with real ongoing cost/content → Plus, subscription-only.** This is
  what keeps a paid focus app from feeling extractive ("Forest is unusable
  without paying" — the thing to avoid).
- **Decide a feature's tier at launch, not later.** Gating a previously-free
  feature in a later version reads as "you took away what was free" — review
  poison. (This is why detailed Insights is Pro from v1, not free-then-gated.)

---

## 2. The model (durable — full picture)

**Tiers**
- **Free (always):** core loop; Focus Score, streak, Today/Total/Average; **basic
  Insights** (Records + consistency heatmap); default **Sand** look; **Sand
  soundscape + session/break sound cues**; profile, guide, onboarding.
- **Pro** — on-device premium, sold **monthly / yearly / lifetime — all three
  from v1.** (Monthly lets users *try* Pro cheaply instead of facing a
  lifetime-only barrier; lifetime stays the honest "own it" anchor.)
- **Plus** — connected/ongoing premium, **monthly / yearly only (no lifetime;
  launches v1.2)**. Unlocks **everything** (Pro + connected/ongoing features). A
  one-time price can't fund forever-running services (sync, blocking, training
  content), and recurring is *fair* here because the value is ongoing. **Plus
  prices above Pro at every interval** (Plus ⊇ Pro).
- **À la carte** — buy individual cosmetics one-time (v1: complete color themes;
  v1.2: the full categorized store).

**Feature → tier × release**

| Feature | Tier | Release |
|---|---|---|
| Core loop, Focus Score, streak, basic stats | Free | v1 |
| Basic Insights (Records + heatmap) | Free | v1 |
| Session/break **sound cues** | Free | v1 |
| Default **Sand** look + Sand soundscape | Free | v1 |
| **Detailed + enhanced Insights** | **Pro** | **v1** |
| **Color themes** (app palette + hourglass colors) | **Pro (bundled) + à la carte** | **v1** |
| Todo/task library, widgets, share cards, break activities, +more themes/soundscapes | Pro | v1.2 |
| Daily/weekly **goal + progress** (pairs with reminders) | Pro | v1.2 |
| **Achievements / badges** (see §3.6 — some Free, some Pro) | Free + Pro | v1.2 (with Levels in v2) |
| Pro billing: **monthly + yearly + lifetime** (all three) | Pro | v1 |
| Full categorized **Store** (shapes · elements · app themes · packs · soundscapes) | à la carte + Plus | v1.2 |
| Cloud **sync** + cross-device | Plus | v1.2 |
| Seasonal/festival drops, "whole store included" | Plus | v1.2 |
| **Training modules**, **PC/Web blocking**, PC/Web apps | Plus | v2 |
| Daily tips/quotes (bundled, in-app; no "come back" nudges) | Pro | v1.2 |
| Reminders/scheduling (local notifications) | Pro | v1.2 |

**Pricing (rough — finalize with market research + India ₹ tiers).**
**Pro** = monthly / yearly / lifetime. **Plus** = monthly / yearly (no lifetime).
The paywall must present them as two clear tiers (a simple comparison), and
**Plus must price above Pro at every interval** (Plus ⊇ Pro):
- À la carte themes **$1.99–2.99** (complete packs ~$3.99–4.99)
- **Pro:** monthly ~**$1.99** · yearly ~**$9.99** · lifetime ~**$24.99** — **all
  three ship in v1.** Lifetime ≈ **3× yearly** (market-normal is 3–5×; the earlier
  2× was too cheap).
- **Plus:** monthly ~**$4.99** · yearly ~**$29.99** (v1.2)
- The ladder keeps each Plus interval clearly above the matching Pro interval, and
  yearly ≈ 40–50% off monthly. **Show monthly prominently** — productivity buyers
  skew monthly (77% of category revenue), unlike fitness/wellness.
- **India ₹ tiers:** set empirically in Play Console (no reliable PPP data — open).

### Research-validated refinements (2026-06-19)
Backed by the two research docs — `docs/references/monetization-research-2026-06-19.md`
and `…/insights-analytics-research-2026-06-19.md`:
- **Plus is a strict superset of Pro** (includes all Pro features). The paywall
  must present two clear doors — *"own Pro"* (one-time-able) vs *"Plus membership"*
  (ongoing services) — so two subscriptions never read as "buy twice." This is the
  single most important clarity fix.
- **Never hard-paywall the free core loop.** Hard paywalls convert ~5× early but
  one-year retention converges (one case: +75% LTV after removing the paywall).
  Freemium is correct for LTV here.
- **No-ads / easy-cancel / privacy-first is a marketed differentiator** (~76% of
  subscription apps use ≥1 dark pattern — FTC 2024).
- **Trial:** optional even in v1 now that Pro has subscriptions — but the **$1.99
  monthly is itself the low-barrier "try it,"** so a trial isn't required. If
  added, use a **3-day / reverse trial** (daily-use cadence), no-card to stay
  respectful. Plus (v1.2) is the more natural place for a trial. Keep cosmetics
  **earned-or-bought; no loot-box/gacha.**

---

## 3. v1 scope — what we build & ship

v1 monetization is intentionally lean: **Pro (monthly/yearly/lifetime) + à la
carte themes**, no full store UI, no Plus yet, no gating of anything except the
new detailed-Insights split.

### 3.1 Billing & entitlements (RevenueCat over Play Billing)
- Use **RevenueCat** over Play Billing — clean **purchase + restore +
  entitlement** handling across subscriptions *and* one-time products, and zero
  rework when Plus lands in v1.2.
- **Products (v1):**
  - **Pro subscriptions:** `pro.monthly`, `pro.yearly` (auto-renewing) →
    grant the **`pro`** entitlement while active.
  - **Pro lifetime:** `pro.lifetime` (non-consumable) → grants `pro` permanently.
  - one **per à la carte theme** (non-consumable), e.g. `theme.obsidian`,
    `theme.sage`, `theme.rose` → grants ownership of that theme.
  - Configure as a RevenueCat **offering** with the three Pro packages so the
    paywall shows monthly/yearly/lifetime side by side (monthly visible, yearly
    as the discounted anchor, lifetime as "own it").
- **Entitlement model (on-device, from RevenueCat customer info, cached offline):**
  - `pro` = an active `pro.monthly`/`pro.yearly` subscription **OR** `pro.lifetime`.
  - A theme is **owned** if `pro` is active **OR** its `theme.<id>` is purchased.
  - `Sand` (default) is always owned/free.
- **Restore purchases** — explicit button (Settings + paywall). Required by stores.
- **Offline:** RevenueCat caches entitlements; the app reads the cache and never
  blocks the free experience if the network/billing is unavailable.
- A single `entitlementsProvider` (Riverpod) exposes `{ pro: bool,
  ownedThemeIds: Set<String> }`; all gating reads from it. This is the contract
  every future paid feature gates against.

### 3.2 Color themes (the v1 cosmetics)
Built on the **existing** token + skin architecture (design-language §2, §8) —
no new hourglass *silhouette* (that's the v1.2 store). Each theme is a complete
**color look**:
- A `HgTheme` (light + dark `HgTokens`) — the app palette. (`HgThemes.all`
  already exists; today only `Sand`.)
- A matching **hourglass skin** (`HourglassSkin` colors: sand/grain/glass) per
  theme + brightness.
- **Wiring change:** today `HourglassView` picks its skin by brightness
  (`classic`/`classicLight`), not by theme. Add the active theme's skin to
  `HgTheme` and expose it via a provider (e.g. `activeSkinProvider`); the
  `HourglassView` callers (Home, Session, Completion, Onboarding) pass it. Falls
  back to Sand's skin. Contained, follows the "skins are data" design rule.
- **Selection/ownership:** `ThemeController` already persists `themeId`. Extend so
  a theme can be **selected only if owned**; selecting a locked theme opens the
  purchase flow. `ThemeMode` (light/dark/system) stays orthogonal.
- **Catalog for v1:** a small curated set of color looks (e.g. **Obsidian,
  Sage, Rose** — final palettes are a design task, see §5). Each is à la carte;
  all current ones are bundled into Pro.

### 3.3 Themes screen (browse / buy / apply / restore)
A simple, calm **Themes** screen (not the full categorized store):
- Lists looks as preview tiles (the hourglass + a palette swatch), marked
  Owned / price / "in Pro".
- Tap → preview + **Apply** (if owned) or **Buy** (purchase flow) or **Get Pro**.
- **Restore purchases** action.
- **Entry point:** a "Themes" row in Settings (and/or Profile) — decide during
  build; Settings is the natural home.

### 3.4 Detailed + enhanced Insights (the Pro anchor) — LOCKED 2026-06-19
Informed by `docs/references/insights-analytics-research-2026-06-19.md`.
- **Free Insights** = Records + consistency heatmap.
- **Pro Insights (v1)** = the **current** depth (Week/Month/All toggle,
  focus-over-time `BarReadoutChart`, when-you-focus time-of-day + day-of-week,
  by-mode donut, period comparison, personalized copy) **+ these locked additions:**
  1. **Focus Score trend** over time (the hero number's trajectory).
  2. **Focus Stamina growth** (sustainable block length climbing) — *unique to Sustain*.
  3. **Peak focus window** recommendation ("you focus best 9–11am").
  4. **Completion / follow-through rate** (+ trend) — controllable, honest.
  5. **Personal-bests timeline** (records over time).
  6. **CSV / data export.**
  All six run on data we already record (mode, planned vs actual duration, start
  time, completion/give-up). The detailed-Insights design lives in its own short
  spec (see §5).
- **Deferred to v1.2:** daily/weekly **goal + progress** (pairs with reminders) —
  needs a goal setting; **intention breakdown** — needs intention tagging.
- **Gating UX:** the free user sees Records + heatmap, then a calm, honest
  upsell panel where the depth would be ("See your full focus story with Pro"),
  never a nag. No data is hidden that the free tier ever had.

### 3.5 Session / break sound cues (free)
- Short, premium cues on **session start, session end, break start, break end**.
- Local audio via **`just_audio`** (pre-chosen dep); bundled **CC0** assets with
  `assets/audio/CREDITS.md` (sourcing is a real task — see §5).
- A **Settings toggle** (sounds on/off). Respect silent mode sensibly.
- These are *ritual feedback*, free — distinct from premium **soundscapes**
  (ambient focus audio), which are v1.2 Pro.

### 3.6 Achievements / badges (NOT v1 — v1.2, design with Levels) — recorded
A milestone/badge layer (research-backed: Insight Timer stars, Headspace medals).
**Own design pass — build with the V2 Levels/progression so they don't duplicate
the Focus-Score-100 "level up."** Seed ideas from founder (2026-06-19):
- **Firsts:** complete one full session in *each* mode (Flow, Pomodoro, Custom).
- **Score/ability:** reach a Focus Score / average milestone.
- **Consistency:** hit daily-streak milestones (7, 30, 100…).
- "More and more" achievements over time; an achievements grid in Profile.
- **Some Free, some Pro** (where relevant/possible) — exact split decided in its
  own design. Honesty rule: celebrate real accomplishment; **no manufactured
  streak guilt / loss-aversion pressure** (per the insights research anti-patterns).

---

## 4. v1.2+ (recorded, not built now)
- **v1.2:** full categorized **Store** (hourglass shapes · elements · app themes ·
  complete packs · soundscapes); **Pro monthly/yearly**; **Plus** subscription
  launches (cloud **sync** + cross-device, whole store + seasonal drops); Pro
  gains todo/task library, widgets, share cards, break activities, daily
  tips/quotes (bundled, in-app), reminders (local notifications), more themes +
  soundscapes; the cloud backend (its real job = sync, **not** quotes).
- **v2:** **training modules** (ongoing curriculum → Plus), **PC/Web blocking**,
  PC/Web apps.
- **Never:** ads; "come back" engagement push notifications.

---

## 5. Dependent designs & open items (decomposition)
This spec is the money model + v1 paid plumbing. These are tracked separately so
v1 stays shippable:
- **Enhanced Pro Insights analytics** — a short follow-on design pass (pick the
  §3.4 enhancements, design charts/calc; reuse the `AnalyticsCalculator` pattern).
  Needed for v1 (the Pro anchor must feel worth it).
- **Color-theme palettes** — design the actual looks (Obsidian/Sage/Rose…): the
  `HgTokens` light+dark + matching `HourglassSkin` for each. A focused design +
  on-device tuning task (the hourglass is the hero — colors must look premium).
- **CC0 audio sourcing** — session/break cues now; soundscapes for v1.2. CREDITS.
- **Pricing** — final tiers per market (incl. ₹).
- **The v1.2 cosmetic Store engine** (shapes/elements/packs) — its own spec.
- **Launch-checklist interaction:** adding IAP means the Play **Data Safety** form
  + a **privacy policy** must disclose purchase processing (Google Play +
  RevenueCat handle purchase tokens + an anonymous app-user id). This is *billing*
  data, not behavior tracking — the "no analytics/telemetry" story still holds,
  but the disclosure is required. (Also still owed before publish: real release
  keystore, R8 keep-rules so the release build succeeds, `allowBackup=false`.)

---

## 6. Testing
- **Entitlements (pure/unit):** `pro` true iff `pro.lifetime` owned; theme owned
  iff `pro` OR `theme.<id>` owned; Sand always owned. Mock RevenueCat customer
  info. Offline cache path returns last-known entitlements.
- **Theme selection:** can select owned themes; selecting a locked theme triggers
  purchase, not apply; `themeId` persists; active skin follows the theme.
- **Insights gating:** free shows Records + heatmap + upsell; `pro` shows the full
  set. No crash when entitlements are loading.
- **Sound cues:** play on each ritual transition; toggle silences them; no audio
  in tests (inject a no-op player).
- **Widget tests** for the Themes screen (owned/locked/Pro states, restore).
- Run serial: `flutter test --concurrency=1`; `flutter analyze` clean. Mock all
  billing — no real network in tests.

---

## 7. Build order (for the planning phase)
1. **Entitlement engine** (RevenueCat + `entitlementsProvider` + restore) — the
   contract everything else gates against.
2. **Color-theme system** (HgTheme→skin wiring + ownership-gated selection) +
   **Themes screen** + theme products.
3. **Insights free/Pro split** + the chosen **enhanced analytics** (after the
   short Insights design pass).
4. **Session/break sound cues** (independent; can land any time).
5. **Launch hardening** (release build/R8, keystore, allowBackup, privacy policy,
   Data Safety) — gates publish.

Each becomes its own plan; the enhanced-Insights analytics + the theme palettes
get a quick design pass first.
