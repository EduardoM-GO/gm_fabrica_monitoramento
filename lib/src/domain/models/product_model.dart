import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';

final class ProductModel extends BaseModel {
  final String name;
  final int unitWeightGrams;
  final int defaultBoxCapacity;

  ProductModel({
    super.id,
    required this.name,
    required this.unitWeightGrams,
    int? defaultBoxCapacity,
  }) : defaultBoxCapacity =
           defaultBoxCapacity ?? (unitWeightGrams >= 500 ? 40 : 50);

  ProductModel copyWith({
    String? id,
    String? name,
    int? unitWeightGrams,
    int? defaultBoxCapacity,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
    );
  }
}
