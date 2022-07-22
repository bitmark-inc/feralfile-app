//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';

Widget eulaAndPrivacyView(BuildContext context) {
  final customLinkStyle = linkStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      GestureDetector(
        child: Text(
          "EULA",
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
        " and ",
        style: TextStyle(
            fontFamily: "AtlasGrotesk", fontSize: 12, color: Colors.black),
      ),
      GestureDetector(
        child: Text(
          "Privacy Policy",
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
