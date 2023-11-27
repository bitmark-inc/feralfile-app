import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:dio/dio.dart';

import 'api_mock_data.dart';

class ActivationApiMock {
  ///// getActivation
  static final MockData getActivationValid = MockData(
      'activationIdValid',
      ActivationInfo(
          'name', 'description', 'blockchain', 'contractAddress', 'tokenID'));
  static final MockData getActivationDioException4xx = MockData(
      'activationIdDioException4xx',
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 400,
              data: {'message': 'invalid id'})));
  static final MockData getActivationDioException5xx = MockData(
      'activationIdDioException5xx',
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 500,
              data: {'message': 'internal server error'})));

  static final MockData getActivationConnectionTimeout = MockData(
      'activationIdConnectionTimeout',
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.connectionTimeout,
          error: 'activationIdConnectionTimeout'));

  static final MockData getActivationReceiveTimeout = MockData(
      'activationIdReceiveTimeout',
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.receiveTimeout,
          error: 'activationIdReceiveTimeout'));

  static final MockData getActivationExceptionOther = MockData(
      'activationIdDioExceptionOther',
      Exception('activationIdExceptionOther'));

  ///// claim
  static final MockData claimValid = MockData(
      ActivationClaimRequest(
          activationID: 'activationIdValid',
          address: 'addressValid',
          airdropTOTPPasscode: 'airdropTOTPPasscodeValid'),
      ActivationClaimResponse());

  static final MockData claimDioException4xx = MockData(
      ActivationClaimRequest(
          activationID: 'activationIdDioException4xx',
          address: 'address4xx',
          airdropTOTPPasscode: 'airdropTOTPPasscode4xx'),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 400,
              data: {'message': 'invalid claim'})));

  static final MockData claimDioException5xx = MockData(
      ActivationClaimRequest(
          activationID: 'activationIdDioException5xx',
          address: 'address5xx',
          airdropTOTPPasscode: 'airdropTOTPPasscode5xx'),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 500,
              data: {'message': 'internal server error'})));

  static final MockData claimConnectionTimeout = MockData(
      ActivationClaimRequest(
          activationID: 'activationIdConnectionTimeout',
          address: 'addressConnectionTimeout',
          airdropTOTPPasscode: 'airdropTOTPPasscodeConnectionTimeout'),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.connectionTimeout,
          error: 'claimConnectionTimeout'));

  static final MockData claimReceiveTimeout = MockData(
      ActivationClaimRequest(
          activationID: 'activationIdReceiveTimeout',
          address: 'addressReceiveTimeout',
          airdropTOTPPasscode: 'airdropTOTPPasscodeReceiveTimeout'),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.receiveTimeout,
          error: 'claimReceiveTimeout'));

  static final MockData claimDioExceptionOther = MockData(
      ActivationClaimRequest(
          activationID: 'activationIdDioExceptionOther',
          address: 'addressDioExceptionOther',
          airdropTOTPPasscode: 'airdropTOTPPasscodeDioExceptionOther'),
      Exception('claimExceptionOther'));

}
