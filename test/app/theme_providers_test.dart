import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/billing_providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/app/theme_providers.dart';
import 'package:hourglass/billing/fake_billing_service.dart';
import 'package:hourglass/domain/entitlements.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container({Entitlements? initial}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fake = FakeBillingService(initial: initial ?? Entitlements.free);
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    billingServiceProvider.overrideWithValue(fake),
  ]);
  addTearDown(c.dispose);
  addTearDown(fake.dispose);
  return c;
}

void main() {
  test('defaults to Sand when nothing selected/owned', () async {
    final c = await _container();
    expect(c.read(activeThemeProvider).id, 'sand');
  });

  test('selected-but-unowned falls back to Sand', () async {
    final c = await _container();
    c.read(themeControllerProvider.notifier).setTheme('obsidian');
    expect(c.read(activeThemeProvider).id, 'sand');
  });

  test('selected-and-owned applies', () async {
    final c = await _container(
        initial: const Entitlements(pro: false, ownedThemeIds: {'sand', 'obsidian'}));
    c.read(themeControllerProvider.notifier).setTheme('obsidian');
    expect(c.read(activeThemeProvider).id, 'obsidian');
  });

  test('Pro owns all → any selected theme applies', () async {
    final c = await _container(
        initial: const Entitlements(pro: true, ownedThemeIds: {'sand', 'noir'}));
    c.read(themeControllerProvider.notifier).setTheme('noir');
    expect(c.read(activeThemeProvider).id, 'noir');
  });

  test('preview overrides ownership and clears back', () async {
    final c = await _container();
    c.read(previewThemeProvider.notifier).set('tide');
    expect(c.read(activeThemeProvider).id, 'tide'); // unowned, still previews
    c.read(previewThemeProvider.notifier).clear();
    expect(c.read(activeThemeProvider).id, 'sand');
  });

  test('preview of an unknown id resolves safely to Sand', () async {
    final c = await _container();
    c.read(previewThemeProvider.notifier).set('bogus');
    expect(c.read(activeThemeProvider).id, 'sand');
  });
}
