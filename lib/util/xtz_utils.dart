//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:typed_data';

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
