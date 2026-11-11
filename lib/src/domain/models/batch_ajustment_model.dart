import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';

final class BatchAjustmentModel extends BaseModel {
  final ProductionBatchModel batch;
  final String batchId;
  final AdjustmentReasonEnum reason;
  final String? customNote;
  final int quantity;
  final DateTime createdAt;

  BatchAjustmentModel({
    required super.id,
    required this.batch,
    required this.batchId,
    required this.reason,
    required this.customNote,
    required this.quantity,
    required this.createdAt,
  });
}
