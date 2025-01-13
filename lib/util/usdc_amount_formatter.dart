//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:easy_localization/easy_localization.dart';

class USDCAmountFormatter {
  USDCAmountFormatter({this.digit = 6});

  final int digit;

  String format(BigInt amount) {
    final formatter =
        NumberFormat("${'#' * 10}0.0${'#' * (digit - 1)}", 'en_US');
    return formatter.format(amount.toDouble() / 1000000);
  }
}

class USDAmountFormatter {
  late NumberFormat formatter;

  USDAmountFormatter({this.digit = 2}) {
    formatter = NumberFormat("${'#' * 10}.${'#' * (digit - 1)}", 'en_US');
  }

  final int digit;

  String format(double amount) => formatter.format(amount / 100);
}
