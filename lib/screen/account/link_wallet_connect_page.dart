//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wallet_connect_dapp_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class LinkWalletConnectPage extends StatefulWidget {
  final String unableOpenAppname;
  const LinkWalletConnectPage({Key? key, this.unableOpenAppname = ""})
      : super(key: key);

  @override
  State<LinkWalletConnectPage> createState() => _LinkWalletConnectPageState();
}

class _LinkWalletConnectPageState extends State<LinkWalletConnectPage> {
  bool _copied = false;

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
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: const EdgeInsets.only(
            top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "scan_code_to_link".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    if (widget.unableOpenAppname.isNotEmpty) ...[
                      Text(
                          'sctl_we_were_unable'.tr(args: ['widget.unableOpenAppname']),
                          //"We were unable to open ${widget.unableOpenAppname} on this device.",
                          style: theme.textTheme.headline4),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      "sctl_if_your_wallet".tr(),
                      //"If your wallet is on another device, you can open it and scan the QR code below to link your account to Autonomy: ",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 24),
                    _wcQRCode(),
                    if (_copied) ...[
                      const SizedBox(height: 24),
                      Center(
                          child: Text("copied".tr(),
                              style: theme.textTheme.atlasBlackBold12)),
                    ]
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
                  ? QrImage(
                      data: wcURI,
                      size: 180.0,
                    )
                  : const CupertinoActivityIndicator(
                      // color: Colors.black,
                      ),
            ),
            onTap: () {
              Vibrate.feedback(FeedbackType.light);
              Clipboard.setData(ClipboardData(text: wcURI));
              setState(() {
                _copied = true;
              });
            },
          );
        });
  }
}
