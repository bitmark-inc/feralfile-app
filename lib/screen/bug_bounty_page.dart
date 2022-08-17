//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class BugBountyPage extends StatelessWidget {
  const BugBountyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Map<String, String> guidelines = {
      "critical".tr():
      "guidelines_critical".tr(),//"Key leaks or invalid transactions resulting in asset loss: Up to \$5,000",
      "high".tr(): "guidelines_high".tr(),// "Crashes or user data loss: \$100 - \$500",
      "medium".tr():"guidelines_medium".tr(),
          //"Incorrect flows or incompatibility with protocol or dapps: \$50 - \$100",
      "low".tr(): "guidelines_low".tr(),// "UI typos, alignment errors: \$10 - \$50",
    };

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsetsNotBottom,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "bug_bounty".tr(),
                style: theme.textTheme.headline1,
              ),
              addTitleSpace(),
              Text(
                "we_value_feedback".tr(),
                //"We greatly value feedback from our customers and the work done by security researchers in improving the usability and security of Autonomy. We are committed to quickly verify, reproduce, and respond to legitimate reported interface issues and vulnerabilities. ",
                style: theme.textTheme.bodyText1,
              ),
              const SizedBox(height: 32),
              Text('Scope'.tr(), style: theme.textTheme.headline4),
              const SizedBox(height: 16),
              RichText(
                  text: TextSpan(
                      style: theme.textTheme.bodyText1,
                      children: <TextSpan>[
                    TextSpan(
                      text:
                          "only_accept_new_bug".tr(),
                          //'We only accept new bug reports for our iPhone or Android Apps; please check our ',
                    ),
                    TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                                Uri.parse(KNOWN_BUGS_LINK),
                                mode: LaunchMode.externalApplication,
                              ),
                        text: 'known_bugs'.tr(),
                        style: theme.textTheme.linkStyle),
                    TextSpan(
                      text:
                          "not_reward_yet".tr(),
                          //' before submitting. Bug reports for web applications or any other projects are out of scope and will not be considered for rewards.',
                    ),
                  ])),
              const SizedBox(height: 32),
              Text('rewards'.tr(), style: theme.textTheme.headline4),
              Text(
                "reward_ranging".tr(),
                //'We pay rewards ranging from \$10 to \$5,000, administered according to the following guidelines:',
                style: theme.textTheme.bodyText1,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                color: AppColor.secondaryDimGreyBackground,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'guidelines'.tr(),
                      style: theme.textTheme.atlasDimgreyBold14,
                    ),
                    const SizedBox(height: 5),
                    ...guidelines.keys
                        .map(
                          (e) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ' •  ',
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
                                        style:
                                            theme.textTheme.atlasBlackNormal14,
                                      ),
                                      TextSpan(
                                        text: " – ${guidelines[e]!}",
                                        style:
                                            theme.textTheme.atlasBlackNormal14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'rewards_in_usdc'.tr(),
                style: theme.textTheme.bodyText1,
              ),
              const SizedBox(height: 32),
              Text('disclosure_policy'.tr(), style: theme.textTheme.headline4),
              const SizedBox(height: 16),
              Text(
                "support_publication".tr(),
                  //'We support the open publication of security research. We do ask that you give us a heads-up before any publication so we can do a final sync-up and check. ',
                  style: theme.textTheme.bodyText1),
              const SizedBox(height: 56),
              AuFilledButton(
                text: "report_a_bug".tr().toUpperCase(),
                onPress: () => Navigator.of(context).pushNamed(
                    AppRouter.supportThreadPage,
                    arguments:
                        NewIssuePayload(reportIssueType: ReportIssueType.Bug)),
              ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}
