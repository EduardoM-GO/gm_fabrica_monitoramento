import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

void main() {
  group('Result<T> Architecture Pattern Tests', () {
    test('Result.ok returns value and matches Ok case', () {
      const Result<String> result = Result.ok('factory_success');

      expect(result, isA<Ok<String>>());
      final value = switch (result) {
        Ok(:final value) => value,
        Error() => 'fail',
      };
      expect(value, equals('factory_success'));
    });

    test('Result.error returns exception and matches Error case', () {
      final exception = Exception('connection_refused');
      final Result<int> result = Result.error(exception);

      expect(result, isA<Error<int>>());
      final errMsg = switch (result) {
        Ok() => 'ok',
        Error(:final error) => error.toString(),
      };
      expect(errMsg, contains('connection_refused'));
    });
  });
}
