import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';

final class FreezerModel extends BaseModel {
  final int idSensor;
  final String name;
  final String description;

  FreezerModel({
    super.id,
    required this.idSensor,
    required this.name,
    required this.description,
  });
}
