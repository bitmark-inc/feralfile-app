//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:share_plus/share_plus.dart';

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
        margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payload.type == CryptoType.ETH
                  ? "receive_eth".tr()
                  : "receive_xtz".tr(),
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
                    "deposit_address".tr(),
                    style: ResponsiveLayout.isMobile
                        ? theme.textTheme.atlasGreyBold12
                        : theme.textTheme.atlasGreyBold14,
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
                    text: "share".tr(),
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
