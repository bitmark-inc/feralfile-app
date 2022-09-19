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

class RecoveryIntroductionPage extends StatelessWidget {
  const RecoveryIntroductionPage({Key? key}) : super(key: key);

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
                      "Set up collaborative recovery",
                      style: theme.textTheme.headline2,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "A network of 3 collaborators will help you restore access if you lose your device. Each collaborator is given a recovery code. A single code by itself is useless, but combining any 2 of your 3 codes allows you to restore access to Autonomy. \n\nWe will help you store your 3 codes with: \n\n 1.  A platform collaborator\n 2. An institutional collaborator\n 3. A personal collaborator",
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
                    text: "Set up".toUpperCase(),
                    onPress: () {
                      Navigator.of(context)
                          .pushNamed(AppRouter.recoveryPlatformPage);
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
