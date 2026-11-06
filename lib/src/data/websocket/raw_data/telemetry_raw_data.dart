import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/freezer_raw_data.dart';

final class TelemetryRawData({
  required super.type,
  required int bootId,
  required int rssi,
  required int freeHeap,
  required int totalCount,
  required List<FreezerRawData> freezers,
}) extends BaseRawData {
  factory TelemetryRawData.fromMap({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    return TelemetryRawData(
      type: type,
      bootId: map['boot'] as int,
      rssi: map['rssi'] as int,
      freeHeap: map['freeHeap'] as int,
      totalCount: map['totalCount'] as int,
      freezers: _parseFreezers(type: type, map: map),
    );
  }

  static List<FreezerRawData> _parseFreezers({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    final int index = 1;
    final List<FreezerRawData> freezers = [];

    while (map.containsKey('f$index')) {
      freezers.add(
        FreezerRawData.fromMap(
          type: type,
          map: map['f$index'] as Map<String, dynamic>,
        ),
      );
    }

    return freezers;
  }
}
