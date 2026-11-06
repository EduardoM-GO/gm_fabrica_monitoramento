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
  const factory Result.error(Exception error) = Error._;
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
  final Exception error;

  @override
  String toString() => 'Result.error($error)';
}

