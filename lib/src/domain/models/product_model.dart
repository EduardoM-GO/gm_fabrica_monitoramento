import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';

final class ProductModel extends BaseModel {
  final String name;
  final int unitWeightGrams;

  ProductModel({super.id, required this.name, required this.unitWeightGrams});
}
