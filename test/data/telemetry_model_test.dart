import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/model/telemetry_model.dart';

void main() {
  group('Telemetry Model Parsing', () {
    test('Parses periodic telemetry frame correctly', () {
      final json = {
        't': 'telem',
        'up': 14205,
        'c': 84,
        'f1': {'temp': 9.25, 'd': 0, 'ok': 1},
        'f2': {'temp': -14.10, 'd': 1, 'ok': 0},
      };

      final frame = IncomingFrame.fromJson(json);
      expect(frame, isA<TelemetryFrame>());

      final telem = frame as TelemetryFrame;
      expect(telem.uptimeMs, 14205);
      expect(telem.eggCount, 84);

      // Freezer 1
      expect(telem.freezer1, isNotNull);
      expect(telem.freezer1!.temp, 9.25);
      expect(telem.freezer1!.door, 0);
      expect(telem.freezer1!.ok, 1);
      expect(telem.freezer1!.isDoorOpen, false);
      expect(telem.freezer1!.isProbeOk, true);

      // Freezer 2
      expect(telem.freezer2, isNotNull);
      expect(telem.freezer2!.temp, -14.10);
      expect(telem.freezer2!.door, 1);
      expect(telem.freezer2!.ok, 0);
      expect(telem.freezer2!.isDoorOpen, true);
      expect(telem.freezer2!.isProbeOk, false);
    });

    test(
      'Parses frame with only 1 freezer correctly and keeps freezer2 null',
      () {
        final json = {
          't': 'telem',
          'up': 14205,
          'c': 84,
          'f1': {'temp': 9.25, 'd': 0, 'ok': 1},
        };

        final frame = IncomingFrame.fromJson(json) as TelemetryFrame;
        expect(frame.freezer1, isNotNull);
        expect(frame.freezer1!.temp, 9.25);
        expect(frame.freezer2, isNull);
      },
    );

    test('Parses instant hit frame correctly', () {
      final json = {'t': 'hit', 'c': 85};

      final frame = IncomingFrame.fromJson(json);
      expect(frame, isA<HitFrame>());

      final hit = frame as HitFrame;
      expect(hit.eggCount, 85);
    });

    test('Throws on unknown frame type', () {
      expect(
        () => IncomingFrame.fromJson({'t': 'invalid'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
