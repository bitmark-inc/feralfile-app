import 'dart:io';

import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

class AuthService {
  final IAPApi _authApi;
  final AccountService _accountService;
  final ConfigurationService _configurationService;
  JWT? _jwt;

  AuthService(this._authApi, this._accountService, this._configurationService);

  Future<JWT> getAuthToken(
      {String? receiptData, bool forceRefresh = true}) async {
    if (!forceRefresh && _jwt != null && _jwt!.isValid()) {
      return _jwt!;
    }

    final account = await this._accountService.getDefaultAccount();

    final message = DateTime.now().millisecondsSinceEpoch.toString();
    final accountDID = await account.getAccountDID();
    final signature = await account.getAccountDIDSignature(message);

    Map<String, dynamic> payload = {
      "requester": accountDID,
      "timestamp": message,
      "signature": signature,
    };

    // the receipt data can be set by passing the parameter,
    // or query through the configuration service
    late String? savedReceiptData;
    if (receiptData != null) {
      savedReceiptData = receiptData;
    } else {
      savedReceiptData = _configurationService.getIAPReceipt();
    }

    // add the receipt data if available
    if (savedReceiptData != null) {
      final platform;
      if (Platform.isIOS) {
        platform = 'apple';
      } else {
        platform = 'google';
      }
      payload.addAll({
        "receipt": {'platform': platform, 'receipt_data': savedReceiptData}
      });
    }

    var newJwt = await _authApi.auth(payload);

    _jwt = newJwt;

    // Save the receipt data if the jwt is valid
    if (savedReceiptData != null) {
      if (newJwt.isValid(withSubscription: true)) {
        _configurationService.setIAPReceipt(receiptData);
      } else {
        _configurationService.setIAPReceipt(null);
        _configurationService.setIAPJWT(null);
      }
    }

    return newJwt;
  }
}
