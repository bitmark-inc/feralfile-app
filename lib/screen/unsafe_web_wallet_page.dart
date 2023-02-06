//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_flutter/view/responsive.dart';

class UnsafeWebWalletPage extends StatelessWidget {
  const UnsafeWebWalletPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "extension_thread".tr(),
                style: theme.textTheme.displayLarge,
              ),
              addTitleSpace(),
              _contentWidget(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contentWidget(BuildContext context) {
    final theme = Theme.of(context);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyLarge,
        children: <TextSpan>[
          TextSpan(
            text: "web_wallet".tr(),
          ),
          TextSpan(
              text: "browser_ext_focus".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "general_focus".tr(),
          ),
          TextSpan(
              text: "browser_creep".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "similarly_attention".tr(),
          ),
          TextSpan(
              text: 'airdrop_scam'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              )),
          TextSpan(
              text: "browser_sandbox".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "poor_sandboxing".tr(),
          ),
          TextSpan(
              text: "browser_expose".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "security_flaws".tr(),
          ),
          TextSpan(
              text: "ext_safe".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "however_javascript".tr(),
          ),
          TextSpan(
              text: "browser_collect".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "flaws_poor".tr(),
          ),
          TextSpan(
              text: "browser_limit".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "browser_are_not_built_for".tr(),
          ),
          TextSpan(
              text: "browser_malicious".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "though_there_are".tr(),
          ),
          TextSpan(
              text: '49_browser_extensions'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              )),
          TextSpan(text: 'steal_crypto'.tr()),
          TextSpan(
              text: "browser_become_mal".tr(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text: "users_feel_safe".tr(),
          ),
          TextSpan(
            text: "app_safer".tr(),
          ),
        ],
      ),
    );
  }
}
