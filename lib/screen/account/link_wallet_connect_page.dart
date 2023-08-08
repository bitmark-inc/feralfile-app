//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/external_app_info_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkWalletConnectPage extends StatefulWidget {
  final String unableOpenAppname;

  const LinkWalletConnectPage({Key? key, this.unableOpenAppname = ""})
      : super(key: key);

  @override
  State<LinkWalletConnectPage> createState() => _LinkWalletConnectPageState();
}

class _LinkWalletConnectPageState extends State<LinkWalletConnectPage> {
  @override
  void initState() {
    super.initState();

    injector<WalletConnectDappService>().start();
    injector<WalletConnectDappService>().connect();
  }

  @override
  void dispose() {
    super.dispose();
    injector<WalletConnectDappService>().disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.ppMori400Black14;
    final Uri uri = Uri.parse("https://www.walletconnect.com");
    return Scaffold(
      appBar: getBackAppBar(context, onBack: () {
        Navigator.of(context).pop();
      }, title: "other_ethereum_wallets".tr()),
      body: Container(
        margin: ResponsiveLayout.pageHorizontalEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    addTitleSpace(),
                    _wcQRCode(),
                    const SizedBox(height: 60),
                    ExternalAppInfoView(
                        icon: Image.asset(
                            "assets/images/walletconnect-alternative.png"),
                        appName: "wallet.connect".tr(),
                        status: "compatible".tr()),
                    const SizedBox(height: 15),
                    if (widget.unableOpenAppname.isNotEmpty) ...[
                      Text(
                          'sctl_we_were_unable'
                              .tr(args: [widget.unableOpenAppname]),
                          //"We were unable to open ${widget.unableOpenAppname} on this device.",
                          style: theme.textTheme.ppMori700Black14),
                      const SizedBox(height: 15),
                    ],
                    Text(
                      "sctl_if_your_wallet".tr(),
                      //"If your wallet is on another device, you can open it and scan the QR code below to link your account to Autonomy: ",
                      style: textStyle,
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: "sure_eth_support".tr(),
                          style: textStyle,
                        ),
                        TextSpan(
                          text: "wallet.connect".tr(),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrl(uri,
                                mode: LaunchMode.externalApplication),
                          style: textStyle.copyWith(
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text: "_protocol".tr(),
                          style: textStyle,
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wcQRCode() {
    return ValueListenableBuilder<String?>(
        valueListenable: injector<WalletConnectDappService>().wcURI,
        builder: (BuildContext context, String? wcURI, Widget? child) {
          return GestureDetector(
            child: Container(
              alignment: Alignment.center,
              width: 180,
              height: 180,
              child: wcURI != null
                  ? QrImageView(
                      data: wcURI,
                      size: 180.0,
                    )
                  : const CupertinoActivityIndicator(
                      // color: Colors.black,
                      ),
            ),
            onTap: () {
              Clipboard.setData(ClipboardData(text: wcURI ?? ""));
              showInfoNotification(
                  const Key("beacon_deeplink"), "copied_to_clipboard".tr());
            },
          );
        });
  }
}
