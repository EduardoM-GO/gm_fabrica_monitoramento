import 'package:flutter/foundation.dart';
import 'package:gm_fabrica_monitoramento/src/core/exceptions/base_exception.dart';

/// Utility class that simplifies error handling following the official
/// Flutter Architecture guidelines (docs.flutter.dev/app-architecture).
///
/// Return a [Result] from an operation to indicate either success or failure.
///
/// A [Result] is either an [Ok] with a value of type [T]
/// or an [Error] with an [Exception].
///
/// Evaluate the result using Dart 3 pattern matching / switch:
/// ```dart
/// switch (result) {
///   case Ok(:final value):
///     print('Success: $value');
///   case Error(:final error):
///     print('Error: $error');
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result] with the provided [value].
  const factory Result.ok(T value) = Ok._;

  /// Creates an error [Result] with the provided [error].
  const factory Result.error(BaseException error) = Error._;

  static Result<T> catchInSync<T>({
    required T Function() fn,
    required String tag,
  }) {
    try {
      return Result.ok(fn());
    } on BaseException catch (e) {
      return Result.error(e);
    } catch (e, st) {
      return Result.error(
        BaseException(error: e, stackTrace: st, tag: st.toString()),
      );
    }
  }

  static Future<Result<T>> catchInAsync<T>({
    required Future<T> Function() fn,
    required String tag,
  }) async {
    try {
      return Result.ok(await fn());
    } on BaseException catch (e) {
      return Result.error(e);
    } catch (e, st) {
      return Result.error(BaseException(error: e, stackTrace: st, tag: tag));
    }
  }

  B fold<B>({
    required B Function(T value) onSuccess,
    required B Function(BaseException error) onError,
  }) => switch (this) {
    Ok(:final value) => onSuccess(value),
    Error(:final error) => onError(error),
  };

  bool get isOk => this is Ok<T>;
  bool get isError => this is Error<T>;

  BaseException get errorOrThrow {
    if (isError) {
      return (this as Error<T>).error;
    }
    throw Exception('No error in Ok result');
  }

  T get valueOrThrow {
    if (isOk) {
      return (this as Ok<T>).value;
    }
    throw Exception('No value in Error result');
  }
}

/// A successful [Result] containing the returned [value].
final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  /// The returned value.
  final T value;

  @override
  String toString() => 'Result.ok($value)';
}

/// An error [Result] containing the captured [Exception].
final class Error<T> extends Result<T> {
  const Error._(this.error);

  /// The captured exception.
  final BaseException error;

  @override
  String toString() => 'Result.error($error)';
}

@immutable
final class Unit {
  const Unit();
}

const unit = Unit();
