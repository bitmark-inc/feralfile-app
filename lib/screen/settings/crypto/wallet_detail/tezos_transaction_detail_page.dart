//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

const _nanoTEZFactor = 1000000;

class TezosTXDetailPage extends StatelessWidget {
  final String? currentAddress;
  final TZKTOperation tx;

  const TezosTXDetailPage({
    Key? key,
    required this.currentAddress,
    required this.tx,
  });

  factory TezosTXDetailPage.fromPayload({
    Key? key,
    required Map<String, dynamic> payload,
  }) =>
      TezosTXDetailPage(
          currentAddress: payload["current_address"], tx: payload["tx"]);

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_transactionTitle(), style: appTextTheme.headline1),
              SizedBox(height: 27),
              Expanded(
                child: ListView(
                  children: [
                    if (tx.parameter != null) ...[
                      _transactionInfo("Call", tx.parameter?.entrypoint),
                      _transactionInfo(
                          "Contract", tx.target?.alias ?? tx.target?.address)
                    ] else if (tx.type == "transaction") ...[
                      tx.sender?.address == currentAddress
                          ? _transactionInfo("To", tx.target?.address)
                          : _transactionInfo("From", tx.sender?.address),
                    ],
                    _transactionInfo("Status", _transactionStatus()),
                    _transactionInfo(
                        "Date", formatter.format(tx.timestamp.toLocal())),
                    if (tx.type == "transaction")
                      _transactionInfo("Amount", _transactionAmount()),
                    if (tx.sender?.address == currentAddress) ...[
                      _transactionInfo("Gas fee", _gasFee()),
                      _transactionInfo("Total amount", _totalAmount()),
                    ],
                    _viewOnTZKT(),
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
      return "Smart contract interaction";
    } else if (tx.type != "transaction") {
      return tx.type.capitalize();
    } else {
      return tx.sender?.address == currentAddress ? "Sent XTZ" : "Received XTZ";
    }
  }

  String _transactionStatus() {
    if (tx.status == null) {
      return "Pending....";
    } else {
      return tx.status!.capitalize();
    }
  }

  String _transactionAmount() {
    return ((tx.amount ?? 0) / _nanoTEZFactor).toString() + " XTZ";
  }

  String _txURL() {
    return "https://tzkt.io/" + tx.hash;
  }

  Widget _transactionInfo(String title, String? detail) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 16,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  Text(title, style: appTextTheme.headline4),
                  if (detail != null)
                    Text(detail,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontFamily: "IBMPlexMono")),
                ])),
        Divider(),
      ],
    );
  }

  Widget _viewOnTZKT() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
                text: TextSpan(
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.black,
              ),
              children: <TextSpan>[
                TextSpan(text: 'View on ', style: appTextTheme.headline4),
                TextSpan(
                    text: 'tzkt.io',
                    style: appTextTheme.headline4
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
    return ((tx.bakerFee + (tx.storageFee ?? 0) + (tx.allocationFee ?? 0)) /
                _nanoTEZFactor)
            .toString() +
        " XTZ";
  }

  String _totalAmount() {
    return (((tx.amount ?? 0) +
                    tx.bakerFee +
                    (tx.storageFee ?? 0) +
                    (tx.allocationFee ?? 0)) /
                _nanoTEZFactor)
            .toString() +
        " XTZ (" +
        tx.quote.usd.toStringAsPrecision(2) +
        " USD)";
  }
}
