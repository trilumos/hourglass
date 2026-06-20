import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/themes_screen.dart';
import '../ui/widgets/preview_bar.dart';
import 'root_gate.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'theme_providers.dart';

/// The app's root navigator, so the app-wide preview bar (which lives above the
/// navigator) can open the Themes screen.
final rootNavigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: rootNavigatorKey,
      theme: buildTheme(theme.light, Brightness.light),
      darkTheme: buildTheme(theme.dark, Brightness.dark),
      themeMode: mode,
      // Overlay the preview bar above every route (Home, Insights, Settings...)
      // so previewing is always visible and dismissible. It renders nothing when
      // not previewing. During onboarding nothing can set a preview, so it stays
      // hidden there too.
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PreviewBar(
              onGetIt: () => rootNavigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const ThemesScreen()),
              ),
            ),
          ),
        ],
      ),
      home: const RootGate(),
    );
  }
}
