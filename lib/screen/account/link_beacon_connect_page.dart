//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/external_app_info_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkBeaconConnectPage extends StatefulWidget {
  final String uri;

  const LinkBeaconConnectPage({Key? key, required this.uri}) : super(key: key);

  @override
  State<LinkBeaconConnectPage> createState() => _LinkBeaconConnectPageState();
}

class _LinkBeaconConnectPageState extends State<LinkBeaconConnectPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.ppMori400Black14;
    final Uri uri = Uri.parse("https://www.walletbeacon.io");
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: "other_tezos_wallets".tr(),
      ),
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
                    GestureDetector(
                      child: Container(
                        alignment: Alignment.center,
                        width: 180,
                        height: 180,
                        child: QrImageView(
                          data: "tezos://${widget.uri}",
                          size: 180.0,
                        ),
                      ),
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: "tezos://${widget.uri}"));
                        showInfoNotification(const Key("beacon_deeplink"),
                            "copied_to_clipboard".tr());
                      },
                    ),
                    const SizedBox(height: 60),
                    ExternalAppInfoView(
                        icon: Image.asset("assets/images/tezos_wallet.png"),
                        appName: "beacon".tr(),
                        status: "compatible".tr()),
                    const SizedBox(height: 15),
                    Text(
                      "sctl_if_your_wallet".tr(),
                      //"If your wallet is on another device, you can open it and scan the QR code below to link your account to Autonomy: ",
                      style: textStyle,
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: "sure_tz_support".tr(),
                          style: textStyle,
                        ),
                        TextSpan(
                          text: "beacon".tr(),
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
}
