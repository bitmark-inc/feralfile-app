//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/constants.dart';

class ParticipateUserTestPage extends StatelessWidget {
  const ParticipateUserTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      "Participate in a user test",
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      """
Do you like to test new things?\n
Help us verify new designs and features, and we will pay you \$50 in USDC for 30 minutes of your time. \n
What to expect:
""",
                      style: theme.textTheme.bodyText1,
                    ),
                    ...[
                      'The user test will be conducted via Zoom.',
                      'You should have a good Internet connection in a quiet area.',
                      'You will be asked questions in English or French.',
                      'You should already have NFTs on Ethereum, Tezos, or Bitmark chains.',
                      'We may ask you to install a development build on your device.',
                    ]
                        .map((e) => Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ' •  ',
                                    style: theme.textTheme.bodyText1,
                                    textAlign: TextAlign.start,
                                  ),
                                  Expanded(
                                    child: Text(e,
                                        style: theme.textTheme.bodyText1),
                                  ),
                                ]))
                        .toList(),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "SCHEDULE YOUR USER TEST".toUpperCase(),
                    onPress: () => launchUrl(Uri.parse(USER_TEST_CALENDAR_LINK),
                        mode: LaunchMode.inAppWebView),
                  ),
                ),
              ],
            ),
          ]),
        ));
  }
}
