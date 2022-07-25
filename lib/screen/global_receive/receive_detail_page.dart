//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class GlobalReceiveDetailPage extends StatefulWidget {
  static const tag = "global_receive_detail";

  final Object? payload;

  const GlobalReceiveDetailPage({Key? key, required this.payload})
      : super(key: key);
  @override
  State<GlobalReceiveDetailPage> createState() =>
      _GlobalReceiveDetailPageState(payload as Account);
}

class _GlobalReceiveDetailPageState extends State<GlobalReceiveDetailPage> {
  final Account _account;
  bool _copied = false;

  _GlobalReceiveDetailPageState(this._account);

  @override
  Widget build(BuildContext context) {
    double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Receive",
                style: appTextTheme.headline1,
              ),
              addTitleSpace(),
              Center(
                child: GestureDetector(
                    child: QrImage(
                      data: _account.accountNumber,
                      size: 180.0,
                    ),
                    onTap: copy),
              ),
              SizedBox(height: 48),
              Text((_blockchainNFTText(_account.blockchain)),
                  style: appTextTheme.headline4),
              accountItem(context, _account),
              GestureDetector(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            width: 1.0,
                            color: Color.fromRGBO(227, 227, 227, 1)),
                      ),
                      color: Color.fromRGBO(237, 237, 237, 0.3),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Account address",
                            textAlign: TextAlign.left,
                            style: appTextTheme.headline4?.copyWith(
                                fontSize: 12,
                                color: AppColorTheme.secondaryDimGrey),
                          ),
                          SizedBox(height: 4.0),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _account.accountNumber,
                              textAlign: TextAlign.start,
                              softWrap: true,
                              style: TextStyle(
                                  fontSize: 12, fontFamily: "IBMPlexMono"),
                            ),
                          ),
                        ]),
                  ),
                  onTap: copy),
              SizedBox(
                  height: 22,
                  child: Container(
                      alignment: Alignment.center,
                      child: _copied
                          ? Text("Copied", style: copiedTextStyle)
                          : SizedBox())),
              SizedBox(height: 4),
              Text(_blockchainWarningText(_account.blockchain),
                  style: paragraph),
            ],
          ),
        )),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16.0, vertical: safeAreaBottom > 0 ? 40 : 16),
          child: AuFilledButton(
              text: "SHARE",
              onPress: () => Share.share(_account.accountNumber,
                  subject: "My account number")),
        ),
      ]),
    );
  }

  copy() {
    Vibrate.feedback(FeedbackType.light);
    Clipboard.setData(ClipboardData(text: _account.accountNumber));
    setState(() {
      _copied = true;
    });
  }
}

String _blockchainNFTText(String? blockchain) {
  switch (blockchain) {
    case "Bitmark":
      return "BITMARK NFT";
    case "Ethereum":
      return "ETHEREUM NFT or ETH";
    case "Tezos":
      return "TEZOS NFT or XTZ";
    default:
      return "Unknown";
  }
}

String _blockchainWarningText(String? blockchain) {
  switch (blockchain) {
    case "Bitmark":
      return "Send only Bitmark NFTs to this address. Do not send cryptocurrencies. Sending cryptocurrencies or non-Bitmark NFTs may result in their permanent loss.";
    case "Ethereum":
      return "Send only Ether (ETH) cryptocurrency and Ethereum NFTs to this address. Do not send anything from an alternate chain such as USD Tether or Binance Smart Chain. Sending non-Ethereum cryptocurrencies or tokens may result in their permanent loss.";
    case "Tezos":
      return "Send only Tezos (XTZ) cryptocurrency and Tezos NFTs (FA2 standard) to this address. Sending other cryptocurrencies or tokens may result in their permanent loss.";
    default:
      return "";
  }
}
