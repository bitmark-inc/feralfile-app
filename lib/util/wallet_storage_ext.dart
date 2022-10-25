//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:typed_data';

import 'package:autonomy_flutter/model/wc2_request.dart';
import 'package:autonomy_flutter/util/wc2_ext.dart';
import 'package:collection/collection.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:web3dart/credentials.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:web3dart/crypto.dart';

extension StringExtension on WalletStorage {
  Future<String> getETHEip55Address() async {
    String address = await getETHAddress();
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
  }}

extension WalletStorageExtension on WalletStorage {
  Future getOwnedQuantity(AssetToken token) async {
    final addresses = [
      await getBitmarkAddress(),
      await getETHEip55Address(),
      await getTezosAddress(),
    ];
    if (token.fungible == true && token.owners.isNotEmpty) {
      return addresses.map((e) => token.owners[e] ?? 0).sum;
    } else {
      return addresses.contains(token.ownerAddress) ? 1 : 0;
    }
  }

  Future getTezosAddress() async {
    final publicKey = await getTezosPublicKey();
    return crypto.addressFromPublicKey(publicKey);
  }

  Future<String> signMessage({
    required String chain,
    required String message,
  }) async {
    final msg = Uint8List.fromList(message.codeUnits);
    switch (chain.caip2Namespace) {
      case "eip155":
        return await ethSignPersonalMessage(msg);
      case "tezos":
        return bytesToHex(await tezosSignMessage(msg));
    }
    throw Exception("Unsupported chain $chain");
  }

  Future<Wc2Chain?> signPermissionRequest({
    required String chain,
    required String message,
  }) async {
    final signature = await signMessage(chain: chain, message: message);
    switch (chain.caip2Namespace) {
      case "eip155":
        return Wc2Chain(
          chain: chain,
          address: await getETHEip55Address(),
          signature: signature,
        );
      case "tezos":
        return Wc2Chain(
          chain: chain,
          address: await getTezosAddress(),
          publicKey: await getTezosPublicKey(),
          signature: signature,
        );
    }
    return null;
  }
}
