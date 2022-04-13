import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/account_service.dart';

class AuthService {
  final IAPApi _authApi;
  final AccountService _accountService;
  JWT? _jwt;

  AuthService(this._authApi, this._accountService);

  Future<String> getAuthToken() async {
    if (_jwt != null && _jwt!.isValid()) {
      return _jwt!.jwtToken;
    }

    final account = await this._accountService.getDefaultAccount();

    final message = DateTime.now().millisecondsSinceEpoch.toString();
    final accountDID = await account.getAccountDID();
    final signature = await account.getAccountDIDSignature(message);

    final newJwt = await _authApi.auth({
      "requester": accountDID,
      "timestamp": message,
      "signature": signature,
    });

    _jwt = newJwt;

    return newJwt.jwtToken;
  }
}
