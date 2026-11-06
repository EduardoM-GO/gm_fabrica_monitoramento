import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';

final class FreezerRawData({
  required super.type,
  required double temp,
  required bool isDoorOpen,
  required bool isSensorOk,
}) extends BaseRawData {
  factory FreezerRawData.fromMap({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    return FreezerRawData(
      type: type,
      temp: (map['temp'] as num).toDouble(),
      isDoorOpen: map['d'] == 1,
      isSensorOk: map['ok'] == 1,
    );
  }
}
