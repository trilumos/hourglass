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
  testWidgets('shows the three plan prices from the offering', (tester) async {
    final fake = FakeBillingService()..offering = _offering();
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.text(r'$1.99'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text(r'$24.99'), findsOneWidget);
  });

  testWidgets('prices unavailable state when offering is null', (tester) async {
    final fake = FakeBillingService(); // no offering
    addTearDown(fake.dispose);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.textContaining('unavailable'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
  });
}
