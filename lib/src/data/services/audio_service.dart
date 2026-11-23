import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Industrial 24/7 audio feedback service backed directly by Android's native
/// [SoundPool] (and iOS [AVAudioPlayer] pool) via [MethodChannel].
///
/// Why native [SoundPool] instead of `audioplayers`:
/// - Preloads all WAV files directly from the APK (`AssetFileDescriptor`) into
///   native audio RAM at startup — never extracts temporary files to `/cache`
///   (which Android OS periodically cleans up during long 18h+ runs).
/// - Stateless fire-and-forget playback (`soundPool.play()`): no `MediaPlayer`
///   state machine (`playing`, `prepared`) or `AudioFocus` conflicts that can
///   deadlock when conveyor beeps and freezer alarms fire simultaneously.
/// - Automatic self-healing: if the Android audio server ever restarts or
///   returns `streamId == 0`, the native pool automatically rebuilds and
///   reloads all WAV assets in memory.
class AudioService {
  static const MethodChannel _channel = MethodChannel(
    'com.gm_fabrica/native_audio',
  );

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

  static const List<String> allAudioAssets = [
    eggHitAsset,
    eggUndoAsset,
    boxCompletedAsset,
    conveyorAlertAsset,
    freezer1StartAsset,
    freezer2StartAsset,
    freezerReadyAsset,
    freezer1ReadyAsset,
    freezer2ReadyAsset,
    doorOpenAsset,
    doorCloseAsset,
    doorAlarmAsset,
  ];

  bool _initialized = false;
  bool _isResetting = false;
  int _consecutiveFailures = 0;

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
      _ensureInitialized();
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

  void _ensureInitialized() {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    unawaited(
      _channel
          .invokeMethod<int>('preload', {'assets': allAudioAssets})
          .catchError((Object e) {
            debugPrint('AudioService: preload notice ($e)');
            return 0;
          }),
    );
  }

  Future<void> _selfHealNativePool() async {
    if (_isResetting || kIsWeb) return;
    _isResetting = true;
    try {
      debugPrint('AudioService: self-healing native SoundPool...');
      await _channel.invokeMethod<int>('reset', {'assets': allAudioAssets});
    } catch (e) {
      debugPrint('AudioService: self-heal reset failed ($e)');
    } finally {
      _isResetting = false;
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

    _play(eggHitAsset, fallback: SystemSoundType.click);
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

    _play(eggUndoAsset, fallback: SystemSoundType.click);
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

    _play(boxCompletedAsset, fallback: SystemSoundType.alert);
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

    _play(conveyorAlertAsset, fallback: SystemSoundType.alert);
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

    final asset = freezerId == 'f2' ? freezer2StartAsset : freezer1StartAsset;
    _play(asset, fallback: SystemSoundType.click);
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

    final asset = freezerId == 'f2' ? freezer2ReadyAsset : freezer1ReadyAsset;
    _play(asset, fallback: SystemSoundType.alert);
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

    _play(doorOpenAsset, fallback: SystemSoundType.click);
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

    _play(doorCloseAsset, fallback: SystemSoundType.click);
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

    _play(doorAlarmAsset, fallback: SystemSoundType.alert);
  }

  void _play(
    String assetPath, {
    required SystemSoundType fallback,
  }) {
    _ensureInitialized();
    unawaited(_invokeNativePlay(assetPath, fallback));
  }

  Future<void> _invokeNativePlay(
    String assetPath,
    SystemSoundType fallback,
  ) async {
    if (kIsWeb) {
      try {
        await SystemSound.play(fallback);
      } catch (_) {}
      return;
    }

    try {
      final played = await _channel.invokeMethod<bool>(
        'play',
        {'asset': assetPath},
      );
      if (played == true) {
        _consecutiveFailures = 0;
        return;
      }

      // If native SoundPool returned false (e.g. Android audio server died or
      // stream allocation failed), trigger self-healing and play again.
      _consecutiveFailures++;
      if (_consecutiveFailures >= 2) {
        _consecutiveFailures = 0;
        await _selfHealNativePool();
        final retryPlayed = await _channel.invokeMethod<bool>(
          'play',
          {'asset': assetPath},
        );
        if (retryPlayed == true) return;
      }
    } catch (e) {
      debugPrint(
        'AudioService: error playing $assetPath ($e). Using system fallback.',
      );
    }

    try {
      await SystemSound.play(fallback);
    } catch (_) {}
  }

  void dispose() {
    _initialized = false;
  }
}
