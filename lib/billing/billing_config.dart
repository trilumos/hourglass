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
