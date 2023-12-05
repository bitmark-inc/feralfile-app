import 'package:autonomy_flutter/gateway/postcard_api.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nft_collection/services/indexer_service.dart';
import 'package:nft_collection/services/tokens_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gateway/postcard_api_mock.dart';
import 'postcard_service_test.mocks.dart';

@GenerateMocks([
  PostcardApi,
  TezosService,
  IndexerService,
  ConfigurationService,
  AccountService,
  TokensService,
  MetricClientService,
  ChatService,
])
void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'key': 'value',
    });
  });
  group('Postcard service test', () {
    late PostcardApi mockPostcardApi;
    late TezosService mockTezosService;
    late IndexerService mockIndexerService;
    late ConfigurationService mockConfigurationService;
    late AccountService mockAccountService;
    late TokensService mockTokensService;
    late MetricClientService mockMetricClientService;
    late ChatService mockChatService;
    late PostcardService postcardService;
    setUp(() {
      mockPostcardApi = MockPostcardApi();
      mockTezosService = MockTezosService();
      mockIndexerService = MockIndexerService();
      mockConfigurationService = MockConfigurationService();
      mockAccountService = MockAccountService();
      mockTokensService = MockTokensService();
      mockMetricClientService = MockMetricClientService();
      mockChatService = MockChatService();
      postcardService = PostcardServiceImpl(
          mockPostcardApi,
          mockTezosService,
          mockIndexerService,
          mockConfigurationService,
          mockAccountService,
          mockTokensService,
          mockMetricClientService,
          mockChatService);
      PostcardApiMock.setup(mockPostcardApi);
    });
    group('claimEmptyPostcard', () {
      test('Valid case', () {
        final expected = PostcardApiMock.claimValid.res;
        final actual =
            postcardService.claimEmptyPostcard(PostcardApiMock.claimValid.req);
        expect(actual, completion(expected));
        verify(mockPostcardApi.claim(PostcardApiMock.claimValid.req)).called(1);
      });
      test('400 case', () {
        final expected = PostcardApiMock.claimException4xx.res;
        final actual = postcardService
            .claimEmptyPostcard(PostcardApiMock.claimException4xx.req);
        expect(actual, throwsA(expected));
        verify(mockPostcardApi.claim(PostcardApiMock.claimException4xx.req))
            .called(1);
      });
      test('500 case', () {
        final expected = PostcardApiMock.claimException5xx.res;
        final actual = postcardService
            .claimEmptyPostcard(PostcardApiMock.claimException5xx.req);
        expect(actual, throwsA(expected));
        verify(mockPostcardApi.claim(PostcardApiMock.claimException5xx.req))
            .called(1);
      });
      test('Connection timeout case', () {
        final expected = PostcardApiMock.claimConnectionTimeout.res;
        final actual = postcardService
            .claimEmptyPostcard(PostcardApiMock.claimConnectionTimeout.req);
        expect(actual, throwsA(expected));
        verify(mockPostcardApi
                .claim(PostcardApiMock.claimConnectionTimeout.req))
            .called(1);
      });
      test('Receive timeout case', () {
        final expected = PostcardApiMock.claimReceiveTimeout.res;
        final actual = postcardService
            .claimEmptyPostcard(PostcardApiMock.claimReceiveTimeout.req);
        expect(actual, throwsA(expected));
        verify(mockPostcardApi.claim(PostcardApiMock.claimReceiveTimeout.req))
            .called(1);
      });
      test('Other Dio exception case', () {
        final expected = PostcardApiMock.claimDioExceptionOther.res;
        final actual = postcardService
            .claimEmptyPostcard(PostcardApiMock.claimDioExceptionOther.req);
        expect(actual, throwsA(expected));
        verify(mockPostcardApi
                .claim(PostcardApiMock.claimDioExceptionOther.req))
            .called(1);
      });
    });
  });
}
