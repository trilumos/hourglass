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
import 'package:hourglass/domain/entitlements.dart';
import 'package:hourglass/ui/home_screen.dart';
import 'package:hourglass/ui/themes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression test for the stale/ghost hourglass on theme apply + preview.
///
/// Root cause (verified): the Home hourglass's Ticker is active-but-muted while
/// the Themes screen covers Home. A theme change rebuilds the app and fires
/// HourglassView.didUpdateWidget, which used `!_ticker.isTicking` (false for a
/// muted-but-active ticker) and called start() on an already-active ticker ->
/// "A ticker was started twice" + leaked frame callbacks = the device-visible
/// frozen ghost. The oracle here is therefore NOT a widget count (the leak is a
/// ticker, not an element) but: NO framework exception may be thrown during the
/// cover-Home + change-theme cycle.
///
/// The hourglass animates forever, so NEVER pumpAndSettle: use bounded pumps.
Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  Entitlements entitlements = Entitlements.free,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase.memory();
  final fake = FakeBillingService(initial: entitlements);
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.byType(HomeScreen), findsOneWidget);
  return container;
}

/// Cover Home with the Themes screen (muting the Home hourglass ticker), apply
/// the theme change while covered (the trigger), then return to Home.
Future<void> _coverChangeReturn(
  WidgetTester tester,
  void Function() changeTheme,
) async {
  final nav = Navigator.of(tester.element(find.byType(HomeScreen)));
  nav.push(MaterialPageRoute(builder: (_) => const ThemesScreen()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  changeTheme(); // fires Home's didUpdateWidget while it is muted
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  nav.pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  const proEverything = Entitlements(pro: true, ownedThemeIds: {
    'sand', 'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha',
  });

  testWidgets('previewing repeatedly throws no ticker/framework exception',
      (tester) async {
    final container = await _pumpHome(tester);

    for (var i = 0; i < 5; i++) {
      await _coverChangeReturn(
        tester,
        () => container.read(previewThemeProvider.notifier).set('obsidian'),
      );
      expect(tester.takeException(), isNull,
          reason: 'preview cycle $i threw (ticker started twice / leaked)');
      container.read(previewThemeProvider.notifier).clear();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull, reason: 'exit cycle $i threw');
    }
  });

  testWidgets('applying themes (Pro) repeatedly throws no framework exception',
      (tester) async {
    final container = await _pumpHome(tester, entitlements: proEverything);

    for (final id in ['obsidian', 'sage', 'tide', 'noir', 'sand']) {
      await _coverChangeReturn(
        tester,
        () => container.read(themeControllerProvider.notifier).setTheme(id),
      );
      expect(tester.takeException(), isNull,
          reason: 'applying "$id" threw (ticker started twice / leaked)');
    }
  });
}
