abstract class FFError implements Exception {
  String get message;

  @override
  String toString() => 'FFError: $message';
}
