//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_flutter/view/responsive.dart';

class BeOwnGalleryPage extends StatelessWidget {
  const BeOwnGalleryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsetsWithSubmitButton,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "own_gallery_tt".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "own_gallery_body".tr(),
                      style: theme.textTheme.bodyText1,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "not_purchase".tr(),
                      //"It is not possible to purchase NFTs in this app.",
                      style: theme.textTheme.headline4,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "continue".tr().toUpperCase(),
                    onPress: () async {
                      if (await injector<IAPService>().isSubscribed()) {
                        await newAccountPageOrSkipInCondition(context);
                      } else {
                        await Navigator.of(context)
                            .pushNamed(AppRouter.moreAutonomyPage);
                      }
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
