//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/account_view.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';

class GlobalReceiveDetailPage extends StatefulWidget {
  static const tag = "global_receive_detail";

  final GlobalReceivePayload payload;

  const GlobalReceiveDetailPage({Key? key, required this.payload})
      : super(key: key);

  @override
  State<GlobalReceiveDetailPage> createState() =>
      _GlobalReceiveDetailPageState();
}

class _GlobalReceiveDetailPageState extends State<GlobalReceiveDetailPage> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "receive".tr(),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: SingleChildScrollView(
          padding: ResponsiveLayout.getPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              addTitleSpace(),
              Center(
                child: GestureDetector(
                    onTap: copy,
                    child: QrImage(
                      data: widget.payload.address,
                      size: 180.0,
                    )),
              ),
              const SizedBox(height: 48),
              Text((_blockchainNFTText(widget.payload.blockchain)),
                  style: theme.textTheme.headlineMedium),
              accountItem(context, widget.payload.account),
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
                            "account_address".tr(),
                            textAlign: TextAlign.left,
                            style: ResponsiveLayout.isMobile
                                ? theme.textTheme.atlasGreyBold12
                                : theme.textTheme.atlasGreyBold14,
                          ),
                          const SizedBox(height: 4.0),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              widget.payload.address,
                              textAlign: TextAlign.start,
                              softWrap: true,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ]),
                  )),
              SizedBox(
                  height: 25,
                  child: Container(
                      alignment: Alignment.center,
                      child: _copied
                          ? Text(
                              "copied".tr(),
                              style: ResponsiveLayout.isMobile
                                  ? theme.textTheme.atlasBlackBold12
                                  : theme.textTheme.atlasBlackBold14,
                            )
                          : const SizedBox())),
              const SizedBox(height: 4),
              Text(
                _blockchainWarningText(widget.payload.blockchain),
                style: ResponsiveLayout.isMobile
                    ? theme.textTheme.atlasGreyNormal12
                    : theme.textTheme.atlasGreyNormal14,
              ),
            ],
          ),
        )),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16.0, vertical: safeAreaBottom > 0 ? 40 : 16),
          child: PrimaryButton(
              text: "share".tr(),
              onTap: () => Share.share(widget.payload.address,
                  subject: "my_account_number".tr())),
        ),
      ]),
    );
  }

  copy() {
    Vibrate.feedback(FeedbackType.light);
    Clipboard.setData(ClipboardData(text: widget.payload.address));
    setState(() {
      _copied = true;
    });
  }
}

String _blockchainNFTText(String? blockchain) {
  switch (blockchain) {
    case "Bitmark":
      return "bitmark_nft".tr();
    case "Ethereum":
      return "nft_or_eth".tr();
    case "Tezos":
      return "nft_or_xtz".tr();
    case "USDC":
      return "USDC (Ethereum ERC-20)";
    default:
      return "unknown".tr();
  }
}

String _blockchainWarningText(String? blockchain) {
  switch (blockchain) {
    case "Bitmark":
      return "bitmark_send_only"
          .tr(); // "Send only Bitmark NFTs to this address. Do not send cryptocurrencies. Sending cryptocurrencies or non-Bitmark NFTs may result in their permanent loss.";
    case "Ethereum":
      return "eth_send_only"
          .tr(); // "Send only Ether (ETH) cryptocurrency and Ethereum NFTs to this address. Do not send anything from an alternate chain such as USD Tether or Binance Smart Chain. Sending non-Ethereum cryptocurrencies or tokens may result in their permanent loss.";
    case "Tezos":
      return "xtz_send_only"
          .tr(); // "Send only Tezos (XTZ) cryptocurrency and Tezos NFTs (FA2 standard) to this address. Sending other cryptocurrencies or tokens may result in their permanent loss.";
    default:
      return "";
  }
}

class GlobalReceivePayload {
  String address;
  String blockchain;
  Account account;

  GlobalReceivePayload({required this.address, required this.blockchain, required this.account});
}
