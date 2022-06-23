//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

AppBar getBackAppBar(BuildContext context,
    {String backTitle = "BACK",
    String title = "",
    required Function()? onBack,
    Function()? action}) {
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    leading: SizedBox(),
    leadingWidth: 0.0,
    automaticallyImplyLeading: true,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onBack,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
            child: Row(
              children: [
                if (onBack != null) ...[
                  Row(
                    children: [
                      SvgPicture.asset('assets/images/nav-arrow-left.svg'),
                      SizedBox(width: 7),
                      Text(
                        backTitle,
                        style: appTextTheme.caption,
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(width: 60),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: appTextTheme.caption,
            textAlign: TextAlign.center,
          ),
        ),
        action != null
            ? IconButton(
                constraints: BoxConstraints(maxWidth: 36.0),
                onPressed: action,
                icon: Icon(
                  Icons.more_horiz,
                  color: Colors.black,
                ))
            : SizedBox(width: 60),
      ],
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );
}

AppBar getCloseAppBar(BuildContext context,
    {String title = "", required Function()? onBack}) {
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    leading: SizedBox(),
    leadingWidth: 0.0,
    automaticallyImplyLeading: true,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onBack,
          child: onBack != null
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
                  child: SvgPicture.asset('assets/images/iconClose.svg'),
                )
              : SizedBox(width: 60),
        ),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: appTextTheme.caption,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: 60),
      ],
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );
}
