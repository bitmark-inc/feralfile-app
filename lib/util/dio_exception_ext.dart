import 'package:dio/dio.dart';

extension PostcardExepctionExt on DioException {
  String get data => response?.data ?? '';

  String get dataMessage {
    if (response?.data is Map) {
      return (response?.data as Map)['message'] ?? '';
    }
    return '';
  }

  int get statusCode => response?.statusCode ?? 0;

  bool get isPostcardAlreadyStamped =>
      data == PostcardExceptionType.alreadyStamped.errorMessage;

  bool get isPostcardClaimEmptyLimited =>
      statusCode == PostcardExceptionType.tooManyRequest.statusCode;

  bool get isPostcardNotInMiami =>
      statusCode == PostcardExceptionType.notInMiami.statusCode &&
      dataMessage == PostcardExceptionType.notInMiami.errorMessage;
}

enum PostcardExceptionType {
  alreadyStamped,
  tooManyRequest,
  notInMiami;

  String get errorMessage {
    switch (this) {
      case PostcardExceptionType.alreadyStamped:
        return 'blockchain tx request is already existed';
      case PostcardExceptionType.notInMiami:
        return 'only allowed in Miami';
      default:
        return '';
    }
  }

  int get statusCode {
    switch (this) {
      case PostcardExceptionType.tooManyRequest:
        return 429;
      case PostcardExceptionType.notInMiami:
        return 403;
      default:
        return 0;
    }
  }
}
