import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/billing_config.dart';

void main() {
  test('catalog has Sand plus the 9 premium themes', () {
    expect(HgThemes.all.first.id, 'sand');
    final ids = HgThemes.all.map((t) => t.id).toList();
    expect(ids, containsAll(<String>[
      'sand', 'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir',
      'mocha', 'aurora',
    ]));
    expect(HgThemes.all.length, 10);
    expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
  });

  test('kCatalogThemeIds is the 9 premium ids (no sand)', () {
    expect(kCatalogThemeIds, <String>{
      'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha',
      'aurora',
    });
    expect(kCatalogThemeIds.contains('sand'), isFalse);
    // Every premium id has a catalog theme, and vice versa.
    final premium = HgThemes.all.map((t) => t.id).where((id) => id != 'sand').toSet();
    expect(premium, kCatalogThemeIds);
  });

  test('every theme supplies non-null light/dark tokens and skins', () {
    for (final t in HgThemes.all) {
      expect(t.light, isNotNull, reason: '${t.id} light');
      expect(t.dark, isNotNull, reason: '${t.id} dark');
      expect(t.skinFor(Brightness.dark), same(t.darkSkin), reason: '${t.id} dark skin');
      expect(t.skinFor(Brightness.light), same(t.lightSkin), reason: '${t.id} light skin');
      // The locked rule: falling sand == bulb sand in every skin.
      expect(t.darkSkin.grainColor, t.darkSkin.sandColor, reason: '${t.id} dark grain');
      expect(t.lightSkin.grainColor, t.lightSkin.sandColor, reason: '${t.id} light grain');
    }
  });

  test('byId falls back to Sand for unknown ids', () {
    expect(HgThemes.byId('nope').id, 'sand');
    expect(HgThemes.byId('obsidian').id, 'obsidian');
  });

  test('kThemeProductId maps id to theme.<id>', () {
    expect(kThemeProductId('obsidian'), 'theme.obsidian');
  });

  test('every theme has a living sand cycle (light + dark)', () {
    for (final t in HgThemes.all) {
      expect(t.darkSkin.sandCycle, isNotNull, reason: '${t.id} dark cycle');
      expect(t.darkSkin.sandCycle!.length, greaterThan(1), reason: '${t.id} dark');
      expect(t.lightSkin.sandCycle, isNotNull, reason: '${t.id} light cycle');
      expect(t.lightSkin.sandCycle!.length, greaterThan(1), reason: '${t.id} light');
    }
  });

  test('withSand keeps grain matched to the cycled sand (locked rule, dynamic)', () {
    final s = HgThemes.tide.darkSkin.withSand(const Color(0xFF123456));
    expect(s.sandColor, const Color(0xFF123456));
    expect(s.grainColor, s.sandColor);
  });
}
