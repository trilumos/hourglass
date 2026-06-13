import 'package:flutter/material.dart';

class HgColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF101010);
  static const sand = Color(0xFFE8C9A0);
  static const textHigh = Color(0xFFF2EDE4);
  static const textLow = Color(0xFF8A8378);
}

ThemeData hourglassDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: HgColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: HgColors.surface,
      primary: HgColors.sand,
      onPrimary: Colors.black,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: HgColors.textHigh,
      displayColor: HgColors.textHigh,
    ),
  );
}
