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
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

class GlobalReceiveDetailPage extends StatefulWidget {
  static const tag = "global_receive_detail";

  final Object? payload;

  const GlobalReceiveDetailPage({Key? key, required this.payload})
      : super(key: key);
  @override
  State<GlobalReceiveDetailPage> createState() =>
      _GlobalReceiveDetailPageState();
}

class _GlobalReceiveDetailPageState extends State<GlobalReceiveDetailPage> {
  late Account _account;
  bool _copied = false;

  @override
  void initState() {
    // TODO: implement initState
    _account = widget.payload as Account;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Receive",
                style: theme.textTheme.headline1,
              ),
              addTitleSpace(),
              Center(
                child: GestureDetector(
                    onTap: copy,
                    child: QrImage(
                      data: _account.accountNumber,
                      size: 180.0,
                    )),
              ),
              const SizedBox(height: 48),
              Text((_blockchainNFTText(_account.blockchain)),
                  style: theme.textTheme.headline4),
              accountItem(context, _account),
              GestureDetector(
                  onTap: copy,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top:
                            BorderSide(color: Color.fromRGBO(227, 227, 227, 1)),
                      ),
                      color: Color.fromRGBO(237, 237, 237, 0.3),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Account address",
                            textAlign: TextAlign.left,
                            style: theme.textTheme.atlasGreyBold12,
                          ),
                          const SizedBox(height: 4.0),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _account.accountNumber,
                              textAlign: TextAlign.start,
                              softWrap: true,
                              style: theme.textTheme.subtitle2,
                            ),
                          ),
                        ]),
                  )),
              SizedBox(
                  height: 22,
                  child: Container(
                      alignment: Alignment.center,
                      child: _copied
                          ? Text("Copied",
                              style: theme.textTheme.atlasBlackBold12)
                          : const SizedBox())),
              const SizedBox(height: 4),
              Text(
                _blockchainWarningText(_account.blockchain),
                style: theme.textTheme.atlasGreyNormal12,
              ),
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
