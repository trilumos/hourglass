import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/billing_service.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/ui/paywall_screen.dart';

ProOffering _offering() => const ProOffering([
      ProPackage(plan: ProPlan.monthly, priceString: r'$1.99', priceAmount: 1.99, currencyCode: 'USD', raw: 'm'),
      ProPackage(plan: ProPlan.yearly, priceString: r'$9.99', priceAmount: 9.99, currencyCode: 'USD', raw: 'y'),
      ProPackage(plan: ProPlan.lifetime, priceString: r'$24.99', priceAmount: 24.99, currencyCode: 'USD', raw: 'l'),
    ]);

Widget _wrap(FakeBillingService fake) => ProviderScope(
      overrides: [billingServiceProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const PaywallScreen(),
      ),
    );

void main() {
  // A tall viewport so the whole paywall list builds (lazy ListView children
  // below the fold are otherwise never built, so taps/finds miss them).
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows the three plan prices from the offering', (tester) async {
    tall(tester);
    final fake = FakeBillingService()..offering = _offering();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.text(r'$1.99'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text(r'$24.99'), findsOneWidget);
  });

  testWidgets('prices unavailable state when offering is null', (tester) async {
    tall(tester);
    final fake = FakeBillingService(); // no offering
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.textContaining('unavailable'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
  });

  testWidgets('successful purchase routes to the Pro success screen',
      (tester) async {
    tall(tester);
    final fake = FakeBillingService(nextPurchase: PurchaseOutcome.success)
      ..offering = _offering();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Pro'));
    await tester.pumpAndSettle();
    expect(find.text("You're Pro"), findsOneWidget);
  });

  testWidgets('cancelled purchase stays on the paywall, no error',
      (tester) async {
    tall(tester);
    final fake = FakeBillingService(nextPurchase: PurchaseOutcome.cancelled)
      ..offering = _offering();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Pro'));
    await tester.pumpAndSettle();
    expect(find.text("You're Pro"), findsNothing);
    expect(find.text('Sustain Pro'), findsOneWidget);
  });

  testWidgets('pending purchase shows a processing message', (tester) async {
    tall(tester);
    final fake = FakeBillingService(nextPurchase: PurchaseOutcome.pending)
      ..offering = _offering();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Pro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('processing'), findsOneWidget);
    expect(find.text("You're Pro"), findsNothing);
  });

  testWidgets('failed purchase shows an error message', (tester) async {
    tall(tester);
    final fake = FakeBillingService(nextPurchase: PurchaseOutcome.error)
      ..offering = _offering();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Pro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('did not go through'), findsOneWidget);
    expect(find.text("You're Pro"), findsNothing);
  });

  testWidgets('restore with nothing shows the no-purchases note', (tester) async {
    tall(tester);
    final fake = FakeBillingService(nextRestore: RestoreOutcome.nothingToRestore)
      ..offering = _offering();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore purchases'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('No previous purchases'), findsOneWidget);
  });
}
