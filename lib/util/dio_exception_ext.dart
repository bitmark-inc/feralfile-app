import 'package:dio/dio.dart';

extension PostcardExepctionExt on DioException {
  String get errorMessage => response?.data ?? '';

  bool get isPostcardAlreadyStamped =>
      errorMessage == PostcardExceptionType.alreadyStamped.errorMessage;
}

enum PostcardExceptionType {
  alreadyStamped;

  String get errorMessage {
    switch (this) {
      case PostcardExceptionType.alreadyStamped:
        return 'blockchain tx request is already existed';
    }
  }
}
