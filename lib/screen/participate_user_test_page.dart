//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
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
                      "p_user_test".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    Text(
                      "like_to_test".tr(),
                      /*"""
Do you like to test new things?\n
Help us verify new designs and features, and we will pay you \$50 in USDC for 30 minutes of your time. \n
What to expect:
""",*/
                      style: theme.textTheme.bodyText1,
                    ),
                    ...[
                      "user_test_will_1".tr(),//'The user test will be conducted via Zoom.',
                      "user_test_will_2".tr(),//'You should have a good Internet connection in a quiet area.',
                      "user_test_will_3".tr(),//'You will be asked questions in English or French.',
                      "user_test_will_4".tr(),//'You should already have NFTs on Ethereum, Tezos, or Bitmark chains.',
                      "user_test_will_5".tr(),//'We may ask you to install a development build on your device.',
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
                    text: "schedule_test".tr().toUpperCase(),
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
