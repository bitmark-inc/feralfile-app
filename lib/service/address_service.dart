//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_object.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/primary_address_channel.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;

class AddressService {
  final PrimaryAddressChannel _primaryAddressChannel;
  final CloudObjects _cloudObject;

  AddressService(this._primaryAddressChannel, this._cloudObject);

  AddressInfo? _primaryAddressInfo;

  Future<AddressInfo?> getPrimaryAddressInfo() async {
    final addressInfo =
        _primaryAddressInfo ?? await _primaryAddressChannel.getPrimaryAddress();
    log.info('[AddressService] Primary address info: ${addressInfo?.toJson()}');
    return addressInfo;
  }

  Future<AddressInfo?> migrateToEthereumAddress(
      AddressInfo currentPrimaryAddress) async {
    final addressInfo = AddressInfo(
        uuid: currentPrimaryAddress.uuid, chain: 'ethereum', index: 0);
    await registerPrimaryAddress(info: addressInfo);
    return addressInfo;
  }

  Future<bool> setPrimaryAddressInfo({required AddressInfo info}) async {
    await _primaryAddressChannel.setPrimaryAddress(info);
    log.info('[AddressService] Primary address info set: ${info.toJson()}');
    return true;
  }

  Future<bool> registerPrimaryAddress(
      {required AddressInfo info, bool withDidKey = false}) async {
    await injector<AuthService>().registerPrimaryAddress(
        primaryAddressInfo: info, withDidKey: withDidKey);
    final res = await setPrimaryAddressInfo(info: info);
    if (withDidKey) {
      await injector<MetricClientService>().migrateFromDidKeyToPrimaryAddress();
    }
    // when register primary address, we need to update the auth token
    await injector<AuthService>().getAuthToken(forceRefresh: true);
    return res;
  }

  Future<bool> clearPrimaryAddress() async {
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
      case 'tezos':
        final signatureUInt8List = await walletStorage
            .tezosSignMessage(utf8.encode(message), index: addressInfo.index);
        signature = crypto.encodeWithPrefix(
            prefix: crypto.Prefixes.edsig, bytes: signatureUInt8List);
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

  Future<String> getAddressPublicKey({required AddressInfo addressInfo}) async {
    final walletStorage = WalletStorage(addressInfo.uuid);
    final chain = addressInfo.chain;
    String publicKey;
    switch (chain) {
      case 'ethereum':
        publicKey = '';
      case 'tezos':
        publicKey =
            await walletStorage.getTezosPublicKey(index: addressInfo.index);
      default:
        throw UnsupportedError('Unsupported chain: $chain');
    }
    return publicKey;
  }

  Future<String> getPrimaryAddressPublicKey() async {
    final addressInfo = await getPrimaryAddressInfo();
    if (addressInfo == null) {
      throw UnsupportedError('Primary address not found');
    }
    return getAddressPublicKey(addressInfo: addressInfo);
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
    final ethAddresses = getAllEthereumAddress();
    if (ethAddresses.isEmpty) {
      throw UnsupportedError('No address found');
    }
    final selectedAddress = ethAddresses.first;
    return AddressInfo(
        uuid: selectedAddress.uuid,
        index: selectedAddress.index,
        chain: selectedAddress.cryptoType.toLowerCase());
  }
}
