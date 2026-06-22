import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../session/session_cue.dart';

/// Plays the short ritual cues at session transitions. Abstracted so tests and
/// theme preview use a silent no-op and never touch the audio plugin.
abstract class SoundCuePlayer {
  /// Warm the players so the first cue isn't late. Safe to call repeatedly.
  Future<void> preload();

  /// Play the cue for [cue]. Must never throw — a cue can't disrupt a session.
  Future<void> play(SessionCue cue);

  Future<void> dispose();
}

/// Does nothing — for tests, theme preview, and any platform without audio.
class SilentSoundCues implements SoundCuePlayer {
  const SilentSoundCues();
  @override
  Future<void> preload() async {}
  @override
  Future<void> play(SessionCue cue) async {}
  @override
  Future<void> dispose() async {}
}

/// Real cue playback via `just_audio`. Plays one preloaded bell for every ritual
/// transition, clipped to a short cue length (the source bell rings long).
/// Configures the audio session to **mix** with other audio and duck only
/// briefly (never pausing the user's music), and to respect the iOS silent
/// switch — so cues feel like gentle feedback, not an interruption.
class JustAudioSoundCues implements SoundCuePlayer {
  /// The default cue bell (a Pixabay CC0 sound — see assets/audio/CREDITS.md).
  static const _asset = 'assets/audio/cue_bell.mp3';

  /// The source bell is long; play only the opening as the cue.
  static const _clip = Duration(seconds: 5);
  static const _volume = 0.85;

  AudioPlayer? _player;
  Future<void>? _init;

  @override
  Future<void> preload() => _ensureInit();

  Future<void> _ensureInit() => _init ??= _doInit();

  Future<void> _doInit() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.assistanceSonification,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
    } catch (_) {/* session config is best-effort */}

    try {
      // Materialize the bundled asset to a temp file and play THAT — never
      // setAsset(). just_audio's setAsset caches each asset's extracted copy in
      // the app cache dir keyed by PATH; that cache survives reinstalls/updates,
      // so a changed asset at the same path keeps playing the old extraction.
      // Writing the current bytes ourselves guarantees the live asset plays.
      final data = await rootBundle.load(_asset);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sustain_cue_bell.mp3');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      final player = AudioPlayer();
      await player.setVolume(_volume);
      await player.setFilePath(file.path);
      await player.setClip(end: _clip); // ~5s cue, not the whole bell
      _player = player;
    } catch (_) {/* a cue must never disrupt a session */}
  }

  @override
  Future<void> play(SessionCue cue) async {
    try {
      await _ensureInit();
      final player = _player;
      if (player == null) return;
      await player.seek(Duration.zero);
      unawaited(player.play()); // fire-and-forget; play() completes on finish
    } catch (_) {/* a cue must never disrupt a session */}
  }

  @override
  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _init = null;
  }
}
