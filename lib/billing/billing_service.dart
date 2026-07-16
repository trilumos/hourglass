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

/// A snapshot of the user's active Pro purchase, for the management screen.
/// Only meaningful when Pro is active; null otherwise (free, unknown, key-less).
class ProStatus {
  /// The plan the user is on, when it can be determined from the store product.
  final ProPlan? plan;

  /// When the current subscription period ends. Null for Lifetime (no expiry)
  /// or when the store did not report a date.
  final DateTime? expiration;

  /// True while a subscription is set to renew at [expiration]; false once it
  /// has been cancelled (but is still active until [expiration]).
  final bool willRenew;

  /// True for a one-time Lifetime purchase (no expiry, nothing to renew).
  final bool isLifetime;

  const ProStatus({
    required this.plan,
    required this.expiration,
    required this.willRenew,
    required this.isLifetime,
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

  /// Details of the active Pro purchase (plan, renewal/expiry), or null when Pro
  /// is not active or the store cannot report it. Never throws (guard internally).
  Future<ProStatus?> proStatus();

  /// The purchasable themes (à la carte). Empty when unavailable (offline /
  /// key-less / no products configured). Pro **Lifetime** grants all themes;
  /// Monthly/Yearly do not — themes are one-time goods (see [entitlementsFrom]).
  Future<List<ThemeProduct>> themeProducts();

  /// Purchase a single theme. On success the `theme_<id>` entitlement becomes
  /// active and the entitlements stream emits. Reuses [PurchaseOutcome].
  Future<PurchaseOutcome> purchaseTheme(String themeId);

  void dispose();
}
