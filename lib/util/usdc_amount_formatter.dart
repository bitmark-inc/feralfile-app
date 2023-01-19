//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:easy_localization/easy_localization.dart';

class USDCAmountFormatter {
  USDCAmountFormatter(this.amount, {this.digit = 6});

  final BigInt amount;
  final int digit;

  String format() {
    final formater =
        NumberFormat("${'#' * 10}0.0${'#' * (digit - 1)}", "en_US");
    return formater.format(amount.toDouble() / 1000000);
  }
}
