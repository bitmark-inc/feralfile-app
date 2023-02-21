//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/tezos_service.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:web3dart/credentials.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;

extension StringExtension on WalletStorage {
  Future<String> getETHEip55Address({int? index}) async {
    String address = await getETHAddress(index: index);
    if (address.isNotEmpty) {
      return EthereumAddress.fromHex(address).hexEip55;
    } else {
      return "";
    }
  }
}

extension StringHelper on String {
  String getETHEip55Address() {
    return EthereumAddress.fromHex(this).hexEip55;
  }

  String publicKeyToTezosAddress() {
    return crypto.addressFromPublicKey(this);
  }
}

extension WalletStorageExtension on WalletStorage {
  int getOwnedQuantity(AssetToken token) {
    return token.balance ?? 0;
  }

  Future getTezosAddress({int? index}) async {
    final publicKey = await getTezosPublicKey(index: index);
    return crypto.addressFromPublicKey(publicKey);
  }

  Future<String> signMessage({
    required String chain,
    required String message,
  }) async {
    var msg = Uint8List.fromList(utf8.encode(message));
    switch (chain.caip2Namespace) {
      case Wc2Chain.ethereum:
        return await injector<EthereumService>().signPersonalMessage(this, msg);
      case Wc2Chain.tezos:
        return await injector<TezosService>().signMessage(this, msg);
      case Wc2Chain.autonomy:
        return await getAccountDIDSignature(message);
    }
    throw Exception("Unsupported chain $chain");
  }

  Future<Wc2Chain?> signPermissionRequest({
    required String chain,
    required String message,
  }) async {
    switch (chain.caip2Namespace) {
      case "eip155":
        final ethAddress = await getETHEip55Address();
        return Wc2Chain(
          chain: chain,
          address: ethAddress,
          signature: await signMessage(chain: chain, message: message),
        );
      case "tezos":
        final tezosAddress = await getTezosAddress();
        return Wc2Chain(
          chain: chain,
          address: tezosAddress,
          publicKey: await getTezosPublicKey(),
          signature: await signMessage(chain: chain, message: message),
        );
    }
    return null;
  }
}
