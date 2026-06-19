import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme.dart';
import 'package:hourglass/app/tokens.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:hourglass/ui/profile_screen.dart';

Widget _harness(FakeBillingService billing) => ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase.memory();
          ref.onDispose(db.close);
          return db;
        }),
        billingServiceProvider.overrideWithValue(billing),
      ],
      child: MaterialApp(
        theme: buildTheme(HgThemes.sand.dark, Brightness.dark),
        home: const ProfileScreen(),
      ),
    );

void main() {
  testWidgets('profile hub nudges setup when no name is set, no PRO tag for free',
      (tester) async {
    final billing = FakeBillingService();
    addTearDown(billing.dispose);
    await tester.pumpWidget(_harness(billing));
    await tester.pumpAndSettle();
    expect(find.textContaining('Set up your profile'), findsOneWidget);
    expect(find.text('PRO'), findsNothing);
  });

  testWidgets('shows the PRO tag for pro users', (tester) async {
    final billing = FakeBillingService(
        initial: const Entitlements(pro: true, ownedThemeIds: {'sand'}));
    addTearDown(billing.dispose);
    await tester.pumpWidget(_harness(billing));
    await tester.pumpAndSettle();
    expect(find.text('PRO'), findsOneWidget);
  });
}
