import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/app.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/home_screen.dart';
import 'package:hourglass/ui/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Reproduces the factory-reset path WHILE a theme is being previewed: the app
  // tears down every route and resets to onboarding. Home and onboarding both
  // carry the hourglass Hero, so this is exactly the teardown that previously
  // threw `_dependents.isEmpty`. It must complete without exceptions.
  testWidgets('resetting to onboarding while previewing does not throw',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    final fake = FakeBillingService();
    addTearDown(fake.dispose);

    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      billingServiceProvider.overrideWithValue(fake),
      databaseProvider.overrideWith((ref) {
        ref.onDispose(db.close);
        return db;
      }),
      onboardingCompleteProvider.overrideWith((ref) async => true),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const HourglassApp(),
    ));
    // The hourglass animates forever, so settle with bounded pumps, not
    // pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(HomeScreen), findsOneWidget);

    // Stand in a live preview: the floating pill appears over Home ("Get" +
    // exit, overlay only — no layout space taken).
    container.read(previewThemeProvider.notifier).set('obsidian');
    await tester.pump();
    expect(find.text('Get'), findsOneWidget);

    // Now do the factory-reset navigation.
    final navContext = tester.element(find.byType(HomeScreen));
    Navigator.of(navContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
