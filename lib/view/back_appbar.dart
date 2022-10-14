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
  final theme = Theme.of(context);
  
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: theme.colorScheme.secondary,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    leading: const SizedBox(),
    leadingWidth: 0.0,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      const SizedBox(width: 7),
                      Text(
                        backTitle,
                        style: theme.textTheme.button,
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(width: 60),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.button,
            textAlign: TextAlign.center,
          ),
        ),
        action != null
            ? IconButton(
                tooltip: "AppbarAction",
                constraints: const BoxConstraints(maxWidth: 36.0),
                onPressed: action,
                icon: Icon(
                  Icons.more_horiz,
                  color: theme.colorScheme.primary,
                ))
            : const SizedBox(width: 60),
      ],
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );
}

AppBar getCloseAppBar(BuildContext context,
    {String title = "", required Function()? onBack}) {
  final theme = Theme.of(context);

  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: theme.colorScheme.secondary,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    leading: const SizedBox(),
    leadingWidth: 0.0,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onBack,
          child: onBack != null
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(0, 7, 18, 8),
                  child: closeIcon(),
                )
              : const SizedBox(width: 60),
        ),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.button,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 60),
      ],
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );
}

AppBar getDefaultAppBar(BuildContext context,
    {String backTitle = "BACK",
      String title = "",
      required Function()? onBack,
      Function()? action,
      Widget? bottomWidget}) {
  final theme = Theme.of(context);
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: theme.colorScheme.secondary,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    leading: const SizedBox(),
    leadingWidth: 0.0,
    toolbarHeight: 34,
    title: Column(
      children: [
        const SizedBox(height: 24,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          const SizedBox(width: 7),
                          Text(
                            backTitle,
                            style: theme.textTheme.button,
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(width: 60),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.button,
                textAlign: TextAlign.center,
              ),
            ),
            action != null
                ? IconButton(
                tooltip: "AppbarAction",
                constraints: const BoxConstraints(maxWidth: 36.0),
                onPressed: action,
                icon: Icon(
                  Icons.more_horiz,
                  color: theme.colorScheme.primary,
                ))
                : const SizedBox(width: 60),
          ],
        ),
      ],
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );
}
