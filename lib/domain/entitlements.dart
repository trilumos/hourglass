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
Entitlements entitlementsFrom({
  required Set<String> activeEntitlementIds,
  required Set<String> catalogThemeIds,
}) {
  final pro = activeEntitlementIds.contains(kProEntitlement);
  final owned = <String>{'sand'};
  for (final id in catalogThemeIds) {
    if (activeEntitlementIds.contains('theme_$id')) owned.add(id);
  }
  if (pro) owned.addAll(catalogThemeIds);
  return Entitlements(pro: pro, ownedThemeIds: owned);
}
