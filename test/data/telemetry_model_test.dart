import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/door_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/hit_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/telemetry_raw_data.dart';

void main() {
  group('BaseRawData WebSocket JSON Parsing', () {
    test('Parses periodic telemetry frame with multiple freezers and room', () {
      final json = {
        't': 'telem',
        'boot': 1,
        'rssi': -62,
        'freeHeap': 180000,
        'totalCount': 84,
        'f1': {'temp': 9.25, 'd': 0, 'ok': 1},
        'f2': {'temp': -14.10, 'd': 1, 'ok': 0},
        'room': {'temp': 21.5, 'h': 55.0},
      };

      final frame = BaseRawData.fromJson(json);
      expect(frame, isA<TelemetryRawData>());

      final telem = frame as TelemetryRawData;
      expect(telem.bootId, 1);
      expect(telem.totalCount, 84);
      expect(telem.freezers.length, 2);

      // Freezer 1
      expect(telem.freezers[0].id, 'f1');
      expect(telem.freezers[0].temp, 9.25);
      expect(telem.freezers[0].isDoorOpen, isFalse);
      expect(telem.freezers[0].isSensorOk, isTrue);

      // Freezer 2
      expect(telem.freezers[1].id, 'f2');
      expect(telem.freezers[1].temp, -14.10);
      expect(telem.freezers[1].isDoorOpen, isTrue);
      expect(telem.freezers[1].isSensorOk, isFalse);

      // Room
      expect(telem.room, isNotNull);
      expect(telem.room!.temp, 21.5);
      expect(telem.room!.humidity, 55.0);
    });

    test('Parses instant hit frame correctly (both c and totalCount)', () {
      final hit1 = BaseRawData.fromJson({'t': 'hit', 'c': 85}) as HitRawData;
      expect(hit1.totalCount, 85);

      final hit2 =
          BaseRawData.fromJson({'t': 'hit', 'totalCount': 86}) as HitRawData;
      expect(hit2.totalCount, 86);
    });

    test('Parses door event frame correctly', () {
      final door =
          BaseRawData.fromJson({'t': 'door', 'f': 1, 'd': 1}) as DoorRawData;
      expect(door.freezerId, 1);
      expect(door.isOpen, isTrue);
    });

    test('Throws Exception on unknown frame type', () {
      expect(
        () => BaseRawData.fromJson({'t': 'invalid'}),
        throwsException,
      );
    });
  });
}
