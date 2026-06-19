import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:hourglass/ui/widgets/pro_gate.dart';

Widget _wrap(Widget child, FakeBillingService fake) => ProviderScope(
      overrides: [billingServiceProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('free shows upsell, pro shows child', (tester) async {
    final free = FakeBillingService();
    await tester.pumpWidget(_wrap(
      const ProGate(upsell: Text('UPSELL'), child: Text('PRO CONTENT')),
      free,
    ));
    await tester.pump();
    expect(find.text('UPSELL'), findsOneWidget);
    expect(find.text('PRO CONTENT'), findsNothing);

    final pro = FakeBillingService(
        initial: const Entitlements(pro: true, ownedThemeIds: {'sand'}));
    await tester.pumpWidget(_wrap(
      const ProGate(upsell: Text('UPSELL'), child: Text('PRO CONTENT')),
      pro,
    ));
    await tester.pump();
    expect(find.text('PRO CONTENT'), findsOneWidget);
    expect(find.text('UPSELL'), findsNothing);
  });
}
