import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([IAPApi, AccountService, ConfigurationService])
void main() async {
  late IAPApi authApi;
  late AccountService accountService;
  late ConfigurationService configService;
  late AuthService authService;
  const jwt =
      '''eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c''';

  group('auth service test', () {
    void setup() {
      authApi = MockIAPApi();
      accountService = MockAccountService();
      configService = MockConfigurationService();
      authService = AuthService(authApi, accountService, configService);

    }

    test('get auth token', () async {
      setup();

      final message = DateTime.now().millisecondsSinceEpoch.toString();
      when(accountService.getDefaultAccount())
          .thenAnswer((_) async => MockWalletStorage(const Uuid().v4()));
      when(configService.getIAPReceipt()).thenReturn(null);
      when(authApi.auth({
        'requester': 'account_did',
        'timestamp': message,
        'signature': 'signature',
      })).thenAnswer((_) async => JWT(jwtToken: jwt));

      final token = await authService.getAuthToken(messageToSign: message);

      expect(token.jwtToken, jwt);
    });

    test('get auth token with force update', () async {
      setup();

      final message = DateTime.now().millisecondsSinceEpoch.toString();
      when(accountService.getDefaultAccount())
          .thenAnswer((_) async => MockWalletStorage(const Uuid().v4()));
      when(configService.getIAPReceipt()).thenReturn(null);
      when(authApi.auth({
        'requester': 'account_did',
        'timestamp': message,
        'signature': 'signature',
      })).thenAnswer((_) async => JWT(jwtToken: jwt));

      final token1 = await authService.getAuthToken(messageToSign: message);
      final token2 = await authService.getAuthToken(
          messageToSign: message, forceRefresh: true);

      verify(accountService.getDefaultAccount()).called(2);
      verify(configService.getIAPReceipt()).called(2);
      verify(authApi.auth({
        'requester': 'account_did',
        'timestamp': message,
        'signature': 'signature',
      })).called(2);

      expect(token1.jwtToken, jwt);
      expect(token2.jwtToken, jwt);
    });
  });
}

class MockWalletStorage extends WalletStorage {
  MockWalletStorage(super.uuid);

  @override
  Future<String> getAccountDID() async => 'account_did';

  @override
  Future<String> getAccountDIDSignature(String message) async => 'signature';
}
