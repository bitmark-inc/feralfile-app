//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: implementation_imports

import 'package:crypto/crypto.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/foundation.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;

class XtzAmountFormatter {
  final int amount;

  XtzAmountFormatter(this.amount);

  String format() {
    return "${amount / 1000000}";
  }
}

const crypto.Prefixes _addressPrefix = crypto.Prefixes.tz1;

String xtzAddress(List<int> publicKey) => crypto.catchUnhandledErrors(() {
      final publicKeyBytes = Uint8List.fromList(_compressPublicKey(publicKey));
      final hash = crypto.hashWithDigestSize(
        size: 160,
        bytes: publicKeyBytes.sublist(1),
      );

      return crypto.encodeWithPrefix(
        prefix: _addressPrefix,
        bytes: hash,
      );
    });

List<int> _compressPublicKey(List<int> publicKey) {
  publicKey[0] = 0x00;
  return publicKey;
}

extension TezosExtension on String {
  bool get isValidTezosAddress {
    final decoded = Base58Decode(this);
    if (decoded.length < 4) {
      return false;
    }
    final checksum = sha256
        .convert(sha256.convert(decoded.sublist(0, decoded.length - 4)).bytes)
        .bytes
        .sublist(0, 4);
    return listEquals(checksum, decoded.sublist(decoded.length - 4));
  }
}
