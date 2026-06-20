# Color Themes (v1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 8 premium color themes (+ the free Sand default), each a complete light+dark app palette **and** a matching hourglass skin, sold à la carte and bundled in Pro, with whole-app live preview of locked themes (capped, non-recording preview session) — built on the existing entitlement engine.

**Architecture:** Themes are **data**. `HgTheme` gains a light/dark `HourglassSkin`; all 9 themes live in `HgThemes.all` (Sand explicit, the 8 premium ones built from a small derivation helper so each is correct-by-construction and tunable by editing ~18 seed hex). A new `activeThemeProvider` is the single source of truth the app + hourglass read, resolving in priority order **preview > owned-selected > Sand fallback**. A `previewThemeProvider` (in-memory only) drives live preview. The billing layer gains à-la-carte `themeProducts()`/`purchaseTheme(id)` alongside the existing Pro flow. A Themes screen (Settings → Display) browses/previews/applies/buys; a preview bar overlays the app while previewing; starting a session while previewing runs a `previewMode` SessionScreen capped at ~10s that persists nothing.

**Tech Stack:** Flutter, Riverpod 3.x (`Notifier`/`Provider`), `purchases_flutter` 10.x (RevenueCat), `shared_preferences`, Drift (unchanged here). Serial tests (`flutter test --concurrency=1`).

## Global Constraints

- **Riverpod 3.x** `Notifier`/`NotifierProvider`; no legacy `StateNotifier`.
- **Colors via `.withValues(alpha:)`**, never `.withOpacity`. Read colors through `context.hg.<token>` / theme tokens; never hardcode in widgets.
- **No em dashes** in any user-facing copy. No fabricated stats.
- **Serial tests only:** `flutter test --concurrency=1` (parallel OOMs this box). `flutter analyze` must be clean.
- **Billing stays key-less-safe:** with `kRevenueCatAndroidKey` empty the app uses `FakeBillingService`; everyone is Free; `themeProducts()` is empty → tiles show "In Pro"; no purchase is possible; dev-unlock (debug only) previews ownership. Pro never set from anything but verified entitlement state.
- **LOCKED hourglass rules (founder):** falling sand colour == bulb sand colour (`HourglassSkin.grainColor` getter returns `sandColor`; new skins set only `sandColor`). Fine falling-sand particle look is locked. Do not touch the painter/particle style — only supply per-theme `sandColor`/glass values.
- **Preview records NOTHING:** a `previewMode` session must never call `SessionFinalizer.persist` / `reviseRecordedFocus`, never start the checkpoint timer, and never invalidate stats providers. No Focus Score, streak, Today, or history may change from a preview.
- **Preview is never persisted:** `previewThemeProvider` is in-memory; a relaunch is never stuck in preview.
- **Fallback safety:** `activeThemeProvider` returns Sand whenever the selected theme is not owned (never bought / Pro lapsed / refund). Stored `themeId` is kept but not *applied* while unowned.

---

### Task 1: Theme catalog — `HgTheme` skins + the 8 premium themes

**Files:**
- Modify: `lib/app/tokens.dart` (add skin fields to `HgTheme`; add `skinFor`; add the 8 premium themes + a private builder; set Sand's skins)
- Modify: `lib/hourglass/hourglass_skin.dart` (no behavior change; ensure `classic`/`classicLight` remain Sand's skins — they already are)
- Modify: `lib/billing/billing_config.dart` (populate `kCatalogThemeIds` with the 8 ids; add `kThemeProductId` helper)
- Test: `test/app/theme_catalog_test.dart` (new)

**Interfaces:**
- Consumes: `HgTokens` (existing), `HourglassSkin` (existing, from `lib/hourglass/hourglass_skin.dart`).
- Produces:
  - `class HgTheme { final String id, name; final HgTokens light, dark; final HourglassSkin lightSkin, darkSkin; HourglassSkin skinFor(Brightness b); }`
  - `HgThemes.all` = `List<HgTheme>` of 9 (sand + obsidian, sage, rose, indigo, dusk, tide, noir, mocha) — now `static final` (builder is not const).
  - `HgThemes.byId(String id)` → falls back to `sand`.
  - `const Set<String> kCatalogThemeIds` = the 8 premium ids.
  - `String kThemeProductId(String themeId)` → `'theme.$themeId'`.

- [ ] **Step 1: Write the failing catalog test**

Create `test/app/theme_catalog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/billing_config.dart';

void main() {
  test('catalog has Sand plus the 8 premium themes', () {
    expect(HgThemes.all.first.id, 'sand');
    final ids = HgThemes.all.map((t) => t.id).toList();
    expect(ids, containsAll(<String>[
      'sand', 'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha',
    ]));
    expect(HgThemes.all.length, 9);
    expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
  });

  test('kCatalogThemeIds is the 8 premium ids (no sand)', () {
    expect(kCatalogThemeIds, <String>{
      'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha',
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
}
```

- [ ] **Step 2: Run it to confirm it fails**

Run: `flutter test --concurrency=1 test/app/theme_catalog_test.dart`
Expected: FAIL (no `skinFor`, no premium themes, `kCatalogThemeIds` empty).

- [ ] **Step 3: Add skin fields + `skinFor` to `HgTheme`, and the premium builder + themes**

In `lib/app/tokens.dart`, add the import at the top:

```dart
import '../hourglass/hourglass_skin.dart';
```

Replace the `HgTheme` class (lines ~119-131) with:

```dart
/// A named identity. Every theme ships BOTH a light and a dark variant (tokens)
/// and a light/dark hourglass skin; the user's mode (light/dark/system) composes
/// orthogonally.
@immutable
class HgTheme {
  final String id;
  final String name;
  final HgTokens light;
  final HgTokens dark;
  final HourglassSkin lightSkin;
  final HourglassSkin darkSkin;
  const HgTheme({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
    required this.lightSkin,
    required this.darkSkin,
  });

  /// The hourglass skin for the active brightness.
  HourglassSkin skinFor(Brightness b) =>
      b == Brightness.dark ? darkSkin : lightSkin;
}
```

Give Sand its skins — in the `static const sand = HgTheme(...)` add, after `light: HgTokens(...)`:

```dart
    lightSkin: HourglassSkin.classicLight,
    darkSkin: HourglassSkin.classic,
```

Replace `static const all = <HgTheme>[sand];` and `byId` with the builder + full catalog:

```dart
  // ── Premium themes ─────────────────────────────────────────────────────────
  // Each is built from research-seeded core hex (spec §1.1), tuned on-device with
  // the founder. The derivation below mirrors Sand's own relationships so every
  // theme is correct-by-construction: backdrop/sunken are darkened steps of bg,
  // glow is the accent at Sand's alphas (12% dark / 8% light), the semantic
  // success/warning/danger trio is shared (functional, not brand), and the
  // hourglass glass mirrors Sand's locked skins (white tints in dark; the theme's
  // dark text colour as the glass body in light) so only the sand MATERIAL
  // (sandColor) changes per theme — keeping the locked falling-sand rule intact.
  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  static HgTheme _premium({
    required String id,
    required String name,
    required Color dBg,
    required Color dSurface,
    required Color dRaised,
    required Color dText,
    required Color dText2,
    required Color dText3,
    required Color dAccent,
    required Color dAccentMuted,
    required Color dOnAccent,
    required Color dHairline,
    required Color lBg,
    required Color lSurface,
    required Color lText,
    required Color lText2,
    required Color lAccent,
    required Color lAccentMuted,
    required Color lHairline,
    required Color sandDark,
    required Color sandLight,
  }) {
    final dark = HgTokens(
      backdrop: _mix(dBg, _black, 0.5),
      background: dBg,
      surface: dSurface,
      surfaceRaised: dRaised,
      surfaceSunken: _mix(dBg, _black, 0.18),
      textPrimary: dText,
      textSecondary: dText2,
      textMuted: dText3,
      accent: dAccent,
      accentMuted: dAccentMuted,
      onAccent: dOnAccent,
      hairline: dHairline,
      glow: dAccent.withValues(alpha: 0.12),
      focusRing: dAccent,
      scrim: const Color(0xB3000000),
      success: const Color(0xFF9BC59A),
      warning: const Color(0xFFE0B873),
      danger: const Color(0xFFD98A7A),
    );
    final light = HgTokens(
      backdrop: _mix(lBg, _black, 0.045),
      background: lBg,
      surface: lSurface,
      surfaceRaised: lSurface,
      surfaceSunken: _mix(lBg, _black, 0.07),
      textPrimary: lText,
      textSecondary: lText2,
      textMuted: _mix(lText2, lBg, 0.32),
      accent: lAccent,
      accentMuted: lAccentMuted,
      onAccent: _white,
      hairline: lHairline,
      glow: lAccent.withValues(alpha: 0.08),
      focusRing: lAccent,
      scrim: const Color(0x40000000),
      success: const Color(0xFF4F7A4D),
      warning: const Color(0xFF9A6F1E),
      danger: const Color(0xFFA8503C),
    );
    final darkSkin = HourglassSkin(
      id: id,
      sandColor: sandDark,
      glassTint: const Color(0x14FFFFFF),
      glassOutline: const Color(0x33FFFFFF),
      neckWidth: 0.012,
    );
    final lightSkin = HourglassSkin(
      id: id,
      sandColor: sandLight,
      glassTint: lText, // opaque dark glass body (mirrors classicLight)
      glassOutline: lText.withValues(alpha: 0.2),
      neckWidth: 0.012,
    );
    return HgTheme(
      id: id,
      name: name,
      light: light,
      dark: dark,
      lightSkin: lightSkin,
      darkSkin: darkSkin,
    );
  }

  static final obsidian = _premium(
    id: 'obsidian', name: 'Obsidian',
    dBg: const Color(0xFF0E1117), dSurface: const Color(0xFF161B24), dRaised: const Color(0xFF1E2530),
    dText: const Color(0xFFE6EAF2), dText2: const Color(0xFFA6AFBF), dText3: const Color(0xFF6E7686),
    dAccent: const Color(0xFF9DB8E0), dAccentMuted: const Color(0xFF25303F), dOnAccent: const Color(0xFF0B0F16), dHairline: const Color(0xFF232A36),
    lBg: const Color(0xFFF4F6FA), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF141821), lText2: const Color(0xFF4C5566),
    lAccent: const Color(0xFF3E5C86), lAccentMuted: const Color(0xFFDCE5F2), lHairline: const Color(0xFFDEE4EE),
    sandDark: const Color(0xFFC9D6EC), sandLight: const Color(0xFF6E86AE),
  );

  static final sage = _premium(
    id: 'sage', name: 'Sage',
    dBg: const Color(0xFF11160F), dSurface: const Color(0xFF1A2117), dRaised: const Color(0xFF222B1D),
    dText: const Color(0xFFE7EDE2), dText2: const Color(0xFFA8B3A0), dText3: const Color(0xFF717C6A),
    dAccent: const Color(0xFFA3C58C), dAccentMuted: const Color(0xFF2A331F), dOnAccent: const Color(0xFF11160F), dHairline: const Color(0xFF262E20),
    lBg: const Color(0xFFF3F6EF), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF161B12), lText2: const Color(0xFF4F5848),
    lAccent: const Color(0xFF5E7B43), lAccentMuted: const Color(0xFFE0E8D4), lHairline: const Color(0xFFDEE5D3),
    sandDark: const Color(0xFFCBD9A8), sandLight: const Color(0xFF8A9A55),
  );

  static final rose = _premium(
    id: 'rose', name: 'Rosé',
    dBg: const Color(0xFF17110F), dSurface: const Color(0xFF211915), dRaised: const Color(0xFF2A1F1B),
    dText: const Color(0xFFF0E6E4), dText2: const Color(0xFFBBA8A4), dText3: const Color(0xFF87746F),
    dAccent: const Color(0xFFD6A8A0), dAccentMuted: const Color(0xFF382626), dOnAccent: const Color(0xFF170F0E), dHairline: const Color(0xFF2E2422),
    lBg: const Color(0xFFFAF2F0), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF1F1513), lText2: const Color(0xFF5C4D49),
    lAccent: const Color(0xFFA65F58), lAccentMuted: const Color(0xFFF1DBD6), lHairline: const Color(0xFFECD9D4),
    sandDark: const Color(0xFFE6C4A8), sandLight: const Color(0xFFC08A6E),
  );

  static final indigo = _premium(
    id: 'indigo', name: 'Indigo',
    dBg: const Color(0xFF0E1020), dSurface: const Color(0xFF161A30), dRaised: const Color(0xFF1E2440),
    dText: const Color(0xFFE7E9F7), dText2: const Color(0xFFA6ABCF), dText3: const Color(0xFF6E7299),
    dAccent: const Color(0xFF9C8CF0), dAccentMuted: const Color(0xFF262A4D), dOnAccent: const Color(0xFF0B0D1A), dHairline: const Color(0xFF232845),
    lBg: const Color(0xFFF3F3FB), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF131526), lText2: const Color(0xFF4C4F6E),
    lAccent: const Color(0xFF5B4BC4), lAccentMuted: const Color(0xFFE2DEF7), lHairline: const Color(0xFFDEDFF1),
    sandDark: const Color(0xFFE8E0B4), sandLight: const Color(0xFFA99A60),
  );

  static final dusk = _premium(
    id: 'dusk', name: 'Dusk',
    dBg: const Color(0xFF16131C), dSurface: const Color(0xFF201C29), dRaised: const Color(0xFF292333),
    dText: const Color(0xFFECE7F2), dText2: const Color(0xFFB3A9C0), dText3: const Color(0xFF7E7390),
    dAccent: const Color(0xFFC3A8E0), dAccentMuted: const Color(0xFF322940), dOnAccent: const Color(0xFF16131C), dHairline: const Color(0xFF2B2535),
    lBg: const Color(0xFFF7F3FB), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF1A1521), lText2: const Color(0xFF564C62),
    lAccent: const Color(0xFF7E5CA8), lAccentMuted: const Color(0xFFEADFF4), lHairline: const Color(0xFFE7DEF0),
    sandDark: const Color(0xFFDCC8EC), sandLight: const Color(0xFFA98AC0),
  );

  static final tide = _premium(
    id: 'tide', name: 'Tide',
    dBg: const Color(0xFF0A1618), dSurface: const Color(0xFF112224), dRaised: const Color(0xFF182E30),
    dText: const Color(0xFFE0EEEC), dText2: const Color(0xFF9FB6B3), dText3: const Color(0xFF6A807D),
    dAccent: const Color(0xFF5FC2B6), dAccentMuted: const Color(0xFF1C3331), dOnAccent: const Color(0xFF07100F), dHairline: const Color(0xFF1E302F),
    lBg: const Color(0xFFEEF6F4), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF0E1A19), lText2: const Color(0xFF46544F),
    lAccent: const Color(0xFF1F7D74), lAccentMuted: const Color(0xFFD6EAE6), lHairline: const Color(0xFFD7E6E2),
    sandDark: const Color(0xFFBFE3D9), sandLight: const Color(0xFF6FA89D),
  );

  static final noir = _premium(
    id: 'noir', name: 'Noir',
    dBg: const Color(0xFF000000), dSurface: const Color(0xFF0E0E0E), dRaised: const Color(0xFF161616),
    dText: const Color(0xFFF2EFE6), dText2: const Color(0xFFADA893), dText3: const Color(0xFF75715F),
    dAccent: const Color(0xFFD9B871), dAccentMuted: const Color(0xFF2E2716), dOnAccent: const Color(0xFF14110A), dHairline: const Color(0xFF201F1C),
    lBg: const Color(0xFFF6F4EE), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF14130F), lText2: const Color(0xFF524E43),
    lAccent: const Color(0xFF997523), lAccentMuted: const Color(0xFFECE0C4), lHairline: const Color(0xFFE5DFD0),
    sandDark: const Color(0xFFE8C66E), sandLight: const Color(0xFFB5892F),
  );

  static final mocha = _premium(
    id: 'mocha', name: 'Mocha',
    dBg: const Color(0xFF18120E), dSurface: const Color(0xFF221A14), dRaised: const Color(0xFF2C211A),
    dText: const Color(0xFFEFE6DC), dText2: const Color(0xFFB6A593), dText3: const Color(0xFF82715F),
    dAccent: const Color(0xFFD7A66B), dAccentMuted: const Color(0xFF38291B), dOnAccent: const Color(0xFF160F09), dHairline: const Color(0xFF2C231B),
    lBg: const Color(0xFFF6F0E8), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF1B140D), lText2: const Color(0xFF574A3C),
    lAccent: const Color(0xFF9B6B35), lAccentMuted: const Color(0xFFEBDDC6), lHairline: const Color(0xFFE8DCCB),
    sandDark: const Color(0xFFECD3AE), sandLight: const Color(0xFFC39A63),
  );

  /// The theme catalog (Sand first as the free default). Add a theme = append here.
  static final List<HgTheme> all = <HgTheme>[
    sand, obsidian, sage, rose, indigo, dusk, tide, noir, mocha,
  ];

  static HgTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => sand);
```

- [ ] **Step 4: Populate `kCatalogThemeIds` + add `kThemeProductId`**

In `lib/billing/billing_config.dart`, replace the empty set and add the helper:

```dart
/// Purchasable theme ids (the app catalog minus the always-free 'sand'). Pro
/// grants all of these; each is also sellable à la carte (see kThemeProductId).
const Set<String> kCatalogThemeIds = <String>{
  'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha',
};

/// The Play / RevenueCat **product id** for a theme (a non-consumable). The
/// matching RevenueCat entitlement is `theme_<id>` (see entitlementsFrom).
String kThemeProductId(String themeId) => 'theme.$themeId';
```

- [ ] **Step 5: Run the catalog test — PASS**

Run: `flutter test --concurrency=1 test/app/theme_catalog_test.dart`
Expected: PASS (all 5 tests).

- [ ] **Step 6: Analyze**

Run: `flutter analyze`
Expected: No issues. (If `kThemeProductId` is flagged unused, that is expected until Task 3 — leave it; do not delete.)

- [ ] **Step 7: Commit**

```bash
git add lib/app/tokens.dart lib/billing/billing_config.dart test/app/theme_catalog_test.dart
git commit -m "feat(themes): add 8 premium themes + hourglass skins to the catalog"
```

---

### Task 2: `activeThemeProvider` + `previewThemeProvider`, wired into the app + hourglass

**Files:**
- Create: `lib/app/theme_providers.dart`
- Modify: `lib/app/app.dart` (watch `activeThemeProvider` for tokens; keep `themeMode` from `themeControllerProvider`)
- Modify: `lib/ui/home_screen.dart` (pass `skin:` to its `HourglassView`)
- Modify: `lib/ui/onboarding_screen.dart` (pass `skin:`)
- Modify: `lib/ui/session_screen.dart` (pass `skin:` to BOTH the running + the completion `HourglassView`)
- Test: `test/app/theme_providers_test.dart` (new)

**Interfaces:**
- Consumes: `HgThemes`, `HgTheme` (Task 1); `entitlementsProvider`, `themeControllerProvider` (existing).
- Produces:
  - `final previewThemeProvider = NotifierProvider<PreviewTheme, String?>(PreviewTheme.new);`
    `class PreviewTheme extends Notifier<String?> { String? build()=>null; void set(String id); void clear(); }`
  - `final activeThemeProvider = Provider<HgTheme>(...)` — priority: preview > owned-selected > Sand.

- [ ] **Step 1: Write the failing provider test**

Create `test/app/theme_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({Entitlements? initial}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = FakeBillingService(initial: initial ?? Entitlements.free);
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    billingServiceProvider.overrideWithValue(fake),
  ]);
  addTearDown(c.dispose);
  addTearDown(fake.dispose);
  return c;
}

void main() {
  test('defaults to Sand when nothing selected/owned', () async {
    final c = await _container();
    expect(c.read(activeThemeProvider).id, 'sand');
  });

  test('selected-but-unowned falls back to Sand', () async {
    final c = await _container();
    c.read(themeControllerProvider.notifier).setTheme('obsidian');
    expect(c.read(activeThemeProvider).id, 'sand');
  });

  test('selected-and-owned applies', () async {
    final c = await _container(
        initial: const Entitlements(pro: false, ownedThemeIds: {'sand', 'obsidian'}));
    c.read(themeControllerProvider.notifier).setTheme('obsidian');
    expect(c.read(activeThemeProvider).id, 'obsidian');
  });

  test('Pro owns all → any selected theme applies', () async {
    final c = await _container(
        initial: const Entitlements(pro: true, ownedThemeIds: {'sand', 'noir'}));
    c.read(themeControllerProvider.notifier).setTheme('noir');
    expect(c.read(activeThemeProvider).id, 'noir');
  });

  test('preview overrides ownership and clears back', () async {
    final c = await _container();
    c.read(previewThemeProvider.notifier).set('tide');
    expect(c.read(activeThemeProvider).id, 'tide'); // unowned, still previews
    c.read(previewThemeProvider.notifier).clear();
    expect(c.read(activeThemeProvider).id, 'sand');
  });

  test('preview of an unknown id resolves safely to Sand', () async {
    final c = await _container();
    c.read(previewThemeProvider.notifier).set('bogus');
    expect(c.read(activeThemeProvider).id, 'sand');
  });
}
```

- [ ] **Step 2: Run it — FAIL**

Run: `flutter test --concurrency=1 test/app/theme_providers_test.dart`
Expected: FAIL (`theme_providers.dart` does not exist).

- [ ] **Step 3: Create `lib/app/theme_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'billing_providers.dart';
import 'theme_controller.dart';
import 'tokens.dart';

/// The id of the theme currently being previewed ("try it on"), or null. IN
/// MEMORY ONLY — never persisted, so a relaunch is never stuck in preview. Set
/// by "Preview", cleared by "Exit" or when a purchase makes the theme owned.
class PreviewTheme extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String themeId) => state = themeId;
  void clear() => state = null;
}

final previewThemeProvider =
    NotifierProvider<PreviewTheme, String?>(PreviewTheme.new);

/// The single source of truth for the look the app + hourglass render, resolved
/// in priority order:
///   1. the PREVIEW theme, if previewing (regardless of ownership);
///   2. else the SELECTED theme, if owned;
///   3. else SAND (free fallback — covers never-bought, Pro lapsed, refund).
/// The stored themeId is kept even when unowned (so renewing restores the look);
/// it is simply not applied while unowned.
final activeThemeProvider = Provider<HgTheme>((ref) {
  final preview = ref.watch(previewThemeProvider);
  if (preview != null) return HgThemes.byId(preview);

  final selectedId = ref.watch(themeControllerProvider).themeId;
  final entitlements = ref.watch(entitlementsProvider);
  if (entitlements.ownsTheme(selectedId)) return HgThemes.byId(selectedId);

  return HgThemes.sand;
});
```

- [ ] **Step 4: Run the provider test — PASS**

Run: `flutter test --concurrency=1 test/app/theme_providers_test.dart`
Expected: PASS (all 6 tests).

- [ ] **Step 5: Wire `app.dart` to `activeThemeProvider`**

Replace the body of `HourglassApp.build` in `lib/app/app.dart`:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(activeThemeProvider);
    final mode = ref.watch(themeControllerProvider).mode;
    return MaterialApp(
      title: 'Sustain',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(theme.light, Brightness.light),
      darkTheme: buildTheme(theme.dark, Brightness.dark),
      themeMode: mode,
      home: const RootGate(),
    );
  }
```

Update the imports in `app.dart`: add `import 'theme_providers.dart';` and keep `theme_controller.dart` (still used for `mode`). Remove the now-unused `tokens.dart` import only if analyze flags it (it may still be needed elsewhere — let analyze decide).

- [ ] **Step 6: Pass `skin:` at the 4 hourglass callers**

**Home** (`lib/ui/home_screen.dart` ~line 113): the widget is `const HourglassView(...)`. Make it non-const and add the skin. It is built inside a `ConsumerWidget`/`Consumer` (it already reads providers). Change:

```dart
                      child: HourglassView(
                        progress: 0,
                        ambient: true, // alive idle fall, full top, no pile
                        heroTag: kHourglassHeroTag,
                        skin: ref
                            .watch(activeThemeProvider)
                            .skinFor(Theme.of(context).brightness),
                      ),
```

Add `import '../app/theme_providers.dart';` to `home_screen.dart` if not already imported. Confirm `ref` and `context` are in scope at that point (Home's build is a Consumer; if the hourglass sits inside a non-Consumer builder, wrap that subtree in a `Consumer(builder: (context, ref, _) => HourglassView(...))`). Verify by reading the surrounding widget before editing.

**Onboarding** (`lib/ui/onboarding_screen.dart` ~line 260): add the same `skin:` argument. Confirm a `ref` is in scope (onboarding is a Consumer); else wrap in `Consumer`.

**Session — running** (`lib/ui/session_screen.dart` ~line 669): add `skin: ref.watch(activeThemeProvider).skinFor(Theme.of(context).brightness),`. `SessionScreen` is a `ConsumerStatefulWidget`, so `ref` is available in `build`.

**Session — completion** (`lib/ui/session_screen.dart` ~line 1030): `const HourglassView(progress: 1, animate: false)` → make non-const and add the same `skin:`. Confirm `ref`/`context` are in scope in that builder; if it is a separate method without `ref`, read `ref`/`context` from the enclosing state (the state has `ref` via `ConsumerState`).

Add `import '../app/theme_providers.dart';` to `session_screen.dart`.

(Leave `lib/hourglass/hourglass_preview.dart` untouched — it is a dev-only harness, not user-facing; its no-skin default stays Sand.)

- [ ] **Step 7: Analyze + full test suite**

Run: `flutter analyze`
Expected: clean.
Run: `flutter test --concurrency=1`
Expected: all green (existing 216 + the new catalog/provider tests). Fix any regression before committing.

- [ ] **Step 8: Commit**

```bash
git add lib/app/theme_providers.dart lib/app/app.dart lib/ui/home_screen.dart lib/ui/onboarding_screen.dart lib/ui/session_screen.dart test/app/theme_providers_test.dart
git commit -m "feat(themes): activeThemeProvider + previewThemeProvider; recolor app + hourglass live"
```

---

### Task 3: À-la-carte billing extension (`ThemeProduct`, `themeProducts`, `purchaseTheme`)

**Files:**
- Modify: `lib/billing/billing_service.dart` (add `ThemeProduct`; add two methods to the `BillingService` interface)
- Modify: `lib/billing/fake_billing_service.dart` (implement them; scriptable + grants `theme_<id>` on success)
- Modify: `lib/billing/revenuecat_billing_service.dart` (implement via `Purchases.getProducts` / `Purchases.purchase(PurchaseParams.storeProduct(...))`)
- Test: `test/billing/fake_billing_service_test.dart` (extend), `test/app/billing_providers_test.dart` (extend for theme unlock)

**Interfaces:**
- Consumes: `Entitlements`, `PurchaseOutcome`, `kCatalogThemeIds`, `kThemeProductId` (Tasks 1 + existing).
- Produces:
  - `class ThemeProduct { final String themeId; final String priceString; final Object raw; const ThemeProduct({...}); }`
  - On `BillingService`: `Future<List<ThemeProduct>> themeProducts();` and `Future<PurchaseOutcome> purchaseTheme(String themeId);`

- [ ] **Step 1: Write failing Fake tests**

Add to `test/billing/fake_billing_service_test.dart` (inside `main()`):

```dart
  test('purchaseTheme success grants theme_<id> and emits', () async {
    final fake = FakeBillingService(nextThemePurchase: PurchaseOutcome.success);
    addTearDown(fake.dispose);
    final emits = <Entitlements>[];
    final sub = fake.entitlements().listen(emits.add);
    addTearDown(sub.cancel);

    final outcome = await fake.purchaseTheme('obsidian');
    await Future<void>.delayed(Duration.zero);

    expect(outcome, PurchaseOutcome.success);
    expect(fake.current.ownsTheme('obsidian'), isTrue);
    expect(emits.last.ownsTheme('obsidian'), isTrue);
  });

  test('purchaseTheme cancelled leaves ownership unchanged', () async {
    final fake = FakeBillingService(nextThemePurchase: PurchaseOutcome.cancelled);
    addTearDown(fake.dispose);
    final outcome = await fake.purchaseTheme('sage');
    expect(outcome, PurchaseOutcome.cancelled);
    expect(fake.current.ownsTheme('sage'), isFalse);
  });

  test('themeProducts returns the scripted list', () async {
    final fake = FakeBillingService(themeProductList: const [
      ThemeProduct(themeId: 'tide', priceString: r'$1.99', raw: 'x'),
    ]);
    addTearDown(fake.dispose);
    final products = await fake.themeProducts();
    expect(products.single.themeId, 'tide');
    expect(products.single.priceString, r'$1.99');
  });

  test('themeProducts defaults to empty (key-less)', () async {
    final fake = FakeBillingService();
    addTearDown(fake.dispose);
    expect(await fake.themeProducts(), isEmpty);
  });
```

- [ ] **Step 2: Run — FAIL**

Run: `flutter test --concurrency=1 test/billing/fake_billing_service_test.dart`
Expected: FAIL (`ThemeProduct`, `themeProducts`, `purchaseTheme`, `nextThemePurchase`, `themeProductList` undefined).

- [ ] **Step 3: Add `ThemeProduct` + interface methods**

In `lib/billing/billing_service.dart`, add after the `ProOffering` class:

```dart
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
```

Add to the `abstract class BillingService` (after `proOffering`):

```dart
  /// The purchasable themes (à la carte). Empty when unavailable (offline /
  /// key-less / no products configured). Pro grants all themes regardless.
  Future<List<ThemeProduct>> themeProducts();

  /// Purchase a single theme. On success the `theme_<id>` entitlement becomes
  /// active and the entitlements stream emits. Reuses [PurchaseOutcome].
  Future<PurchaseOutcome> purchaseTheme(String themeId);
```

- [ ] **Step 4: Implement on `FakeBillingService`**

In `lib/billing/fake_billing_service.dart`, add fields to the class + constructor:

```dart
  List<ThemeProduct> themeProductList;
  PurchaseOutcome nextThemePurchase;
```

Constructor — add the two named params with defaults:

```dart
  FakeBillingService({
    Entitlements initial = Entitlements.free,
    this.offering,
    this.nextPurchase = PurchaseOutcome.success,
    this.nextRestore = RestoreOutcome.nothingToRestore,
    this.themeProductList = const [],
    this.nextThemePurchase = PurchaseOutcome.success,
  }) : _current = initial;
```

Add the two methods (before `dispose`):

```dart
  @override
  Future<List<ThemeProduct>> themeProducts() async => themeProductList;

  @override
  Future<PurchaseOutcome> purchaseTheme(String themeId) async {
    if (nextThemePurchase == PurchaseOutcome.success ||
        nextThemePurchase == PurchaseOutcome.alreadyOwned) {
      _current = _current.copyWith(
        ownedThemeIds: {..._current.ownedThemeIds, themeId},
      );
      _controller.add(_current);
    }
    return nextThemePurchase;
  }
```

- [ ] **Step 5: Run Fake tests — PASS**

Run: `flutter test --concurrency=1 test/billing/fake_billing_service_test.dart`
Expected: PASS.

- [ ] **Step 6: Implement on `RevenueCatBillingService`**

In `lib/billing/revenuecat_billing_service.dart`, add `import 'billing_config.dart';` is already present. Add the two methods (before `dispose`):

```dart
  @override
  Future<List<ThemeProduct>> themeProducts() async {
    if (kCatalogThemeIds.isEmpty) return const [];
    try {
      final wantedIds = {for (final id in kCatalogThemeIds) kThemeProductId(id)};
      final products = await Purchases.getProducts(wantedIds.toList());
      final out = <ThemeProduct>[];
      for (final p in products) {
        // Recover the theme id from the product id (kThemeProductId == 'theme.<id>').
        final id = _themeIdOf(p.identifier);
        if (id == null || !kCatalogThemeIds.contains(id)) continue;
        out.add(ThemeProduct(
          themeId: id,
          priceString: p.priceString,
          raw: p,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<PurchaseOutcome> purchaseTheme(String themeId) async {
    try {
      final wanted = kThemeProductId(themeId);
      final products = await Purchases.getProducts([wanted]);
      final match =
          products.where((p) => p.identifier == wanted).cast<StoreProduct?>();
      final product = match.isEmpty ? null : match.first;
      if (product == null) return PurchaseOutcome.error;
      final result =
          await Purchases.purchase(PurchaseParams.storeProduct(product));
      _update(result.customerInfo);
      return _current.ownsTheme(themeId)
          ? PurchaseOutcome.success
          : PurchaseOutcome.pending;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      if (code == PurchasesErrorCode.paymentPendingError) {
        return PurchaseOutcome.pending;
      }
      if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        try {
          _update(await Purchases.getCustomerInfo());
        } catch (_) {/* leave _current as-is */}
        return _current.ownsTheme(themeId)
            ? PurchaseOutcome.alreadyOwned
            : PurchaseOutcome.error;
      }
      return PurchaseOutcome.error;
    } catch (_) {
      return PurchaseOutcome.error;
    }
  }

  /// 'theme.obsidian' → 'obsidian'. Mirrors [kThemeProductId]. Null if no match.
  String? _themeIdOf(String productId) {
    const prefix = 'theme.';
    if (!productId.startsWith(prefix)) return null;
    return productId.substring(prefix.length);
  }
```

> Note: `PurchaseParams.storeProduct` and `Purchases.getProducts` are part of `purchases_flutter` 10.x (already imported via `package:purchases_flutter/purchases_flutter.dart`). If the analyzer reports a different constructor name for `PurchaseParams` in the installed version, check the installed API with `Get-Content` on the package's `purchases_flutter.dart` exports and adjust to the version's actual symbol — do not guess. This file is never executed key-less (Fake is used), but it MUST compile.

- [ ] **Step 7: Extend the providers test for live theme unlock**

Add to `test/app/billing_providers_test.dart` (inside `main()`):

```dart
  test('a theme purchase unlocks it live through entitlementsProvider', () async {
    final fake = FakeBillingService();
    final container = ProviderContainer(
        overrides: [billingServiceProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    addTearDown(fake.dispose);

    expect(container.read(entitlementsProvider).ownsTheme('obsidian'), isFalse);

    await fake.purchaseTheme('obsidian');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(entitlementsProvider).ownsTheme('obsidian'), isTrue);
  });
```

- [ ] **Step 8: Analyze + full suite + commit**

Run: `flutter analyze` (clean), then `flutter test --concurrency=1` (green).

```bash
git add lib/billing/billing_service.dart lib/billing/fake_billing_service.dart lib/billing/revenuecat_billing_service.dart test/billing/fake_billing_service_test.dart test/app/billing_providers_test.dart
git commit -m "feat(billing): à-la-carte theme products (themeProducts/purchaseTheme); Pro still unlocks all"
```

---

### Task 4: Themes screen (browse / preview / apply / buy) + Settings entry

**Files:**
- Create: `lib/ui/themes_screen.dart` (grid of tiles + a tap-through preview sheet)
- Modify: `lib/ui/settings_screen.dart` (a "Themes" action row in the DISPLAY section)
- Test: `test/ui/themes_screen_test.dart` (new)

**Interfaces:**
- Consumes: `HgThemes`/`HgTheme` (Task 1), `activeThemeProvider`/`previewThemeProvider` (Task 2), `entitlementsProvider`, `themeControllerProvider`, `billingServiceProvider` (existing), `ThemeProduct`/`purchaseTheme`/`themeProducts` (Task 3), `paywall` route (existing `PaywallScreen` — confirm its exact class name by reading `lib/ui/paywall_screen.dart` before wiring).
- Produces: `class ThemesScreen extends ConsumerStatefulWidget` (navigable). A per-tile state badge resolver: Owned / In Pro / price.

**Design note (impeccable):** this is a paid, user-facing surface — build the visuals to the highest craft with the `impeccable` skill (grid of preview tiles each showing a small static themed hourglass + a 3-swatch chip + name + badge; a calm preview sheet). The code below is the correct, working, tokens-driven structure; the visual refinement pass + on-device palette tuning happen with the founder (Tasks 6 of the spec). Do NOT invent colors — every color comes from `theme.light/dark` tokens or the skin.

- [ ] **Step 1: Confirm the paywall entry point**

Read `lib/ui/paywall_screen.dart` and `lib/ui/settings_screen.dart`'s "Get Pro" row to learn the exact widget/route used to open the paywall. Use that same navigation in the Themes screen's "Get Pro" action. (Do not assume the class name.)

- [ ] **Step 2: Write the failing widget test**

Create `test/ui/themes_screen_test.dart`. It pumps `ThemesScreen` in a `ProviderScope` with overrides, and asserts gating behavior. A helper to load the theme product map and a fake:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:hourglass/ui/themes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app(FakeBillingService fake, SharedPreferences prefs) async {
  return ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      billingServiceProvider.overrideWithValue(fake),
    ],
    child: const MaterialApp(home: ThemesScreen()),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Sand shows as Owned and active by default', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeBillingService();
    addTearDown(fake.dispose);
    await tester.pumpWidget(await _app(fake, prefs));
    await tester.pumpAndSettle();
    expect(find.text('Sand'), findsOneWidget);
    expect(find.text('Owned'), findsWidgets); // at least Sand
  });

  testWidgets('a locked theme opens a sheet with Preview + Get Pro', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeBillingService(); // key-less: no à-la-carte products
    addTearDown(fake.dispose);
    await tester.pumpWidget(await _app(fake, prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Obsidian'));
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    expect(find.textContaining('Pro'), findsWidgets); // "Get Pro" / "In Pro"
  });

  testWidgets('Pro user sees every theme as Owned', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeBillingService(
      initial: Entitlements(pro: true, ownedThemeIds: {
        'sand', 'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha',
      }),
    );
    addTearDown(fake.dispose);
    await tester.pumpWidget(await _app(fake, prefs));
    await tester.pumpAndSettle();
    // Open a previously-locked theme; it should offer Apply, not Buy.
    await tester.tap(find.text('Obsidian'));
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Buy'), findsNothing);
  });

  testWidgets('Preview sets previewThemeProvider', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final fake = FakeBillingService();
    addTearDown(fake.dispose);
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        billingServiceProvider.overrideWithValue(fake),
      ],
      child: Builder(builder: (context) {
        container = ProviderScope.containerOf(context);
        return const MaterialApp(home: ThemesScreen());
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(container.read(previewThemeProvider), 'tide');
  });
}
```

- [ ] **Step 3: Run — FAIL**

Run: `flutter test --concurrency=1 test/ui/themes_screen_test.dart`
Expected: FAIL (`themes_screen.dart` missing).

- [ ] **Step 4: Build `lib/ui/themes_screen.dart`**

A `ConsumerStatefulWidget` that loads `themeProducts()` once (à-la-carte prices, empty when key-less) and renders a grid. Each tile resolves a badge: **Owned** (entitlements.ownsTheme), else **price** if a `ThemeProduct` exists for it, else **In Pro**. Tapping a tile opens a bottom sheet with the right primary action. Use tokens only; embed a small `HourglassView` per tile using the theme's own skin (pass `skin:` explicitly so the tile renders in that theme regardless of the app's active theme).

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme_controller.dart';
import '../app/theme_providers.dart';
import '../app/billing_providers.dart';
import '../app/tokens.dart';
import '../billing/billing_service.dart';
import '../hourglass/hourglass_view.dart';
import 'widgets/screen_background.dart';
// import the paywall using the class name confirmed in Step 1.

/// Browse, preview, apply, and buy color themes. Owned themes apply instantly;
/// locked themes can be previewed live (whole app) and bought à la carte or via
/// Pro. Sand is always free/owned. Reached from Settings → Display → Themes.
class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({super.key});
  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> {
  Map<String, ThemeProduct> _products = const {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await ref.read(billingServiceProvider).themeProducts();
    if (!mounted) return;
    setState(() => _products = {for (final p in list) p.themeId: p});
  }

  @override
  Widget build(BuildContext context) {
    final hg = context.hg;
    final entitlements = ref.watch(entitlementsProvider);
    final activeId = ref.watch(activeThemeProvider).id;
    final selectedId = ref.watch(themeControllerProvider).themeId;

    return Scaffold(
      backgroundColor: hg.background,
      appBar: AppBar(
        backgroundColor: hg.background,
        elevation: 0,
        title: Text('Themes',
            style: TextStyle(fontFamily: HgFont.sans, color: hg.textPrimary)),
      ),
      body: ScreenBackground(
        child: SafeArea(
          child: GridView.count(
            padding: const EdgeInsets.all(HgSpacing.lg),
            crossAxisCount: 2,
            mainAxisSpacing: HgSpacing.md,
            crossAxisSpacing: HgSpacing.md,
            childAspectRatio: 0.74,
            children: [
              for (final theme in HgThemes.all)
                _ThemeTile(
                  theme: theme,
                  owned: entitlements.ownsTheme(theme.id),
                  // The currently-applied look gets the check; while a locked
                  // theme is selected, the active look is Sand (fallback), so the
                  // check follows what is actually on screen.
                  active: theme.id == activeId && theme.id == selectedId,
                  product: _products[theme.id],
                  onTap: () => _openSheet(theme,
                      owned: entitlements.ownsTheme(theme.id),
                      product: _products[theme.id]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(HgTheme theme,
      {required bool owned, ThemeProduct? product}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ThemeSheet(
        theme: theme,
        owned: owned,
        product: product,
        onApply: () {
          ref.read(themeControllerProvider.notifier).setTheme(theme.id);
          ref.read(previewThemeProvider.notifier).clear();
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
        },
        onPreview: () {
          ref.read(previewThemeProvider.notifier).set(theme.id);
          Navigator.of(context).pop();
        },
        onBuy: () async {
          final outcome =
              await ref.read(billingServiceProvider).purchaseTheme(theme.id);
          if (!mounted) return;
          if (outcome == PurchaseOutcome.success) {
            // The entitlements stream unlocks it; apply + leave preview.
            ref.read(themeControllerProvider.notifier).setTheme(theme.id);
            ref.read(previewThemeProvider.notifier).clear();
          }
          Navigator.of(context).pop();
        },
        onGetPro: () {
          Navigator.of(context).pop();
          // Navigator.push(... PaywallScreen ...) — use the confirmed route.
        },
      ),
    );
  }
}
```

Then implement `_ThemeTile` and `_ThemeSheet` as private widgets in the same file:
- `_ThemeTile`: a card (`hg.surface`, `hg.hairline` border, rounded) containing a small `SizedBox(height: ~72, child: HourglassView(progress: 0.5, animate: false, skin: theme.skinFor(brightness)))` over the theme's own `theme.dark.background`/`theme.light.background` (pick by current `Theme.of(context).brightness`) so the tile previews the theme's real colors, a 3-dot swatch row (`background`, `surface`, `accent` from the theme's tokens for the current brightness), the `theme.name`, and a badge built by `_badge(owned, product)` → `'Owned'` / `product.priceString` / `'In Pro'`. Show a check when `active`.
- `_ThemeSheet`: a rounded sheet (`hg.surface`) with a larger themed hourglass, the name + mood line, and the primary action(s): if `owned` → a single `Apply` button; else → `Preview` + (`product != null` ? `Buy <price>` : nothing) + `Get Pro`. All buttons use the existing `PrimaryButton` / a quiet secondary style. Copy has no em dashes.

> The exact spacing/typography/elevation is the impeccable pass. Keep it tokens-only and calm. Reuse `PrimaryButton` from `lib/ui/widgets/primary_button.dart`.

- [ ] **Step 5: Run the widget test — PASS**

Run: `flutter test --concurrency=1 test/ui/themes_screen_test.dart`
Expected: PASS. (If `find.text('Preview')`/`'Apply'` mismatch your button labels, align the labels to the test or the test to the labels — keep them exact: `Apply`, `Preview`, `Buy`, `Get Pro`, `Owned`, `In Pro`.)

- [ ] **Step 6: Add the Settings "Themes" row**

In `lib/ui/settings_screen.dart`, in the DISPLAY section (after the light/dark/system `_ChoiceRow`s, ~line 118, before the `SizedBox(height: HgSpacing.xl)` that closes the section), add:

```dart
                const SizedBox(height: HgSpacing.sm),
                _ActionRow(
                  title: 'Themes',
                  subtitle: 'Color the whole app and the hourglass',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemesScreen()),
                  ),
                ),
```

Add `import 'themes_screen.dart';` to `settings_screen.dart`. (Confirm `_ActionRow` supports `subtitle` — it does, per the About rows.)

- [ ] **Step 7: Analyze + full suite + commit**

Run: `flutter analyze` (clean), `flutter test --concurrency=1` (green).

```bash
git add lib/ui/themes_screen.dart lib/ui/settings_screen.dart test/ui/themes_screen_test.dart
git commit -m "feat(themes): Themes screen (browse/preview/apply/buy) + Settings entry"
```

---

### Task 5: Live preview — preview bar + `previewMode` session (capped, no persist) + Begin interception

**Files:**
- Create: `lib/ui/widgets/preview_bar.dart` (the app-wide "Previewing X · Get it / Exit" overlay)
- Modify: `lib/app/root_gate.dart` (or wherever the app shell wraps screens) to overlay the preview bar when previewing — confirm the shell by reading `root_gate.dart` first
- Modify: `lib/ui/session_screen.dart` (add `previewMode`; cap ~10s; skip ALL persistence; show a buy/exit prompt at the end)
- Modify: `lib/ui/setup_screen.dart` (when previewing, launch the session in `previewMode`)
- Test: `test/ui/preview_session_test.dart` (new), extend `test/app/theme_providers_test.dart` if needed

**Interfaces:**
- Consumes: `previewThemeProvider`, `activeThemeProvider` (Task 2); `HgThemes.byId` (Task 1).
- Produces: `SessionScreen({required config, ticker, now, bool previewMode = false})`; `PreviewBar` widget.

- [ ] **Step 1: Read the app shell**

Read `lib/app/root_gate.dart` to find where the persistent app scaffold lives (the widget that hosts Home/Insights/Settings under the app). The preview bar overlays *that* so it shows across the app while previewing, but NOT during onboarding. Decide the insertion point (likely a `Stack` wrapping the shell's body with the `PreviewBar` pinned to the bottom). Record the exact widget/line.

- [ ] **Step 2: Build `PreviewBar`**

Create `lib/ui/widgets/preview_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_providers.dart';
import '../../app/tokens.dart';

/// A persistent bar shown while a locked theme is being previewed. "Previewing
/// X" + Get it (opens its buy / Get Pro options) + Exit (clears the preview).
/// Renders nothing when not previewing. Never persisted; a relaunch clears it.
class PreviewBar extends ConsumerWidget {
  final VoidCallback onGetIt;
  const PreviewBar({super.key, required this.onGetIt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewId = ref.watch(previewThemeProvider);
    if (previewId == null) return const SizedBox.shrink();
    final name = HgThemes.byId(previewId).name;
    final hg = context.hg;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(HgSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: HgSpacing.lg, vertical: HgSpacing.sm),
        decoration: BoxDecoration(
          color: hg.surfaceRaised,
          borderRadius: BorderRadius.circular(HgRadius.lg),
          border: Border.all(color: hg.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Previewing $name',
                  style: TextStyle(
                      fontFamily: HgFont.sans, color: hg.textPrimary)),
            ),
            TextButton(onPressed: onGetIt, child: const Text('Get it')),
            TextButton(
              onPressed: () => ref.read(previewThemeProvider.notifier).clear(),
              child: const Text('Exit'),
            ),
          ],
        ),
      ),
    );
  }
}
```

> Confirm `HgRadius.lg`/`HgFont.sans`/`HgSpacing.*` names against `lib/app/theme.dart` before relying on them; substitute the real token names if different.

- [ ] **Step 3: Overlay the bar in the app shell**

At the insertion point found in Step 1, wrap the shell body in a `Stack` with `Positioned(left:0,right:0,bottom:0, child: PreviewBar(onGetIt: () => Navigator.push(... ThemesScreen ...)))`. "Get it" opens the Themes screen (the single place to buy / Get Pro), which is correct and avoids duplicating purchase UI. Verify it does not cover critical bottom controls (it sits above content; the impeccable pass tunes placement).

- [ ] **Step 4: Write the failing preview-session test**

Create `test/ui/preview_session_test.dart`. It pumps `SessionScreen(..., previewMode: true)` with a fake ticker, advances past ~10s, and asserts NO record is persisted and the buy/exit prompt appears. Use the existing session test as a template for the fake-ticker + repository override (read `test/` for the existing `SessionScreen` test to copy its harness exactly — same overrides, same fake ticker type).

```dart
// Skeleton — mirror the existing SessionScreen test harness for overrides/ticker.
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview session caps ~10s and persists nothing', (tester) async {
    // 1. Build SessionScreen(config: <short flow config>, ticker: fakeTicker,
    //    now: () => fixedNow, previewMode: true) inside a ProviderScope with an
    //    in-memory session repository override (so we can assert zero rows).
    // 2. Advance the fake ticker beyond 10 seconds.
    // 3. Expect: the repository has NO sessions (allSessions() is empty), and the
    //    "Enjoying <name>? Get it / Exit preview" prompt is shown.
  });
}
```

Fill the skeleton with the real harness from the existing session test (do not invent ticker/repo APIs — copy them).

- [ ] **Step 5: Add `previewMode` to `SessionScreen`**

In `lib/ui/session_screen.dart`:

Add the field + constructor param:

```dart
  /// When true, this is a THEME PREVIEW run (started while previewing a locked
  /// theme). It shows the themed hourglass in motion but is capped at ~10s and
  /// persists NOTHING — no Focus Score, streak, Today, or history. It exists so
  /// a preview can show the hero moment without granting free themed usage.
  final bool previewMode;
```

```dart
  const SessionScreen({
    super.key,
    required this.config,
    this.ticker,
    this.now,
    this.previewMode = false,
  });
```

Guard ALL persistence. In `_saveCheckpoint`, return immediately in preview mode (first line):

```dart
  Future<void> _saveCheckpoint(SessionRecord record) async {
    if (widget.previewMode) return; // preview records nothing, ever
    ...
  }
```

Do not start the checkpoint timer in preview mode — in `initState`, change the guard to:

```dart
    if (widget.ticker == null && !widget.previewMode) {
      _checkpointTimer = Timer.periodic(...);
    }
```

Add the ~10s cap. In `initState`, after `_controller.start();`, add (only in preview, and only with a real ticker so tests using a fake ticker drive their own time):

```dart
    if (widget.previewMode) {
      _previewCapTimer = Timer(const Duration(seconds: 10), _endPreview);
    }
```

Declare `Timer? _previewCapTimer;` with the other timers, and cancel it in `dispose`. `_endPreview` stops the session and shows the prompt:

```dart
  void _endPreview() {
    if (!mounted) return;
    _controller.pause(); // freeze the hourglass; persist nothing
    setState(() => _previewEnded = true);
  }
```

Declare `bool _previewEnded = false;`. When `_previewEnded`, render an overlay (instead of the normal completion UI) with the line "Enjoying {previewName}? " + a "Get it" button (pop to Themes / open buy) + an "Exit preview" button (`ref.read(previewThemeProvider.notifier).clear()` then `Navigator.maybePop()`). Get `previewName` from `HgThemes.byId(ref.read(previewThemeProvider) ?? '').name`.

**Critical:** in preview mode the protect-the-block lifecycle handler must NOT persist an abandon. Find the `didChangeAppLifecycleState` handler; early-return when `widget.previewMode` (preview persists nothing and has no block to protect). Verify by reading that method before editing.

Also: the completion branches in `_onChange` (`completed`/`finished`) call `_saveCheckpoint` — those are now no-ops in preview because `_saveCheckpoint` returns early, but they also set `_record`/flags and disable wakelock; that is harmless. The ~10s cap will usually fire first. Confirm no stats provider is invalidated in preview (it is gated inside `_saveCheckpoint` after the persist, which we short-circuit).

- [ ] **Step 6: Intercept Begin at Setup when previewing**

In `lib/ui/setup_screen.dart` (~line 184), the Start handler pushes `SessionScreen(config: config)`. Make it preview-aware. `setup_screen` must be a `Consumer`/`ConsumerWidget` to read the provider (confirm; it likely already is for theming). Change the push to:

```dart
    final previewing = ref.read(previewThemeProvider) != null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionScreen(config: config, previewMode: previewing),
      ),
    );
```

Add `import '../app/theme_providers.dart';` to `setup_screen.dart`. (Founder-chosen flow: Begin → Setup → Start still works; the launched session is the capped, non-recording preview while previewing.)

- [ ] **Step 7: Run the preview test — PASS**

Run: `flutter test --concurrency=1 test/ui/preview_session_test.dart`
Expected: PASS (zero persisted rows; prompt shown).

- [ ] **Step 8: Analyze + FULL suite + commit**

Run: `flutter analyze` (clean), `flutter test --concurrency=1` (ALL green — this is the integration point; re-run the whole suite, not just new tests).

```bash
git add lib/ui/widgets/preview_bar.dart lib/app/root_gate.dart lib/ui/session_screen.dart lib/ui/setup_screen.dart test/ui/preview_session_test.dart
git commit -m "feat(themes): live whole-app preview + capped non-recording preview session"
```

---

### Task 6: Final verification pass (hand off to founder for on-device tuning)

**Files:** none (verification + handoff).

- [ ] **Step 1: Whole-suite gate**

Run: `flutter analyze` → clean. `flutter test --concurrency=1` → all green. Record the test count.

- [ ] **Step 2: Self-audit against the iron rule + spec**

Walk the spec §2–§6 checklist and confirm each is implemented and tested: catalog integrity, ownership gating + Sand fallback, à-la-carte billing (key-less safe), Themes screen states, live preview override + clear + not-persisted, preview session caps + persists nothing + buy/exit prompt, lapsed-entitlement → Sand. Confirm no privacy/security gap (no entitlement granted optimistically; preview never writes data; dev-unlock debug-only). Fix anything that is not genuinely correct.

- [ ] **Step 3: Update the handoff**

Write the next handoff to `d:/Dev/Trilumos/hourglass/.remember/remember.md`: themes built + tested; **on-device palette tuning with the founder is pending** (the spec's §6 / build-order step 6 — the hero must look premium in his eyes); the Sounds feature is next after that. Note that selling à la carte needs the founder's Play Console + RevenueCat setup (spec §7), no code changes.

- [ ] **Step 4: Do NOT self-deploy to verify visuals.** Per the standing rule, on-device verification + palette tuning are the founder's. Hand off; build/install the APK only if/when he asks.

---

## Self-Review

**1. Spec coverage:**
- §1 lineup + §1.1 palettes → Task 1 (builder + 8 themes, seeded hex, tunable).
- §2 architecture (HgTheme skins, all 9 in `all`, activeThemeProvider, previewThemeProvider, app.dart, hourglass wiring, kCatalogThemeIds) → Tasks 1 + 2.
- §3 Themes screen (grid/preview/apply/buy) + §3.1 preview + preview session → Tasks 4 + 5.
- §4 à-la-carte billing → Task 3.
- §5 ownership/fallback rules → Task 2 (activeThemeProvider) + tested.
- §6 testing → tests in every task; serial.
- §7 founder setup → Task 6 handoff (no code).
- §8 files / §9 build order → mirrored by Tasks 1-5.

**2. Placeholder scan:** UI visual refinement (Task 4/5) is deliberately left to the impeccable pass + on-device tuning per the locked spec ("starting points, tuned on-device"); the code provided is complete and compiles/tests. Two steps (Task 4 Step 1, Task 5 Step 1) require reading a file (paywall class, app shell) before wiring — these are verification gates, not placeholders, because the exact symbol must not be guessed (iron rule). The preview-session test (Task 5 Step 4) is a skeleton to be filled from the existing session test harness — flagged explicitly because inventing the ticker/repo API would violate "no foolish mistakes."

**3. Type consistency:** `ThemeProduct{themeId, priceString, raw}`, `purchaseTheme(String)→PurchaseOutcome`, `themeProducts()→List<ThemeProduct>`, `activeThemeProvider→HgTheme`, `previewThemeProvider→String?` with `.set(id)`/`.clear()`, `skinFor(Brightness)→HourglassSkin`, `kThemeProductId(String)→String`, `kCatalogThemeIds:Set<String>` — used consistently across Tasks 1-5.
