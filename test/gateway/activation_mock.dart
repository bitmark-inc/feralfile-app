// ignore_for_file: discarded_futures

import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

import 'api_mock_data.dart';
import 'constants.dart';

class ActivationApiMock {
  ///// getActivation
  static final MockData getActivationValid = MockData(
      req: activationId,
      res: ActivationInfo(
        name,
        description,
        blockchain,
        contractAddress,
        tokenID,
      ));
  static final MockData getActivationDioException4xx = MockData(
      req: activationIdDioException4xx,
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 400,
              data: {'message': 'invalid id'})));
  static final MockData getActivationDioException5xx = MockData(
      req: activationIdDioException5xx,
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 500,
              data: {'message': 'internal server error'})));

  static final MockData getActivationConnectionTimeout = MockData(
      req: activationIdConnectionTimeout,
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.connectionTimeout,
          error: 'activationIdConnectionTimeout'));

  static final MockData getActivationReceiveTimeout = MockData(
      req: activationIdReceiveTimeout,
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.receiveTimeout,
          error: 'activationIdReceiveTimeout'));

  static final MockData getActivationExceptionOther = MockData(
      req: activationIdExceptionOther,
      res: Exception('activationIdExceptionOther'));

  ///// claim
  static final MockData claimValid = MockData(
      req: ActivationClaimRequest(
        activationID: activationId,
        address: address,
        airdropTOTPPasscode: airdropTOTPPasscode,
      ),
      res: ActivationClaimResponse());

  static final MockData claimDioException4xx = MockData(
      req: ActivationClaimRequest(
          activationID: activationIdDioException4xx,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 400,
              data: {'message': 'invalid claim'})));

  static final MockData claimDioException5xx = MockData(
      req: ActivationClaimRequest(
          activationID: activationIdDioException5xx,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          response: Response(
              requestOptions: RequestOptions(path: 'path'),
              statusCode: 500,
              data: {'message': 'internal server error'})));

  static final MockData claimConnectionTimeout = MockData(
      req: ActivationClaimRequest(
          activationID: activationIdConnectionTimeout,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.connectionTimeout,
          error: 'claimConnectionTimeout'));

  static final MockData claimReceiveTimeout = MockData(
      req: ActivationClaimRequest(
          activationID: activationIdReceiveTimeout,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      res: DioException(
          requestOptions: RequestOptions(path: 'path'),
          type: DioExceptionType.receiveTimeout,
          error: 'claimReceiveTimeout'));

  static final MockData claimDioExceptionOther = MockData(
      req: ActivationClaimRequest(
          activationID: activationIdExceptionOther,
          address: address,
          airdropTOTPPasscode: airdropTOTPPasscode),
      res: Exception('claimExceptionOther'));

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
  }
}
