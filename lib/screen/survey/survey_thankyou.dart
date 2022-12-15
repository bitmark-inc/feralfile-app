//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SurveyThankyouPage extends StatelessWidget {
  static const String tag = 'survey_thankyou';

  const SurveyThankyouPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: null,
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "thank_you".tr(),
              style: theme.textTheme.headline1,
            ),
            const SizedBox(height: 40.0),
            Text("entered_drawing".tr(),
                //"You’ve been automatically entered in this month’s drawing to win a Feral File artwork. If you win, we’ll transfer the NFT to your Autonomy account and notify you.",
                style: theme.textTheme.bodyText1),
            const Spacer(),
            AuFilledButton(
                text: "continue".tr(),
                onPress: () => Navigator.of(context).popUntil((route) =>
                    route.settings.name == AppRouter.homePage ||
                    route.settings.name == AppRouter.homePageNoTransition)),
            const SizedBox(height: 27.0),
          ],
        ),
      ),
    );
  }
}
