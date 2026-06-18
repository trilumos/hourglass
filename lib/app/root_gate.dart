import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/home_screen.dart';
import '../ui/onboarding_screen.dart';
import '../ui/widgets/screen_background.dart';
import 'providers.dart';

/// Decides the app's first screen: onboarding for fresh installs, Home otherwise.
/// Fails open to Home on any read error (never trap the user out of the app).
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(onboardingCompleteProvider).when(
          data: (done) => done ? const HomeScreen() : const OnboardingScreen(),
          loading: () =>
              const Scaffold(body: ScreenBackground(child: SizedBox.expand())),
          error: (_, _) => const HomeScreen(),
        );
  }
}
