import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';

final class HitRawData extends BaseRawData {
  final int totalCount;

  HitRawData({required super.type, required this.totalCount});

  factory HitRawData.fromMap({
    required TypeRawDataEnum type,
    required Map<String, dynamic> map,
  }) {
    return HitRawData(type: type, totalCount: map['totalCount'] as int);
  }
}
