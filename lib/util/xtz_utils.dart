//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: implementation_imports

import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/foundation.dart';

class XtzAmountFormatter {
  final int digit;

  XtzAmountFormatter({this.digit = 6});

  String format(int amount) {
    final formater =
        NumberFormat("${'#' * 10}0.0${'#' * (digit - 1)}", 'en_US');
    return formater.format(amount / 1000000);
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
