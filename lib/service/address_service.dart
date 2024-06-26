//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:libauk_dart/libauk_dart.dart';

class AddressService {
  Future<AddressInfo> getPrimaryAddressInfo() async =>
      AddressInfo('uuid', 'chain', 0);

  Future<bool> setPrimaryAddressInfo({required AddressInfo info}) async {
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

  Future<String> getPrimaryAddress() async {
    final addressInfo = await getPrimaryAddressInfo();
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

  Future<String> getPrimaryAddressSignature({required String message}) async {
    final addressInfo = await getPrimaryAddressInfo();
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
    return getAddressPublicKey(addressInfo: addressInfo);
  }

  String getFeralfileAccountMessage(
          {required String address, required String timestamp}) =>
      'feralfile-account: {"requester":"$address","timestamp":"$timestamp"}';
}

class AddressInfo {
  final String uuid;
  final String chain;
  final int index;

  AddressInfo(this.uuid, this.chain, this.index);

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'chain': chain,
        'index': index,
      };

  factory AddressInfo.fromJson(Map<String, dynamic> json) => AddressInfo(
        json['uuid'],
        json['chain'],
        json['index'],
      );

  bool get isEthereum => chain == 'ethereum';
}
