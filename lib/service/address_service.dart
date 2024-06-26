//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/primary_address_channel.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:libauk_dart/libauk_dart.dart';

class AddressService {
  final PrimaryAddressChannel _primaryAddressChannel;

  AddressService(this._primaryAddressChannel);

  Future<AddressInfo?> getPrimaryAddressInfo() async {
    final addressInfo = await _primaryAddressChannel.getPrimaryAddress();
    return addressInfo;
  }

  Future<bool> setPrimaryAddressInfo({required AddressInfo info}) async {
    await _primaryAddressChannel.setPrimaryAddress(info);
    return true;
  }

  Future<bool> registerPrimaryAddress({required AddressInfo info}) async {
    await injector<AuthService>()
        .registerPrimaryAddress(primaryAddressInfo: info);
    return setPrimaryAddressInfo(info: info);
  }

  Future<String> getAddress({required AddressInfo info}) async {
    final walletStorage = WalletStorage(info.uuid);
    final chain = info.chain;
    switch (chain) {
      case 'ethereum':
        return walletStorage.getETHAddress(index: info.index);
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
        signature = await walletStorage.ethSignMessage(hexToBytes(message));
      case 'tezos':
        final signatureUInt8List =
            await walletStorage.tezosSignMessage(hexToBytes(message));
        signature = bytesToHex(signatureUInt8List);
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
}
