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
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:dio/dio.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:synchronized/synchronized.dart';

class AuthService {
  final IAPApi _authApi;
  final AccountService _accountService;
  final ConfigurationService _configurationService;
  JWT? _jwt;
  static const int _accountNotCreatedErrorCode = 998;
  final _authLock = Lock();

  AuthService(
    this._authApi,
    this._accountService,
    this._configurationService,
  );

  void reset() {
    _jwt = null;
  }

  Future<JWT> getAuthToken(
          {String? receiptData,
          bool forceRefresh = false,
          bool retry = true}) async =>
      await _authLock.synchronized(() async => await _getAuthToken(
          receiptData: receiptData, forceRefresh: forceRefresh, retry: retry));

  Future<JWT> _getAuthToken(
      {String? receiptData,
      bool forceRefresh = false,
      bool retry = true}) async {
    if (!forceRefresh && _jwt != null && _jwt!.isValid()) {
      return _jwt!;
    }

    final account = await _accountService.getDefaultAccount();

    // the receipt data can be set by passing the parameter,
    // or query through the configuration service
    late String? savedReceiptData;
    if (receiptData != null) {
      savedReceiptData = receiptData;
    } else {
      savedReceiptData = _configurationService.getIAPReceipt();
    }

    // add the receipt data if available
    dynamic receipt;
    if (savedReceiptData != null) {
      final String platform;
      if (Platform.isIOS) {
        platform = 'apple';
      } else {
        platform = 'google';
      }
      receipt = {'platform': platform, 'receipt_data': savedReceiptData};
    }

    final request = await _getDIDRequest(account, receipt: receipt);
    late JWT newJwt;
    try {
      newJwt = await _authApi.authV2(request);
    } on DioException catch (authError) {
      log.info('[AuthService] Failed to get jwt $authError');
      final code = authError.response?.data['error']['code'] ?? 0;
      if (retry && code == _accountNotCreatedErrorCode) {
        log.info('[AuthService] Retry, creating account');
        try {
          await createAccount(account);
        } catch (createAccountError) {
          log.info(
              '[AuthService] Failed to create account $createAccountError');
          rethrow;
        }

        log.info('[AuthService] Retry, calling original method');
        newJwt = await _getAuthToken(
            receiptData: receiptData, forceRefresh: forceRefresh, retry: false);
      } else {
        rethrow;
      }
    } catch (e) {
      log.info('[AuthService] Could not get jwt, rethrow');
      rethrow;
    }

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
    try {
      final request = await _getRequestFromWallet(walletAddress);
      await _authApi.addIdentity(request);
      log.info(
          '[AuthService] Added identity for address ${walletAddress.address}');
    } catch (e) {
      log.info('[AuthService] Error adding identity for address'
          ' ${walletAddress.address}: $e');
    }
  }

  Future<AccountV2Request> _getRequestFromWallet(
      WalletAddress walletAddress) async {
    final address = walletAddress.address;
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
    return AccountV2Request(
      type: isTezos ? 'tezos' : 'ethereum',
      requester: walletAddress.address,
      publicKey: tezosPublicKey,
      timestamp: timestamp,
      signature: signature,
    );
  }

  Future<JWT?> _getJwtTokenV2(AccountV2Request request) async {
    try {
      final jwt = await _authApi.authV2(request);
      return jwt;
    } catch (e) {
      log.info('[AuthService] Failed to get jwt v2 $e');
      return null;
    }
  }

  Future<JWT?> getJwtForWallet(WalletAddress walletAddress) async {
    final request = await _getRequestFromWallet(walletAddress);
    return await _getJwtTokenV2(request);
  }

  Future<JWT?> getJwtForDID({WalletStorage? account}) async {
    final request = await _getDIDRequest(
        account ?? await injector<AccountService>().getDefaultAccount());
    return await _getJwtTokenV2(request);
  }

  Future<AccountV2Request> _getDIDRequest(WalletStorage wallet,
          {receipt}) async =>
      await wallet.getDIDRequest(receipt: receipt);

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
    try {
      final request = await _getDIDRequest(walletStorage);
      await _authApi.createAccount(request);
      log.info('[AuthService] Created account for did ${walletStorage.uuid}');
    } catch (e) {
      log.info('[AuthService] Error creating account for DID '
          '${walletStorage.uuid}: $e');
    }
  }
}
