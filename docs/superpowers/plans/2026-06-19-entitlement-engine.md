# Entitlement Engine + Paywall Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Pro entitlement contract (RevenueCat over Google Play Billing, key-less for now), a custom paywall + success screen, a reusable `ProGate`, and wire the two existing Pro surfaces (Insights depth band, "Start again") + Profile PRO tag.

**Architecture:** A pure `Entitlements` model derived by one tested function; a `BillingService` interface with a real `RevenueCatBillingService` (the only file importing the SDK) and a `FakeBillingService` (tests + key-less dev); a default-Free, reactive `entitlementsProvider`; gating via `ProGate`. Pro is granted only from Google-verified entitlement state; a `kDebugMode`-only dev-unlock previews Pro on device.

**Tech Stack:** Flutter, Riverpod 3.x (`Notifier`/`NotifierProvider`), `purchases_flutter` (RevenueCat), `url_launcher` (already present, for the manage-subscription link).

## Global Constraints

- Tests run serial: `flutter test --concurrency=1`. `flutter analyze` must be clean.
- Riverpod 3.x: use `Notifier`/`NotifierProvider` (no `StateProvider`).
- Colors via `context.hg.<token>` and `.withValues(alpha:)`; non-color tokens via `HgSpacing`/`HgRadius`/`HgMotion`/`HgFont`. No hardcoded styling.
- Copy: warm, honest, NO fabricated stats, NO em dashes (use commas/periods/parentheses).
- Prices are NEVER hardcoded — always the store's localized `priceString`.
- Pro is granted ONLY from verified entitlement state. The only client override is the dev-unlock, which exists ONLY under `kDebugMode`.
- The free experience must never be blocked by billing/network state (default `Entitlements.free`).
- Flutter at `D:\Dev\tools\flutter`; serial tests; build/deploy is the founder's call (don't auto-build unless asked).
- RevenueCat entitlement id: `pro`. Per-theme entitlement id: `theme_<id>`.

---

### Task 1: Entitlements model + pure derivation

**Files:**
- Create: `lib/billing/billing_config.dart`
- Create: `lib/domain/entitlements.dart`
- Test: `test/domain/entitlements_test.dart`

**Interfaces:**
- Produces: `Entitlements { bool pro; Set<String> ownedThemeIds; bool ownsTheme(String); Entitlements copyWith(...); static const free }`; `Entitlements entitlementsFrom({required Set<String> activeEntitlementIds, required Set<String> catalogThemeIds})`; consts `kRevenueCatAndroidKey`, `kProEntitlement`, `kCatalogThemeIds`.

- [ ] **Step 1: Write `billing_config.dart`** (no test; consumed by later tasks)

```dart
/// Billing configuration. The Android RevenueCat **public** SDK key — empty
/// means key-less: the app runs Free for everyone (see createBillingService).
/// Fill this in (and create the Play Console + RevenueCat products) to go live;
/// no other code changes are needed.
const String kRevenueCatAndroidKey = '';

/// The single RevenueCat entitlement that means "Pro" (attached in the dashboard
/// to pro.monthly / pro.yearly / pro.lifetime).
const String kProEntitlement = 'pro';

/// Purchasable theme ids (the app catalog minus the always-free 'sand'). Empty
/// until the themes build adds products; Pro grants all of these.
const Set<String> kCatalogThemeIds = <String>{};
```

- [ ] **Step 2: Write the failing test** `test/domain/entitlements_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/entitlements.dart';

void main() {
  group('entitlementsFrom', () {
    test('no active entitlements -> free, only sand owned', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {}, catalogThemeIds: const {'obsidian'});
      expect(e.pro, isFalse);
      expect(e.ownedThemeIds, {'sand'});
      expect(e.ownsTheme('sand'), isTrue);
      expect(e.ownsTheme('obsidian'), isFalse);
    });

    test('pro entitlement -> pro true and owns every catalog theme', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'pro'},
          catalogThemeIds: const {'obsidian', 'sage'});
      expect(e.pro, isTrue);
      expect(e.ownedThemeIds, {'sand', 'obsidian', 'sage'});
    });

    test('a single theme entitlement -> owns that theme, not pro', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'theme_obsidian'},
          catalogThemeIds: const {'obsidian', 'sage'});
      expect(e.pro, isFalse);
      expect(e.ownedThemeIds, {'sand', 'obsidian'});
      expect(e.ownsTheme('sage'), isFalse);
    });

    test('free constant owns only sand', () {
      expect(Entitlements.free.pro, isFalse);
      expect(Entitlements.free.ownedThemeIds, {'sand'});
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test --concurrency=1 test/domain/entitlements_test.dart`
Expected: FAIL (entitlements.dart / entitlementsFrom not defined).

- [ ] **Step 4: Write `lib/domain/entitlements.dart`**

```dart
import 'package:flutter/foundation.dart';

import '../billing/billing_config.dart';

/// What the user has unlocked. Derived only from verified entitlement state
/// (see [entitlementsFrom]); never set optimistically. Always owns 'sand'.
@immutable
class Entitlements {
  final bool pro;
  final Set<String> ownedThemeIds;
  const Entitlements({required this.pro, required this.ownedThemeIds});

  static const free = Entitlements(pro: false, ownedThemeIds: {'sand'});

  bool ownsTheme(String id) => ownedThemeIds.contains(id);

  Entitlements copyWith({bool? pro, Set<String>? ownedThemeIds}) => Entitlements(
        pro: pro ?? this.pro,
        ownedThemeIds: ownedThemeIds ?? this.ownedThemeIds,
      );

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      other.pro == pro &&
      setEquals(other.ownedThemeIds, ownedThemeIds);

  @override
  int get hashCode => Object.hash(pro, Object.hashAllUnordered(ownedThemeIds));
}

/// The single source of truth for entitlement rules. Pure: plain sets in, an
/// [Entitlements] out. [activeEntitlementIds] are RevenueCat's active entitlement
/// identifiers; [catalogThemeIds] is the app's purchasable theme catalog.
Entitlements entitlementsFrom({
  required Set<String> activeEntitlementIds,
  required Set<String> catalogThemeIds,
}) {
  final pro = activeEntitlementIds.contains(kProEntitlement);
  final owned = <String>{'sand'};
  for (final id in catalogThemeIds) {
    if (activeEntitlementIds.contains('theme_$id')) owned.add(id);
  }
  if (pro) owned.addAll(catalogThemeIds);
  return Entitlements(pro: pro, ownedThemeIds: owned);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test --concurrency=1 test/domain/entitlements_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/billing/billing_config.dart lib/domain/entitlements.dart test/domain/entitlements_test.dart
git commit -m "feat(billing): pure Entitlements model + derivation"
```

---

### Task 2: BillingService interface + value types + FakeBillingService

**Files:**
- Create: `lib/billing/billing_service.dart`
- Create: `lib/billing/fake_billing_service.dart`
- Test: `test/billing/fake_billing_service_test.dart`

**Interfaces:**
- Consumes: `Entitlements` (Task 1).
- Produces: `abstract class BillingService { Future<void> init(); Stream<Entitlements> entitlements(); Entitlements get current; Future<ProOffering?> proOffering(); Future<PurchaseOutcome> purchase(ProPackage); Future<RestoreOutcome> restore(); void dispose(); }`; enums `ProPlan{monthly,yearly,lifetime}`, `PurchaseOutcome{success,cancelled,pending,alreadyOwned,error}`, `RestoreOutcome{restoredPro,nothingToRestore,error}`; classes `ProPackage{ProPlan plan; String priceString; double priceAmount; String currencyCode; Object raw}`, `ProOffering{List<ProPackage> packages; ProPackage? byPlan(ProPlan)}`; `class FakeBillingService implements BillingService` with settable `offering`, `nextPurchase`, `nextRestore`, and ctor `initial`.

- [ ] **Step 1: Write `lib/billing/billing_service.dart`** (interface + value types; no test of its own)

```dart
import 'entitlements_export.dart';

/// Which Pro plan a package represents.
enum ProPlan { monthly, yearly, lifetime }

/// The result of a purchase attempt.
enum PurchaseOutcome { success, cancelled, pending, alreadyOwned, error }

/// The result of a restore attempt.
enum RestoreOutcome { restoredPro, nothingToRestore, error }

/// A purchasable Pro package, normalized away from RevenueCat's types. [raw]
/// holds the underlying store package the real service needs to purchase.
class ProPackage {
  final ProPlan plan;
  final String priceString; // localized, store-formatted (e.g. "₹169.00")
  final double priceAmount; // numeric, for the "save %" calc only
  final String currencyCode;
  final Object raw;
  const ProPackage({
    required this.plan,
    required this.priceString,
    required this.priceAmount,
    required this.currencyCode,
    required this.raw,
  });
}

/// The Pro offering = the packages to show on the paywall.
class ProOffering {
  final List<ProPackage> packages;
  const ProOffering(this.packages);
  ProPackage? byPlan(ProPlan plan) {
    for (final p in packages) {
      if (p.plan == plan) return p;
    }
    return null;
  }
}

/// The billing contract the app depends on. The only implementations are
/// [RevenueCatBillingService] (real) and FakeBillingService (tests + key-less).
abstract class BillingService {
  /// Safe to call always; must never throw (guard internally).
  Future<void> init();

  /// Live entitlement updates (emits on purchase, restore, expiry, refund).
  Stream<Entitlements> entitlements();

  /// The latest known entitlements (synchronous; defaults to free).
  Entitlements get current;

  /// The Pro packages to show, or null when unavailable (offline / key-less).
  Future<ProOffering?> proOffering();

  Future<PurchaseOutcome> purchase(ProPackage package);
  Future<RestoreOutcome> restore();

  void dispose();
}
```

- [ ] **Step 2: Create `lib/billing/entitlements_export.dart`** (re-export so billing files import one path)

```dart
export '../domain/entitlements.dart';
```

- [ ] **Step 3: Write the failing test** `test/billing/fake_billing_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';

void main() {
  test('starts free and emits pro after a successful purchase', () async {
    final svc = FakeBillingService(nextPurchase: PurchaseOutcome.success);
    addTearDown(svc.dispose);
    expect(svc.current.pro, isFalse);

    final emitted = <Entitlements>[];
    final sub = svc.entitlements().listen(emitted.add);

    final pkg = const ProPackage(
        plan: ProPlan.monthly,
        priceString: r'$1.99',
        priceAmount: 1.99,
        currencyCode: 'USD',
        raw: 'x');
    final outcome = await svc.purchase(pkg);

    expect(outcome, PurchaseOutcome.success);
    expect(svc.current.pro, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(emitted.last.pro, isTrue);
    await sub.cancel();
  });

  test('cancelled purchase leaves entitlements free', () async {
    final svc = FakeBillingService(nextPurchase: PurchaseOutcome.cancelled);
    addTearDown(svc.dispose);
    final outcome = await svc.purchase(const ProPackage(
        plan: ProPlan.lifetime,
        priceString: r'$24.99',
        priceAmount: 24.99,
        currencyCode: 'USD',
        raw: 'x'));
    expect(outcome, PurchaseOutcome.cancelled);
    expect(svc.current.pro, isFalse);
  });

  test('restore with nothing returns nothingToRestore', () async {
    final svc = FakeBillingService(nextRestore: RestoreOutcome.nothingToRestore);
    addTearDown(svc.dispose);
    expect(await svc.restore(), RestoreOutcome.nothingToRestore);
    expect(svc.current.pro, isFalse);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test --concurrency=1 test/billing/fake_billing_service_test.dart`
Expected: FAIL (fake_billing_service.dart not defined).

- [ ] **Step 5: Write `lib/billing/fake_billing_service.dart`**

```dart
import 'dart:async';

import '../domain/entitlements.dart';
import 'billing_config.dart';
import 'billing_service.dart';

/// In-memory BillingService for tests and the key-less app. Scripts purchase /
/// restore outcomes and emits entitlement changes like the real one.
class FakeBillingService implements BillingService {
  Entitlements _current;
  ProOffering? offering;
  PurchaseOutcome nextPurchase;
  RestoreOutcome nextRestore;
  final _controller = StreamController<Entitlements>.broadcast();

  FakeBillingService({
    Entitlements initial = Entitlements.free,
    this.offering,
    this.nextPurchase = PurchaseOutcome.success,
    this.nextRestore = RestoreOutcome.nothingToRestore,
  }) : _current = initial;

  Entitlements get _pro =>
      entitlementsFrom(activeEntitlementIds: const {kProEntitlement}, catalogThemeIds: kCatalogThemeIds);

  @override
  Future<void> init() async {}

  @override
  Entitlements get current => _current;

  @override
  Stream<Entitlements> entitlements() => _controller.stream;

  @override
  Future<ProOffering?> proOffering() async => offering;

  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async {
    if (nextPurchase == PurchaseOutcome.success ||
        nextPurchase == PurchaseOutcome.alreadyOwned) {
      _current = _pro;
      _controller.add(_current);
    }
    return nextPurchase;
  }

  @override
  Future<RestoreOutcome> restore() async {
    if (nextRestore == RestoreOutcome.restoredPro) {
      _current = _pro;
      _controller.add(_current);
    }
    return nextRestore;
  }

  @override
  void dispose() => _controller.close();
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test --concurrency=1 test/billing/fake_billing_service_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/billing/billing_service.dart lib/billing/entitlements_export.dart lib/billing/fake_billing_service.dart test/billing/fake_billing_service_test.dart
git commit -m "feat(billing): BillingService interface + value types + fake"
```

---

### Task 3: Providers (default-free, reactive, debug-only dev unlock)

**Files:**
- Create: `lib/app/billing_providers.dart`
- Test: `test/app/billing_providers_test.dart`

**Interfaces:**
- Consumes: `BillingService` + `FakeBillingService` (Task 2), `Entitlements` (Task 1), `HgThemes` (`lib/app/tokens.dart`).
- Produces: `billingServiceProvider` (Provider<BillingService>, must be overridden); `createBillingService()` (picks fake/real by key); `rawEntitlementsProvider` (NotifierProvider<RawEntitlements, Entitlements>); `devProUnlockProvider` (NotifierProvider<DevProUnlock, bool>); `entitlementsProvider` (Provider<Entitlements>).

- [ ] **Step 1: Write the failing test** `test/app/billing_providers_test.dart`

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';

void main() {
  test('defaults to free, then reflects a billing emit', () async {
    final fake = FakeBillingService();
    final container = ProviderContainer(
        overrides: [billingServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    addTearDown(fake.dispose);

    expect(container.read(entitlementsProvider).pro, isFalse);

    // Simulate a confirmed purchase pushing through the stream.
    await fake.purchase(const ProPackage(
        plan: ProPlan.monthly,
        priceString: 'x',
        priceAmount: 1,
        currencyCode: 'USD',
        raw: 'x'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(entitlementsProvider).pro, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test --concurrency=1 test/app/billing_providers_test.dart`
Expected: FAIL (billing_providers.dart not defined).

- [ ] **Step 3: Write `lib/app/billing_providers.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../billing/billing_config.dart';
import '../billing/billing_service.dart';
import '../billing/fake_billing_service.dart';
import '../billing/revenuecat_billing_service.dart';
import '../domain/entitlements.dart';
import 'tokens.dart';

/// Picks the real service when a key is configured, else the fake (key-less:
/// everyone Free). Real purchases are inherently Play Console / RevenueCat work.
BillingService createBillingService() => kRevenueCatAndroidKey.isEmpty
    ? FakeBillingService()
    : RevenueCatBillingService(apiKey: kRevenueCatAndroidKey);

/// The billing service. Overridden in main() with the initialized instance and
/// in tests with a fake (mirrors sharedPrefsProvider).
final billingServiceProvider = Provider<BillingService>(
  (ref) => throw UnimplementedError('billingServiceProvider must be overridden'),
);

/// Real entitlements: seeded from the service's last-known value (free until
/// known) and updated by its stream. Never blocks the free experience.
class RawEntitlements extends Notifier<Entitlements> {
  @override
  Entitlements build() {
    final svc = ref.watch(billingServiceProvider);
    final sub = svc.entitlements().listen((e) => state = e);
    ref.onDispose(sub.cancel);
    return svc.current;
  }
}

final rawEntitlementsProvider =
    NotifierProvider<RawEntitlements, Entitlements>(RawEntitlements.new);

/// Debug-only Pro preview. Has no effect in release builds (see entitlements).
class DevProUnlock extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final devProUnlockProvider =
    NotifierProvider<DevProUnlock, bool>(DevProUnlock.new);

/// The entitlement contract every gate reads. In debug, the dev-unlock can force
/// Pro; in release that branch is compiled out (kDebugMode is a const false), so
/// the override can never affect a shipped build.
final entitlementsProvider = Provider<Entitlements>((ref) {
  final raw = ref.watch(rawEntitlementsProvider);
  if (kDebugMode && ref.watch(devProUnlockProvider)) {
    return Entitlements(
      pro: true,
      ownedThemeIds: {'sand', for (final t in HgThemes.all) t.id},
    );
  }
  return raw;
});
```

- [ ] **Step 4: Create a stub `lib/billing/revenuecat_billing_service.dart`** so this task compiles before Task 5 fills it in. (Task 5 replaces the body.)

```dart
import 'dart:async';

import '../domain/entitlements.dart';
import 'billing_service.dart';

/// Real RevenueCat-backed billing. Fully implemented in Task 5; this stub keeps
/// the app compiling and is never constructed while the key is empty.
class RevenueCatBillingService implements BillingService {
  final String apiKey;
  RevenueCatBillingService({required this.apiKey});

  final _controller = StreamController<Entitlements>.broadcast();
  Entitlements _current = Entitlements.free;

  @override
  Future<void> init() async {}
  @override
  Entitlements get current => _current;
  @override
  Stream<Entitlements> entitlements() => _controller.stream;
  @override
  Future<ProOffering?> proOffering() async => null;
  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async =>
      PurchaseOutcome.error;
  @override
  Future<RestoreOutcome> restore() async => RestoreOutcome.error;
  @override
  void dispose() => _controller.close();
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test --concurrency=1 test/app/billing_providers_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/app/billing_providers.dart lib/billing/revenuecat_billing_service.dart test/app/billing_providers_test.dart
git commit -m "feat(billing): entitlements providers (default-free, reactive, debug dev-unlock)"
```

---

### Task 4: ProGate + wire Insights depth band + gate "Start again"

**Files:**
- Create: `lib/ui/widgets/pro_gate.dart`
- Modify: `lib/ui/insights_screen.dart` (wrap `_DepthBand`)
- Modify: `lib/ui/start_again.dart` (gate the action)
- Test: `test/ui/pro_gate_test.dart`

**Interfaces:**
- Consumes: `entitlementsProvider` (Task 3).
- Produces: `class ProGate extends ConsumerWidget { ProGate({required Widget child, required Widget upsell}) }`; `class ProUpsell` (the calm Insights upsell panel); updated `startAgain(context, ref, record)` that routes free users to the paywall.

- [ ] **Step 1: Write the failing test** `test/ui/pro_gate_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:hourglass/ui/widgets/pro_gate.dart';

Widget _wrap(Widget child, FakeBillingService fake) => ProviderScope(
      overrides: [billingServiceProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('free shows upsell, pro shows child', (tester) async {
    final free = FakeBillingService();
    await tester.pumpWidget(_wrap(
      const ProGate(child: Text('PRO CONTENT'), upsell: Text('UPSELL')),
      free,
    ));
    await tester.pump();
    expect(find.text('UPSELL'), findsOneWidget);
    expect(find.text('PRO CONTENT'), findsNothing);

    final pro = FakeBillingService(initial: Entitlements(pro: true, ownedThemeIds: {'sand'}));
    await tester.pumpWidget(_wrap(
      const ProGate(child: Text('PRO CONTENT'), upsell: Text('UPSELL')),
      pro,
    ));
    await tester.pump();
    expect(find.text('PRO CONTENT'), findsOneWidget);
    expect(find.text('UPSELL'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test --concurrency=1 test/ui/pro_gate_test.dart`
Expected: FAIL (pro_gate.dart not defined).

- [ ] **Step 3: Write `lib/ui/widgets/pro_gate.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/billing_providers.dart';
import '../../app/theme.dart';
import '../../app/tokens.dart';
import '../paywall_screen.dart';

/// Shows [child] to Pro users, [upsell] to everyone else. Treats unknown/loading
/// as not-Pro (safe default); a real Pro user flips to [child] within a frame as
/// the cached entitlement loads.
class ProGate extends ConsumerWidget {
  final Widget child;
  final Widget upsell;
  const ProGate({super.key, required this.child, required this.upsell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(entitlementsProvider).pro;
    return pro ? child : upsell;
  }
}

/// The calm Insights upsell: a short honest line + a Get Pro action. No nag.
class ProUpsell extends StatelessWidget {
  final String headline;
  final String body;
  const ProUpsell({super.key, required this.headline, required this.body});

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(HgSpacing.lg),
      decoration: BoxDecoration(
        color: hg.surfaceRaised,
        borderRadius: BorderRadius.circular(HgRadius.lg),
        border: Border.all(color: hg.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline,
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: hg.textPrimary)),
          const SizedBox(height: HgSpacing.sm),
          Text(body,
              style: TextStyle(
                  fontFamily: HgFont.sans,
                  fontSize: 14,
                  height: 1.4,
                  color: hg.textSecondary)),
          const SizedBox(height: HgSpacing.lg),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen())),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: HgSpacing.lg, vertical: HgSpacing.sm + 3),
              decoration: BoxDecoration(
                  color: hg.accent,
                  borderRadius: BorderRadius.circular(HgRadius.pill)),
              child: Text('See your full focus story',
                  style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hg.onAccent)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Create a minimal `lib/ui/paywall_screen.dart` stub** so `pro_gate.dart` compiles before Task 6. (Task 6 replaces it.)

```dart
import 'package:flutter/material.dart';

/// Replaced with the full custom paywall in Task 6.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Sustain Pro')));
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test --concurrency=1 test/ui/pro_gate_test.dart`
Expected: PASS.

- [ ] **Step 6: Wrap the Insights depth band.** In `lib/ui/insights_screen.dart`, change the depth-band line (currently `const _DepthBand(),`) to gate it, and add imports `import 'widgets/pro_gate.dart';` and `import 'insights_copy.dart';` (already imported).

Replace:
```dart
                  // ── Pro depth band (one wrappable subtree) ───────────────
                  const _DepthBand(),
```
with:
```dart
                  // ── Pro depth band (gated) ───────────────────────────────
                  const ProGate(
                    child: _DepthBand(),
                    upsell: ProUpsell(
                      headline: 'See your full focus story with Pro',
                      body:
                          'Your Focus Score and Stamina over time, when you focus best, '
                          'follow-through, personal bests, and CSV export.',
                    ),
                  ),
```

- [ ] **Step 7: Gate "Start again".** Rewrite `lib/ui/start_again.dart` so the action requires Pro (free users open the paywall). It becomes ref-aware.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/billing_providers.dart';
import '../domain/session_record.dart';
import '../session/config_codec.dart';
import 'paywall_screen.dart';
import 'session_screen.dart';

/// Whether a session can be reused exactly (has a captured config).
bool canReuse(SessionRecord r) => decodeConfig(r.planJson) != null;

/// Replay the exact session (Pro). Free users are sent to the paywall instead,
/// so the action stays discoverable. No-op if the config can't be decoded.
void startAgain(BuildContext context, WidgetRef ref, SessionRecord r) {
  if (!ref.read(entitlementsProvider).pro) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
    return;
  }
  final config = decodeConfig(r.planJson, intention: r.intention);
  if (config == null) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SessionScreen(config: config)),
  );
}
```

- [ ] **Step 8: Update the caller** in `lib/ui/session_summary_screen.dart:172`. The summary screen is a `ConsumerWidget`/`ConsumerStatefulWidget` (it reads providers) — confirm a `WidgetRef ref` is in scope in its `build`. Change:
```dart
                    onPressed: () => startAgain(context, session),
```
to:
```dart
                    onPressed: () => startAgain(context, ref, session),
```
If `session_summary_screen.dart`'s build has no `ref`, convert its widget to `ConsumerWidget` (add `WidgetRef ref` to `build`) — it already imports Riverpod for other providers, so the change is mechanical.

- [ ] **Step 9: Run analyze + the gate/insights/summary tests**

Run: `flutter analyze`
Run: `flutter test --concurrency=1 test/ui/pro_gate_test.dart test/ui/insights_screen_test.dart test/ui/session_history_screen_test.dart`
Expected: analyze clean; tests PASS. (Note: `insights_screen_test.dart` overrides providers and reads the depth band; it must now also override `billingServiceProvider` with a Pro `FakeBillingService` so the depth band renders — update those test cases to add `billingServiceProvider.overrideWithValue(FakeBillingService(initial: Entitlements(pro: true, ownedThemeIds: {'sand'})))`.)

- [ ] **Step 10: Update `insights_screen_test.dart`** — add the Pro billing override to the two tests that assert depth-band sections render ("populated history…" and "switching the range…"), and the empty-trend test. For the "trend sections show honest empty copy" + "populated" tests, add to their `overrides` list:
```dart
        billingServiceProvider.overrideWithValue(
            FakeBillingService(initial: Entitlements(pro: true, ownedThemeIds: {'sand'}))),
```
and the imports:
```dart
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';
```
Re-run: `flutter test --concurrency=1 test/ui/insights_screen_test.dart` → PASS.

- [ ] **Step 11: Commit**

```bash
git add lib/ui/widgets/pro_gate.dart lib/ui/paywall_screen.dart lib/ui/insights_screen.dart lib/ui/start_again.dart lib/ui/session_summary_screen.dart test/ui/pro_gate_test.dart test/ui/insights_screen_test.dart
git commit -m "feat(billing): ProGate; gate Insights depth band + Start again"
```

---

### Task 5: RevenueCat implementation + dependency + app init

**Files:**
- Modify: `pubspec.yaml` (+`purchases_flutter`)
- Modify: `lib/billing/revenuecat_billing_service.dart` (real implementation)
- Modify: `lib/main.dart` (create + init + override the provider)
- Modify: `android/app/build.gradle` (verify/raise minSdk if required)

**Interfaces:**
- Consumes: `BillingService`, value types (Task 2), `entitlementsFrom` (Task 1), `kRevenueCatAndroidKey`/`kCatalogThemeIds` (Task 1).
- Produces: a working `RevenueCatBillingService`; `main()` overrides `billingServiceProvider` with the initialized instance.

> No unit test for the SDK layer (it wraps native billing — `flutter test` can't exercise it). It is covered by the FakeBillingService at every consumer. Verification is on-device by the founder once a key + products exist.

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add purchases_flutter`
Expected: `pubspec.yaml` gains `purchases_flutter:` and `flutter pub get` succeeds.

- [ ] **Step 2: Implement `lib/billing/revenuecat_billing_service.dart`**

```dart
import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../domain/entitlements.dart';
import 'billing_config.dart';
import 'billing_service.dart';

/// Real billing via RevenueCat, which calls Google Play Billing underneath. The
/// only file that imports the SDK. Never constructed while [apiKey] is empty.
class RevenueCatBillingService implements BillingService {
  final String apiKey;
  RevenueCatBillingService({required this.apiKey});

  final _controller = StreamController<Entitlements>.broadcast();
  Entitlements _current = Entitlements.free;
  void Function(CustomerInfo)? _listener;

  Entitlements _map(CustomerInfo info) => entitlementsFrom(
        activeEntitlementIds: info.entitlements.active.keys.toSet(),
        catalogThemeIds: kCatalogThemeIds,
      );

  @override
  Future<void> init() async {
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _current = _map(await Purchases.getCustomerInfo());
      _controller.add(_current);
      _listener = (info) {
        _current = _map(info);
        _controller.add(_current);
      };
      Purchases.addCustomerInfoUpdateListener(_listener!);
    } catch (_) {
      // Billing unavailable: stay free, never block the app.
      _current = Entitlements.free;
    }
  }

  @override
  Entitlements get current => _current;

  @override
  Stream<Entitlements> entitlements() => _controller.stream;

  @override
  Future<ProOffering?> proOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return null;
      final pkgs = <ProPackage>[];
      void add(Package? p, ProPlan plan) {
        if (p == null) return;
        final sp = p.storeProduct;
        pkgs.add(ProPackage(
          plan: plan,
          priceString: sp.priceString,
          priceAmount: sp.price,
          currencyCode: sp.currencyCode,
          raw: p,
        ));
      }

      add(current.monthly, ProPlan.monthly);
      add(current.annual, ProPlan.yearly);
      add(current.lifetime, ProPlan.lifetime);
      return pkgs.isEmpty ? null : ProOffering(pkgs);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async {
    try {
      final info = await Purchases.purchasePackage(package.raw as Package);
      _current = _map(info);
      _controller.add(_current);
      return _current.pro ? PurchaseOutcome.success : PurchaseOutcome.pending;
    } on PurchasesErrorCode catch (code) {
      return _outcomeFor(code);
    } on PlatformException catch (e) {
      return _outcomeFor(PurchasesErrorHelper.getErrorCode(e));
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  PurchaseOutcome _outcomeFor(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return PurchaseOutcome.cancelled;
      case PurchasesErrorCode.paymentPendingError:
        return PurchaseOutcome.pending;
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return PurchaseOutcome.alreadyOwned;
      default:
        return PurchaseOutcome.error;
    }
  }

  @override
  Future<RestoreOutcome> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _current = _map(info);
      _controller.add(_current);
      return _current.pro
          ? RestoreOutcome.restoredPro
          : RestoreOutcome.nothingToRestore;
    } catch (_) {
      return RestoreOutcome.error;
    }
  }

  @override
  void dispose() {
    if (_listener != null) Purchases.removeCustomerInfoUpdateListener(_listener!);
    _controller.close();
  }
}
```
> Note for the implementer: the exact `purchases_flutter` symbol names (e.g. `PurchasesConfiguration`, `PurchasesErrorHelper.getErrorCode`, `PackageType` accessors `current.monthly/annual/lifetime`, `StoreProduct.price/priceString/currencyCode`, `PlatformException` from `package:flutter/services.dart`) are from the 8.x API; if `flutter pub add` resolves a different major, adjust to that version's API and re-run `flutter analyze`. Add `import 'package:flutter/services.dart';` for `PlatformException`.

- [ ] **Step 3: Wire init in `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/billing_providers.dart';
import 'app/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  final prefs = await SharedPreferences.getInstance();
  final billing = createBillingService();
  await billing.init(); // guarded internally; never throws
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        billingServiceProvider.overrideWithValue(billing),
      ],
      child: const HourglassApp(),
    ),
  );
}
```

- [ ] **Step 4: Verify Android minSdk.** Open `android/app/build.gradle`; ensure `minSdkVersion` is at least `flutter.minSdkVersion` and ≥ 21 (RevenueCat requirement). If it's a literal below 21, raise to 21. (Most Flutter projects already satisfy this.)

- [ ] **Step 5: Analyze + full test suite (logic unaffected; fake still used in tests)**

Run: `flutter analyze`
Run: `flutter test --concurrency=1`
Expected: analyze clean; all tests PASS (no test constructs the real service).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/billing/revenuecat_billing_service.dart lib/main.dart android/app/build.gradle
git commit -m "feat(billing): RevenueCat implementation + key-guarded app init"
```

---

### Task 6: Custom paywall + purchase success screen

**Files:**
- Modify: `lib/ui/paywall_screen.dart` (replace stub with the real screen)
- Create: `lib/ui/pro_success_screen.dart`
- Test: `test/ui/paywall_screen_test.dart`

**Interfaces:**
- Consumes: `billingServiceProvider`, `entitlementsProvider` (Task 3); `ProOffering`/`ProPackage`/`ProPlan`/`PurchaseOutcome`/`RestoreOutcome` (Task 2); `url_launcher` (manage link).
- Produces: `PaywallScreen` (ConsumerStatefulWidget); `ProSuccessScreen`.

> Build the visuals to a premium bar with the **impeccable** skill during execution — the code below is a correct, compiling baseline (states + purchase outcomes + restore + disclosures) for impeccable to refine, not a placeholder.

- [ ] **Step 1: Write the failing widget test** `test/ui/paywall_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/ui/paywall_screen.dart';

ProOffering _offering() => const ProOffering([
      ProPackage(plan: ProPlan.monthly, priceString: r'$1.99', priceAmount: 1.99, currencyCode: 'USD', raw: 'm'),
      ProPackage(plan: ProPlan.yearly, priceString: r'$9.99', priceAmount: 9.99, currencyCode: 'USD', raw: 'y'),
      ProPackage(plan: ProPlan.lifetime, priceString: r'$24.99', priceAmount: 24.99, currencyCode: 'USD', raw: 'l'),
    ]);

Widget _wrap(FakeBillingService fake) => ProviderScope(
      overrides: [billingServiceProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const PaywallScreen(),
      ),
    );

void main() {
  testWidgets('shows the three plan prices from the offering', (tester) async {
    final fake = FakeBillingService()..offering = _offering();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.text(r'$1.99'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text(r'$24.99'), findsOneWidget);
  });

  testWidgets('prices unavailable state when offering is null', (tester) async {
    final fake = FakeBillingService(); // no offering
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.textContaining('unavailable'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test --concurrency=1 test/ui/paywall_screen_test.dart`
Expected: FAIL (PaywallScreen stub has none of these).

- [ ] **Step 3: Write `lib/ui/pro_success_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../app/tokens.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// Serene "you're Pro" confirmation (completion-screen register: gentle haptic,
/// never confetti). Continue returns to Home, clearing the paywall + origin.
class ProSuccessScreen extends StatefulWidget {
  const ProSuccessScreen({super.key});
  @override
  State<ProSuccessScreen> createState() => _ProSuccessScreenState();
}

class _ProSuccessScreenState extends State<ProSuccessScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('You’re Pro',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: hg.textPrimary)),
                const SizedBox(height: HgSpacing.md),
                Text(
                  'Your full focus story is unlocked. Thank you for supporting Sustain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: HgFont.sans,
                      fontSize: 15,
                      height: 1.5,
                      color: hg.textSecondary),
                ),
                const SizedBox(height: HgSpacing.xl),
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write `lib/ui/paywall_screen.dart`** (baseline; impeccable polishes visuals later)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/billing_providers.dart';
import '../app/theme.dart';
import '../app/tokens.dart';
import '../billing/billing_service.dart';
import 'pro_success_screen.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_background.dart';

/// The custom "Sustain Pro" paywall. Reads live store prices from the offering;
/// never hardcodes prices. Handles every purchase/restore outcome.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  ProOffering? _offering;
  bool _loading = true;
  bool _busy = false;
  ProPlan _selected = ProPlan.yearly;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final o = await ref.read(billingServiceProvider).proOffering();
    if (!mounted) return;
    setState(() {
      _offering = o;
      _loading = false;
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _buy(ProPackage pkg) async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingServiceProvider).purchase(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.success:
      case PurchaseOutcome.alreadyOwned:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProSuccessScreen()));
      case PurchaseOutcome.cancelled:
        break; // silent
      case PurchaseOutcome.pending:
        _snack('Your purchase is processing. Pro unlocks once it is confirmed.');
      case PurchaseOutcome.error:
        _snack('That did not go through. Please try again.');
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final outcome = await ref.read(billingServiceProvider).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case RestoreOutcome.restoredPro:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProSuccessScreen()));
      case RestoreOutcome.nothingToRestore:
        _snack('No previous purchases found on this Google account.');
      case RestoreOutcome.error:
        _snack('Could not restore right now. Please try again.');
    }
  }

  Future<void> _manage() => launchUrl(
        Uri.parse('https://play.google.com/store/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final pro = ref.watch(entitlementsProvider).pro;
    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: HgSpacing.screen),
            child: ListView(
              children: [
                const SizedBox(height: HgSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: hg.textSecondary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: HgSpacing.md),
                Text('Sustain Pro',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary)),
                const SizedBox(height: HgSpacing.sm),
                Text('Train your focus, deeper.',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 16,
                        color: hg.textSecondary)),
                const SizedBox(height: HgSpacing.xl),
                ..._benefits(hg),
                const SizedBox(height: HgSpacing.xl),
                if (pro)
                  _ownedPanel(hg)
                else if (_loading)
                  const Center(child: Padding(
                      padding: EdgeInsets.all(HgSpacing.xl),
                      child: CircularProgressIndicator()))
                else if (_offering == null)
                  _unavailable(hg)
                else
                  ..._plans(hg, _offering!),
                const SizedBox(height: HgSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _restore,
                    child: Text('Restore purchases',
                        style: TextStyle(
                            fontFamily: HgFont.sans, color: hg.textSecondary)),
                  ),
                ),
                const SizedBox(height: HgSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _benefits(HgTokens hg) {
    const items = [
      'Your Focus Score and Stamina, traced over time',
      'When you focus best, and your follow-through',
      'Personal bests and CSV export',
      'Every color theme, and session reuse',
      'Every Pro feature we add',
    ];
    return [
      for (final t in items)
        Padding(
          padding: const EdgeInsets.only(bottom: HgSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_rounded, size: 18, color: hg.accent),
              const SizedBox(width: HgSpacing.sm),
              Expanded(
                  child: Text(t,
                      style: TextStyle(
                          fontFamily: HgFont.sans,
                          fontSize: 15,
                          height: 1.35,
                          color: hg.textPrimary))),
            ],
          ),
        ),
    ];
  }

  List<Widget> _plans(HgTokens hg, ProOffering offering) {
    final monthly = offering.byPlan(ProPlan.monthly);
    final yearly = offering.byPlan(ProPlan.yearly);
    final lifetime = offering.byPlan(ProPlan.lifetime);
    String? savings;
    if (monthly != null && yearly != null && monthly.priceAmount > 0) {
      final pct =
          (100 * (1 - yearly.priceAmount / (monthly.priceAmount * 12))).round();
      if (pct > 0) savings = 'Save $pct%';
    }
    final selectedPkg = offering.byPlan(_selected) ?? offering.packages.first;
    return [
      if (monthly != null)
        _PlanTile(
            label: 'Monthly',
            price: monthly.priceString,
            note: 'Billed monthly, auto-renews until cancelled',
            selected: _selected == ProPlan.monthly,
            onTap: () => setState(() => _selected = ProPlan.monthly)),
      if (yearly != null)
        _PlanTile(
            label: 'Yearly',
            price: yearly.priceString,
            badge: savings,
            note: 'Billed yearly, auto-renews until cancelled',
            selected: _selected == ProPlan.yearly,
            onTap: () => setState(() => _selected = ProPlan.yearly)),
      if (lifetime != null)
        _PlanTile(
            label: 'Lifetime',
            price: lifetime.priceString,
            note: 'One-time payment, yours forever',
            selected: _selected == ProPlan.lifetime,
            onTap: () => setState(() => _selected = ProPlan.lifetime)),
      const SizedBox(height: HgSpacing.lg),
      PrimaryButton(
        label: _selected == ProPlan.lifetime ? 'Get Lifetime' : 'Start Pro',
        onPressed: _busy ? null : () => _buy(selectedPkg),
      ),
      const SizedBox(height: HgSpacing.sm),
      Text(
        _selected == ProPlan.lifetime
            ? 'A one-time payment. No subscription, no renewal.'
            : 'Auto-renews until cancelled. Manage or cancel anytime in Google Play.',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontFamily: HgFont.sans, fontSize: 12, color: hg.textMuted),
      ),
      if (_selected != ProPlan.lifetime) ...[
        const SizedBox(height: HgSpacing.xs),
        Center(
          child: TextButton(
            onPressed: _manage,
            child: Text('Manage subscription',
                style: TextStyle(fontFamily: HgFont.sans, color: hg.textSecondary)),
          ),
        ),
      ],
    ];
  }

  Widget _unavailable(HgTokens hg) => Container(
        padding: const EdgeInsets.all(HgSpacing.lg),
        decoration: BoxDecoration(
            color: hg.surfaceRaised,
            borderRadius: BorderRadius.circular(HgRadius.lg),
            border: Border.all(color: hg.hairline)),
        child: Text(
          'Pricing is unavailable right now. Check your connection and try again.',
          style: TextStyle(
              fontFamily: HgFont.sans, fontSize: 14, color: hg.textSecondary),
        ),
      );

  Widget _ownedPanel(HgTokens hg) => Container(
        padding: const EdgeInsets.all(HgSpacing.lg),
        decoration: BoxDecoration(
            color: hg.accentMuted,
            borderRadius: BorderRadius.circular(HgRadius.lg)),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: hg.accent),
            const SizedBox(width: HgSpacing.sm),
            Expanded(
                child: Text('You have Pro. Thank you.',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hg.textPrimary))),
          ],
        ),
      );
}

class _PlanTile extends StatelessWidget {
  final String label;
  final String price;
  final String? note;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTile({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
    this.note,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: HgSpacing.sm),
        padding: const EdgeInsets.all(HgSpacing.md),
        decoration: BoxDecoration(
          color: selected ? hg.accentMuted : hg.surfaceRaised,
          borderRadius: BorderRadius.circular(HgRadius.lg),
          border: Border.all(
              color: selected ? hg.accent : hg.hairline,
              width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label,
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: hg.textPrimary)),
                    if (badge != null) ...[
                      const SizedBox(width: HgSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: hg.accent,
                            borderRadius: BorderRadius.circular(HgRadius.sm)),
                        child: Text(badge!,
                            style: TextStyle(
                                fontFamily: HgFont.sans,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: hg.onAccent)),
                      ),
                    ],
                  ]),
                  if (note != null) ...[
                    const SizedBox(height: 2),
                    Text(note!,
                        style: TextStyle(
                            fontFamily: HgFont.sans,
                            fontSize: 12,
                            color: hg.textMuted)),
                  ],
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontFamily: HgFont.sans,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hg.textPrimary)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test --concurrency=1 test/ui/paywall_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Polish with impeccable (visual craft only).** Invoke the `impeccable` skill to refine the paywall + success screen visuals (hero, plan-tile hierarchy, the yearly anchor emphasis, spacing rhythm, the benefit list) without changing the purchase/restore logic or the tested text. Re-run the test after; it must still PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/paywall_screen.dart lib/ui/pro_success_screen.dart test/ui/paywall_screen_test.dart
git commit -m "feat(billing): custom Sustain Pro paywall + success screen"
```

---

### Task 7: Settings rows (Pro / Restore / dev-unlock) + Profile PRO tag

**Files:**
- Modify: `lib/ui/settings_screen.dart` (add rows)
- Modify: `lib/ui/profile_screen.dart` (PRO tag under avatar)
- Test: `test/ui/profile_screen_test.dart` (extend) and `test/ui/settings_screen_test.dart` (create if absent)

**Interfaces:**
- Consumes: `entitlementsProvider`, `billingServiceProvider`, `devProUnlockProvider` (Task 3); `PaywallScreen` (Task 6).

- [ ] **Step 1: Add Settings rows.** In `lib/ui/settings_screen.dart`, add a "Sustain Pro" section near the top of the list (above Display). The screen is a `ConsumerWidget` (it uses `ref` in `_clearAll`); read entitlements in `build`. Add imports `import '../app/billing_providers.dart';`, `import 'paywall_screen.dart';`, and `import 'package:flutter/foundation.dart';` (for `kDebugMode`). Insert:

```dart
                _SectionLabel('Sustain Pro'),
                const SizedBox(height: HgSpacing.sm),
                _ActionRow(
                  title: ref.watch(entitlementsProvider).pro
                      ? 'You have Pro'
                      : 'Get Sustain Pro',
                  subtitle: ref.watch(entitlementsProvider).pro
                      ? 'Thank you for supporting Sustain.'
                      : 'Your full focus story, every theme, and more.',
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen())),
                ),
                _ActionRow(
                  title: 'Restore purchases',
                  onTap: () async {
                    final outcome =
                        await ref.read(billingServiceProvider).restore();
                    if (!context.mounted) return;
                    final msg = switch (outcome) {
                      RestoreOutcome.restoredPro => 'Pro restored.',
                      RestoreOutcome.nothingToRestore =>
                        'No previous purchases found on this Google account.',
                      RestoreOutcome.error =>
                        'Could not restore right now. Please try again.',
                    };
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  },
                ),
                if (kDebugMode)
                  _ActionRow(
                    title: 'Dev: unlock Pro',
                    subtitle: ref.watch(devProUnlockProvider)
                        ? 'On (debug only)'
                        : 'Off (debug only)',
                    onTap: () =>
                        ref.read(devProUnlockProvider.notifier).toggle(),
                  ),
                const SizedBox(height: HgSpacing.xl),
```
Use the existing section-label widget in that file (match the name used for "Display"/"Session"; if it's an inline `Text`, mirror that). Add `import 'package:hourglass/billing/billing_service.dart';` if `RestoreOutcome` isn't visible. Ensure `_ActionRow` supports an optional `subtitle` (it already does per the file).

- [ ] **Step 2: Add the Profile PRO tag.** In `lib/ui/profile_screen.dart`, locate the avatar widget in the hub header. Directly below it, add (the screen reads providers, so `ref` is in scope; add `import '../app/billing_providers.dart';`):

```dart
            if (ref.watch(entitlementsProvider).pro) ...[
              const SizedBox(height: HgSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: context.hg.accentMuted,
                  borderRadius: BorderRadius.circular(HgRadius.pill),
                ),
                child: Text('PRO',
                    style: TextStyle(
                        fontFamily: HgFont.sans,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: context.hg.accent)),
              ),
            ],
```

- [ ] **Step 3: Write/extend the failing test.** In `test/ui/profile_screen_test.dart`, add a Pro override + assert the tag. Add imports for `billing_providers`, `fake_billing_service`, `entitlements`. New test:

```dart
  testWidgets('shows PRO tag for pro users', (tester) async {
    // ... existing harness, but add to overrides:
    //   billingServiceProvider.overrideWithValue(
    //     FakeBillingService(initial: Entitlements(pro: true, ownedThemeIds: {'sand'}))),
    // pump the profile hub, then:
    expect(find.text('PRO'), findsOneWidget);
  });
```
(Adapt to the file's existing harness/override pattern; a free-user case should assert `find.text('PRO')` is `findsNothing`.)

- [ ] **Step 4: Run tests to verify they fail, then pass after Steps 1-2**

Run: `flutter test --concurrency=1 test/ui/profile_screen_test.dart`
Expected: PASS after the tag is added. Also run any existing `settings_screen` test if present.

- [ ] **Step 5: Analyze + full suite + commit**

Run: `flutter analyze` (clean)
Run: `flutter test --concurrency=1` (all PASS)

```bash
git add lib/ui/settings_screen.dart lib/ui/profile_screen.dart test/ui/profile_screen_test.dart
git commit -m "feat(billing): Settings Pro/Restore/dev-unlock rows + Profile PRO tag"
```

---

### Task 8: Full verification + deploy

- [ ] **Step 1:** `flutter analyze` — clean.
- [ ] **Step 2:** `flutter test --concurrency=1` — all green.
- [ ] **Step 3:** Build + deploy to device V2521 (free RAM first if the build OOMs; trim `StartMenuExperienceHost`): `flutter build apk --debug`, install, launch. Verify: Insights shows the upsell for a free user; toggling **Dev: unlock Pro** reveals the depth band + the Profile PRO tag; the paywall opens and shows its "pricing unavailable" state (key-less); Restore shows the "no purchases" note.
- [ ] **Step 4:** Update `.remember/remember.md` handoff; final commit + `git push origin master`.

---

## Self-Review

**Spec coverage:** §3 entitlement model → Task 1. §4 abstraction (interface + RC + fake) → Tasks 2, 3 (stub), 5 (real). §5 provider/offline/default-free → Task 3. §6 paywall + outcomes + manage/restore/disclosure + regional prices (store priceString) → Task 6. §7 success screen → Home → Task 6. §8 key-less + dev-unlock (debug-only) → Tasks 3, 5, 7. §9 ProGate + Insights + Start again → Task 4. §10 Profile PRO tag → Task 7. §11 edge cases (cancel/pending/alreadyOwned/error/restore-empty/expiry via stream) → Tasks 2, 5, 6. §12 legal (Restore, Manage, disclosure, Play Billing) → Task 6; privacy/Data-Safety/R8 carried to launch hardening (out of scope here, noted). §13 deps/init/minSdk → Task 5. §14 testing → each task's tests. §16 files → covered.

**Placeholder scan:** No "TBD/TODO". UI in Task 6 is a complete compiling baseline (the impeccable step refines visuals only, not logic). The `purchases_flutter` API note (Task 5 Step 2) is a version-guard instruction, not a placeholder.

**Type consistency:** `BillingService` method names (`init`, `entitlements`, `current`, `proOffering`, `purchase`, `restore`, `dispose`), `ProPackage`/`ProOffering`/`ProPlan`/`PurchaseOutcome`/`RestoreOutcome`, `entitlementsFrom(activeEntitlementIds:, catalogThemeIds:)`, and `startAgain(context, ref, r)` are used identically across tasks. `billingServiceProvider`/`entitlementsProvider`/`devProUnlockProvider` names are consistent.
