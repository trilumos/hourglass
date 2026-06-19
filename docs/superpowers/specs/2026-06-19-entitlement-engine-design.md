# Entitlement Engine + Paywall (v1) — Design Spec (Sustain)

> **Status:** scope LOCKED 2026-06-19 (founder approved the design in brainstorm).
> Build order item #1 from the monetization spec
> (`docs/superpowers/specs/2026-06-19-monetization-and-v1-paid-tier-design.md` §7):
> the **entitlement contract** every paid feature gates against, plus the custom
> paywall, built **key-less** now (everyone Free, dev-unlock for on-device
> preview) and wired to real RevenueCat products later with **zero code changes**.
>
> **Sensitivity note (founder):** billing is sensitive — legal, financial, and
> store-policy. This design grants Pro **only** from Google-verified entitlement
> state (never client optimism), shows **store-provided localized prices** (never
> hardcoded), handles every purchase/restore failure path, and bakes in the
> required Play-policy + consumer-law obligations (Restore, Manage/cancel,
> auto-renewal disclosure, Data-Safety disclosure).

---

## 1. How payments actually work (plain language)
RevenueCat does **not** replace Google Play Billing — it sits on top of it.
1. User taps **Buy** on a plan → app asks RevenueCat to purchase that package.
2. RevenueCat calls **Google Play Billing** → the **native Google Play purchase
   sheet** appears.
3. The user pays with their Google Play account (card, UPI, Play balance…) —
   **Google processes the payment**; we and RevenueCat never see card data.
4. Google returns the purchase; RevenueCat verifies the token server-side and
   activates the **`pro` entitlement**.
5. `entitlementsProvider` sees `pro = true` and the app unlocks instantly.

RevenueCat earns its place by handling token verification, entitlement on/off
state, **Restore** (reinstalls/new devices), and subscriptions + one-time buys
uniformly — and by making iOS/Plus zero-rework later.

---

## 2. Scope of THIS build
Engine + paywall + gating contract. **In:**
- `Entitlements` model + pure derivation function.
- `BillingService` interface + `RevenueCatBillingService` + `FakeBillingService`.
- `entitlementsProvider` (default-Free, reactive, offline-safe).
- Custom **paywall** screen + **purchase-success** screen.
- Reusable `ProGate` widget, wrapping the two **existing** Pro surfaces:
  the Insights **depth band** (`_DepthBand`) and the **"Start again"** action.
- Settings rows: **Sustain Pro** (→ paywall), **Restore purchases**, and a
  **debug-only** "Dev: unlock Pro".
- Profile **PRO** tag below the avatar.

**Out (separate later builds):** color themes + Themes screen (the theme-ownership
*logic* is in the model, but no theme is gated yet — no theme products exist);
sound cues; launch hardening (R8 keep-rules, privacy policy, Data Safety form).

---

## 3. Entitlement model (pure — the fully-tested core)
`lib/domain/entitlements.dart`:
```dart
@immutable
class Entitlements {
  final bool pro;
  final Set<String> ownedThemeIds; // always contains 'sand'
  const Entitlements({required this.pro, required this.ownedThemeIds});
  static const free = Entitlements(pro: false, ownedThemeIds: {'sand'});
  bool ownsTheme(String id) => ownedThemeIds.contains(id);
}
```
Pure derivation (unit-tested with plain sets — no RevenueCat objects):
```dart
Entitlements entitlementsFrom({
  required Set<String> activeEntitlementIds, // RC customerInfo.entitlements.active.keys
  required Set<String> catalogThemeIds,      // our themes minus 'sand'
}) {
  final pro = activeEntitlementIds.contains(kProEntitlement); // 'pro'
  final owned = <String>{'sand'};
  for (final id in catalogThemeIds) {
    if (activeEntitlementIds.contains('theme_$id')) owned.add(id);
  }
  if (pro) owned.addAll(catalogThemeIds); // Pro includes all current themes
  return Entitlements(pro: pro, ownedThemeIds: owned);
}
```
- **Entitlement identifiers (RevenueCat):** `pro` (attached in the dashboard to
  `pro.monthly`, `pro.yearly`, `pro.lifetime`), and `theme_<id>` per theme.
- "lifetime vs subscription" is invisible here — RevenueCat reports one `pro`
  entitlement active for any of the three. Lifetime simply never expires.
- "Pro unlocks every theme" is computed in **our** code from the catalog, so the
  dashboard stays simple (one product → one entitlement).

---

## 4. Billing abstraction (RevenueCat kept at the edge)
`lib/billing/billing_service.dart` — the interface the app depends on:
```dart
abstract class BillingService {
  Future<void> init();                       // safe to call always; never throws
  Stream<Entitlements> entitlements();       // live; seeded from cache on init
  Entitlements get current;                  // latest known (sync; defaults free)
  Future<ProOffering?> proOffering();        // null when unavailable
  Future<PurchaseOutcome> purchase(ProPackage pkg);
  Future<RestoreOutcome> restore();
}
```
Supporting value types (our own, not RevenueCat's): `ProOffering` (the list of
`ProPackage`s), `ProPackage { ProPlan plan, String priceString, String? period }`
where `ProPlan = { monthly, yearly, lifetime }`, and result enums
`PurchaseOutcome { success, cancelled, pending, alreadyOwned, error }`,
`RestoreOutcome { restoredPro, nothingToRestore, error }`.

- **`RevenueCatBillingService`** — the **only** file importing `purchases_flutter`.
  Configures RevenueCat with the key, registers an update listener, maps
  `CustomerInfo` → `activeEntitlementIds` → `entitlementsFrom(...)`, and maps the
  default offering's packages (by `PackageType.monthly/annual/lifetime`) →
  `ProPackage` using `storeProduct.priceString` (live, localized).
- **`FakeBillingService`** — tests + the current key-less app. Holds an in-memory
  `Entitlements`, lets tests script purchase/restore outcomes, emits on changes.
- Swapping real↔fake is a single Riverpod provider override; the rest of the app
  only ever sees our types.

---

## 5. Provider layer + offline / default behavior
`lib/app/billing_providers.dart`:
- `billingServiceProvider` → the chosen `BillingService` (Fake until a key is set;
  see §8). `init()` is awaited at app start (in `main`), guarded so failure is
  non-fatal.
- `entitlementsProvider` → exposes the **current** `Entitlements`, backed by the
  service's stream, **defaulting to `Entitlements.free`** until the first value
  and whenever billing is unavailable. Implemented so reads are synchronous for
  gating widgets (a `Notifier<Entitlements>` seeded `free`, updated by the
  stream). Updates reactively: the moment RevenueCat confirms a purchase (or an
  expiry/refund), gated UI re-renders.
- **Offline:** RevenueCat caches the last-known `CustomerInfo`; the app reads it.
  A brand-new install offline shows Free until it can reach Google once. The free
  experience is **never** blocked by network/billing state.

---

## 6. Custom paywall — "Sustain Pro" (high-craft UI)
Reached from: the Insights upsell panel, the Settings "Sustain Pro" row, and any
locked surface. Built with the **impeccable** skill during implementation to a
premium bar; honors `docs/design-language.md` (Geist, Sand tokens, hourglass
motif, calm/warm/exact, accent as punctuation, no fake claims).

**Layout / UX intent:**
- **Hero:** a quiet premium framing — the hourglass motif + a short, honest
  headline ("Train your focus, deeper") and one-line subhead. Calm, not shouty.
- **Value props:** a concise, benefit-led list of what Pro unlocks — the full
  Insights depth (Focus Score trend, Stamina growth, peak window, follow-through,
  personal bests, CSV export), every color theme, "Start again" session reuse,
  and "every Pro feature we add." Honest, specific, no invented stats.
- **Plan selector:** three options from the live offering — **Monthly**,
  **Yearly** (visually emphasized as the value anchor, "best value", with a
  computed "save N%" derived from the live monthly vs yearly prices, never
  hardcoded), and **Lifetime** ("own it forever", one-time). A single selected
  plan with a clear primary CTA (pill, accent) reading e.g. "Start Monthly" /
  "Get Lifetime". Prices and currency come **entirely from the store**.
- **Required fine print** under the CTA: the selected plan's price + period +
  **"auto-renews until cancelled"** (subscriptions only) + a **Manage/cancel**
  link, and **Restore purchases**. Lifetime shows "one-time payment, yours
  forever" — no renewal text.
- **States:** prices loading → calm skeleton; prices unavailable (offline /
  key-less) → honest line + Restore still available, no crash; **already Pro** →
  a "You have Pro" state (no buy buttons, with Manage link).
- **No dark patterns:** no countdown timers, no fake scarcity, easy dismiss,
  cancel made obvious (a deliberate brand differentiator).

**Purchase flow & outcomes (every path handled):**
- **success** → push the **Pro success screen** (§7).
- **cancelled** → silent return to the paywall (cancelling is not an error).
- **pending/deferred** (e.g. UPI, slow card) → "Your purchase is processing —
  Pro unlocks as soon as it's confirmed." Nothing is granted; the entitlement
  flips later via the listener.
- **alreadyOwned** → treated as restore → success path.
- **error / declined / network** → a kind, plain message + retry; nothing granted.

**Manage/cancel** = deep link to the Play subscriptions page
(`https://play.google.com/store/account/subscriptions?...`). Required by Play +
consumer law and by our "easy cancel" promise.

---

## 7. Purchase-success screen → Home
`lib/ui/pro_success_screen.dart`: a serene, calm-celebratory confirmation
("You're Pro" / "Welcome to Sustain Pro") in the **completion-screen register**
(design-language §13 — gentle haptic, never confetti), a one-line thank-you, and
a single **Continue** button that returns to **Home**, clearing the paywall and
its origin from the navigation stack (`Navigator.pushAndRemoveUntil` to the
Home/`RootGate`). No surprise auto-navigation — the user taps Continue. Because
entitlements are reactive, any gated surface the user revisits is already
unlocked.

---

## 8. Key-less today + dev unlock (release-safe)
- **No SDK key:** `RevenueCatBillingService.init()` detects the absent/empty key
  and **skips RevenueCat entirely** (wrapped in try/catch so a missing/invalid
  key can never crash launch); the app uses `FakeBillingService` → everyone Free,
  Buy is inert, the paywall shows its "prices unavailable" state.
- The key lives in one constant/config (`kRevenueCatAndroidKey`, empty for now).
  Filling it in + creating products is the only step to go live (§12).
- **Dev unlock:** a `devProUnlockProvider` (bool) and a Settings row **"Dev:
  unlock Pro"** that exist **only under `kDebugMode`**. `entitlementsProvider`
  applies the override **only when `kDebugMode` is true**, so it is impossible in
  a release build and never touches real purchase state. **Default off**, so a
  debug build behaves like a real Free user (you see the upsells); flip it on to
  preview Pro content/the PRO tag.

---

## 9. ProGate + the two consumers
`lib/ui/widgets/pro_gate.dart`: `ProGate({required Widget child, required Widget
upsell})` → if `entitlementsProvider.pro` shows `child`, else `upsell`. Treats
unknown/loading as **not Pro** (safe default); a real Pro user flips to `child`
within a frame as the cached entitlement loads.
- **Insights:** wrap the existing `_DepthBand` in `ProGate`; the upsell is the
  calm "See your full focus story with Pro" panel (→ paywall). Records + heatmap
  remain free above it. No data a free user ever had is hidden.
- **"Start again":** the reuse-config action stays **visible** for everyone
  (discoverable), but for a free user tapping it **opens the paywall** instead of
  replaying the session; for a Pro user it replays as today. (Visible-but-routes-
  to-paywall, not hidden — matches the stamina-chip discoverability decision and
  the reuse-config spec's "wrap the entry in ProGate with an upsell".)

---

## 10. Profile PRO tag
In the Profile hub, render a small **PRO** badge directly below the avatar when
`entitlementsProvider.pro` is true (accent / accent-muted pill, Geist overline,
on-brand). Hidden for free users. Reads the provider; no new state.

---

## 11. Edge cases (explicitly handled)
Cancel; pending/deferred; declined/error; network loss mid-purchase; restore with
nothing to restore; offline launch; entitlements still loading; **subscription
lapse/expiry** (RevenueCat flips `pro` off → gated content returns to the upsell,
no crash); **refund/chargeback** (same path); reinstall / new device (Restore);
**already Pro** (no double-buy — paywall shows the owned state). No path grants
Pro from client optimism — only from Google-verified entitlement state. Dev
unlock is debug-only and separate from real state.

---

## 12. Legal / compliance (built in, not bolted on)
- **Play Billing** for all in-app digital goods (✓ via RevenueCat) — required by
  policy; using any other processor for digital goods would violate it.
- **Restore purchases** provided (Settings + paywall) — required for
  non-consumables/subscriptions.
- **Manage/cancel** access (Play subscriptions deep link) — required + our "easy
  cancel" promise.
- **Live localized prices** from the store, with **auto-renewal disclosure** near
  the CTA — required by Play and consumer-protection law (US/EU/India).
- **No payment data** stored by us; Google handles payment; RevenueCat stores only
  an anonymous app-user id + the purchase token.
- **Privacy policy + Play Data Safety** must disclose purchase processing — this
  is *billing* data, not behavior tracking, so the "no analytics/telemetry" story
  still holds, but the disclosure is mandatory. **Carried to launch hardening.**
- **R8/ProGuard keep-rules** for RevenueCat for the release build. **Carried to
  launch hardening.**

---

## 13. Dependencies, init, compatibility
- Add **`purchases_flutter`** (RevenueCat Flutter SDK). It bundles the Google Play
  Billing dependency and the `com.android.vending.BILLING` permission.
- Configure once in `main()` behind the key guard, before `runApp`, awaiting
  `billingServiceProvider.init()` (non-fatal on failure).
- Verify Android `minSdkVersion` meets the SDK's requirement; bump if needed
  (RevenueCat current line needs a modern minSdk; confirm against
  `android/app/build.gradle`).
- Offline-first behavior unchanged.

---

## 14. Testing (all billing mocked; no real network)
- **Pure (`entitlements_test.dart`):** `pro` true only with the `pro` entitlement;
  theme owned via `theme_<id>` OR pro; `sand` always owned; empty → `free`;
  combinations.
- **Provider:** defaults `free`; updates on stream emit; stays `free` on
  init/billing failure; dev-unlock applies only in debug (guarded).
- **ProGate (widget):** Pro shows child; free shows upsell; loading shows upsell.
- **Paywall (widget, FakeBillingService):** renders the three packages with
  prices; success → success screen; cancel → silent; pending → processing note;
  error → message; "prices unavailable" state; already-Pro state.
- **Restore:** restoredPro → unlock; nothingToRestore → calm note.
- **Profile:** PRO tag shows iff `pro`.
- Serial: `flutter test --concurrency=1`; `flutter analyze` clean.

---

## 15. Founder setup later (to actually sell — no code changes)
In **Play Console**: create a subscription with **monthly** and **yearly** base
plans, a **lifetime** non-consumable, and the **theme** products (later); add
**license testers**. In the **RevenueCat dashboard**: create the **`pro`**
entitlement (attach the three Pro products), the per-theme entitlements (later),
and an **offering** with the monthly/yearly/lifetime packages. Give me the
**public Android SDK key** → it goes in `kRevenueCatAndroidKey`. Done.

---

## 16. Files
**Create:** `lib/domain/entitlements.dart`, `lib/billing/billing_service.dart`,
`lib/billing/revenuecat_billing_service.dart`, `lib/billing/fake_billing_service.dart`,
`lib/app/billing_providers.dart`, `lib/ui/paywall_screen.dart`,
`lib/ui/pro_success_screen.dart`, `lib/ui/widgets/pro_gate.dart`; tests for each.
**Modify:** `pubspec.yaml` (+`purchases_flutter`), `lib/main.dart` (init),
`lib/ui/insights_screen.dart` (wrap `_DepthBand`), `lib/ui/start_again.dart`
(gate), `lib/ui/settings_screen.dart` (Pro + Restore + debug dev-unlock rows),
`lib/ui/profile_screen.dart` (PRO tag), `android/app/build.gradle` (minSdk if
needed).

---

## 17. Build order (for the plan)
1. Pure `Entitlements` + mapper (TDD).
2. `BillingService` interface + `FakeBillingService` + `entitlementsProvider`
   (default-free, reactive) + tests.
3. `RevenueCatBillingService` (key-guarded) + `purchases_flutter` + `main` init.
4. `ProGate` + wrap Insights `_DepthBand` + "Start again"; Insights upsell panel.
5. Paywall screen (impeccable) + purchase outcomes + Pro success screen.
6. Settings rows (Pro / Restore / debug dev-unlock) + Profile PRO tag.
7. Full test pass; analyze; deploy; commit.
