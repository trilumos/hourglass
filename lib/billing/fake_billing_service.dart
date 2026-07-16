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
  List<ThemeProduct> themeProductList;
  PurchaseOutcome nextThemePurchase;
  final _controller = StreamController<Entitlements>.broadcast();

  /// Which plan a [RestoreOutcome.restoredPro] restores. Defaults to a
  /// subscription (no themes) — the conservative case.
  bool restoredIsLifetime;

  FakeBillingService({
    Entitlements initial = Entitlements.free,
    this.offering,
    this.nextPurchase = PurchaseOutcome.success,
    this.nextRestore = RestoreOutcome.nothingToRestore,
    this.themeProductList = const [],
    this.nextThemePurchase = PurchaseOutcome.success,
    this.restoredIsLifetime = false,
  }) : _current = initial;

  /// Mirrors the real rule: only Lifetime bundles the themes.
  Entitlements _proFor({required bool lifetime}) => entitlementsFrom(
        activeEntitlementIds: const {kProEntitlement},
        catalogThemeIds: kCatalogThemeIds,
        proLifetime: lifetime,
      );

  @override
  Future<void> init() async {}

  @override
  Entitlements get current => _current;

  @override
  Stream<Entitlements> entitlements() => _controller.stream;

  @override
  Future<ProOffering?> proOffering() async => offering;

  /// The last package passed to [purchase] — lets tests assert the right plan
  /// was bought (e.g. that selecting Lifetime doesn't buy Yearly).
  ProPackage? lastPurchased;

  @override
  Future<PurchaseOutcome> purchase(ProPackage package) async {
    lastPurchased = package;
    if (nextPurchase == PurchaseOutcome.success ||
        nextPurchase == PurchaseOutcome.alreadyOwned) {
      _current = _proFor(lifetime: package.plan == ProPlan.lifetime);
      _controller.add(_current);
    }
    return nextPurchase;
  }

  @override
  Future<RestoreOutcome> restore() async {
    if (nextRestore == RestoreOutcome.restoredPro) {
      _current = _proFor(lifetime: restoredIsLifetime);
      _controller.add(_current);
    }
    return nextRestore;
  }

  @override
  Future<ProStatus?> proStatus() async => proStatusValue;

  /// Scripted status for tests; null by default (key-less / dev-unlock show none).
  ProStatus? proStatusValue;

  @override
  Future<List<ThemeProduct>> themeProducts() async => themeProductList;

  @override
  Future<PurchaseOutcome> purchaseTheme(String themeId) async {
    if (nextThemePurchase == PurchaseOutcome.success ||
        nextThemePurchase == PurchaseOutcome.alreadyOwned) {
      _current = _current.copyWith(
        ownedThemeIds: {..._current.ownedThemeIds, themeId},
      );
      _controller.add(_current);
    }
    return nextThemePurchase;
  }

  @override
  void dispose() => _controller.close();
}
