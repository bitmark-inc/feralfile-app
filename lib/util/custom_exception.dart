import 'package:autonomy_flutter/database/entity/connection.dart';

class SystemException implements Exception {
  final String reason;

  SystemException(this.reason);
}

class AlreadyLinkedException implements Exception {
  final Connection connection;
  AlreadyLinkedException(this.connection);
}

class AbortedException implements Exception {}
