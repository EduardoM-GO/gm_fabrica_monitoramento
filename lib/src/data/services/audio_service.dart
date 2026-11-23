import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  bool isMuted;
  bool _eggSoundEnabled;
  bool _alarmSoundEnabled;

  // Chaves individuais para cada aviso sonoro da sala 4x4m
  bool eggHitSoundEnabled;
  bool boxCompletedSoundEnabled;
  bool conveyorAlertSoundEnabled;
  bool freezerStartSoundEnabled;
  bool freezerReadySoundEnabled;
  bool doorToggleSoundEnabled;
  bool doorAlarmSoundEnabled;

  DateTime? _lastAlarmSoundTime;
  DateTime? _lastConveyorAlertTime;

  // Bundled asset paths in assets/audio/
  static const String eggHitAsset = 'audio/egg_hit.wav';
  static const String eggUndoAsset = 'audio/egg_undo.wav';
  static const String boxCompletedAsset = 'audio/box_completed.wav';
  static const String conveyorAlertAsset = 'audio/conveyor_alert.wav';
  static const String freezer1StartAsset = 'audio/freezer1_start.wav';
  static const String freezer2StartAsset = 'audio/freezer2_start.wav';
  static const String freezerReadyAsset = 'audio/freezer_ready.wav';
  static const String freezer1ReadyAsset = 'audio/freezer1_ready.wav';
  static const String freezer2ReadyAsset = 'audio/freezer2_ready.wav';
  static const String doorOpenAsset = 'audio/door_open.wav';
  static const String doorCloseAsset = 'audio/door_close.wav';
  static const String doorAlarmAsset = 'audio/door_alarm.wav';

  // Round-robin pool of AudioPlayers for rapid hits
  final List<AudioPlayer> _hitPlayers = [];
  int _hitIndex = 0;
  static const int _poolSize = 3;

  AudioPlayer? _undoPlayer;
  AudioPlayer? _boxPlayer;
  AudioPlayer? _conveyorAlertPlayer;
  AudioPlayer? _freezerStartPlayer;
  AudioPlayer? _freezerPlayer;
  AudioPlayer? _doorTogglePlayer;
  AudioPlayer? _alarmPlayer;

  bool _initialized = false;

  AudioService({
    this.isMuted = false,
    bool eggSoundEnabled = true,
    bool alarmSoundEnabled = true,
    bool? eggHitSoundEnabled,
    bool? boxCompletedSoundEnabled,
    bool? conveyorAlertSoundEnabled,
    bool? freezerStartSoundEnabled,
    bool? freezerReadySoundEnabled,
    bool? doorToggleSoundEnabled,
    bool? doorAlarmSoundEnabled,
  }) : _eggSoundEnabled = eggSoundEnabled,
       _alarmSoundEnabled = alarmSoundEnabled,
       eggHitSoundEnabled = eggHitSoundEnabled ?? eggSoundEnabled,
       boxCompletedSoundEnabled = boxCompletedSoundEnabled ?? eggSoundEnabled,
       conveyorAlertSoundEnabled = conveyorAlertSoundEnabled ?? eggSoundEnabled,
       freezerStartSoundEnabled = freezerStartSoundEnabled ?? alarmSoundEnabled,
       freezerReadySoundEnabled = freezerReadySoundEnabled ?? alarmSoundEnabled,
       doorToggleSoundEnabled = doorToggleSoundEnabled ?? alarmSoundEnabled,
       doorAlarmSoundEnabled = doorAlarmSoundEnabled ?? alarmSoundEnabled {
    if (!isMuted) {
      _initPlayers();
    }
  }

  bool get eggSoundEnabled => _eggSoundEnabled;
  set eggSoundEnabled(bool value) {
    _eggSoundEnabled = value;
    eggHitSoundEnabled = value;
    boxCompletedSoundEnabled = value;
    conveyorAlertSoundEnabled = value;
  }

  bool get alarmSoundEnabled => _alarmSoundEnabled;
  set alarmSoundEnabled(bool value) {
    _alarmSoundEnabled = value;
    freezerStartSoundEnabled = value;
    freezerReadySoundEnabled = value;
    doorToggleSoundEnabled = value;
    doorAlarmSoundEnabled = value;
  }

  void _initPlayers() {
    if (_initialized) return;
    _initialized = true;
    try {
      for (int i = 0; i < _poolSize; i++) {
        final p = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
        _hitPlayers.add(p);
      }
      _undoPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _boxPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _conveyorAlertPlayer = AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency);
      _freezerStartPlayer = AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency);
      _freezerPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _doorTogglePlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _alarmPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('AudioService: AudioPlayer initialization error: $e');
    }
  }

  /// Plays crisp supermarket scanner beep (2600 Hz, 48ms) and light haptic tap
  void playEggHit({bool forceTest = false}) {
    if (isMuted || (!forceTest && (!eggSoundEnabled || !eggHitSoundEnabled))) {
      return;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }

    _initPlayers();
    final player = _hitPlayers.isNotEmpty
        ? _hitPlayers[_hitIndex % _hitPlayers.length]
        : null;
    _hitIndex++;
    _play(player, eggHitAsset, fallback: SystemSoundType.click);
  }

  /// Plays descending cancel tone (480 -> 320 Hz, 85ms) when an egg count is decremented
  void playEggUndo({bool forceTest = false}) {
    if (isMuted || (!forceTest && (!eggSoundEnabled || !eggHitSoundEnabled))) {
      return;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }

    _initPlayers();
    _play(_undoPlayer, eggUndoAsset, fallback: SystemSoundType.click);
  }

  /// Plays dual affirmative chirp ("bip-BIP!") when box is full (40 or 50 eggs)
  void playBoxCompleted({bool forceTest = false}) {
    if (isMuted ||
        (!forceTest && (!eggSoundEnabled || !boxCompletedSoundEnabled))) {
      return;
    }

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

  /// Plays warning tone when conveyor moves without an active batch
  void playConveyorAlert({bool forceTest = false}) {
    if (isMuted ||
        (!forceTest && (!eggSoundEnabled || !conveyorAlertSoundEnabled))) {
      return;
    }

    if (!forceTest) {
      final now = DateTime.now();
      if (_lastConveyorAlertTime != null &&
          now.difference(_lastConveyorAlertTime!).inMilliseconds < 2500) {
        return;
      }
      _lastConveyorAlertTime = now;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    _initPlayers();
    _play(
      _conveyorAlertPlayer,
      conveyorAlertAsset,
      fallback: SystemSoundType.alert,
    );
  }

  /// Plays unique cycle start chime differentiated by freezer (F1: 1 warm chord, F2: 2 bright pulses)
  void playFreezerStarted({String freezerId = 'f1', bool forceTest = false}) {
    if (isMuted ||
        (!forceTest && (!alarmSoundEnabled || !freezerStartSoundEnabled))) {
      return;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    _initPlayers();
    final asset =
        freezerId == 'f2' ? freezer2StartAsset : freezer1StartAsset;
    _play(_freezerStartPlayer, asset, fallback: SystemSoundType.click);
  }

  /// Plays machine chime when freezer batch is ready for pickup, differentiated by freezer (F1 vs F2)
  void playFreezerReady({String freezerId = 'f1', bool forceTest = false}) {
    if (isMuted ||
        (!forceTest && (!alarmSoundEnabled || !freezerReadySoundEnabled))) {
      return;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    _initPlayers();
    final asset =
        freezerId == 'f2' ? freezer2ReadyAsset : freezer1ReadyAsset;
    _play(_freezerPlayer, asset, fallback: SystemSoundType.alert);
  }

  /// Plays subtle ascending pop when freezer door opens
  void playDoorOpened({bool forceTest = false}) {
    if (isMuted ||
        (!forceTest && (!alarmSoundEnabled || !doorToggleSoundEnabled))) {
      return;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }

    _initPlayers();
    _play(_doorTogglePlayer, doorOpenAsset, fallback: SystemSoundType.click);
  }

  /// Plays subtle descending seal click when freezer door closes
  void playDoorClosed({bool forceTest = false}) {
    if (isMuted ||
        (!forceTest && (!alarmSoundEnabled || !doorToggleSoundEnabled))) {
      return;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }

    _initPlayers();
    _play(_doorTogglePlayer, doorCloseAsset, fallback: SystemSoundType.click);
  }

  /// Plays two-tone industrial buzzer when freezer door is left open
  void playDoorAlarm({bool forceTest = false}) {
    if (isMuted ||
        (!forceTest && (!alarmSoundEnabled || !doorAlarmSoundEnabled))) {
      return;
    }

    if (!forceTest) {
      final now = DateTime.now();
      if (_lastAlarmSoundTime != null &&
          now.difference(_lastAlarmSoundTime!).inMilliseconds < 2500) {
        return;
      }
      _lastAlarmSoundTime = now;
    }

    if (!kIsWeb) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    _initPlayers();
    _play(_alarmPlayer, doorAlarmAsset, fallback: SystemSoundType.alert);
  }

  void _play(
    AudioPlayer? player,
    String assetPath, {
    required SystemSoundType fallback,
    bool stopBeforePlay = false,
  }) {
    if (player != null) {
      final playFuture = stopBeforePlay
          ? player.stop().then((_) => player.play(AssetSource(assetPath)))
          : player.play(AssetSource(assetPath));
      playFuture.catchError((e) {
        debugPrint(
          'AudioService: error playing $assetPath ($e). Using system fallback.',
        );
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
    _conveyorAlertPlayer?.dispose();
    _freezerStartPlayer?.dispose();
    _freezerPlayer?.dispose();
    _doorTogglePlayer?.dispose();
    _alarmPlayer?.dispose();
  }
}
