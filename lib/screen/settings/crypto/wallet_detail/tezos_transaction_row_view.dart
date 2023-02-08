//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
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
        ? dateFormatterMD
        : dateFormatterYMD;
    return TappableForwardRow(
      onTap: () => Navigator.of(context).pushNamed(
        AppRouter.tezosTXDetailPage,
        arguments: {
          "current_address": currentAddress,
          "tx": tx,
        },
      ),
      leftWidget: Row(
        children: [
          tx.transactionImage(currentAddress),
          const SizedBox(
            width: 12,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx.transactionTitle(currentAddress),
                  style: theme.textTheme.ppMori700Black14),
              Row(
                children: [
                  Text(
                    formatter.format(tx.getTimeStamp()).toUpperCase(),
                    style: ResponsiveLayout.isMobile
                        ? theme.textTheme.ppMori400Grey14
                        : theme.textTheme.ppMori400Grey16,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(tx.transactionStatus(),
                      style: theme.textTheme.ppMori400Grey14),
                ],
              )
            ],
          )
        ],
      ),
      rightWidget: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                "${tx.txAmountSign(currentAddress)}${tx.totalAmount(currentAddress)}",
                style: theme.textTheme.ppMori400Black14),
            Text(
              tx is! TZKTTokenTransfer
                  ? "${tx.txAmountSign(currentAddress)}${((tx as TZKTOperation).quote.usd * (tx as TZKTOperation).getTotalAmount(currentAddress) / _nanoTEZFactor).toStringAsPrecision(2)} USD"
                  : "",
              style: theme.textTheme.ppMori400Grey14,
            )
          ],
        ),
      ),
    );
  }
}
