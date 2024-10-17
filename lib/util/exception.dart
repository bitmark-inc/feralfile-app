class AccountException implements Exception {
  final String? message;

  AccountException({this.message});
}

class LinkAddressException implements Exception {
  final String message;

  LinkAddressException({required this.message});
}

class JwtException implements Exception {
  final String message;

  JwtException({required this.message});
}

class ErrorBindingException implements Exception {
  final String message;
  final Exception originalException;

  ErrorBindingException({
    required this.message,
    required this.originalException,
  });
}
