import 'package:autonomy_flutter/util/constants.dart';
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

  bool get isAlreadyClaimedPostcard =>
      dataMessage == PostcardExceptionType.alreadyClaimed.errorMessage &&
      statusCode == PostcardExceptionType.alreadyClaimed.statusCode;

  bool get isFailToClaimPostcard =>
      dataMessage == PostcardExceptionType.failToClaimPostcard.errorMessage &&
      statusCode == PostcardExceptionType.failToClaimPostcard.statusCode;
}

enum PostcardExceptionType {
  alreadyStamped,
  tooManyRequest,
  notInMiami,
  alreadyClaimed,
  failToClaimPostcard;

  String get errorMessage {
    switch (this) {
      case PostcardExceptionType.alreadyStamped:
        return 'blockchain tx request is already existed';
      case PostcardExceptionType.notInMiami:
        return 'only allowed in Miami';
      case PostcardExceptionType.alreadyClaimed:
        return 'fail to claim a postcard';
      case PostcardExceptionType.failToClaimPostcard:
        return 'fail to claim a postcard';
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
      case PostcardExceptionType.alreadyClaimed:
        return StatusCode.forbidden.value;
      case PostcardExceptionType.failToClaimPostcard:
        return StatusCode.badRequest.value;
      default:
        return 0;
    }
  }
}
