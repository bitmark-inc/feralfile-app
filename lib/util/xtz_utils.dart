//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: implementation_imports

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/foundation.dart';
import 'package:tezart/src/crypto/crypto.dart' as crypto;
import 'package:web3dart/crypto.dart';

class XtzAmountFormatter {
  final int amount;
  final int digit;

  XtzAmountFormatter(this.amount, {this.digit = 6});

  String format() {
    final formater =
        NumberFormat("${'#' * 10}0.0${'#' * (digit - 1)}", "en_US");
    return formater.format(amount / 1000000);
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

class TezosPack {
  static Uint8List packInteger(int input) {
    var binaryString = input.toRadixString(2);
    var pad = 6;
    if ((binaryString.length - 6) % 7 == 0) {
      pad = binaryString.length;
    } else if (binaryString.length > 6) {
      pad = binaryString.length + 7 - ((binaryString.length - 6) % 7);
    }

    binaryString = binaryString.padLeft(pad, '0');

    var septets = [];
    for (var i = 0; i <= (pad / 7).floor(); i++) {
      var val =
          binaryString.substring(7 * i, 7 * i + [7, pad - 7 * i].reduce(min));
      septets.add(val);
    }

    septets = septets.reversed.toList();
    septets[0] = (input >= 0 ? '0' : '1') + septets[0];

    var res = Uint8List(septets.length + 1);
    for (var i = 0; i < septets.length; i++) {
      var prefix = i == septets.length - 1 ? '0' : '1';
      res[i + 1] = int.parse(prefix + septets[i], radix: 2);
    }

    // Add type indication for integer = 0x00
    res[0] = 0;

    return Uint8List.fromList(hexToBytes('05').toList() + res);
  }

  static Uint8List packAddress(String input) {
    var bytes = Base58Decode(input);
    const addressFixedLength = 22;
    if (bytes.length < 5) {
      throw const FormatException(
          "Invalid Base58Check encoded string: must be at least size 5");
    }

    List<int> subBytes = bytes.sublist(0, bytes.length - 4);
    List<int> checksum = sha256.convert(sha256.convert(subBytes).bytes).bytes;
    List<int> providedChecksum = bytes.sublist(bytes.length - 4, bytes.length);
    if (!const ListEquality()
        .equals(providedChecksum, checksum.sublist(0, 4))) {
      throw const FormatException("Invalid checksum in Base58Check encoding.");
    }

    subBytes = hexToBytes('01') + bytes.sublist(3, bytes.length - 4);
    for (var i = 0; i < addressFixedLength - subBytes.length; i++) {
      subBytes += hexToBytes('00');
    }

    final res = hexToBytes('050a00000016').toList()..addAll(subBytes);
    return Uint8List.fromList(res);
  }
}

extension TezosExtension on String {
  bool get isValidTezosAddress {
    try {
      final decoded = Base58Decode(this);
      if (decoded.length < 4) {
        return false;
      }
      final checksum = sha256
          .convert(sha256.convert(decoded.sublist(0, decoded.length - 4)).bytes)
          .bytes
          .sublist(0, 4);
      return listEquals(checksum, decoded.sublist(decoded.length - 4));
    } catch (_) {
      return false;
    }
  }
}
