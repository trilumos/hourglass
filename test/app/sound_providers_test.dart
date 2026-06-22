import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hourglass/app/sound_providers.dart';
import 'package:hourglass/app/theme_controller.dart';
import 'package:hourglass/audio/sound_cues.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('soundsEnabled defaults on, toggles, and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    expect(container.read(soundsEnabledProvider), isTrue); // on by default
    await container.read(soundsEnabledProvider.notifier).set(false);
    expect(container.read(soundsEnabledProvider), isFalse);
    expect(prefs.getBool('hg.soundsEnabled'), isFalse);
  });

  test('the cue player is silent under flutter_test (no real audio plugin)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(soundCuePlayerProvider), isA<SilentSoundCues>());
  });
}
