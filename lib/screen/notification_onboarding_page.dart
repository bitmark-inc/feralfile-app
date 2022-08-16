//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationOnboardingPage extends StatelessWidget {
  const NotificationOnboardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: null,
      ),
      body: Container(
        margin: const EdgeInsets.only(
            top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Notifications",
                      style: theme.textTheme.headline1,
                    ),
                    const SizedBox(height: 30),
                    Markdown(
                      data: '''
**Grant Autonomy permission to notify you when:** 
* An NFT is added to your collection or someone sends you an NFT
* You receive a signing requests from a dapp or service (coming soon)
* You receive a customer support message 
''',
                      softLineBreak: true,
                      padding: const EdgeInsets.only(bottom: 50),
                      shrinkWrap: true,
                      styleSheet:
                          markDownLightStyle(context).copyWith(blockSpacing: 8),
                    ),
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 25),
                      child: SvgPicture.asset(
                          'assets/images/notification_onboarding.svg'),
                    ))
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuFilledButton(
                  text: "ENABLE NOTIFICATIONS".toUpperCase(),
                  onPress: () async {
                    if (Platform.isIOS &&
                        !await OneSignal.shared
                            .promptUserForPushNotificationPermission()) {
                      return;
                    }
                    Navigator.of(context).pop();
                    registerPushNotifications();
                  },
                ),
                TextButton(
                  onPressed: () {
                    injector<ConfigurationService>()
                        .setNotificationEnabled(false);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "NOT NOW",
                    style: theme.textTheme.button,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
