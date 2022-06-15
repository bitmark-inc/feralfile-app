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
main() async {
  final authApi = MockIAPApi();
  final accountService = MockAccountService();
  final configService = MockConfigurationService();
  final authService = AuthService(authApi, accountService, configService);

  group('auth service test', () {
    test('get auth token', () async {
      final message = DateTime.now().millisecondsSinceEpoch.toString();
      when(accountService.getDefaultAccount())
          .thenAnswer((_) async => MockWalletStorage(Uuid().v4().toString()));
      when(configService.getIAPReceipt()).thenReturn(null);
      when(authApi.auth({
        "requester": "account_did",
        "timestamp": message,
        "signature": "signature",
      })).thenAnswer((_) async => JWT(jwtToken: "jwtToken"));

      final token = await authService.getAuthToken(messageToSign: message);

      expect(token.jwtToken, "jwtToken");
    });
  });
}

class MockWalletStorage extends WalletStorage {
  MockWalletStorage(String uuid) : super(uuid);

  @override
  Future<String> getAccountDID() async {
    return "account_did";
  }

  @override
  Future<String> getAccountDIDSignature(String message) async {
    return "signature";
  }
}