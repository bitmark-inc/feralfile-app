//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class LinkTezosKukaiPage extends StatelessWidget {
  const LinkTezosKukaiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tezosBeaconService = injector<TezosBeaconService>();

    return Scaffold(
        appBar: getBackAppBar(
          context,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Container(
          margin: pageEdgeInsetsWithSubmitButton,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Linking to Kukai",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "Since Kukai only exists as a web wallet, you will need to follow these additional steps to link it to Autonomy: ",
                      style: appTextTheme.bodyText1,
                    ),
                    SizedBox(height: 20),
                    _stepWidget('1',
                        'Generate a link request and send it to the web browser where you are currently signed in to Kukai.'),
                    SizedBox(height: 10),
                    _stepWidget('2',
                        'When prompted by Kukai, approve Autonomy’s permissions requests. '),
                    SizedBox(height: 40),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: wantMoreSecurityWidget(
                                  context, WalletApp.Kukai))
                        ]),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "GENERATE LINK".toUpperCase(),
                    onPress: () async {
                      final uri = await tezosBeaconService.getConnectionURI();
                      Share.share("https://wallet.kukai.app/tezos$uri");
                    },
                  ),
                ),
              ],
            ),
          ]),
        ));
  }

  Widget _stepWidget(String stepNumber, String stepGuide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            stepNumber,
            style: appTextTheme.caption,
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(stepGuide, style: appTextTheme.bodyText1),
        )
      ],
    );
  }
}
