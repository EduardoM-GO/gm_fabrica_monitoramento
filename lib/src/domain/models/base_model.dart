import 'package:gm_fabrica_monitoramento/src/utils/generator_id.dart';

base class BaseModel {
  final String id;

  BaseModel({required String? id}) : id = id ?? GeneratorId.getid();
}
