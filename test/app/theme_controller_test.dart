import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reset() restores the default theme and clears stored prefs', () async {
    SharedPreferences.setMockInitialValues({
      'hg.themeId': 'sage',
      'hg.mode': ThemeMode.dark.index,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    // Starts from the stored choice.
    expect(container.read(themeControllerProvider).themeId, 'sage');
    expect(container.read(themeControllerProvider).mode, ThemeMode.dark);

    await container.read(themeControllerProvider.notifier).reset();

    // Back to the default (Sand, follow system) and the keys are gone.
    final state = container.read(themeControllerProvider);
    expect(state.themeId, 'sand');
    expect(state.mode, ThemeMode.system);
    expect(prefs.getString('hg.themeId'), isNull);
    expect(prefs.getInt('hg.mode'), isNull);
  });
}
