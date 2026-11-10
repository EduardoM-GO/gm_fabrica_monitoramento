import 'package:gm_fabrica_monitoramento/src/data/local/enum/trigger_freezer_enum.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';

final class FreezerEventModel extends BaseModel {
  final ProductionBatchModel batch;
  final FreezerModel freezer;
  final double temperature;
  final bool isDoorOpen;
  final TriggerFreezerEnum triggerReason;

  FreezerEventModel({
    super.id,
    required this.batch,
    required this.freezer,
    required this.temperature,
    required this.isDoorOpen,
    required this.triggerReason,
  });
}
