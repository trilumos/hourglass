import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/root_gate.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/ui/home_screen.dart';
import 'package:hourglass/ui/onboarding_screen.dart';

Future<void> _pump(WidgetTester tester, {required bool complete}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        billingServiceProvider.overrideWith((ref) {
          final s = FakeBillingService();
          ref.onDispose(s.dispose);
          return s;
        }),
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
        onboardingCompleteProvider.overrideWith((ref) async => complete),
      ],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const RootGate(),
      ),
    ),
  );
  await tester.pump(); // resolve the future
}

void main() {
  testWidgets('complete -> HomeScreen', (tester) async {
    await _pump(tester, complete: true);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('not complete -> OnboardingScreen', (tester) async {
    await _pump(tester, complete: false);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}
