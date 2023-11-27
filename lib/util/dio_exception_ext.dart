import 'package:dio/dio.dart';

extension PostcardExepctionExt on DioException {
  String get errorMessage => response?.data ?? '';

  int get statusCode => response?.statusCode ?? 0;

  bool get isPostcardAlreadyStamped =>
      errorMessage == PostcardExceptionType.alreadyStamped.errorMessage;

  bool get isPostcardClaimEmptyLimited =>
      statusCode == PostcardExceptionType.tooManyRequest.statusCode;
}

enum PostcardExceptionType {
  alreadyStamped,
  tooManyRequest;

  String get errorMessage {
    switch (this) {
      case PostcardExceptionType.alreadyStamped:
        return 'blockchain tx request is already existed';
      default:
        return '';
    }
  }

  int get statusCode {
    switch (this) {
      case PostcardExceptionType.tooManyRequest:
        return 429;
      default:
        return 0;
    }
  }
}
