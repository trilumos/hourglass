/// Billing configuration. The Android RevenueCat **public** SDK key — empty
/// means key-less: the app runs Free for everyone (see createBillingService).
/// Fill this in (and create the Play Console + RevenueCat products) to go live;
/// no other code changes are needed.
const String kRevenueCatAndroidKey = 'goog_qvcafNNwzocZLDKSJFfVqqRPmgW';

/// The single RevenueCat entitlement that means "Pro" (attached in the dashboard
/// to pro.monthly / pro.yearly / pro.lifetime).
const String kProEntitlement = 'pro';

/// Purchasable theme ids (the app catalog minus the always-free 'sand'). Pro
/// **Lifetime** grants all of these — Monthly/Yearly do not, since a theme is a
/// one-time good (see entitlementsFrom). Each is also sellable à la carte
/// (see kThemeProductId).
const Set<String> kCatalogThemeIds = <String>{
  'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha', 'aurora',
};

/// The Play / RevenueCat **product id** for a theme (a non-consumable). The
/// matching RevenueCat entitlement is `theme_<id>` (see entitlementsFrom).
String kThemeProductId(String themeId) => 'theme.$themeId';
