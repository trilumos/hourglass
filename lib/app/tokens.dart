import 'package:flutter/material.dart';

import '../hourglass/hourglass_skin.dart';

/// Semantic design tokens — the ONLY color contract widgets read (via
/// `context.hg`). Each theme/mode remaps these same names to its palette, so
/// restyles, light/dark, and future skins are cheap. See docs/design-language.md.
@immutable
class HgTokens extends ThemeExtension<HgTokens> {
  final Color backdrop;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentMuted;
  final Color onAccent;
  final Color hairline;
  final Color glow;
  final Color focusRing;
  final Color scrim;
  final Color success;
  final Color warning;
  final Color danger;

  const HgTokens({
    required this.backdrop,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentMuted,
    required this.onAccent,
    required this.hairline,
    required this.glow,
    required this.focusRing,
    required this.scrim,
    required this.success,
    required this.warning,
    required this.danger,
  });

  @override
  HgTokens copyWith({
    Color? backdrop,
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentMuted,
    Color? onAccent,
    Color? hairline,
    Color? glow,
    Color? focusRing,
    Color? scrim,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return HgTokens(
      backdrop: backdrop ?? this.backdrop,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      onAccent: onAccent ?? this.onAccent,
      hairline: hairline ?? this.hairline,
      glow: glow ?? this.glow,
      focusRing: focusRing ?? this.focusRing,
      scrim: scrim ?? this.scrim,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  HgTokens lerp(ThemeExtension<HgTokens>? other, double t) {
    if (other is! HgTokens) return this;
    return HgTokens(
      backdrop: Color.lerp(backdrop, other.backdrop, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

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

/// The theme catalog. Add a skin = append here; zero widget changes.
class HgThemes {
  static const sand = HgTheme(
    id: 'sand',
    name: 'Sand',
    dark: HgTokens(
      backdrop: Color(0xFF000000),
      background: Color(0xFF15120E), // warm charcoal (richer than near-black)
      surface: Color(0xFF1E1A15),
      surfaceRaised: Color(0xFF272118),
      surfaceSunken: Color(0xFF110E0A),
      textPrimary: Color(0xFFF2EDE4),
      textSecondary: Color(0xFFB7AF9F),
      textMuted: Color(0xFF8A8378),
      accent: Color(0xFFE8C9A0),
      accentMuted: Color(0xFF3A3024),
      onAccent: Color(0xFF1A1206),
      hairline: Color(0xFF2E2A24),
      glow: Color(0x1FE8C9A0),
      focusRing: Color(0xFFE8C9A0),
      scrim: Color(0xB3000000),
      success: Color(0xFF9BC59A),
      warning: Color(0xFFE0B873),
      danger: Color(0xFFD98A7A),
    ),
    light: HgTokens(
      backdrop: Color(0xFFF2ECE1),
      background: Color(0xFFF7F3EC),
      surface: Color(0xFFFFFFFF),
      surfaceRaised: Color(0xFFFFFFFF),
      surfaceSunken: Color(0xFFEFE8DB),
      textPrimary: Color(0xFF1F1B14),
      textSecondary: Color(0xFF5A5246),
      textMuted: Color(0xFF8A8073),
      accent: Color(0xFFB07A3C),
      accentMuted: Color(0xFFEBDCC4),
      onAccent: Color(0xFFFFFFFF),
      hairline: Color(0xFFE3DACB),
      glow: Color(0x14B07A3C),
      focusRing: Color(0xFFB07A3C),
      scrim: Color(0x40000000),
      success: Color(0xFF4F7A4D),
      warning: Color(0xFF9A6F1E),
      danger: Color(0xFFA8503C),
    ),
    lightSkin: HourglassSkin.classicLight,
    darkSkin: HourglassSkin.classic,
  );

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
}

/// Ergonomic, testable token access: `context.hg.accent`.
extension HgContext on BuildContext {
  HgTokens get hg => Theme.of(this).extension<HgTokens>()!;
}
