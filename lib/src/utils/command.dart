import 'dart:async';
import 'package:flutter/foundation.dart';
import 'result.dart';

/// Defines a command action that returns a [Result] of type [T].
/// Used by [Command0] for actions without arguments.
typedef CommandAction0<T> = Future<Result<T>> Function();

/// Defines a command action that returns a [Result] of type [T]
/// and accepts an argument of type [A].
/// Used by [Command1] for single-argument actions.
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

/// Base class for the Command pattern recommended by the official
/// Flutter App Architecture guide (docs.flutter.dev/app-architecture).
///
/// Encapsulates an asynchronous action, exposes its running/error state,
/// and prevents concurrent executions (e.g., duplicate button taps).
abstract class Command<T> extends ChangeNotifier {
  Command();

  bool _running = false;

  /// Whether the command is currently executing.
  bool get running => _running;

  Result<T>? _result;

  /// The result of the most recent execution, if completed.
  Result<T>? get result => _result;

  /// Whether the command completed successfully with an [Ok] result.
  bool get completed => _result is Ok<T>;

  /// Whether the command finished with an [Error] result.
  bool get error => _result is Error<T>;

  /// Clears the last result and notifies listeners.
  void clearResult() {
    _result = null;
    notifyListeners();
  }

  /// Internal execution wrapper with loading state management and error capture.
  Future<void> _execute(CommandAction0<T> action) async {
    if (_running) return;

    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await action();
    } catch (e) {
      _result = Result.error(e is Exception ? e : Exception(e.toString()));
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

/// A [Command] that accepts no arguments.
final class Command0<T> extends Command<T> {
  Command0(this._action);

  final CommandAction0<T> _action;

  /// Executes the command action.
  Future<void> execute() async {
    await _execute(_action);
  }
}

/// A [Command] that accepts one argument of type [A].
final class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final CommandAction1<T, A> _action;

  /// Executes the command action with the given [argument].
  Future<void> execute(A argument) async {
    await _execute(() => _action(argument));
  }
}

