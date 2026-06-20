import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../billing/billing_config.dart';
import '../billing/billing_service.dart';
import '../billing/fake_billing_service.dart';
import '../billing/revenuecat_billing_service.dart';
import '../domain/entitlements.dart';
import 'tokens.dart';

/// Debug-only stand-in à-la-carte products so the per-theme Buy flow is visible
/// and testable on-device before the real Play Console / RevenueCat products
/// exist. Compiled out of release (kDebugMode is a const false), where key-less
/// themes correctly show "In Pro" until the founder configures real products.
List<ThemeProduct> _devThemeProducts() => [
      for (final id in kCatalogThemeIds)
        ThemeProduct(themeId: id, priceString: r'$1.99', raw: 'dev'),
    ];

/// Picks the real service when a key is configured, else the fake (key-less:
/// everyone Free). Real purchases are inherently Play Console / RevenueCat work.
BillingService createBillingService() => kRevenueCatAndroidKey.isEmpty
    ? FakeBillingService(
        themeProductList: kDebugMode ? _devThemeProducts() : const [])
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
