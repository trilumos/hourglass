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

  /// Optional premium full-screen backdrop gradient (a subtle, STATIC accent
  /// wash). Null = the neutral surface→background radial (Sand's austere look).
  /// Static only — never animated; honours the motion rule on every screen.
  final Gradient? backdropGradient;

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
    this.backdropGradient,
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
    Gradient? backdropGradient,
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
      backdropGradient: backdropGradient ?? this.backdropGradient,
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
    List<Color>? sandCycleDark,
    List<Color>? sandCycleLight,
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
      // Premium static backdrop: a soft accent-tinted glow from above fading to
      // bg. Subtle (no chroma under body text) and motionless.
      backdropGradient: RadialGradient(
        center: const Alignment(0, -0.8),
        radius: 1.3,
        colors: [_mix(dSurface, dAccent, 0.14), dBg],
        stops: const [0.0, 0.62],
      ),
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
      backdropGradient: RadialGradient(
        center: const Alignment(0, -0.8),
        radius: 1.3,
        colors: [_mix(lBg, lAccent, 0.06), lBg],
        stops: const [0.0, 0.62],
      ),
    );
    final darkSkin = HourglassSkin(
      id: id,
      sandColor: sandDark,
      glassTint: const Color(0x14FFFFFF),
      glassOutline: const Color(0x33FFFFFF),
      neckWidth: 0.012,
      sandCycle: sandCycleDark,
    );
    final lightSkin = HourglassSkin(
      id: id,
      sandColor: sandLight,
      glassTint: lText, // opaque dark glass body (mirrors classicLight)
      glassOutline: lText.withValues(alpha: 0.2),
      neckWidth: 0.012,
      sandCycle: sandCycleLight,
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
    dBg: const Color(0xFF0F141E), dSurface: const Color(0xFF171D2A), dRaised: const Color(0xFF212A3B),
    dText: const Color(0xFFE2E8F5), dText2: const Color(0xFFA4B0C8), dText3: const Color(0xFF6E7A92),
    dAccent: const Color(0xFF6E9BF0), dAccentMuted: const Color(0xFF202B40), dOnAccent: const Color(0xFF0A0F18), dHairline: const Color(0xFF262F40),
    lBg: const Color(0xFFEEF1F8), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF121726), lText2: const Color(0xFF49546B),
    lAccent: const Color(0xFF2456C4), lAccentMuted: const Color(0xFFD9E2F7), lHairline: const Color(0xFFD7DEEC),
    sandDark: const Color(0xFFC3D2EE), sandLight: const Color(0xFF5E7CB0),
  );

  static final sage = _premium(
    id: 'sage', name: 'Sage',
    dBg: const Color(0xFF12180F), dSurface: const Color(0xFF1B2417), dRaised: const Color(0xFF24301E),
    dText: const Color(0xFFE4ECDC), dText2: const Color(0xFFA6B49B), dText3: const Color(0xFF6F7D64),
    dAccent: const Color(0xFF8FCB6E), dAccentMuted: const Color(0xFF2C3A1F), dOnAccent: const Color(0xFF12180F), dHairline: const Color(0xFF2A3622),
    lBg: const Color(0xFFEFF3E7), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF161C10), lText2: const Color(0xFF4C5743),
    lAccent: const Color(0xFF3F7A24), lAccentMuted: const Color(0xFFDDE8CD), lHairline: const Color(0xFFDBE3CC),
    sandDark: const Color(0xFFD7DCA0), sandLight: const Color(0xFF879143),
  );

  static final rose = _premium(
    id: 'rose', name: 'Rosé',
    dBg: const Color(0xFF1A1216), dSurface: const Color(0xFF241A1E), dRaised: const Color(0xFF32242B),
    dText: const Color(0xFFF2E4E6), dText2: const Color(0xFFC2A9AE), dText3: const Color(0xFF8C757B),
    dAccent: const Color(0xFFE59CAB), dAccentMuted: const Color(0xFF3D262C), dOnAccent: const Color(0xFF2A1115), dHairline: const Color(0xFF3A2730),
    lBg: const Color(0xFFF9EDEB), lSurface: const Color(0xFFFFFBFA),
    lText: const Color(0xFF2A171A), lText2: const Color(0xFF6E5258),
    lAccent: const Color(0xFFB94E5C), lAccentMuted: const Color(0xFFF1D7D9), lHairline: const Color(0xFFEDD5D6),
    sandDark: const Color(0xFFEAB6A4), sandLight: const Color(0xFFC97D74),
  );

  static final indigo = _premium(
    id: 'indigo', name: 'Indigo',
    dBg: const Color(0xFF101329), dSurface: const Color(0xFF181C3A), dRaised: const Color(0xFF222850),
    dText: const Color(0xFFEAEAFB), dText2: const Color(0xFFAEB0DC), dText3: const Color(0xFF7376A8),
    dAccent: const Color(0xFF9485F5), dAccentMuted: const Color(0xFF272C52), dOnAccent: const Color(0xFF0C0D1F), dHairline: const Color(0xFF2A3060),
    lBg: const Color(0xFFF1F1FB), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF15172B), lText2: const Color(0xFF4A4D72),
    lAccent: const Color(0xFF4B30D6), lAccentMuted: const Color(0xFFE2DDF9), lHairline: const Color(0xFFDCDCF0),
    sandDark: const Color(0xFFEFE3B0), sandLight: const Color(0xFFA8923F),
    // Starfield shimmer (home only): starlight-gold -> periwinkle -> ice-blue -> violet.
    sandCycleDark: const [
      Color(0xFFEFE3B0), Color(0xFFCFCAF2), Color(0xFFC6D6F0), Color(0xFFDCC6F0),
    ],
    sandCycleLight: const [
      Color(0xFFA8923F), Color(0xFF8076C0), Color(0xFF6E84C0), Color(0xFF9A78B0),
    ],
  );

  static final dusk = _premium(
    id: 'dusk', name: 'Dusk',
    dBg: const Color(0xFF15121C), dSurface: const Color(0xFF1F1A2B), dRaised: const Color(0xFF2A2440),
    dText: const Color(0xFFEDE6F6), dText2: const Color(0xFFB6ABC8), dText3: const Color(0xFF837795),
    dAccent: const Color(0xFFBC92E8), dAccentMuted: const Color(0xFF332846), dOnAccent: const Color(0xFF1A1226), dHairline: const Color(0xFF2E2740),
    lBg: const Color(0xFFF5F0FB), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF1C1626), lText2: const Color(0xFF564B66),
    lAccent: const Color(0xFF7B3FC9), lAccentMuted: const Color(0xFFE9DCF8), lHairline: const Color(0xFFE6DBF3),
    sandDark: const Color(0xFFD7B8F2), sandLight: const Color(0xFF9B6FCB),
    // Twilight shimmer (home only): orchid -> lavender -> lilac -> periwinkle.
    sandCycleDark: const [
      Color(0xFFD7B8F2), Color(0xFFC4BEF2), Color(0xFFE6BCEA), Color(0xFFC2C8F2),
    ],
    sandCycleLight: const [
      Color(0xFF9B6FCB), Color(0xFF8478C8), Color(0xFFB068C2), Color(0xFF7E78CC),
    ],
  );

  static final tide = _premium(
    id: 'tide', name: 'Tide',
    dBg: const Color(0xFF08191B), dSurface: const Color(0xFF0F2528), dRaised: const Color(0xFF163438),
    dText: const Color(0xFFDCEEEB), dText2: const Color(0xFF94B3AE), dText3: const Color(0xFF5E7E7A),
    dAccent: const Color(0xFF34CCBF), dAccentMuted: const Color(0xFF0E3A37), dOnAccent: const Color(0xFF04110F), dHairline: const Color(0xFF1C3A3C),
    lBg: const Color(0xFFE4F2EE), lSurface: const Color(0xFFFBFFFE),
    lText: const Color(0xFF0B201F), lText2: const Color(0xFF3E5450),
    lAccent: const Color(0xFF0B746A), lAccentMuted: const Color(0xFFCDE8E2), lHairline: const Color(0xFFCFE3DD),
    sandDark: const Color(0xFFA9E8DC), sandLight: const Color(0xFF4FA294),
    // Ocean shimmer (home only): seafoam -> aqua -> mint -> sky-cyan.
    sandCycleDark: const [
      Color(0xFFA9E8DC), Color(0xFF9BE6E2), Color(0xFFAEE6C6), Color(0xFF96DCEC),
    ],
    sandCycleLight: const [
      Color(0xFF4FA294), Color(0xFF3FA0A8), Color(0xFF5BA878), Color(0xFF4894A8),
    ],
  );

  static final noir = _premium(
    id: 'noir', name: 'Noir',
    dBg: const Color(0xFF050402), dSurface: const Color(0xFF121009), dRaised: const Color(0xFF1C180E),
    dText: const Color(0xFFF4EFE2), dText2: const Color(0xFFB7AF96), dText3: const Color(0xFF847C66),
    dAccent: const Color(0xFFE5B84B), dAccentMuted: const Color(0xFF332A12), dOnAccent: const Color(0xFF171202), dHairline: const Color(0xFF26210F),
    lBg: const Color(0xFFF7F1E3), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF171309), lText2: const Color(0xFF544D3B),
    lAccent: const Color(0xFF9A6A10), lAccentMuted: const Color(0xFFEFE1BE), lHairline: const Color(0xFFE7DEC8),
    sandDark: const Color(0xFFF0C44E), sandLight: const Color(0xFFC9911F),
  );

  static final mocha = _premium(
    id: 'mocha', name: 'Mocha',
    dBg: const Color(0xFF17110B), dSurface: const Color(0xFF21190F), dRaised: const Color(0xFF2D2215),
    dText: const Color(0xFFF1E7D8), dText2: const Color(0xFFC0AC90), dText3: const Color(0xFF8A7558),
    dAccent: const Color(0xFFE3A654), dAccentMuted: const Color(0xFF3D2C16), dOnAccent: const Color(0xFF1A1003), dHairline: const Color(0xFF33271A),
    lBg: const Color(0xFFF5ECDC), lSurface: const Color(0xFFFFFDF8),
    lText: const Color(0xFF2A1D0E), lText2: const Color(0xFF6B5A44),
    lAccent: const Color(0xFF9A5E1C), lAccentMuted: const Color(0xFFEEDCBE), lHairline: const Color(0xFFE6D6BB),
    sandDark: const Color(0xFFF0D5A6), sandLight: const Color(0xFFC68F4A),
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
