import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum HapticLevel {
  slow('Slow'),
  middle('Middle'),
  high('High'),
  tooHigh('Extreme');

  final String label;
  const HapticLevel(this.label);

  static HapticLevel fromString(String val) {
    final lower = val.toLowerCase().replaceAll(' ', '');
    if (lower == 'toohigh' || lower == 'extreme' || lower == 'extrim') {
      return HapticLevel.tooHigh;
    }
    return HapticLevel.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => HapticLevel.middle,
    );
  }
}

class AudioService with WidgetsBindingObserver {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();
  factory AudioService() => instance;

  final List<AudioPlayer> _sfxPool = List.generate(
    4,
    (_) => AudioPlayer()..positionUpdater = null,
  );
  final AudioPlayer _bgmPlayer = AudioPlayer()..positionUpdater = null;
  int _sfxIndex = 0;

  double _sfxVolume = 0.8;
  double _bgmVolume = 0.7;
  bool _hapticEnabled = true;
  HapticLevel _hapticLevel = HapticLevel.middle;
  bool _isBgmPlaying = false;
  bool _wasBgmPlayingBeforeLifecyclePause = false;
  bool _initialized = false;

  double get sfxVolume => _sfxVolume;
  double get bgmVolume => _bgmVolume;
  bool get hapticEnabled => _hapticEnabled;
  HapticLevel get hapticLevel => _hapticLevel;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Register WidgetsBindingObserver to auto-pause music when screen is off / app backgrounded
    WidgetsBinding.instance.addObserver(this);

    // Load persisted volume & haptic settings from Hive if box is open
    try {
      if (Hive.isBoxOpen('user_progress_box')) {
        final box = Hive.box('user_progress_box');
        _sfxVolume = (box.get('sfx_volume', defaultValue: 0.8) as num).toDouble();
        _bgmVolume = (box.get('bgm_volume', defaultValue: 0.7) as num).toDouble();
        _hapticEnabled = (box.get('haptic_enabled', defaultValue: true) as bool);
        final savedHapticLevel = box.get('haptic_level', defaultValue: 'Middle') as String?;
        if (savedHapticLevel != null) {
          _hapticLevel = HapticLevel.fromString(savedHapticLevel);
        }
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
          category: AVAudioSessionCategory.ambient,
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
        player.positionUpdater = null;
        try {
          await player.setPlayerMode(PlayerMode.lowLatency);
        } catch (_) {}
        player.setVolume(_sfxVolume);
      }
      _bgmPlayer.positionUpdater = null;
      _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

      // Loop safety fallback listener
      _bgmPlayer.onPlayerComplete.listen((_) async {
        if (_bgmVolume > 0.0 && _isBgmPlaying && !_wasBgmPlayingBeforeLifecyclePause) {
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
        HapticFeedback.vibrate();
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/click.wav'));
    } catch (_) {}
  }

  // Play block placement sound effect
  Future<void> playBlockPlaceSound() async {
    if (_hapticEnabled) {
      try {
        switch (_hapticLevel) {
          case HapticLevel.slow:
            HapticFeedback.vibrate();
            break;
          case HapticLevel.middle:
            HapticFeedback.vibrate();
            break;
          case HapticLevel.high:
            HapticFeedback.vibrate();
            Future.delayed(const Duration(milliseconds: 90), () {
              HapticFeedback.vibrate();
            });
            break;
          case HapticLevel.tooHigh:
            HapticFeedback.vibrate();
            Future.delayed(const Duration(milliseconds: 70), () {
              HapticFeedback.vibrate();
            });
            break;
        }
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/place.wav'));
    } catch (_) {}
  }

  // Play combo line clear sound effect
  Future<void> playClearSound() async {
    if (_hapticEnabled) {
      try {
        switch (_hapticLevel) {
          case HapticLevel.slow:
            HapticFeedback.vibrate();
            break;
          case HapticLevel.middle:
            HapticFeedback.vibrate();
            Future.delayed(const Duration(milliseconds: 90), () {
              HapticFeedback.vibrate();
            });
            break;
          case HapticLevel.high:
            for (int i = 0; i < 3; i++) {
              Future.delayed(Duration(milliseconds: i * 80), () {
                HapticFeedback.vibrate();
              });
            }
            break;
          case HapticLevel.tooHigh:
            for (int i = 0; i < 4; i++) {
              Future.delayed(Duration(milliseconds: i * 65), () {
                HapticFeedback.vibrate();
              });
            }
            break;
        }
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/clear.wav'));
    } catch (_) {}
  }

  // Play game over sound effect
  Future<void> playGameOverSound() async {
    if (_hapticEnabled) {
      try {
        switch (_hapticLevel) {
          case HapticLevel.slow:
            HapticFeedback.vibrate();
            break;
          case HapticLevel.middle:
            for (int i = 0; i < 2; i++) {
              Future.delayed(Duration(milliseconds: i * 90), () {
                HapticFeedback.vibrate();
              });
            }
            break;
          case HapticLevel.high:
            for (int i = 0; i < 3; i++) {
              Future.delayed(Duration(milliseconds: i * 80), () {
                HapticFeedback.vibrate();
              });
            }
            break;
          case HapticLevel.tooHigh:
            for (int i = 0; i < 4; i++) {
              Future.delayed(Duration(milliseconds: i * 65), () {
                HapticFeedback.vibrate();
              });
            }
            break;
        }
      } catch (_) {}
    }
    if (_sfxVolume <= 0.0) return;

    try {
      final player = _getNextSfxPlayer();
      await player.setVolume(_sfxVolume);
      await player.play(AssetSource('sounds/game_over.wav'));
    } catch (_) {}
  }

  // Start background music loop (continuous throughout app unless disabled in settings)
  Future<void> startBackgroundMusic() async {
    if (_bgmVolume <= 0.0) return;
    _wasBgmPlayingBeforeLifecyclePause = false;

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

  // Explicitly pause background music
  Future<void> pauseBackgroundMusic() async {
    _isBgmPlaying = false;
    _wasBgmPlayingBeforeLifecyclePause = false;
    try {
      await _bgmPlayer.pause();
    } catch (_) {}
  }

  // Explicitly resume background music
  Future<void> resumeBackgroundMusic() async {
    if (_bgmVolume <= 0.0) return;
    _isBgmPlaying = true;
    _wasBgmPlayingBeforeLifecyclePause = false;
    try {
      if (_bgmPlayer.state == PlayerState.paused) {
        await _bgmPlayer.resume();
      } else {
        await startBackgroundMusic();
      }
    } catch (_) {}
  }

  /// App lifecycle listener:
  /// When screen turns off, phone locks, or app is backgrounded (paused/inactive/hidden),
  /// the music turns OFF immediately.
  /// When screen turns back on and user returns (resumed), music turns back ON.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Screen turned off / locked / app minimized: pause music immediately
        if (_isBgmPlaying && _bgmVolume > 0.0) {
          _wasBgmPlayingBeforeLifecyclePause = true;
          _bgmPlayer.pause();
        }
        // Silence any ongoing sfx
        for (final player in _sfxPool) {
          try {
            player.stop();
          } catch (_) {}
        }
        break;

      case AppLifecycleState.resumed:
        // Screen turned on / unlocked / app foregrounded: resume music if previously playing
        if (_wasBgmPlayingBeforeLifecyclePause && _bgmVolume > 0.0) {
          _wasBgmPlayingBeforeLifecyclePause = false;
          _isBgmPlaying = true;
          if (_bgmPlayer.state == PlayerState.paused) {
            _bgmPlayer.resume();
          } else {
            startBackgroundMusic();
          }
        }
        break;

      case AppLifecycleState.detached:
        _wasBgmPlayingBeforeLifecyclePause = false;
        _bgmPlayer.pause();
        break;
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
      _wasBgmPlayingBeforeLifecyclePause = false;
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

  // Set Haptic Feedback Intensity Level
  void setHapticLevel(HapticLevel level) {
    _hapticLevel = level;
    _hapticEnabled = true;
    _persistSetting('haptic_level', level.label);
    _persistSetting('haptic_enabled', true);
    triggerHaptic(level, true);
  }

  // Trigger tactile vibration matching the chosen haptic level (distinct feelable pulses for all 4 levels)
  Future<void> triggerHaptic([HapticLevel? overrideLevel, bool force = false]) async {
    if (!_hapticEnabled && !force) return;
    final level = overrideLevel ?? _hapticLevel;
    try {
      switch (level) {
        case HapticLevel.slow:
          // Level 1: 1 single crisp pulse - gentle tactile feedback
          await HapticFeedback.heavyImpact();
          await HapticFeedback.vibrate();
          break;
        case HapticLevel.middle:
          // Level 2: 2 rhythmic pulses - clear medium tactile feedback
          await HapticFeedback.heavyImpact();
          await HapticFeedback.vibrate();
          await Future.delayed(const Duration(milliseconds: 120));
          await HapticFeedback.heavyImpact();
          await HapticFeedback.vibrate();
          break;
        case HapticLevel.high:
          // Level 3: 3 strong rhythmic pulses - high tactile feedback
          for (int i = 0; i < 3; i++) {
            await HapticFeedback.heavyImpact();
            await HapticFeedback.vibrate();
            await Future.delayed(const Duration(milliseconds: 90));
          }
          break;
        case HapticLevel.tooHigh:
          // Level 4: 5 rapid intense pulses - maximum tactile vibration burst
          for (int i = 0; i < 5; i++) {
            await HapticFeedback.heavyImpact();
            await HapticFeedback.vibrate();
            await Future.delayed(const Duration(milliseconds: 70));
          }
          break;
      }
    } catch (_) {}
  }

  void _persistSetting(String key, dynamic value) {
    try {
      if (Hive.isBoxOpen('user_progress_box')) {
        Hive.box('user_progress_box').put(key, value);
      }
    } catch (_) {}
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final player in _sfxPool) {
      player.dispose();
    }
    _bgmPlayer.dispose();
  }
}
