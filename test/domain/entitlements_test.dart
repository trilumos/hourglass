import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/domain/entitlements.dart';

void main() {
  group('entitlementsFrom', () {
    test('no active entitlements -> free, only sand owned', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {}, catalogThemeIds: const {'obsidian'});
      expect(e.pro, isFalse);
      expect(e.ownedThemeIds, {'sand'});
      expect(e.ownsTheme('sand'), isTrue);
      expect(e.ownsTheme('obsidian'), isFalse);
    });

    test('pro entitlement -> pro true and owns every catalog theme', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'pro'},
          catalogThemeIds: const {'obsidian', 'sage'});
      expect(e.pro, isTrue);
      expect(e.ownedThemeIds, {'sand', 'obsidian', 'sage'});
    });

    test('a single theme entitlement -> owns that theme, not pro', () {
      final e = entitlementsFrom(
          activeEntitlementIds: const {'theme_obsidian'},
          catalogThemeIds: const {'obsidian', 'sage'});
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
