//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Widget privacyView(BuildContext context) {
  final theme = Theme.of(context);
  final customLinkStyle = theme.textTheme.linkStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  final Uri uri = Uri.parse(AUTONOMY_CLIENT_GITHUB_LINK);

  return Column(
    children: [
      Column(
        children: [
          Text(
            'believe_transparency'.tr(),
            style: theme.textTheme.atlasBlackBold14,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'autonomy_is_'.tr(),
                style: theme.textTheme.atlasBlackNormal14,
              ),
              GestureDetector(
                child: Text(
                  'open_source'.tr(),
                  style: customLinkStyle.copyWith(fontSize: 14),
                ),
                onTap: () => unawaited(
                    launchUrl(uri, mode: LaunchMode.externalApplication)),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      GestureDetector(
        child: Text(
          'privacy_policy'.tr(),
          style: customLinkStyle.copyWith(fontSize: 14),
        ),
        onTap: () => unawaited(Navigator.of(context)
            .pushNamed(AppRouter.githubDocPage, arguments: {
          'prefix': '/bitmark-inc/autonomy.io/main/apps/docs/',
          'document': 'privacy.md',
          'title': ''
        })),
      ),
    ],
  );
}
