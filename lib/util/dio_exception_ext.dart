import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:dio/dio.dart';

extension DioExceptionExt on DioException {
  String get data => response?.data ?? '';

  String get dataMessage {
    if (response?.data is Map) {
      return (response?.data as Map)['message'] ?? '';
    }
    return '';
  }

  int get statusCode => response?.statusCode ?? 0;

  int? get ffErrorCode => response?.data['error']['code'] as int?;

  // DioExceptionExt for MoMA Postcard
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

  // DioExceptionExt for Airdrop

  bool get isClaimPassLimit =>
      statusCode == AirdropExceptionType.claimPassLimit.statusCode &&
      dataMessage == AirdropExceptionType.claimPassLimit.errorMessage;

  bool get isBranchError => requestOptions.baseUrl.contains('branch.io');

  FeralfileError get branchError =>
      FeralfileError(StatusCode.badRequest.value, 'Branch.io error');

  bool get isAlreadySetReferralCode {
    if (response?.data is Map) {
      return response!.statusCode == 400 &&
          (response!.data as Map)['error']?['code'] == 3002;
    }
    return false;
  }
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

enum AirdropExceptionType {
  claimPassLimit;

  String get errorMessage {
    switch (this) {
      case AirdropExceptionType.claimPassLimit:
        return 'exceeds claim pass limit';
      default:
        return '';
    }
  }

  int get statusCode {
    switch (this) {
      case AirdropExceptionType.claimPassLimit:
        return 500;
      default:
        return 0;
    }
  }
}
