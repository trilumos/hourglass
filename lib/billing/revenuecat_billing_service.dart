import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../domain/entitlements.dart';
import 'billing_config.dart';
import 'billing_service.dart';

/// Real billing via RevenueCat, which calls Google Play Billing underneath. The
/// only file that imports the SDK. Never constructed while [apiKey] is empty.
/// Built against purchases_flutter 10.x.
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

  void _update(CustomerInfo info) {
    _current = _map(info);
    _controller.add(_current);
  }

  @override
  Future<void> init() async {
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      // Register the listener FIRST so that even if the initial fetch fails
      // (transient/offline), a later push still updates entitlements without an
      // app restart. The SDK delivers the last-known info to a new listener.
      _listener = _update;
      Purchases.addCustomerInfoUpdateListener(_listener!);
      try {
        _update(await Purchases.getCustomerInfo());
      } catch (_) {
        // Initial fetch failed; the listener above will deliver when able.
      }
    } catch (_) {
      // Billing unavailable (e.g. configure failed): stay free, never block.
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
      final result =
          await Purchases.purchase(PurchaseParams.package(package.raw as Package));
      _update(result.customerInfo);
      return _current.pro ? PurchaseOutcome.success : PurchaseOutcome.pending;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        return PurchaseOutcome.pending;
      }
      if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        // Re-sync from verified state and only treat as owned if Pro is really
        // active for this account — never celebrate on the error alone.
        try {
          _update(await Purchases.getCustomerInfo());
        } catch (_) {/* leave _current as-is */}
        return _current.pro ? PurchaseOutcome.alreadyOwned : PurchaseOutcome.error;
      }
      return PurchaseOutcome.error;
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  @override
  Future<RestoreOutcome> restore() async {
    try {
      _update(await Purchases.restorePurchases());
      return _current.pro
          ? RestoreOutcome.restoredPro
          : RestoreOutcome.nothingToRestore;
    } catch (_) {
      return RestoreOutcome.error;
    }
  }

  @override
  void dispose() {
    final l = _listener;
    if (l != null) Purchases.removeCustomerInfoUpdateListener(l);
    _controller.close();
  }
}
