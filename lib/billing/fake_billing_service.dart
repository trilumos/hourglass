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

  FakeBillingService({
    Entitlements initial = Entitlements.free,
    this.offering,
    this.nextPurchase = PurchaseOutcome.success,
    this.nextRestore = RestoreOutcome.nothingToRestore,
    this.themeProductList = const [],
    this.nextThemePurchase = PurchaseOutcome.success,
  }) : _current = initial;

  Entitlements get _pro => entitlementsFrom(
        activeEntitlementIds: const {kProEntitlement},
        catalogThemeIds: kCatalogThemeIds,
      );

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
