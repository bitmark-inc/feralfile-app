//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
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

  AuthService(
    this._authApi,
    this._accountService,
    this._configurationService,
  );

  void reset() {
    _jwt = null;
  }

  Future<JWT> getAuthToken(
      {String? messageToSign,
      String? receiptData,
      bool forceRefresh = false}) async {
    if (!forceRefresh && _jwt != null && _jwt!.isValid()) {
      return _jwt!;
    }

    final account = await _accountService.getDefaultAccount();

    final message =
        messageToSign ?? DateTime.now().millisecondsSinceEpoch.toString();
    final accountDID = await account.getAccountDID();
    final signature = await account.getAccountDIDSignature(message);

    Map<String, dynamic> payload = {
      'requester': accountDID,
      'timestamp': message,
      'signature': signature,
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
      final String platform;
      if (Platform.isIOS) {
        platform = 'apple';
      } else {
        platform = 'google';
      }
      payload.addAll({
        'receipt': {'platform': platform, 'receipt_data': savedReceiptData}
      });
    }

    var newJwt = await _authApi.auth(payload);

    _jwt = newJwt;

    if (newJwt.isValid(withSubscription: true)) {
      unawaited(_configurationService.setIAPReceipt(savedReceiptData));
      unawaited(_configurationService.setIAPJWT(newJwt));
    } else {
      unawaited(_configurationService.setIAPReceipt(null));
      unawaited(_configurationService.setIAPJWT(null));
    }

    return newJwt;
  }
}
