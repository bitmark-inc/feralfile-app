import 'package:autonomy_flutter/gateway/activation_api.dart';
import 'package:autonomy_flutter/service/activation_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nft_collection/services/tokens_service.dart';

import '../gateway/activation_mock.dart';
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

      // Add more assertions based on your actual data

      // Verify that the getActivation method on ActivationApi was called
      verify(mockActivationApi.getActivation(
              ActivationApiMock.getActivationDioException4xx.req))
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
}
