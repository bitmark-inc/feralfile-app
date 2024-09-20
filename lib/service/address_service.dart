//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/primary_address_channel.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;

class AddressService {
  final PrimaryAddressChannel _primaryAddressChannel;
  final CloudDatabase _cloudDB;

  AddressService(this._primaryAddressChannel, this._cloudDB);

  Future<AddressInfo?> getPrimaryAddressInfo() async {
    final addressInfo = await _primaryAddressChannel.getPrimaryAddress();
    log.info('[AddressService] Primary address info: ${addressInfo?.toJson()}');
    return addressInfo;
  }

  Future<AddressInfo?> migrateToEthereumAddress() async {
    final currentPrimaryAddress = await getPrimaryAddressInfo();
    if (currentPrimaryAddress == null || currentPrimaryAddress.isEthereum) {
      return null;
    }
    final allEthAddresses = await getAllEthereumAddress();
    if (allEthAddresses.isEmpty) {
      await deriveAddressesFromAllPersona();
    }
    final addressInfo = await pickAddressAsPrimary();
    await registerPrimaryAddress(info: addressInfo);
    return addressInfo;
  }

  Future<void> deriveAddressesFromAllPersona() async {
    final personas = await _cloudDB.personaDao.getPersonas();
    for (final persona in personas) {
      await Future.wait([
        persona.insertAddressAtIndex(walletType: WalletType.Ethereum, index: 0),
        persona.insertAddressAtIndex(walletType: WalletType.Tezos, index: 0),
      ]);
    }
  }

  Future<void> derivePrimaryAddress() async {
    final primaryAddressInfo = await getPrimaryAddressInfo();
    if (primaryAddressInfo == null) {
      return;
    }
    final persona = await _cloudDB.personaDao.findById(primaryAddressInfo.uuid);
    await persona?.insertAddressAtIndex(
        walletType: primaryAddressInfo.walletType,
        index: primaryAddressInfo.index);
  }

  Future<bool> setPrimaryAddressInfo({required AddressInfo info}) async {
    await _primaryAddressChannel.setPrimaryAddress(info);
    log.info('[AddressService] Primary address info set: ${info.toJson()}');
    return true;
  }

  Future<bool> registerPrimaryAddress(
      {required AddressInfo info, bool withDidKey = false}) async {
    final referralCode = injector<ConfigurationService>().getReferralCode();
    await injector<AuthService>().registerPrimaryAddress(
        primaryAddressInfo: info,
        withDidKey: withDidKey,
        referralCode: referralCode);
    await injector<ConfigurationService>().removeReferralCode();
    final res = await setPrimaryAddressInfo(info: info);
    // when register primary address, we need to update the auth token
    await injector<AuthService>().getAuthToken(forceRefresh: true);
    // we also need to identity the metric client
    await injector<MetricClientService>().identity();
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
    final addresses = await _cloudDB.addressDao.getAllAddresses();
    final persona = await _cloudDB.personaDao.getPersonas();
    addresses
        .removeWhere((address) => !persona.any((p) => p.uuid == address.uuid));
    return addresses;
  }

  Future<List<WalletAddress>> getAllEthereumAddress() async {
    final addresses =
        await _cloudDB.addressDao.getAddressesByType(CryptoType.ETH.source);
    addresses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final persona = await _cloudDB.personaDao.getPersonas();
    persona.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final sortedAddresses = <WalletAddress>[];
    for (final p in persona) {
      final pAddresses = addresses.where((a) => a.uuid == p.uuid).toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      sortedAddresses.addAll(pAddresses);
    }
    return sortedAddresses;
  }

  Future<AddressInfo> pickAddressAsPrimary() async {
    final ethAddresses = await getAllEthereumAddress();
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
