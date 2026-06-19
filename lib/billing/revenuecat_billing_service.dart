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
      final result =
          await Purchases.purchase(PurchaseParams.package(package.raw as Package));
      _current = _map(result.customerInfo);
      _controller.add(_current);
      return _current.pro ? PurchaseOutcome.success : PurchaseOutcome.pending;
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
    final l = _listener;
    if (l != null) Purchases.removeCustomerInfoUpdateListener(l);
    _controller.close();
  }
}
