import 'package:uuid/uuid.dart';

final class GeneratorId {
  GeneratorId._();

  static const _uuid = Uuid();

  static String getid() {
    return _uuid.v4();
  }
}
