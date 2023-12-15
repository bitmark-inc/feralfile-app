//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/util/account_ext.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/crypto_view.dart';
import 'package:autonomy_flutter/view/important_note_view.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
  late Account _account;
  late String? _blockchain;

  @override
  void initState() {
    _account = widget.payload.account;
    _blockchain = widget.payload.blockchain;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "receive_on_".tr(args: [_blockchain!]),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: SingleChildScrollView(
          padding:
              ResponsiveLayout.pageEdgeInsetsWithSubmitButton.copyWith(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              addTitleSpace(),
              Center(
                child: GestureDetector(
                    onTap: copy,
                    child: QrImageView(
                      data: widget.payload.address,
                      size: 180.0,
                    )),
              ),
              const SizedBox(height: 30),
              _blockchain != "USDC"
                  ? ImportantNoteView(note: _blockchainWarningText(_blockchain))
                  : const SizedBox(),
              const SizedBox(height: 16),
              Container(
                decoration: const BoxDecoration(
                  color: AppColor.auLightGrey,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        LogoCrypto(cryptoType: _account.cryptoType, size: 24),
                        const SizedBox(width: 10),
                        Text(_account.name,
                            style: theme.textTheme.ppMori700Black16),
                        const Expanded(child: SizedBox()),
                      ]),
                    ),
                    GestureDetector(
                        onTap: copy,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "your_blockchain_address".tr(
                                    namedArgs: {'blockChain': _blockchain!}),
                                textAlign: TextAlign.left,
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.ppMori400Black12
                                    : theme.textTheme.ppMori400Black14,
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                _account.accountNumber,
                                textAlign: TextAlign.start,
                                softWrap: true,
                                style: theme.textTheme.ppMori400Black14,
                              ),
                            ])),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        )),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16.0, vertical: safeAreaBottom > 0 ? 40 : 16),
          child: OutlineButton(
              color: Colors.transparent,
              textColor: AppColor.primaryBlack,
              borderColor: AppColor.primaryBlack,
              text: "share".tr(),
              onTap: () => Share.share(widget.payload.address,
                  subject: "my_account_number".tr())),
        ),
      ]),
    );
  }

  copy() {
    showInfoNotification(
        const Key("address"), "address_copied_to_clipboard".tr());
    Vibrate.feedback(FeedbackType.light);
    Clipboard.setData(ClipboardData(text: widget.payload.address));
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

  GlobalReceivePayload(
      {required this.address, required this.blockchain, required this.account});
}
