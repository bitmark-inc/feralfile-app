//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _nanoTEZFactor = 1000000;

class TezosTXRowView extends StatelessWidget {
  final TZKTTransactionInterface tx;
  final String? currentAddress;

  const TezosTXRowView({
    Key? key,
    required this.tx,
    this.currentAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat formatter;
    formatter = DateTime.now().year == tx.getTimeStamp().year
        ? DateFormat('MMM-dd hh:mm')
        : DateFormat('yyyy-MMM-dd hh:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatter.format(tx.getTimeStamp()).toUpperCase(),
            style: ResponsiveLayout.isMobile
                ? theme.textTheme.ibmBlackNormal14
                : theme.textTheme.ibmBlackNormal16,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              tx.transactionImage(currentAddress),
              const SizedBox(width: 13),
              Text(tx.transactionTitle(currentAddress),
                  style: theme.textTheme.headline4),
              const Spacer(),
              Text(
                  "${tx.txAmountSign(currentAddress)}${tx.totalAmount(currentAddress)}",
                  style: theme.textTheme.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 43),
              Text(tx.transactionStatus(), style: theme.textTheme.headline5),
              const Spacer(),
              Text(
                tx is! TZKTTokenTransfer
                    ? "${tx.txAmountSign(currentAddress)}${((tx as TZKTOperation).quote.usd * (tx as TZKTOperation).getTotalAmount(currentAddress) / _nanoTEZFactor).toStringAsPrecision(2)}  USD"
                    : "",
                style: theme.textTheme.headline5,
              )
            ],
          ),
        ],
      ),
    );
  }
}
