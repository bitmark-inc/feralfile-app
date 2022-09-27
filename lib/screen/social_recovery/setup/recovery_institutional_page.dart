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
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecoveryInstitutionalPage extends StatelessWidget {
  RecoveryInstitutionalPage({Key? key}) : super(key: key);

  final steps = [
    "Tap the button below to continue in your browser to https://feralfile.com.",
    "Feral File will link your code to an email address that you provide then send you a verification email to confirm your address.",
    "If you lose access to your device, Feral File will send your recovery code to your email address.",
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
              "Feral File works with curators, artists, and institutions to explore new ways of exhibiting and collecting digital art. As a trusted institutional collaborator, Feral File will safely keep your second recovery code.",
              style: theme.textTheme.bodyText1,
            ),
            const SizedBox(height: 40),
            Text(
              "HOW IT WORKS",
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
                  child: AuFilledButton(
                    text: "CONTINUE TO STEP 3".toUpperCase(),
                    onPress: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.recoveryInstitutionalVerifyPage);
                      launchUrl(Uri.parse(Environment.autonomyShardService),
                          mode: LaunchMode.externalApplication);
                    },
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
