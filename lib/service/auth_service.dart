//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/jwt.dart'; // import 'package:autonomy_flutter/screen/bloc/scan_wallet/scan_wallet_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/address_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:autonomy_flutter/util/primary_address_channel.dart';

class AuthService {
  final IAPApi _authApi;
  final AddressService _addressService;
  final ConfigurationService _configurationService;
  JWT? _jwt;

  AuthService(
    this._authApi,
    this._addressService,
    this._configurationService,
  );

  void reset() {
    _jwt = null;
  }

  Future<JWT?> _getPrimaryAddressAuthToken({String? receiptData}) async {
    final primaryAddressInfo = await _addressService.getPrimaryAddressInfo();
    if (primaryAddressInfo == null) {
      return null;
    }
    final address = await _addressService.getPrimaryAddress();
    final timeStamp = DateTime.now().millisecondsSinceEpoch.toString();

    final message = _addressService.getFeralfileAccountMessage(
      address: address!,
      timestamp: timeStamp,
    );

    final signature =
        await _addressService.getPrimaryAddressSignature(message: message);
    final publicKey = await _addressService.getPrimaryAddressPublicKey();

    Map<String, dynamic> payload = {
      'requester': address,
      'type': primaryAddressInfo.chain,
      'publicKey': publicKey,
      'timestamp': timeStamp,
      'signature': signature,
    };

    if (receiptData != null) {
      // add the receipt data if available
      final String platform;
      if (Platform.isIOS) {
        platform = 'apple';
      } else {
        platform = 'google';
      }
      payload.addAll({
        'receipt': {'platform': platform, 'receipt_data': receiptData}
      });
    }

    var newJwt = await _authApi.authAddress(payload);
    _jwt = newJwt;

    if (newJwt.isValid(withSubscription: true)) {
      unawaited(_configurationService
          .setIAPReceipt(receiptData ?? _configurationService.getIAPReceipt()));
      unawaited(_configurationService.setIAPJWT(newJwt));
    } else {
      unawaited(_configurationService.setIAPReceipt(null));
      unawaited(_configurationService.setIAPJWT(null));
    }
    return newJwt;
  }

  Future<JWT?> getAuthToken({
    String? messageToSign,
    String? receiptData,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _jwt != null && _jwt!.isValid()) {
      return _jwt!;
    }
    final primaryAddressAuthToken =
        await _getPrimaryAddressAuthToken(receiptData: receiptData);
    return primaryAddressAuthToken;
  }

  Future<void> registerPrimaryAddress(
      {required AddressInfo primaryAddressInfo,
      bool withDidKey = false}) async {
    final address = await _addressService.getAddress(info: primaryAddressInfo);
    final publicKey = await _addressService.getAddressPublicKey(
        addressInfo: primaryAddressInfo);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final messageForAddress = _addressService.getFeralfileAccountMessage(
      address: address,
      timestamp: timestamp,
    );
    final signatureForAddress = await _addressService.getAddressSignature(
      addressInfo: primaryAddressInfo,
      message: messageForAddress,
    );

    Map<String, dynamic> payload = {
      'requester': address,
      'type': primaryAddressInfo.chain,
      'publicKey': publicKey,
      'signature': signatureForAddress,
      'timestamp': timestamp,
    };
    if (withDidKey) {
      final defaultAccount =
          await injector<AccountService>().getDefaultAccount();
      final didKey = await defaultAccount.getAccountDID();
      final messageForDidKey = _addressService.getFeralfileAccountMessage(
        address: didKey,
        timestamp: timestamp,
      );
      log.info('setting external user by did: $didKey');
      unawaited(OneSignalHelper.setExternalUserId(userId: didKey));
      final signatureForDidKey =
          await defaultAccount.getAccountDIDSignature(messageForDidKey);
      payload['did'] = didKey;
      payload['didSignature'] = signatureForDidKey;
    }
    await _authApi.registerPrimaryAddress(payload);
  }

  Future<bool> redeemGiftCode(String giftCode) async {
    final response = await _authApi.redeemGiftCode(giftCode);
    return response.ok == 1;
  }

  Future<void> registerReferralCode({required String referralCode}) async {
    final body = {'code': referralCode};
    await _authApi.registerReferralCode(body);
  }
}
