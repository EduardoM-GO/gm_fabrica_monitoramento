import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';

final class ProductionBatchModel extends BaseModel {
  final ProductModel product;
  final int initialQuantity;
  final int actualQuantity;
  final DateTime startedAt;
  final DateTime? finishedAt;

  ProductionBatchModel({
    super.id,
    required this.product,
    required this.initialQuantity,
    int? actualQuantity,
    DateTime? startedAt,
    this.finishedAt,
  }) : actualQuantity = actualQuantity ?? initialQuantity,
       startedAt = startedAt ?? DateTime.now();
}
