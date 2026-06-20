import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entitlements.dart';
import 'billing_providers.dart';
import 'root_gate.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'theme_providers.dart';

class HourglassApp extends ConsumerWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When a theme being previewed becomes owned (bought à la carte OR via Pro,
    // from anywhere), apply it and drop the preview — so it just becomes the
    // user's theme, with no preview bar or cap left over.
    ref.listen<Entitlements>(entitlementsProvider, (_, next) {
      final previewId = ref.read(previewThemeProvider);
      if (previewId != null && next.ownsTheme(previewId)) {
        ref.read(themeControllerProvider.notifier).setTheme(previewId);
        ref.read(previewThemeProvider.notifier).clear();
      }
    });

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
