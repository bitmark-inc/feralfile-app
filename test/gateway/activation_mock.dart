// ignore_for_file: discarded_futures

import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'api_mock_data.dart';
import 'constants.dart';

class ActivationApiMock {
  ///// getActivation
  static final MockData getActivationValid = MockData(
      activationId,
      ActivationInfo(
        name,
        description,
        blockchain,
        contractAddress,
        tokenID,
      ));
  static final MockData getActivationDioException4xx = MockData(
      activationIdDioException4xx,
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 400,
              data: {'message': 'invalid id'})));
  static final MockData getActivationDioException5xx = MockData(
      activationIdDioException5xx,
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 500,
              data: {'message': 'internal server error'})));

  static final MockData getActivationConnectionTimeout = MockData(
      activationIdConnectionTimeout,
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.connectionTimeout,
          error: 'activationIdConnectionTimeout'));

  static final MockData getActivationReceiveTimeout = MockData(
      activationIdReceiveTimeout,
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.receiveTimeout,
          error: 'activationIdReceiveTimeout'));

  static final MockData getActivationExceptionOther = MockData(
      activationIdExceptionOther, Exception('activationIdExceptionOther'));

  ///// claim
  static final MockData claimValid = MockData(
      ActivationClaimRequest(
        activationID: activationId,
        address: address,
        airdropTOTPPasscode: airdropTOTPPasscode,
      ),
      ActivationClaimResponse());

  static final MockData claimDioException4xx = MockData(
      ActivationClaimRequest(
          activationID: activationIdDioException4xx,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 400,
              data: {'message': 'invalid claim'})));

  static final MockData claimDioException5xx = MockData(
      ActivationClaimRequest(
          activationID: activationIdDioException5xx,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 500,
              data: {'message': 'internal server error'})));

  static final MockData claimConnectionTimeout = MockData(
      ActivationClaimRequest(
          activationID: activationIdConnectionTimeout,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.connectionTimeout,
          error: 'claimConnectionTimeout'));

  static final MockData claimReceiveTimeout = MockData(
      ActivationClaimRequest(
          activationID: activationIdReceiveTimeout,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.receiveTimeout,
          error: 'claimReceiveTimeout'));

  static final MockData claimDioExceptionOther = MockData(
      ActivationClaimRequest(
          activationID: activationIdExceptionOther,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      Exception('claimExceptionOther'));

  static final MockData claimSelfClaim = MockData(
      ActivationClaimRequest(
          activationID: cannotSelfClaim,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 403,
              data: {'message': cannotSelfClaim})));

  static final MockData claimInvalidClaim = MockData(
      ActivationClaimRequest(
          activationID: invalidClaim,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 403,
              data: {'message': invalidClaim})));

  static final MockData claimAlreadyShare = MockData(
      ActivationClaimRequest(
          activationID: alreadyShare,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 403,
              data: {'message': alreadyShare})));

  static void setup(ActivationApi mockActivationApi) {
    when(mockActivationApi
            .getActivation(ActivationApiMock.getActivationValid.req))
        .thenAnswer((_) async =>
            ActivationApiMock.getActivationValid.res as ActivationInfo);

    when(mockActivationApi
            .getActivation(ActivationApiMock.getActivationDioException4xx.req))
        .thenThrow(
            ActivationApiMock.getActivationDioException4xx.res as DioException);

    when(mockActivationApi
            .getActivation(ActivationApiMock.getActivationDioException5xx.req))
        .thenThrow(
            ActivationApiMock.getActivationDioException5xx.res as DioException);

    when(mockActivationApi.getActivation(
            ActivationApiMock.getActivationConnectionTimeout.req))
        .thenThrow(ActivationApiMock.getActivationConnectionTimeout.res
            as DioException);

    when(mockActivationApi
            .getActivation(ActivationApiMock.getActivationReceiveTimeout.req))
        .thenThrow(
            ActivationApiMock.getActivationReceiveTimeout.res as DioException);

    when(mockActivationApi
            .getActivation(ActivationApiMock.getActivationExceptionOther.req))
        .thenThrow(
            ActivationApiMock.getActivationExceptionOther.res as Exception);

    when(mockActivationApi.claim(ActivationApiMock.claimValid.req)).thenAnswer(
        (_) async =>
            ActivationApiMock.claimValid.res as ActivationClaimResponse);

    when(mockActivationApi.claim(ActivationApiMock.claimDioException4xx.req))
        .thenThrow(ActivationApiMock.claimDioException4xx.res as DioException);

    when(mockActivationApi.claim(ActivationApiMock.claimDioException5xx.req))
        .thenThrow(ActivationApiMock.claimDioException5xx.res as DioException);

    when(mockActivationApi.claim(ActivationApiMock.claimConnectionTimeout.req))
        .thenThrow(
            ActivationApiMock.claimConnectionTimeout.res as DioException);

    when(mockActivationApi.claim(ActivationApiMock.claimReceiveTimeout.req))
        .thenThrow(ActivationApiMock.claimReceiveTimeout.res as DioException);

    when(mockActivationApi.claim(ActivationApiMock.claimDioExceptionOther.req))
        .thenThrow(ActivationApiMock.claimDioExceptionOther.res as Exception);

    when(mockActivationApi.claim(ActivationApiMock.claimSelfClaim.req))
        .thenAnswer((_) async =>
            throw ActivationApiMock.claimSelfClaim.res as DioException);

    when(mockActivationApi.claim(ActivationApiMock.claimInvalidClaim.req))
        .thenAnswer((_) async =>
            throw ActivationApiMock.claimInvalidClaim.res as DioException);

    when(mockActivationApi.claim(ActivationApiMock.claimAlreadyShare.req))
        .thenAnswer((_) async =>
            throw ActivationApiMock.claimAlreadyShare.res as DioException);
  }
}
