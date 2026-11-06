import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';

final class DoorRawData({
  required super.type,
  required int freezerId,
  required bool isOpen,
}) extends BaseRawData {
  factory DoorRawData.fromMap({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    return DoorRawData(
      type: type,
      freezerId: map['f'] as int,
      isOpen: map['d'] == 1,
    );
  }
}
