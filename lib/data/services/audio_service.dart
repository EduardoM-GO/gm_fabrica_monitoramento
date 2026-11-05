import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  bool isMuted;
  bool eggSoundEnabled;
  bool alarmSoundEnabled;

  DateTime? _lastAlarmSoundTime;

  // Bundled asset paths in assets/audio/
  static const String eggHitAsset = 'audio/egg_hit.wav';
  static const String eggUndoAsset = 'audio/egg_undo.wav';
  static const String boxCompletedAsset = 'audio/box_completed.wav';
  static const String freezerReadyAsset = 'audio/freezer_ready.wav';
  static const String doorAlarmAsset = 'audio/door_alarm.wav';

  // Round-robin pool of AudioPlayers for rapid hits
  final List<AudioPlayer> _hitPlayers = [];
  int _hitIndex = 0;
  static const int _poolSize = 3;

  AudioPlayer? _undoPlayer;
  AudioPlayer? _boxPlayer;
  AudioPlayer? _freezerPlayer;
  AudioPlayer? _alarmPlayer;

  bool _initialized = false;

  AudioService({
    this.isMuted = false,
    this.eggSoundEnabled = true,
    this.alarmSoundEnabled = true,
  }) {
    if (!isMuted) {
      _initPlayers();
    }
  }

  void _initPlayers() {
    if (_initialized) return;
    _initialized = true;
    try {
      for (int i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        _hitPlayers.add(p);
      }
      _undoPlayer = AudioPlayer();
      _boxPlayer = AudioPlayer();
      _freezerPlayer = AudioPlayer();
      _alarmPlayer = AudioPlayer();
    } catch (e) {
      debugPrint('AudioService: AudioPlayer initialization error: $e');
    }
  }

  /// Plays crisp supermarket scanner beep (2600 Hz, 48ms) and light haptic tap
  void playEggHit() {
    if (isMuted || !eggSoundEnabled) return;

    if (!kIsWeb) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }

    _initPlayers();
    final player = _hitPlayers.isNotEmpty ? _hitPlayers[_hitIndex % _hitPlayers.length] : null;
    _hitIndex++;
    _play(player, eggHitAsset, fallback: SystemSoundType.click);
  }

  /// Plays descending cancel tone (480 -> 320 Hz, 85ms) when an egg count is decremented
  void playEggUndo() {
    if (isMuted || !eggSoundEnabled) return;

    if (!kIsWeb) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }

    _initPlayers();
    _play(_undoPlayer, eggUndoAsset, fallback: SystemSoundType.click);
  }

  /// Plays dual affirmative chirp ("bip-BIP!") when box is full (40 or 50 eggs)
  void playBoxCompleted() {
    if (isMuted || !eggSoundEnabled) return;

    if (!kIsWeb) {
      try {
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });
      } catch (_) {}
    }

    _initPlayers();
    _play(_boxPlayer, boxCompletedAsset, fallback: SystemSoundType.alert);
  }

  /// Plays triple ascending machine chime when freezer batch is ready for pickup
  void playFreezerReady() {
    if (isMuted || !alarmSoundEnabled) return;

    if (!kIsWeb) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    _initPlayers();
    _play(_freezerPlayer, freezerReadyAsset, fallback: SystemSoundType.alert);
  }

  /// Plays two-tone industrial buzzer when freezer door is left open
  void playDoorAlarm() {
    if (isMuted || !alarmSoundEnabled) return;

    final now = DateTime.now();
    if (_lastAlarmSoundTime != null &&
        now.difference(_lastAlarmSoundTime!).inMilliseconds < 2500) {
      return;
    }
    _lastAlarmSoundTime = now;

    if (!kIsWeb) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    _initPlayers();
    _play(_alarmPlayer, doorAlarmAsset, fallback: SystemSoundType.alert);
  }

  void _play(AudioPlayer? player, String assetPath, {required SystemSoundType fallback}) {
    if (player != null) {
      player.stop().then((_) {
        return player.play(AssetSource(assetPath));
      }).catchError((e) {
        debugPrint('AudioService: error playing $assetPath ($e). Using system fallback.');
        try {
          SystemSound.play(fallback);
        } catch (_) {}
      });
      return;
    }
    try {
      SystemSound.play(fallback);
    } catch (_) {}
  }

  void dispose() {
    for (final p in _hitPlayers) {
      p.dispose();
    }
    _hitPlayers.clear();
    _undoPlayer?.dispose();
    _boxPlayer?.dispose();
    _freezerPlayer?.dispose();
    _alarmPlayer?.dispose();
  }
}
