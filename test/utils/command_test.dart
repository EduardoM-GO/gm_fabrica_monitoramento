import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/utils/command.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

void main() {
  group('Command Pattern Architecture Tests', () {
    test('Command0 executes successfully and updates state', () async {
      int callCount = 0;
      final command = Command0<int>(() async {
        callCount++;
        return const Result.ok(42);
      });

      expect(command.running, isFalse);
      expect(command.completed, isFalse);

      final future = command.execute();
      expect(command.running, isTrue);

      await future;

      expect(command.running, isFalse);
      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect(callCount, equals(1));
      expect((command.result as Ok<int>).value, equals(42));
    });

    test(
      'Command0 prevents concurrent duplicate executions while running',
      () async {
        final completer = Completer<Result<void>>();
        int executions = 0;

        final command = Command0<void>(() async {
          executions++;
          return completer.future;
        });

        // Start first execution
        final f1 = command.execute();
        expect(command.running, isTrue);

        // Attempt second execution while running
        final f2 = command.execute();

        completer.complete(const Result.ok(null));
        await Future.wait([f1, f2]);

        expect(
          executions,
          equals(1),
          reason: 'Duplicate execution should be blocked',
        );
        expect(command.running, isFalse);
        expect(command.completed, isTrue);
      },
    );

    test('Command1 passes argument and handles errors safely', () async {
      final command = Command1<String, int>((arg) async {
        if (arg < 0) {
          throw Exception('Negative values not allowed');
        }
        return Result.ok('val_$arg');
      });

      await command.execute(10);
      expect(command.completed, isTrue);
      expect((command.result as Ok<String>).value, equals('val_10'));

      await command.execute(-1);
      expect(command.error, isTrue);
      expect(command.completed, isFalse);
      expect(
        (command.result as Error<String>).error.toString(),
        contains('Negative values'),
      );
    });
  });
}
