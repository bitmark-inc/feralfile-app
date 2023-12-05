import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:autonomy_flutter/service/activation_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nft_collection/services/tokens_service.dart';

import '../gateway/activation_mock.dart';
import '../gateway/token_service_mock_data.dart';
import 'activation_service_test.mocks.dart';

@GenerateMocks([ActivationApi, TokensService, NavigationService])
void main() async {
  group('ActivationService tests', () {
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

    test('claimActivation: case valid', () async {
      expect(
          await activationService.claimActivation(
              request: ActivationApiMock.claimValid.req,
              assetToken: TokenServiceMockData.anyAssetToken),
          ActivationApiMock.claimValid.res);

      verify(mockActivationApi.claim(ActivationApiMock.claimValid.req))
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

    // Add more test cases for other methods if needed

    tearDown(() {
      // Verify that methods on dependencies were called as expected
      //verifyNoMoreInteractions(mockActivationApi);
      //verifyNoMoreInteractions(mockTokensService);
      //verifyNoMoreInteractions(mockNavigationService);
    });
  });
}
