//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:sentry/sentry.dart';

class AddressService {
  final UserAccountChannel _primaryAddressChannel;
  final CloudManager _cloudObject;

  AddressService(this._primaryAddressChannel, this._cloudObject);

  AddressInfo? _primaryAddressInfo;

  Future<AddressInfo?> getPrimaryAddressInfo() async {
    if (_primaryAddressInfo != null) {
      log.info('[AddressService] (Already set) Primary address info:'
          ' ${_primaryAddressInfo?.toJson()}');
      return _primaryAddressInfo;
    }
    _primaryAddressInfo = await _primaryAddressChannel.getPrimaryAddress();
    log.info('[AddressService] Primary address info:'
        ' ${_primaryAddressInfo?.toJson()}');
    return _primaryAddressInfo;
  }

  Future<AddressInfo?> migrateToEthereumAddress(
      AddressInfo currentPrimaryAddress) async {
    final addressInfo = AddressInfo(
        uuid: currentPrimaryAddress.uuid, chain: 'ethereum', index: 0);
    await registerPrimaryAddress(info: addressInfo);
    log.info(
      '[AddressService] Migrated to Ethereum address: ${addressInfo.toJson()}',
    );
    return addressInfo;
  }

  Future<bool> setPrimaryAddressInfo({required AddressInfo info}) async {
    await _primaryAddressChannel.setPrimaryAddress(info);
    log.info('[AddressService] Primary address info set: ${info.toJson()}');
    return true;
  }

  Future<bool> registerPrimaryAddress({required AddressInfo info}) async {
    log.info('[AddressService] Registering primary address: ${info.toJson()}');
    final res = await setPrimaryAddressInfo(info: info);
    return res;
  }

  Future<bool> registerReferralCode({required String referralCode}) async {
    try {
      await injector<AuthService>()
          .registerReferralCode(referralCode: referralCode);
      return true;
    } catch (e) {
      log.info('Failed to register referral code: $e');
      unawaited(Sentry.captureException(e));
      rethrow;
    }
  }

  Future<bool> clearPrimaryAddress() async {
    _primaryAddressInfo = null;
    await _primaryAddressChannel.clearPrimaryAddress();
    return true;
  }

  Future<String> getAddress({required AddressInfo info}) async {
    final walletStorage = WalletStorage(info.uuid);
    final chain = info.chain;
    switch (chain) {
      case 'ethereum':
        final address =
            await walletStorage.getETHEip55Address(index: info.index);
        final checksumAddress = address.getETHEip55Address();
        return checksumAddress;
      case 'tezos':
        return walletStorage.getTezosAddress(index: info.index);
      default:
        throw UnsupportedError('Unsupported chain: $chain');
    }
  }

  Future<String?> getPrimaryAddress() async {
    final addressInfo = await getPrimaryAddressInfo();
    if (addressInfo == null) {
      return null;
    }
    return getAddress(info: addressInfo);
  }

  Future<String> getAddressSignature(
      {required AddressInfo addressInfo, required String message}) async {
    final walletStorage = WalletStorage(addressInfo.uuid);
    final chain = addressInfo.chain;
    String signature;
    switch (chain) {
      case 'ethereum':
        signature = await walletStorage.ethSignPersonalMessage(
            utf8.encode(message),
            index: addressInfo.index);
      default:
        throw UnsupportedError('Unsupported chain: $chain');
    }
    return signature;
  }

  Future<String?> getPrimaryAddressSignature({required String message}) async {
    final addressInfo = await getPrimaryAddressInfo();
    if (addressInfo == null) {
      return null;
    }
    return getAddressSignature(addressInfo: addressInfo, message: message);
  }

  String getFeralfileAccountMessage(
          {required String address, required String timestamp}) =>
      'feralfile-account: {"requester":"$address","timestamp":"$timestamp"}';

  Future<List<WalletAddress>> getAllAddress() async {
    final addresses = _cloudObject.addressObject.getAllAddresses();
    return addresses;
  }

  List<WalletAddress> getAllEthereumAddress() {
    final addresses = _cloudObject.addressObject
        .getAddressesByType(CryptoType.ETH.source)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return addresses;
  }

  AddressInfo pickAddressAsPrimary() {
    log.info('[AddressService] Picking address as primary');
    final ethAddresses = getAllEthereumAddress();
    if (ethAddresses.isEmpty) {
      log.info('[AddressService] No address found');
      throw UnsupportedError('No address found');
    }
    final selectedAddress = ethAddresses.first;
    log.info('[AddressService] Selected address: $selectedAddress');
    return AddressInfo(
        uuid: selectedAddress.uuid,
        index: selectedAddress.index,
        chain: selectedAddress.cryptoType.toLowerCase());
  }
}
