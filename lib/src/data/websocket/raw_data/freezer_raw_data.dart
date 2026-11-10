import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';

final class FreezerRawData extends BaseRawData {
  final String id;
  final double temp;
  final bool isDoorOpen;
  final bool isSensorOk;

  FreezerRawData({
    required this.id,
    required super.type,
    required this.temp,
    required this.isDoorOpen,
    required this.isSensorOk,
  });

  factory FreezerRawData.fromMap({
    required TypeRawDataEnum type,
    required String id,
    required Map<String, dynamic> map,
  }) => FreezerRawData(
    type: type,
    id: id,
    temp: (map['temp'] as num).toDouble(),
    isDoorOpen: map['d'] == 1,
    isSensorOk: map['ok'] == 1,
  );
}
