import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';

final class RoomModel extends BaseModel {
  final ProductionBatchModel batch;
  final double temperature;
  final double humidity;

  RoomModel({
    super.id,
    required this.batch,
    required this.temperature,
    required this.humidity,
  });
}
