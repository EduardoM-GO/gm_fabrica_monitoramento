import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/freezer_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/room_raw_data.dart';

final class TelemetryRawData extends BaseRawData {
  final int bootId;
  final int rssi;
  final int freeHeap;
  final int totalCount;
  final List<FreezerRawData> freezers;
  final RoomRawData? room;

  TelemetryRawData({
    required super.type,
    required this.bootId,
    required this.rssi,
    required this.freeHeap,
    required this.totalCount,
    required this.freezers,
    required this.room,
  });

  factory TelemetryRawData.fromMap({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) => TelemetryRawData(
    type: type,
    bootId: map['boot'] as int,
    rssi: map['rssi'] as int,
    freeHeap: map['freeHeap'] as int,
    totalCount: map['totalCount'] as int,
    freezers: _parseFreezers(type: type, map: map),
    room: _parseRoom(type: type, map: map),
  );

  static List<FreezerRawData> _parseFreezers({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    final int index = 1;
    final List<FreezerRawData> freezers = [];

    while (map.containsKey('f$index')) {
      final id = 'f$index';
      freezers.add(
        FreezerRawData.fromMap(
          type: type,
          id: id,
          map: map[id] as Map<String, dynamic>,
        ),
      );
    }

    return freezers;
  }

  static RoomRawData? _parseRoom({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    final roomMap = map['room'];
    if (roomMap is! Map) {
      return null;
    }

    return RoomRawData.fromJson(
      type: type,
      map: roomMap as Map<String, dynamic>,
    );
  }
}
