base class BaseException implements Exception {
  final Object error;
  final StackTrace stackTrace;
  final String tag;

  const BaseException({
    required this.error,
    required this.stackTrace,
    required this.tag,
  });

  @override
  String toString() => '[$tag] $error';
}
