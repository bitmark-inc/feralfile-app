//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class LinkBeaconConnectPage extends StatefulWidget {
  final String uri;

  const LinkBeaconConnectPage({Key? key, required this.uri}) : super(key: key);

  @override
  State<LinkBeaconConnectPage> createState() => _LinkBeaconConnectPageState();
}

class _LinkBeaconConnectPageState extends State<LinkBeaconConnectPage> {
  bool _copied = false;

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
                    Text(
                      "sctl_if_your_wallet".tr(),
                      //"If your wallet is on another device, you can open it and scan the QR code below to link your account to Autonomy: ",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      child: Container(
                        alignment: Alignment.center,
                        width: 180,
                        height: 180,
                        child: QrImage(
                          data: "tezos://${widget.uri}",
                          size: 180.0,
                        ),
                      ),
                      onTap: () {
                        Vibrate.feedback(FeedbackType.light);
                        Clipboard.setData(
                            ClipboardData(text: "tezos://${widget.uri}"));
                        setState(() {
                          _copied = true;
                        });
                      },
                    ),
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
}
