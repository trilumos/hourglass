import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:hourglass/ui/themes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

MaterialApp _themedApp(Widget home) => MaterialApp(
      theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
      home: home,
    );

Future<Widget> _app(FakeBillingService fake, SharedPreferences prefs) async {
  return ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      billingServiceProvider.overrideWithValue(fake),
    ],
    child: _themedApp(const ThemesScreen()),
  );
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('Sand shows as Owned and the catalog renders', (tester) async {
    final fake = FakeBillingService();
    addTearDown(fake.dispose);
    await tester.pumpWidget(await _app(fake, prefs));
    await tester.pumpAndSettle();
    expect(find.text('Sand'), findsOneWidget);
    expect(find.text('Obsidian'), findsOneWidget);
    expect(find.text('Owned'), findsWidgets); // at least Sand
  });

  testWidgets('a locked theme opens a sheet with Preview + Get Pro', (tester) async {
    final fake = FakeBillingService(); // key-less: no à-la-carte products
    addTearDown(fake.dispose);
    await tester.pumpWidget(await _app(fake, prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Obsidian'));
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Get Pro'), findsOneWidget);
    expect(find.text('Buy'), findsNothing); // no à-la-carte product key-less
  });

  testWidgets('Pro user sees a locked theme as Apply, not Buy', (tester) async {
    final fake = FakeBillingService(
      initial: const Entitlements(pro: true, ownedThemeIds: {
        'sand', 'obsidian', 'sage', 'rose', 'indigo', 'dusk', 'tide', 'noir', 'mocha',
      }),
    );
    addTearDown(fake.dispose);
    await tester.pumpWidget(await _app(fake, prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Obsidian'));
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Buy'), findsNothing);
  });

  testWidgets('Preview sets previewThemeProvider', (tester) async {
    final fake = FakeBillingService();
    addTearDown(fake.dispose);
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        billingServiceProvider.overrideWithValue(fake),
      ],
      child: Builder(builder: (context) {
        container = ProviderScope.containerOf(context);
        return _themedApp(const ThemesScreen());
      }),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Obsidian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(container.read(previewThemeProvider), 'obsidian');
  });

  testWidgets('an owned theme applies via the sheet', (tester) async {
    final fake = FakeBillingService(
      initial: const Entitlements(pro: false, ownedThemeIds: {'sand', 'obsidian'}),
    );
    addTearDown(fake.dispose);
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        billingServiceProvider.overrideWithValue(fake),
      ],
      child: Builder(builder: (context) {
        container = ProviderScope.containerOf(context);
        return _themedApp(const ThemesScreen());
      }),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Obsidian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(container.read(activeThemeProvider).id, 'obsidian');
  });
}
