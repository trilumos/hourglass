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
      // Trusted Entitlements (informational): RevenueCat cryptographically
      // verifies the entitlement response, so a tampered local cache (e.g. a
      // rooted device editing it) can be detected. Informational mode only
      // *reports* the result (via CustomerInfo.entitlements.verification) and
      // never locks anyone out — zero effect on legitimate users.
      await Purchases.configure(
        PurchasesConfiguration(apiKey)
          ..entitlementVerificationMode =
              EntitlementVerificationMode.informational,
      );
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
  Future<ProStatus?> proStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final ent = info.entitlements.active[kProEntitlement];
      if (ent == null || !ent.isActive) return null;
      // Lifetime is a non-subscription purchase: no expiry, nothing to renew.
      final exp = ent.expirationDate;
      final isLifetime = exp == null;
      return ProStatus(
        plan: _planOf(ent.productIdentifier, ent.productPlanIdentifier),
        expiration: exp == null ? null : DateTime.tryParse(exp),
        willRenew: ent.willRenew,
        isLifetime: isLifetime,
      );
    } catch (_) {
      return null;
    }
  }

  /// Best-effort plan from the store ids (e.g. 'pro.yearly', base plan 'p1y').
  ProPlan? _planOf(String productId, String? planId) {
    final s = '${productId.toLowerCase()} ${(planId ?? '').toLowerCase()}';
    if (s.contains('life')) return ProPlan.lifetime;
    if (s.contains('year') || s.contains('annual') || s.contains('p1y')) {
      return ProPlan.yearly;
    }
    if (s.contains('month') || s.contains('p1m')) return ProPlan.monthly;
    return null;
  }

  @override
  Future<List<ThemeProduct>> themeProducts() async {
    if (kCatalogThemeIds.isEmpty) return const [];
    try {
      final wantedIds = {for (final id in kCatalogThemeIds) kThemeProductId(id)};
      // Themes are non-consumable in-app products, NOT subscriptions, so the
      // non-subscription category is required or Google returns nothing.
      final products = await Purchases.getProducts(
        wantedIds.toList(),
        productCategory: ProductCategory.nonSubscription,
      );
      final out = <ThemeProduct>[];
      for (final p in products) {
        // Recover the theme id from the product id (kThemeProductId == 'theme.<id>').
        final id = _themeIdOf(p.identifier);
        if (id == null || !kCatalogThemeIds.contains(id)) continue;
        out.add(ThemeProduct(themeId: id, priceString: p.priceString, raw: p));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<PurchaseOutcome> purchaseTheme(String themeId) async {
    try {
      final wanted = kThemeProductId(themeId);
      final products = await Purchases.getProducts(
        [wanted],
        productCategory: ProductCategory.nonSubscription,
      );
      StoreProduct? product;
      for (final p in products) {
        if (p.identifier == wanted) {
          product = p;
          break;
        }
      }
      if (product == null) return PurchaseOutcome.error;
      final result =
          await Purchases.purchase(PurchaseParams.storeProduct(product));
      _update(result.customerInfo);
      return _current.ownsTheme(themeId)
          ? PurchaseOutcome.success
          : PurchaseOutcome.pending;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        return PurchaseOutcome.pending;
      }
      if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        // Re-sync from verified state; only treat as owned if it really is.
        try {
          _update(await Purchases.getCustomerInfo());
        } catch (_) {/* leave _current as-is */}
        return _current.ownsTheme(themeId)
            ? PurchaseOutcome.alreadyOwned
            : PurchaseOutcome.error;
      }
      return PurchaseOutcome.error;
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  /// 'theme.obsidian' -> 'obsidian'. Mirrors [kThemeProductId]. Null if no match.
  String? _themeIdOf(String productId) {
    const prefix = 'theme.';
    if (!productId.startsWith(prefix)) return null;
    return productId.substring(prefix.length);
  }

  @override
  void dispose() {
    final l = _listener;
    if (l != null) Purchases.removeCustomerInfoUpdateListener(l);
    _controller.close();
  }
}
