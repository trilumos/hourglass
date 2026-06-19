import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/home_screen.dart';
import 'package:hourglass/ui/onboarding_screen.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    databaseProvider.overrideWith((ref) {
      final db = AppDatabase.memory();
      ref.onDispose(db.close);
      return db;
    }),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const OnboardingScreen(),
      ),
    ),
  );
  await tester.pump();
  return container;
}

// The hourglass hero animates forever, so we never pumpAndSettle — we pump with
// explicit durations to let page/route transitions complete.
Future<void> _skipToProfile(WidgetTester tester) async {
  await tester.tap(find.text('Skip'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('opens on the first teach page with Continue + Skip + dots',
      (tester) async {
    await _pump(tester);
    expect(find.text('Train your focus like an athlete.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 5'), findsOneWidget);
  });

  testWidgets('Skip jumps to the profile page (name field + Begin)',
      (tester) async {
    await _pump(tester);
    await _skipToProfile(tester);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 5 of 5'), findsOneWidget);
  });

  testWidgets('Begin with a name saves the profile + marks onboarding done',
      (tester) async {
    final container = await _pump(tester);
    await _skipToProfile(tester);
    await tester.enterText(find.byType(TextField), 'Maya');
    await tester.tap(find.text('Begin'));
    // Finish = drain (~750ms) + flip (~600ms) + route. The hourglass animates
    // forever, so we step the clock instead of pumpAndSettle.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final profile = await container.read(profileRepositoryProvider).load();
    expect(profile.name, 'Maya');
    expect(
      await container
          .read(settingsRepositoryProvider)
          .getBool(SettingsKeys.onboardingComplete, defaultValue: false),
      isTrue,
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
