//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../util/constants.dart';

class ParticipateUserTestPage extends StatelessWidget {
  const ParticipateUserTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'user_test'.tr(),
        onBack: () => Navigator.of(context).pop(),
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
                    addTitleSpace(),
                    Text(
                      "like_to_test".tr(),
                      style: theme.textTheme.ppMori700Black24,
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Text(
                      "help_us_verify".tr(),
                      style: theme.textTheme.ppMori400Black16,
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColor.auSuperTeal,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "what_to_expect".tr(),
                            style: theme.textTheme.ppMori700Black14,
                          ),
                          const SizedBox(height: 12),
                          ...[
                            "user_test_will_1".tr(),
                            //'The user test will be conducted via Zoom.',
                            "user_test_will_2".tr(),
                            //'You should have a good Internet connection in a quiet area.',
                            "user_test_will_3".tr(),
                            //'You will be asked questions in English or French.',
                            "user_test_will_4".tr(),
                            //'You should already have NFTs on Ethereum, Tezos, or Bitmark chains.',
                            "user_test_will_5".tr(),
                            //'We may ask you to install a development build on your device.',
                          ]
                              .map(
                                (e) => Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      ' •  ',
                                      style: ResponsiveLayout.isMobile
                                          ? theme.textTheme.ppMori400Black14
                                          : theme.textTheme.ppMori400Black16,
                                      textAlign: TextAlign.start,
                                    ),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: ResponsiveLayout.isMobile
                                            ? theme.textTheme.ppMori400Black14
                                            : theme.textTheme.ppMori400Black16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: "schedule_test".tr(),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.inappWebviewPage,
                        arguments: InAppWebViewPayload(USER_TEST_CALENDAR_LINK),
                      );
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
