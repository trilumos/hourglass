import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'root_gate.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'theme_providers.dart';

class HourglassApp extends ConsumerWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The active look resolves preview > owned-selected > Sand, so a lapsed
    // entitlement (or an active preview) recolors the whole app automatically.
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
}
