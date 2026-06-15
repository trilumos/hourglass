import 'package:flutter/material.dart';

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

/// A named identity. Every theme ships BOTH a light and a dark variant; the
/// user's mode (light/dark/system) and skin choice compose orthogonally.
@immutable
class HgTheme {
  final String id;
  final String name;
  final HgTokens light;
  final HgTokens dark;
  const HgTheme({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });
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
  );

  static const all = <HgTheme>[sand];

  static HgTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => sand);
}

/// Ergonomic, testable token access: `context.hg.accent`.
extension HgContext on BuildContext {
  HgTokens get hg => Theme.of(this).extension<HgTokens>()!;
}
