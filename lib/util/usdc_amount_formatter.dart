//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class USDCAmountFormatter {
  USDCAmountFormatter(this.amount);

  final BigInt amount;

  String format() {
    if (amount == BigInt.zero) return "0.0";

    return "${amount.toDouble() / 1000000}";
  }
}
