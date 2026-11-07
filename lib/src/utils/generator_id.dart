import 'package:uuid/uuid.dart';

final class GeneratorId {
  final Uuid _uuid;

  GeneratorId() : _uuid = const Uuid();

  String getid() {
    return _uuid.v4();
  }
}
