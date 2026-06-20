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

  /// Optional STATIC gradient for the primary button. Null = a subtle top-sheen
  /// derived from [accent]; a theme (e.g. Aurora) may supply a richer one.
  final Gradient? accentGradient;

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
    this.accentGradient,
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
    Gradient? accentGradient,
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
      accentGradient: accentGradient ?? this.accentGradient,
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
      background: Color(0xFF161009), // warm golden-dark (not grey-brown mud)
      surface: Color(0xFF211913),
      surfaceRaised: Color(0xFF2C2218),
      surfaceSunken: Color(0xFF120C06),
      textPrimary: Color(0xFFF5EFE1),
      textSecondary: Color(0xFFC0B299),
      textMuted: Color(0xFF8E8167),
      accent: Color(0xFFEDC56C), // rich warm GOLD (was a desaturated tan)
      accentMuted: Color(0xFF3E311C),
      onAccent: Color(0xFF1A1204),
      hairline: Color(0xFF342A1C),
      glow: Color(0x1FEDC56C),
      focusRing: Color(0xFFEDC56C),
      scrim: Color(0xB3000000),
      success: Color(0xFF9BC59A),
      warning: Color(0xFFE0B873),
      danger: Color(0xFFD98A7A),
      // Warm-gold accent backdrop (matches the premium themes' 3-stop style).
      backdropGradient: RadialGradient(
        center: Alignment(0, -0.85),
        radius: 1.5,
        colors: [Color(0xFF4E3F27), Color(0xFF21190E), Color(0xFF140F08)],
        stops: [0.0, 0.42, 1.0],
      ),
    ),
    light: HgTokens(
      backdrop: Color(0xFFF2EAD9),
      background: Color(0xFFF9F4E9), // warm golden paper
      surface: Color(0xFFFFFFFF),
      surfaceRaised: Color(0xFFFFFFFF),
      surfaceSunken: Color(0xFFF0E7D4),
      textPrimary: Color(0xFF221A0E),
      textSecondary: Color(0xFF5E5340),
      textMuted: Color(0xFF8E8167),
      accent: Color(0xFFB5831E), // deep GOLD (was a muddy caramel-brown)
      accentMuted: Color(0xFFEEDDB8),
      onAccent: Color(0xFFFFFFFF),
      hairline: Color(0xFFE9DFC8),
      glow: Color(0x14B5831E),
      focusRing: Color(0xFFB5831E),
      scrim: Color(0x40000000),
      success: Color(0xFF4F7A4D),
      warning: Color(0xFF9A6F1E),
      danger: Color(0xFFA8503C),
      backdropGradient: RadialGradient(
        center: Alignment(0, -0.85),
        radius: 1.5,
        colors: [Color(0xFFF2E9D5), Color(0xFFF7F1E3), Color(0xFFF9F4E9)],
        stops: [0.0, 0.48, 1.0],
      ),
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
      // Premium static backdrop: a soft accent-lit crown from above, a gentle
      // accent wash through the middle, and a slightly deeper foot (vignette
      // depth). Subtle (no chroma under body text) and motionless.
      backdropGradient: RadialGradient(
        center: const Alignment(0, -0.85),
        radius: 1.5,
        colors: [
          _mix(dSurface, dAccent, 0.22),
          _mix(dBg, dAccent, 0.05),
          _mix(dBg, _black, 0.07),
        ],
        stops: const [0.0, 0.42, 1.0],
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
        center: const Alignment(0, -0.85),
        radius: 1.5,
        colors: [
          _mix(lBg, lAccent, 0.10),
          _mix(lBg, lAccent, 0.03),
          lBg,
        ],
        stops: const [0.0, 0.48, 1.0],
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
    // Quicksilver shimmer (home only): silver -> ice-blue -> steel -> frost.
    sandCycleDark: const [
      Color(0xFFCBD8F2), Color(0xFFA9C0EF), Color(0xFF7FA8F4),
      Color(0xFF6E9BF0), Color(0xFF93B4F2), Color(0xFFC0D2F0),
    ],
    sandCycleLight: const [
      Color(0xFF6E8BC0), Color(0xFF4E74C2), Color(0xFF3A63C6),
      Color(0xFF2456C4), Color(0xFF4E78C0), Color(0xFF7088B8),
    ],
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
    // Wheat shimmer (home only): wheat-gold -> sage -> moss -> lime-cream.
    sandCycleDark: const [
      Color(0xFFE2E0A4), Color(0xFFC4DA88), Color(0xFF9FCF6E),
      Color(0xFF8FCB6E), Color(0xFFB7D67E), Color(0xFFD6DC9A),
    ],
    sandCycleLight: const [
      Color(0xFF8E9445), Color(0xFF6F9038), Color(0xFF528A2A),
      Color(0xFF3F7A24), Color(0xFF5F8A30), Color(0xFF879143),
    ],
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
    // Rose-gold shimmer (home only): rose-gold -> blush -> peach -> pink.
    sandCycleDark: const [
      Color(0xFFEAB6A4), Color(0xFFE59CAB), Color(0xFFCF6E8E),
      Color(0xFFEC9CB0), Color(0xFFF0C2A6),
    ],
    sandCycleLight: const [
      Color(0xFFC97D74), Color(0xFFC95C72), Color(0xFFB94E5C),
      Color(0xFFCE7A6E), Color(0xFFC96E84),
    ],
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
      Color(0xFFF2E4A8), Color(0xFFB9A9FA), Color(0xFF8E7BE8),
      Color(0xFF7A66E2), Color(0xFFAEC2F2), Color(0xFFD8CEF0),
    ],
    sandCycleLight: const [
      Color(0xFFA8923F), Color(0xFF7C68D8), Color(0xFF5B40D8),
      Color(0xFF4B30D6), Color(0xFF5E72C0), Color(0xFF8E7A4E),
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
      Color(0xFFD7B8F2), Color(0xFFC79CF0), Color(0xFFB081E2),
      Color(0xFFCE92E2), Color(0xFFA898EE), Color(0xFFDEC2F4),
    ],
    sandCycleLight: const [
      Color(0xFF9B6FCB), Color(0xFF8C56C8), Color(0xFF7B3FC9),
      Color(0xFFA050BE), Color(0xFF6E58C2), Color(0xFF9466C6),
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
      Color(0xFFA9E8DC), Color(0xFF6FE3D6), Color(0xFF3FD6C8),
      Color(0xFF49C9DE), Color(0xFF7CE0C0),
    ],
    sandCycleLight: const [
      Color(0xFF4FA294), Color(0xFF2FA89A), Color(0xFF159A8E),
      Color(0xFF0B746A), Color(0xFF3C9E92),
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
    // Molten-gold shimmer (home only): gold -> amber -> champagne -> bronze.
    sandCycleDark: const [
      Color(0xFFF6D169), Color(0xFFE5B84B), Color(0xFFD9A22F),
      Color(0xFFC68A1E), Color(0xFFE0AE3C), Color(0xFFF2C95A),
    ],
    sandCycleLight: const [
      Color(0xFFD8A12C), Color(0xFFC9911F), Color(0xFFB67A14),
      Color(0xFF9A6A10), Color(0xFFBE8420), Color(0xFFD49A28),
    ],
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
    // Caramel shimmer (home only): cream -> caramel -> latte -> honey.
    sandCycleDark: const [
      Color(0xFFF3DCAE), Color(0xFFEDC882), Color(0xFFE3A654),
      Color(0xFFD99A4A), Color(0xFFEFCB8E),
    ],
    sandCycleLight: const [
      Color(0xFFCE9A56), Color(0xFFC07E36), Color(0xFF9A5E1C),
      Color(0xFFB06A24), Color(0xFFC68F4A),
    ],
  );

  // Flagship "living" theme: a deep cosmic base with luminous aurora accent and
  // the most vivid home-sand shimmer (a full aurora spectrum). Still static off
  // the hourglass; the sand shimmer is home-only.
  static final aurora = _premium(
    id: 'aurora', name: 'Aurora',
    dBg: const Color(0xFF0A0E1A), dSurface: const Color(0xFF121A2E), dRaised: const Color(0xFF1C2742),
    dText: const Color(0xFFEAEDFA), dText2: const Color(0xFFAAB4D8), dText3: const Color(0xFF6E78A0),
    dAccent: const Color(0xFF5BE3C0), dAccentMuted: const Color(0xFF123830), dOnAccent: const Color(0xFF021712), dHairline: const Color(0xFF222C48),
    lBg: const Color(0xFFEFF2FB), lSurface: const Color(0xFFFFFFFF),
    lText: const Color(0xFF111626), lText2: const Color(0xFF49526E),
    lAccent: const Color(0xFF0E8A78), lAccentMuted: const Color(0xFFD2EEE8), lHairline: const Color(0xFFD8E0EE),
    sandDark: const Color(0xFFA8E8D0), sandLight: const Color(0xFF4FA890),
    // Aurora spectrum (home only): green -> cyan -> violet -> magenta -> mint.
    sandCycleDark: const [
      Color(0xFF5BE3C0), Color(0xFF34CFB8), Color(0xFF5FC8EA),
      Color(0xFF9A86F0), Color(0xFFE07ECE), Color(0xFF53E0A8),
    ],
    sandCycleLight: const [
      Color(0xFF0E8A78), Color(0xFF1AA38C), Color(0xFF2E86B0),
      Color(0xFF6A54B8), Color(0xFFA8489A), Color(0xFF1F9E6E),
    ],
  );

  /// The theme catalog (Sand first as the free default). Add a theme = append here.
  static final List<HgTheme> all = <HgTheme>[
    sand, obsidian, sage, rose, indigo, dusk, tide, noir, mocha, aurora,
  ];

  static HgTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => sand);
}

/// Ergonomic, testable token access: `context.hg.accent`.
extension HgContext on BuildContext {
  HgTokens get hg => Theme.of(this).extension<HgTokens>()!;
}
