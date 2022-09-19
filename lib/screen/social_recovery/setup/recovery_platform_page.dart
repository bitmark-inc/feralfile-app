//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecoveryPlatformPage extends StatelessWidget {
  const RecoveryPlatformPage({Key? key}) : super(key: key);

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
              "STEP 1 OF 3",
              style: theme.textTheme.headline3,
            ),
            Text(
              "Platform collaborator",
              style: theme.textTheme.headline2,
            ),
            const SizedBox(height: 40),
            Text(
              "Apple is your platform collaborator. Autonomy has securely stored your first recovery code in your iCloud keychain.",
              style: theme.textTheme.bodyText1,
            ),
            const Expanded(child: SizedBox()),
            Center(
              child: SvgPicture.asset("assets/images/icloudKeychainGuide.svg"),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "CONTINUE TO STEP 2".toUpperCase(),
                    onPress: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.recoveryInstitutionalPage);
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
