//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

Widget eulaAndPrivacyView(BuildContext context) {
  final theme = Theme.of(context);
  final customLinkStyle = theme.textTheme.linkStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        child: Text(
          "eula".tr(),
          style: customLinkStyle,
        ),
        onTap: () => Navigator.of(context)
            .pushNamed(AppRouter.githubDocPage, arguments: {
          "prefix": "/bitmark-inc/autonomy.io/main/apps/docs/",
          "document": "eula.md",
          "title": ""
        }),
      ),
      Text(
        "_and".tr(),
        style: theme.textTheme.headline5,
      ),
      GestureDetector(
        child: Text(
          "privacy_policy".tr(),
          style: customLinkStyle,
        ),
        onTap: () => Navigator.of(context)
            .pushNamed(AppRouter.githubDocPage, arguments: {
          "prefix": "/bitmark-inc/autonomy.io/main/apps/docs/",
          "document": "privacy.md",
          "title": ""
        }),
      ),
    ],
  );
}
