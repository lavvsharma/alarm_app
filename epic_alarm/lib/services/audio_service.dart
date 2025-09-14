import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Simple audio playback service for looping alarm sounds with audio focus.
class AlarmAudioService {
  final AudioPlayer _player = AudioPlayer();
  AudioSession? _session;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _session = await AudioSession.instance;
    await _session!.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.alarm,
          flags: AndroidAudioFlags.none,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );
    _initialized = true;
  }

  /// Plays the provided [assetPath] (asset or bundled) as a looping alarm until [stop] is called.
  /// If [assetPath] is null, plays the default asset at 'assets/sounds/default_alarm.mp3'.
  Future<void> start({String? assetPath, double volume = 1.0}) async {
    if (!_initialized) {
      await initialize();
    }
    final String path = assetPath?.trim().isNotEmpty == true
        ? assetPath!.trim()
        : 'assets/sounds/default_alarm.mp3';

    try {
      await _session?.setActive(true);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(volume.clamp(0.0, 1.0));
      if (path.startsWith('asset:') || path.startsWith('assets/')) {
        await _player.setAudioSource(AudioSource.asset(path.replaceFirst('asset:', '')));
      } else {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(path)));
      }
      await _player.play();
    } catch (_) {
      // If asset missing or failed, keep session active but do not crash.
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } finally {
      await _session?.setActive(false);
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

