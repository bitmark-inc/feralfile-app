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

class RestoreIntroductionPage extends StatelessWidget {
  const RestoreIntroductionPage({Key? key}) : super(key: key);

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
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Restore from collaborative recovery",
                      style: theme.textTheme.headline2,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "Your network of 3 collaborators will help you restore access. Only 2 codes are necessary to restore your access.\n\nAutonomy will attempt to retrieve your recovery codes in the following order:\n\n 1. Platform collaborator\n 2. Institutional collaborator\n 3. Personal collaborator",
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child:
                          SvgPicture.asset("assets/images/setup_recovery.svg"),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "INITIATE RECOVERY".toUpperCase(),
                    onPress: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.restorePlatformPage);
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
