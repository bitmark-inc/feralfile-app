//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/gateway/iap_api.dart';
import 'package:autonomy_flutter/model/account_v2_request.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:libauk_dart/libauk_dart.dart';

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

  Future<void> addIdentity(WalletAddress walletAddress) async {
    final address = walletAddress.address;
    try {
      final wallet = LibAukDart.getWallet(walletAddress.uuid);
      final isTezos = walletAddress.cryptoType == CryptoType.XTZ.source;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final message = getFeralFileAccountMessage(address, timestamp);
      final messageBytes = Uint8List.fromList(utf8.encode(message));
      final signature = isTezos
          ? await injector<TezosService>()
              .signMessage(wallet, walletAddress.index, messageBytes)
          : await injector<EthereumService>()
              .signPersonalMessage(wallet, walletAddress.index, messageBytes);
      final tezosPublicKey = isTezos
          ? await wallet.getTezosPublicKey(index: walletAddress.index)
          : null;
      await _authApi.addIdentity(AccountV2Request(
        type: isTezos ? 'tezos' : 'ethereum',
        requester: walletAddress.address,
        publicKey: tezosPublicKey,
        timestamp: timestamp,
        signature: signature,
      ));
      log.info('[AuthService] Added identity for address $address');
    } catch (e) {
      log.info('[AuthService] Error adding identity for address $address: $e');
    }
  }

  Future<void> removeIdentity(String address) async {
    try {
      await _authApi.deleteIdentity(address);
      log.info('[AuthService] Removed identity for address $address');
    } catch (e) {
      log.info(
          '[AuthService] Error removing identity for address $address: $e');
    }
  }

  Future<void> createAccount(WalletStorage walletStorage) async {
    final accountDID = await walletStorage.getAccountDID();
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final message = getFeralFileAccountMessage(accountDID, timestamp);
      final signature = await walletStorage.getAccountDIDSignature(message);
      await _authApi.createAccount(AccountV2Request(
        type: 'did',
        requester: accountDID,
        timestamp: timestamp,
        signature: signature,
      ));
      log.info('[AuthService] Created account for did $accountDID');
    } catch (e) {
      log.info('[AuthService] Error creating account for DID $accountDID: $e');
    }
  }
}
