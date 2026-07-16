import 'package:flutter/foundation.dart';

import '../billing/billing_config.dart';

/// What the user has unlocked. Derived only from verified entitlement state
/// (see [entitlementsFrom]); never set optimistically. Always owns 'sand'.
@immutable
class Entitlements {
  final bool pro;
  final Set<String> ownedThemeIds;
  const Entitlements({required this.pro, required this.ownedThemeIds});

  static const free = Entitlements(pro: false, ownedThemeIds: {'sand'});

  bool ownsTheme(String id) => ownedThemeIds.contains(id);

  Entitlements copyWith({bool? pro, Set<String>? ownedThemeIds}) => Entitlements(
        pro: pro ?? this.pro,
        ownedThemeIds: ownedThemeIds ?? this.ownedThemeIds,
      );

  @override
  bool operator ==(Object other) =>
      other is Entitlements &&
      other.pro == pro &&
      setEquals(other.ownedThemeIds, ownedThemeIds);

  @override
  int get hashCode => Object.hash(pro, Object.hashAllUnordered(ownedThemeIds));
}

/// The single source of truth for entitlement rules. Pure: plain sets in, an
/// [Entitlements] out. [activeEntitlementIds] are RevenueCat's active entitlement
/// identifiers; [catalogThemeIds] is the app's purchasable theme catalog.
///
/// **Subscriptions rent features; only a one-time purchase owns one-time goods.**
/// Themes are one-time goods, so only [proLifetime] bundles them — Monthly and
/// Yearly grant every Pro *feature* but no themes (buy à-la-carte, owned forever).
/// [proLifetime] is required, not defaulted: a silent default here either revokes
/// a Lifetime buyer's themes or gives subscribers themes free, and both are money
/// bugs. Callers must state it.
Entitlements entitlementsFrom({
  required Set<String> activeEntitlementIds,
  required Set<String> catalogThemeIds,
  required bool proLifetime,
}) {
  final pro = activeEntitlementIds.contains(kProEntitlement);
  final owned = <String>{'sand'};
  for (final id in catalogThemeIds) {
    if (activeEntitlementIds.contains('theme_$id')) owned.add(id);
  }
  // `pro &&` guards the caller passing proLifetime:true without an active Pro.
  if (pro && proLifetime) owned.addAll(catalogThemeIds);
  return Entitlements(pro: pro, ownedThemeIds: owned);
}
