//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RestoreInstitutionalPage extends StatelessWidget {
  RestoreInstitutionalPage({Key? key}) : super(key: key);

  final steps = [
    "Tap the button below to request your recovery code from https://feralfile.com",
    "Feral File will ask you to enter the email address you used to set up collaborative recovery",
    "Feral File will email your recovery code.",
    "Copy the recovery code from the email then return here and paste it into Autonomy.",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getTrailingCloseAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "STEP 2 OF 3",
              style: theme.textTheme.headline3,
            ),
            Text(
              "Institutional collaborator",
              style: theme.textTheme.headline2,
            ),
            const SizedBox(height: 40),
            Text(
              "Feral File is your institutional collaborator. ",
              style: theme.textTheme.bodyText1,
            ),
            const SizedBox(height: 40),
            Text(
              "HOW TO GET YOUR CODE",
              style: theme.textTheme.headline4,
            ),
            const SizedBox(height: 8),
            ...steps
                .mapIndexed(
                  (index, e) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ' ${index + 1}. ',
                        style: theme.textTheme.bodyText1,
                        textAlign: TextAlign.start,
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyText1,
                            children: <TextSpan>[
                              TextSpan(
                                text: e,
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.atlasBlackNormal14
                                    : theme.textTheme.atlasBlackNormal16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
            const Expanded(child: SizedBox()),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AuFilledButton(
                        text: "REQUEST SECOND RECOVERY CODE ".toUpperCase(),
                        onPress: () {
                          Navigator.of(context).pushNamed(
                              AppRouter.restoreInstitutionalVerifyPage);
                          launchUrl(Uri.parse(Environment.autonomyShardService),
                              mode: LaunchMode.externalApplication);
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                              AppRouter.restorePersonalPage);
                        },
                        child: Text(
                          "CONTINUE WITHOUT PLATFORM CODE",
                          style: theme.textTheme.button,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
