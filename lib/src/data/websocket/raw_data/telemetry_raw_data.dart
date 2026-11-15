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
    bootId: (map['boot'] as num?)?.toInt() ?? 1,
    rssi: (map['rssi'] as num?)?.toInt() ?? 0,
    freeHeap: (map['freeHeap'] as num?)?.toInt() ?? 0,
    totalCount: ((map['totalCount'] ?? map['c']) as num?)?.toInt() ?? 0,
    freezers: _parseFreezers(type: type, map: map),
    room: _parseRoom(type: type, map: map),
  );

  static List<FreezerRawData> _parseFreezers({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    int index = 1;
    final List<FreezerRawData> freezers = [];

    while (map.containsKey('f$index')) {
      final id = 'f$index';
      final rawFreezer = map[id];
      if (rawFreezer is Map<String, dynamic>) {
        freezers.add(
          FreezerRawData.fromMap(
            type: type,
            id: id,
            map: rawFreezer,
          ),
        );
      }
      index++;
    }

    return freezers;
  }

  static RoomRawData? _parseRoom({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    final roomMap = map['room'];
    if (roomMap is! Map<String, dynamic>) {
      return null;
    }

    return RoomRawData.fromJson(
      type: type,
      map: roomMap,
    );
  }
}
