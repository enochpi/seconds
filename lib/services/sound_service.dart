import 'package:audioplayers/audioplayers.dart';

import 'storage_service.dart';

enum GameSound {
  countdownTick,
  tapPerfect,
  tapGood,
  tapMiss,
  highScore,
}

class SoundService {
  SoundService._internal();

  static final SoundService instance = SoundService._internal();

  final Map<GameSound, AudioPlayer> _players = {
    for (final sound in GameSound.values) sound: AudioPlayer(),
  };

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    for (final entry in _players.entries) {
      await entry.value.setPlayerMode(PlayerMode.lowLatency);
      await entry.value.setReleaseMode(ReleaseMode.stop);
      await entry.value.setSource(AssetSource('sounds/${_assetName(entry.key)}'));
    }
  }

  String _assetName(GameSound sound) {
    switch (sound) {
      case GameSound.countdownTick:
        return 'countdown_tick.wav';
      case GameSound.tapPerfect:
        return 'tap_perfect.wav';
      case GameSound.tapGood:
        return 'tap_good.wav';
      case GameSound.tapMiss:
        return 'tap_miss.wav';
      case GameSound.highScore:
        return 'high_score.wav';
    }
  }

  Future<void> play(GameSound sound) async {
    if (!StorageService.getSoundEnabled()) return;
    if (!_initialized) return;

    try {
      await _players[sound]?.seek(Duration.zero);
      await _players[sound]?.resume();
    } catch (_) {
      // Playback failures (e.g. no audio device) should never crash the game.
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
  }
}
