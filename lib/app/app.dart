import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/home_screen.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'tokens.dart';

class HourglassApp extends ConsumerWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themeControllerProvider);
    final theme = HgThemes.byId(prefs.themeId);
    return MaterialApp(
      title: 'Sustain',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(theme.light, Brightness.light),
      darkTheme: buildTheme(theme.dark, Brightness.dark),
      themeMode: prefs.mode,
      home: const HomeScreen(),
    );
  }
}
