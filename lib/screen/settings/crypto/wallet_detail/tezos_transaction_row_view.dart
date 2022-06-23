//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

const _nanoTEZFactor = 1000000;

class TezosTXRowView extends StatelessWidget {
  final TZKTOperation tx;
  final String? currentAddress;

  const TezosTXRowView({
    Key? key,
    required this.tx,
    this.currentAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d hh:mm');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatter.format(tx.timestamp.toLocal()),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: "IBMPlexMono"),
          ),
          SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _transactionImage(),
              SizedBox(width: 13),
              Text(_transactionTitle(), style: appTextTheme.headline4),
              Spacer(),
              Text(_totalAmount(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: "IBMPlexMono"))
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 43),
              Text(_transactionStatus(),
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      fontFamily: "AtlasGrotesk")),
              Spacer(),
              Text(tx.quote.usd.toStringAsPrecision(2) + "  USD",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      fontFamily: "AtlasGrotesk"))
            ],
          ),
        ],
      ),
    );
  }

  Widget _transactionImage() {
    if (tx.parameter != null ||
        tx.type == "reveal" ||
        tx.type == "origination") {
      return SvgPicture.asset("assets/images/tezos_tx_smartcontract.svg");
    } else {
      return SvgPicture.asset(tx.sender?.address == currentAddress
          ? "assets/images/tezos_tx_sent.svg"
          : "assets/images/tezos_tx_received.svg");
    }
  }

  String _transactionTitle() {
    if (tx.type != "transaction") {
      return tx.type.capitalize();
    } else if (tx.parameter != null) {
      return tx.parameter!.entrypoint.snakeToCapital();
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

  String _totalAmount() {
    if (tx.sender?.address == currentAddress) {
      return (((tx.amount ?? 0) +
                  tx.bakerFee +
                  (tx.storageFee ?? 0) +
                  (tx.allocationFee ?? 0)) /
              _nanoTEZFactor)
          .toStringAsPrecision(3);
    } else {
      return ((tx.amount ?? 0) / _nanoTEZFactor).toStringAsPrecision(3);
    }
  }
}
