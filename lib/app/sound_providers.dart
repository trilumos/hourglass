import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_cues.dart';
import '../session/session_guard.dart';
import 'theme_controller.dart' show sharedPrefsProvider;

/// Whether session sound cues play. Persisted; **on by default**. The cues are
/// gentle ritual feedback, so most users keep them; one tap silences them.
class SoundsEnabledController extends Notifier<bool> {
  static const _key = 'hg.soundsEnabled';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPrefsProvider).setBool(_key, value);
  }

  Future<void> toggle() => set(!state);
}

final soundsEnabledProvider =
    NotifierProvider<SoundsEnabledController, bool>(SoundsEnabledController.new);

/// The app's cue player. Real `just_audio` playback in production; a silent
/// no-op under `flutter_test` (no audio plugins there, and just_audio spins up
/// async platform init that would otherwise surface as unhandled in tests).
final soundCuePlayerProvider = Provider<SoundCuePlayer>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return const SilentSoundCues();
  }
  final player = JustAudioSoundCues();
  ref.onDispose(player.dispose);
  return player;
});

/// The session foreground-service guard (the live, non-dismissable session +
/// "come back" notification). Silent no-op under `flutter_test`.
final sessionGuardProvider = Provider<SessionGuard>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return const SilentSessionGuard();
  }
  return FgsSessionGuard();
});
