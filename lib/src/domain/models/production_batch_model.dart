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

  bool get isFinished => finishedAt != null;
  bool get isActive => finishedAt == null;

  /// Quantidade líquida de ovos produzidos neste lote
  int get producedQuantity => (actualQuantity - initialQuantity).clamp(0, 99999999);

  ProductionBatchModel copyWith({
    String? id,
    ProductModel? product,
    int? initialQuantity,
    int? actualQuantity,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return ProductionBatchModel(
      id: id ?? this.id,
      product: product ?? this.product,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}
