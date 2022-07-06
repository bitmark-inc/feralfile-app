//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const eulaURL =
    "https://github.com/bitmark-inc/autonomy.io/blob/gh-pages/apps/docs/eula.md";
const privacyURL =
    "https://github.com/bitmark-inc/autonomy.io/blob/gh-pages/apps/docs/privacy.md";

Widget eulaAndPrivacyView() {
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
        onTap: () => launch(eulaURL, forceSafariVC: true),
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
        onTap: () => launch(privacyURL, forceSafariVC: true),
      ),
    ],
  );
}
