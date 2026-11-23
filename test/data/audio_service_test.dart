import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.gm_fabrica/native_audio');

  group('AudioService - Native SoundPool Channel & 18h+ Self-Healing', () {
    final List<MethodCall> methodCalls = [];
    bool shouldFailNextPlay = false;

    setUp(() {
      methodCalls.clear();
      shouldFailNextPlay = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            methodCalls.add(call);
            if (call.method == 'preload' || call.method == 'reset') {
              return AudioService.allAudioAssets.length;
            }
            if (call.method == 'play') {
              if (shouldFailNextPlay) {
                return false;
              }
              return true;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('preloads all 12 audio assets on initialization when not muted', () async {
      final service = AudioService(isMuted: false);
      await Future<void>.delayed(Duration.zero);

      expect(methodCalls.any((c) => c.method == 'preload'), isTrue);
      final preloadCall = methodCalls.firstWhere((c) => c.method == 'preload');
      final assets = (preloadCall.arguments as Map)['assets'] as List;
      expect(assets.length, AudioService.allAudioAssets.length);
      service.dispose();
    });

    test('dispatches native play calls for each industrial sound event', () async {
      final service = AudioService(isMuted: false);
      await Future<void>.delayed(Duration.zero);
      methodCalls.clear();

      service.playEggHit();
      service.playEggUndo();
      service.playBoxCompleted();
      service.playConveyorAlert(forceTest: true);
      service.playFreezerStarted(freezerId: 'f1');
      service.playFreezerStarted(freezerId: 'f2');
      service.playFreezerReady(freezerId: 'f1');
      service.playFreezerReady(freezerId: 'f2');
      service.playDoorOpened();
      service.playDoorClosed();
      service.playDoorAlarm(forceTest: true);

      await Future<void>.delayed(Duration.zero);

      final playedAssets = methodCalls
          .where((c) => c.method == 'play')
          .map((c) => (c.arguments as Map)['asset'] as String)
          .toList();

      expect(
        playedAssets,
        equals([
          AudioService.eggHitAsset,
          AudioService.eggUndoAsset,
          AudioService.boxCompletedAsset,
          AudioService.conveyorAlertAsset,
          AudioService.freezer1StartAsset,
          AudioService.freezer2StartAsset,
          AudioService.freezer1ReadyAsset,
          AudioService.freezer2ReadyAsset,
          AudioService.doorOpenAsset,
          AudioService.doorCloseAsset,
          AudioService.doorAlarmAsset,
        ]),
      );
    });

    test('triggers automatic self-healing reset after consecutive native stream failures', () async {
      final service = AudioService(isMuted: false);
      await Future<void>.delayed(Duration.zero);
      methodCalls.clear();

      shouldFailNextPlay = true;

      // 1st failure increments consecutive failure counter
      service.playEggHit();
      await Future<void>.delayed(Duration.zero);
      expect(methodCalls.where((c) => c.method == 'reset'), isEmpty);

      // 2nd failure triggers self-healing reset and retries play
      service.playEggHit();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(methodCalls.any((c) => c.method == 'reset'), isTrue);
    });
  });
}
