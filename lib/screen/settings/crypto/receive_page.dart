//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class ReceivePage extends StatelessWidget {
  static const String tag = 'receive';

  final WalletPayload payload;

  const ReceivePage({Key? key, required this.payload}) : super(key: key);

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
        margin: pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Receive ${payload.type == CryptoType.ETH ? "ETH" : "XTZ"}",
              style: theme.textTheme.headline1,
            ),
            const SizedBox(height: 96),
            Center(
              child: QrImage(
                data: payload.address,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.centerLeft,
              color: const Color(0x44EDEDED),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deposit address",
                    style: theme.textTheme.atlasGreyBold12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      payload.address,
                      textAlign: TextAlign.start,
                      softWrap: true,
                      style: theme.textTheme.subtitle2,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "Share",
                    onPress: () {
                      Share.share(payload.address);
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class WalletPayload {
  final CryptoType type;
  final String address;

  WalletPayload(this.type, this.address);
}
