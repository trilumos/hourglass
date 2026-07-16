import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/entitlements.dart';

void main() {
  group('entitlementsFrom', () {
    test('no active entitlements -> free, only sand owned', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {},
          catalogThemeIds: const {'obsidian'},
          proLifetime: false);
      expect(e.pro, isFalse);
      expect(e.ownedThemeIds, {'sand'});
      expect(e.ownsTheme('sand'), isTrue);
      expect(e.ownsTheme('obsidian'), isFalse);
    });

    test('pro LIFETIME -> pro true and owns every catalog theme', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'pro'},
          catalogThemeIds: const {'obsidian', 'sage'},
          proLifetime: true);
      expect(e.pro, isTrue);
      expect(e.ownedThemeIds, {'sand', 'obsidian', 'sage'});
    });

    test('pro SUBSCRIPTION -> pro true but NO themes (they are one-time goods)',
        () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'pro'},
          catalogThemeIds: const {'obsidian', 'sage'},
          proLifetime: false);
      expect(e.pro, isTrue, reason: 'every Pro feature is still unlocked');
      expect(e.ownedThemeIds, {'sand'});
      expect(e.ownsTheme('obsidian'), isFalse);
    });

    test('a subscriber keeps themes bought a la carte', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'pro', 'theme_obsidian'},
          catalogThemeIds: const {'obsidian', 'sage'},
          proLifetime: false);
      expect(e.pro, isTrue);
      expect(e.ownedThemeIds, {'sand', 'obsidian'});
      expect(e.ownsTheme('sage'), isFalse);
    });

    test('proLifetime without an active pro entitlement grants no themes', () {
      // Guards the caller mis-deriving lifetime (e.g. a null expiry on absent
      // Pro reading as "lifetime"). Pro must be present for themes to unlock.
      final e = entitlementsFrom(
          activeEntitlementIds: const {},
          catalogThemeIds: const {'obsidian', 'sage'},
          proLifetime: true);
      expect(e.pro, isFalse);
      expect(e.ownedThemeIds, {'sand'});
    });

    test('a single theme entitlement -> owns that theme, not pro', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'theme_obsidian'},
          catalogThemeIds: const {'obsidian', 'sage'},
          proLifetime: false);
      expect(e.pro, isFalse);
      expect(e.ownedThemeIds, {'sand', 'obsidian'});
      expect(e.ownsTheme('sage'), isFalse);
    });

    test('free constant owns only sand', () {
      expect(Entitlements.free.pro, isFalse);
      expect(Entitlements.free.ownedThemeIds, {'sand'});
    });
  });
}
