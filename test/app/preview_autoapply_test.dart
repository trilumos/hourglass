import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/app.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/data/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('buying a previewed theme applies it and clears the preview',
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
    ]);
    addTearDown(container.dispose);

    // Previewing a locked theme.
    container.read(previewThemeProvider.notifier).set('obsidian');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const HourglassApp(),
    ));
    await tester.pump();
    expect(container.read(previewThemeProvider), 'obsidian');

    // The theme is purchased (à la carte or via Pro): ownership arrives.
    await fake.purchaseTheme('obsidian');
    await tester.pump();
    await tester.pump();

    // It is now simply the applied theme: no preview left over.
    expect(container.read(previewThemeProvider), isNull);
    expect(container.read(themeControllerProvider).themeId, 'obsidian');
    expect(container.read(activeThemeProvider).id, 'obsidian');
  });
}
