import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:autonomy_flutter/service/activation_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:nft_collection/services/tokens_service.dart';

import '../gateway/activation_mock.dart';
import '../gateway/constants.dart';
import '../gateway/token_service_mock_data.dart';
import '../generate_mock/gateway/mock_activation_api.mocks.dart';
import '../generate_mock/service/mock_navigation_service.mocks.dart';
import '../generate_mock/service/mock_tokens_service.mocks.dart';

void main() async {
  late ActivationApi mockActivationApi;
  late TokensService mockTokensService;
  late NavigationService mockNavigationService;
  late ActivationService activationService;

  setUp(() {
    mockActivationApi = MockActivationApi();
    mockTokensService = MockTokensService();
    mockNavigationService = MockNavigationService();
    activationService = ActivationService(
        mockActivationApi, mockTokensService, mockNavigationService);

    ActivationApiMock.setup(mockActivationApi);
    TokenServiceMockData.setUp(mockTokensService as MockTokensService);
  });
  group('getActivation tests', () {
    test('getActivation case valid', () async {
      expect(
          await activationService.getActivation(
              activationID: ActivationApiMock.getActivationValid.req),
          ActivationApiMock.getActivationValid.res);

      verify(mockActivationApi
              .getActivation(ActivationApiMock.getActivationValid.req))
          .called(1);
    });

    test('getActivation case 400', () async {
      final error = activationService.getActivation(
          activationID: ActivationApiMock.getActivationDioException4xx.req);
      expect(
          error, throwsA(ActivationApiMock.getActivationDioException4xx.res));
      verify(mockActivationApi.getActivation(
              ActivationApiMock.getActivationDioException4xx.req))
          .called(1);
    });

    test('getActivation case 500', () async {
      final error = activationService.getActivation(
          activationID: ActivationApiMock.getActivationDioException5xx.req);
      expect(
          error, throwsA(ActivationApiMock.getActivationDioException5xx.res));
      verify(mockActivationApi.getActivation(
              ActivationApiMock.getActivationDioException5xx.req))
          .called(1);
    });

    test('getActivation case connectionTimeout', () async {
      final error = activationService.getActivation(
          activationID: ActivationApiMock.getActivationConnectionTimeout.req);
      expect(
          error, throwsA(ActivationApiMock.getActivationConnectionTimeout.res));
      verify(mockActivationApi.getActivation(
              ActivationApiMock.getActivationConnectionTimeout.req))
          .called(1);
    });

    test('getActivation case receiveTimeout', () async {
      final error = activationService.getActivation(
          activationID: ActivationApiMock.getActivationReceiveTimeout.req);
      expect(error, throwsA(ActivationApiMock.getActivationReceiveTimeout.res));
      verify(mockActivationApi
              .getActivation(ActivationApiMock.getActivationReceiveTimeout.req))
          .called(1);
    });

    test('getActivation case exceptionOther', () async {
      final error = activationService.getActivation(
          activationID: ActivationApiMock.getActivationExceptionOther.req);
      expect(error, throwsA(ActivationApiMock.getActivationExceptionOther.res));
      verify(mockActivationApi
              .getActivation(ActivationApiMock.getActivationExceptionOther.req))
          .called(1);
    });

    // Add more test cases for other methods if needed

    tearDown(() {
      // Verify that methods on dependencies were called as expected
      //verifyNoMoreInteractions(mockActivationApi);
      //verifyNoMoreInteractions(mockTokensService);
      //verifyNoMoreInteractions(mockNavigationService);
    });
  });

  group('claimActivation test', () {
    test('claimActivation: case valid', () async {
      expect(
          await activationService.claimActivation(
              request: ActivationApiMock.claimValid.req,
              assetToken: TokenServiceMockData.anyAssetToken),
          ActivationApiMock.claimValid.res);

      verify(mockActivationApi.claim(ActivationApiMock.claimValid.req))
          .called(1);
    });

    test('claimActivation: case 400', () async {
      final error = activationService.claimActivation(
          request: ActivationApiMock.claimDioException4xx.req,
          assetToken: TokenServiceMockData.anyAssetToken);
      expect(error, throwsA(ActivationApiMock.claimDioException4xx.res));
      verify(mockActivationApi
              .claim(ActivationApiMock.claimDioException4xx.req))
          .called(1);
    });

    test('claimActivation: case 500', () async {
      final error = activationService
          .claimActivation(
              request: ActivationApiMock.claimDioException5xx.req,
              assetToken: TokenServiceMockData.anyAssetToken)
          .then((value) {
        verify(mockNavigationService.showActivationError(
                value, TokenServiceMockData.anyAssetToken.id))
            .called(1);
      });
      expect(error, throwsA(ActivationApiMock.claimDioException5xx.res));
      verify(mockActivationApi
              .claim(ActivationApiMock.claimDioException5xx.req))
          .called(1);
    });

    test('claimActivation: case connectionTimeout', () async {
      final error = activationService
          .claimActivation(
              request: ActivationApiMock.claimConnectionTimeout.req,
              assetToken: TokenServiceMockData.anyAssetToken)
          .then((value) {
        verify(mockNavigationService.showActivationError(
                value, TokenServiceMockData.anyAssetToken.id))
            .called(1);
      });
      expect(error, throwsA(ActivationApiMock.claimConnectionTimeout.res));
      verify(mockActivationApi
              .claim(ActivationApiMock.claimConnectionTimeout.req))
          .called(1);
    });

    test('claimActivation: case receiveTimeout', () async {
      final error = activationService
          .claimActivation(
              request: ActivationApiMock.claimReceiveTimeout.req,
              assetToken: TokenServiceMockData.anyAssetToken)
          .then((value) {
        verify(mockNavigationService.showActivationError(
                value, TokenServiceMockData.anyAssetToken.id))
            .called(1);
      });
      expect(error, throwsA(ActivationApiMock.claimReceiveTimeout.res));
      verify(mockActivationApi.claim(ActivationApiMock.claimReceiveTimeout.req))
          .called(1);
    });

    test('claimActivation: case exceptionOther', () async {
      final error = activationService
          .claimActivation(
              request: ActivationApiMock.claimDioExceptionOther.req,
              assetToken: TokenServiceMockData.anyAssetToken)
          .then((value) {
        verify(mockNavigationService.showActivationError(
                value, TokenServiceMockData.anyAssetToken.id))
            .called(0);
      });
      expect(error, throwsA(ActivationApiMock.claimDioExceptionOther.res));
      verify(mockActivationApi
              .claim(ActivationApiMock.claimDioExceptionOther.req))
          .called(1);
    });

    test('claimActivation: error self claim', () async {
      final error = activationService
          .claimActivation(
              request: ActivationApiMock.claimSelfClaim.req,
              assetToken: TokenServiceMockData.anyAssetToken)
          .then((value) {
        verify(mockNavigationService.showAirdropJustOnce()).called(1);
      });

      expect(error, throwsA(ActivationApiMock.claimSelfClaim.res));
    });

    test('claimActivation: error invalid claim', () async {
      final error = activationService
          .claimActivation(
              request: ActivationApiMock.claimInvalidClaim.req,
              assetToken: TokenServiceMockData.anyAssetToken)
          .then((value) {
        verify(mockNavigationService.showAirdropAlreadyClaimed()).called(1);
      });

      expect(error, throwsA(ActivationApiMock.claimInvalidClaim.res));
    });

    test('claimActivation: error already share', () async {
      final error = activationService
          .claimActivation(
              request: ActivationApiMock.claimAlreadyShare.req,
              assetToken: TokenServiceMockData.anyAssetToken)
          .then((value) {
        verify(mockNavigationService.showAirdropAlreadyClaimed()).called(1);
      });

      expect(error, throwsA(ActivationApiMock.claimAlreadyShare.res));
    });

    tearDown(() {
      // Verify that methods on dependencies were called as expected
      //verifyNoMoreInteractions(mockActivationApi);
      //verifyNoMoreInteractions(mockTokensService);
      //verifyNoMoreInteractions(mockNavigationService);
    });
  });

  group('getIndexerId', () {
    test('case ethereum', () {
      final indexerID =
          activationService.getIndexerID(ethChain, contractAddress, tokenID);
      expect(indexerID, ethIndexerID);
    });

    test('case tezos', () {
      final indexerID =
          activationService.getIndexerID(tezChain, contractAddress, tokenID);
      expect(indexerID, tezosIndexerID);
    });
  });
}
