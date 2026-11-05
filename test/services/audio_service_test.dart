import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/sound_synthesizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundSynthesizer Tests', () {
    test('Generates valid RIFF/WAVE header and non-empty byte arrays', () {
      final hit = SoundSynthesizer.createEggHitWav();
      final undo = SoundSynthesizer.createEggUndoWav();
      final box = SoundSynthesizer.createBoxCompletedWav();
      final freezer = SoundSynthesizer.createFreezerReadyWav();
      final alarm = SoundSynthesizer.createDoorAlarmWav();

      for (final wav in [hit, undo, box, freezer, alarm]) {
        expect(wav.length, greaterThan(44));
        // 'RIFF'
        expect(wav.sublist(0, 4), [0x52, 0x49, 0x46, 0x46]);
        // 'WAVE'
        expect(wav.sublist(8, 12), [0x57, 0x41, 0x56, 0x45]);
        // 'fmt '
        expect(wav.sublist(12, 16), [0x66, 0x6D, 0x74, 0x20]);
        // 'data'
        expect(wav.sublist(36, 40), [0x64, 0x61, 0x74, 0x61]);
      }
    });
  });

  group('AudioService Tests', () {
    test('Muted AudioService does not throw on any method call', () {
      final service = AudioService(isMuted: true);
      expect(() => service.playEggHit(), returnsNormally);
      expect(() => service.playEggUndo(), returnsNormally);
      expect(() => service.playBoxCompleted(), returnsNormally);
      expect(() => service.playFreezerReady(), returnsNormally);
      expect(() => service.playDoorAlarm(), returnsNormally);
      service.dispose();
    });

    test('Unmuted AudioService handles calls safely without throwing', () {
      final service = AudioService(isMuted: false);
      expect(() => service.playEggHit(), returnsNormally);
      expect(() => service.playEggUndo(), returnsNormally);
      expect(() => service.playBoxCompleted(), returnsNormally);
      expect(() => service.playFreezerReady(), returnsNormally);
      expect(() => service.playDoorAlarm(), returnsNormally);
      service.dispose();
    });
  });
}

