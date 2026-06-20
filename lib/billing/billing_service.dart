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

/// A purchasable theme (non-consumable), normalized away from RevenueCat's
/// types. [raw] holds the underlying store product the real service purchases.
class ThemeProduct {
  final String themeId;
  final String priceString; // localized, store-formatted (e.g. "₹169.00")
  final Object raw;
  const ThemeProduct({
    required this.themeId,
    required this.priceString,
    required this.raw,
  });
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

  /// The purchasable themes (à la carte). Empty when unavailable (offline /
  /// key-less / no products configured). Pro grants all themes regardless.
  Future<List<ThemeProduct>> themeProducts();

  /// Purchase a single theme. On success the `theme_<id>` entitlement becomes
  /// active and the entitlements stream emits. Reuses [PurchaseOutcome].
  Future<PurchaseOutcome> purchaseTheme(String themeId);

  void dispose();
}
