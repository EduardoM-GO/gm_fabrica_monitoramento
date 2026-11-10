import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';

final class RoomRawData extends BaseRawData {
  final double temp;
  final double humidity;

  RoomRawData({
    required super.type,
    required this.temp,
    required this.humidity,
  });

  factory RoomRawData.fromJson({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) => RoomRawData(type: type, temp: map['temp'], humidity: map['h']);
}
