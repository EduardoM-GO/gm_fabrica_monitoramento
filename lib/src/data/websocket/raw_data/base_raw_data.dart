import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/door_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/hit_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/telemetry_raw_data.dart';

base class BaseRawData({required TypeRawDataEnum type}) {
  factory BaseRawData.fromJson(Map<String, dynamic> map) {
    final type = TypeRawDataEnum.fromMap(map);

    return switch (type) {
      TypeRawDataEnum.telem => TelemetryRawData.fromMap(type: type, map: map),
      TypeRawDataEnum.door => DoorRawData.fromMap(type: type, map: map),
      TypeRawDataEnum.hit => HitRawData.fromMap(type: type, map: map),
    };
  }
}
