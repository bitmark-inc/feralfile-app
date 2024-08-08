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
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:autonomy_flutter/util/primary_address_channel.dart';
import 'package:libauk_dart/libauk_dart.dart';

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

  Future<JWT?> getAuthToken(
      {String? messageToSign,
      String? receiptData,
      bool forceRefresh = false,
      bool shouldGetDidKeyInstead = false}) async {
    if (!forceRefresh && _jwt != null && _jwt!.isValid()) {
      return _jwt!;
    }
    final primaryAddressAuthToken =
        await _getPrimaryAddressAuthToken(receiptData: receiptData);
    final newJwt = primaryAddressAuthToken ??
        (shouldGetDidKeyInstead ? await getDidKeyAuthToken() : null);
    return newJwt;
  }

  Future<JWT> _getAuthTokenByAccount(WalletStorage account) async {
    final didKey = await account.getAccountDID();
    final message = DateTime.now().millisecondsSinceEpoch.toString();
    _addressService.getFeralfileAccountMessage(
      address: didKey,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    final signature = await account.getAccountDIDSignature(message);

    Map<String, dynamic> payload = {
      'requester': didKey,
      'timestamp': message,
      'signature': signature,
    };
    try {
      var newJwt = await _authApi.auth(payload);
      return newJwt;
    } catch (e) {
      rethrow;
    }
  }

  Future<JWT> getDidKeyAuthToken() async {
    final defaultAccount = await injector<AccountService>().getDefaultAccount();
    return _getAuthTokenByAccount(defaultAccount);
  }

  Future<void> registerPrimaryAddress(
      {required AddressInfo primaryAddressInfo,
      bool withDidKey = false}) async {
    final address = await _addressService.getAddress(info: primaryAddressInfo);
    final publicKey = await _addressService.getAddressPublicKey(
        addressInfo: primaryAddressInfo);
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final defaultAccount = await injector<AccountService>().getDefaultAccount();
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
      final didKey = await defaultAccount.getAccountDID();
      final messageForDidKey = _addressService.getFeralfileAccountMessage(
        address: didKey,
        timestamp: timestamp,
      );
      unawaited(OneSignalHelper.setExternalUserId(userId: didKey));
      final signatureForDidKey =
          await defaultAccount.getAccountDIDSignature(messageForDidKey);
      payload['did'] = didKey;
      payload['didSignature'] = signatureForDidKey;
    }
    await _authApi.registerPrimaryAddress(payload);
  }
}
