import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();
  factory AudioService() => instance;

  final List<AudioPlayer> _sfxPool = List.generate(4, (_) => AudioPlayer());
  final AudioPlayer _bgmPlayer = AudioPlayer();
  int _sfxIndex = 0;

  double _sfxVolume = 0.8;
  double _bgmVolume = 0.7;
  bool _hapticEnabled = true;
  bool _isBgmPlaying = false;
  bool _initialized = false;

  double get sfxVolume => _sfxVolume;
  double get bgmVolume => _bgmVolume;
  bool get hapticEnabled => _hapticEnabled;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Load persisted volume & haptic settings from Hive if box is open
    try {
      if (Hive.isBoxOpen('user_progress_box')) {
        final box = Hive.box('user_progress_box');
        _sfxVolume = (box.get('sfx_volume', defaultValue: 0.8) as num).toDouble();
        _bgmVolume = (box.get('bgm_volume', defaultValue: 0.7) as num).toDouble();
        _hapticEnabled = (box.get('haptic_enabled', defaultValue: true) as bool);
      }
    } catch (_) {}

    // Configure AudioContext for iOS & Android
    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ));
    } catch (_) {
      // Ignore on platforms where audio context isn't supported (e.g. Windows/Web)
    }

    try {
      for (final player in _sfxPool) {
        player.setVolume(_sfxVolume);
      }
      _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

      // Loop safety fallback listener
      _bgmPlayer.onPlayerComplete.listen((_) async {
        if (_bgmVolume > 0.0 && _isBgmPlaying) {
          try {
            await _bgmPlayer.play(AssetSource('sounds/bgm.wav'));
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  AudioPlayer _getNextSfxPlayer() {
    final player = _sfxPool[_sfxIndex];
    _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
    return player;
  }

  DateTime? _lastClickTime;

  // Play crisp tactile arcade tap sound effect
  Future<void> playClickSound() async {
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < 80) {
      return;
    }
    _lastClickTime = now;

    if (_hapticEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.stop();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/click.wav'));
    } catch (_) {}
  }

  // Play block placement sound effect
  Future<void> playBlockPlaceSound() async {
    if (_hapticEnabled) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.stop();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/place.wav'));
    } catch (_) {}
  }

  // Play combo line clear sound effect
  Future<void> playClearSound() async {
    if (_hapticEnabled) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.stop();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/clear.wav'));
    } catch (_) {}
  }

  // Play game over sound effect
  Future<void> playGameOverSound() async {
    if (_hapticEnabled) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.stop();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/game_over.wav'));
    } catch (_) {}
  }

  // Start background music loop (continuous throughout app unless disabled in settings)
  Future<void> startBackgroundMusic() async {
    if (_bgmVolume <= 0.0) return;

    try {
      if (_bgmPlayer.state == PlayerState.playing) {
        _isBgmPlaying = true;
        return;
      }
      _isBgmPlaying = true;
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('sounds/bgm.wav'));
    } catch (_) {
      _isBgmPlaying = false;
    }
  }

  // Set Sound Effects volume
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
    for (final player in _sfxPool) {
      player.setVolume(_sfxVolume);
    }
    _persistSetting('sfx_volume', _sfxVolume);
  }

  // Set Background Music volume (ONLY called from Settings screen)
  void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
    _bgmPlayer.setVolume(_bgmVolume);
    if (_bgmVolume <= 0.0) {
      _isBgmPlaying = false;
      _bgmPlayer.pause();
    } else if (!_isBgmPlaying || _bgmPlayer.state != PlayerState.playing) {
      startBackgroundMusic();
    }
    _persistSetting('bgm_volume', _bgmVolume);
  }

  // Enable / Disable Haptic Vibration
  void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
    _persistSetting('haptic_enabled', _hapticEnabled);
  }

  void _persistSetting(String key, dynamic value) {
    try {
      if (Hive.isBoxOpen('user_progress_box')) {
        Hive.box('user_progress_box').put(key, value);
      }
    } catch (_) {}
  }

  void dispose() {
    for (final player in _sfxPool) {
      player.dispose();
    }
    _bgmPlayer.dispose();
  }
}
