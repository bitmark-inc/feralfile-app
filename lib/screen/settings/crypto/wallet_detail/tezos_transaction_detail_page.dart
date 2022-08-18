//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher_string.dart';

const _nanoTEZFactor = 1000000;

class TezosTXDetailPage extends StatelessWidget {
  final String? currentAddress;
  final TZKTOperation tx;

  const TezosTXDetailPage({
    Key? key,
    required this.currentAddress,
    required this.tx,
  }) : super(key: key);

  factory TezosTXDetailPage.fromPayload({
    Key? key,
    required Map<String, dynamic> payload,
  }) =>
      TezosTXDetailPage(
          currentAddress: payload["current_address"], tx: payload["tx"]);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm');

    return Scaffold(
      appBar: getBackAppBar(context, onBack: () => Navigator.of(context).pop()),
      body: Container(
          margin: EdgeInsets.only(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_transactionTitle(), style: theme.textTheme.headline1),
              const SizedBox(height: 27),
              Expanded(
                child: ListView(
                  children: [
                    if (tx.parameter != null) ...[
                      _transactionInfo(
                          context, "call".tr(), tx.parameter?.entrypoint),
                      _transactionInfo(context, "contract".tr(),
                          tx.target?.alias ?? tx.target?.address)
                    ] else if (tx.type == "transaction") ...[
                      tx.sender?.address == currentAddress
                          ? _transactionInfo(context, "to".tr(), tx.target?.address)
                          : _transactionInfo(
                              context, "from".tr(), tx.sender?.address),
                    ],
                    _transactionInfo(context, "status".tr(), _transactionStatus()),
                    _transactionInfo(context, "date".tr(),
                        formatter.format(tx.timestamp.toLocal())),
                    if (tx.type == "transaction")
                      _transactionInfo(context, "amount".tr(), _transactionAmount()),
                    if (tx.sender?.address == currentAddress) ...[
                      _transactionInfo(context, "gas_fee2".tr(), _gasFee()),
                      _transactionInfo(context, "total_amount".tr(), _totalAmount()),
                    ],
                    _viewOnTZKT(context),
                  ],
                ),
              ),
              AuFilledButton(
                  text: "Share", onPress: () => Share.share(_txURL())),
            ],
          )),
    );
  }

  String _transactionTitle() {
    if (tx.parameter != null) {
      return "sc_interaction".tr();
    } else if (tx.type != "transaction") {
      return tx.type.capitalize();
    } else {
      return tx.sender?.address == currentAddress ? "sent_xtz".tr() : "received_xtz".tr();
    }
  }

  String _transactionStatus() {
    if (tx.status == null) {
      return "pending".tr();
    } else {
      return tx.status!.capitalize();
    }
  }

  String _transactionAmount() {
    return "${(tx.amount ?? 0) / _nanoTEZFactor} XTZ";
  }

  String _txURL() {
    return "https://tzkt.io/${tx.hash}";
  }

  Widget _transactionInfo(BuildContext context, String title, String? detail) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 16,
            runAlignment: WrapAlignment.center,
            children: [
              Text(title, style: theme.textTheme.headline4),
              if (detail != null)
                Text(
                  detail,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.subtitle1,
                ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _viewOnTZKT(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
                text: TextSpan(
              style: TextStyle(
                fontSize: 14.0,
                color: theme.colorScheme.primary,
              ),
              children: <TextSpan>[
                TextSpan(text: 'view_on'.tr(), style: theme.textTheme.headline4),
                TextSpan(
                    text: 'tzkt.io',
                    style: theme.textTheme.headline4
                        ?.copyWith(decoration: TextDecoration.underline)),
              ],
            )),
            SvgPicture.asset("assets/images/external_link.svg"),
          ],
        ),
      ),
      onTap: () => launchUrlString(_txURL()),
    );
  }

  String _gasFee() {
    return "${(tx.bakerFee + (tx.storageFee ?? 0) + (tx.allocationFee ?? 0)) / _nanoTEZFactor} XTZ";
  }

  String _totalAmount() {
    return "${((tx.amount ?? 0) + tx.bakerFee + (tx.storageFee ?? 0) + (tx.allocationFee ?? 0)) / _nanoTEZFactor} XTZ (${tx.quote.usd.toStringAsPrecision(2)} USD)";
  }
}
