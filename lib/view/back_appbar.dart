//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

AppBar getBackAppBar(
  BuildContext context, {
  required Function()? onBack,
  String backTitle = 'BACK',
  String title = '',
  TextStyle? titleStyle,
  Widget? icon,
  Widget? titleIcon,
  Function()? action,
  List<Widget>? actions,
  bool isWhite = true,
  bool withDivider = true,
  Color? backgroundColor,
  Color? statusBarColor,
}) {
  final theme = Theme.of(context);

  final primaryColor = isWhite ? AppColor.primaryBlack : AppColor.white;
  final secondaryColor = isWhite ? AppColor.white : AppColor.primaryBlack;
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? backgroundColor ?? secondaryColor,
        statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
        statusBarBrightness: isWhite ? Brightness.light : Brightness.dark),
    centerTitle: true,
    leadingWidth: 44,
    leading: onBack != null
        ? Semantics(
            label: 'BACK',
            child: IconButton(
              onPressed: onBack,
              constraints: const BoxConstraints(maxWidth: 36),
              icon: SvgPicture.asset(
                'assets/images/icon_back.svg',
                colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              ),
            ),
          )
        : const SizedBox(width: 36),
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (titleIcon != null) ...[titleIcon, const SizedBox(width: 10)],
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: titleStyle ??
              theme.textTheme.ppMori400Black16.copyWith(color: primaryColor),
          textAlign: TextAlign.center,
        ),
      ],
    ),
    actions: [
      ...actions ?? [],
      if (action != null)
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: IconButton(
            tooltip: 'AppbarAction',
            constraints: const BoxConstraints(maxWidth: 36),
            onPressed: action,
            icon: icon ??
                Icon(
                  Icons.more_horiz,
                  color: primaryColor,
                ),
          ),
        )
      else
        const SizedBox(width: 36),
    ],
    backgroundColor: backgroundColor ?? Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: withDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: addOnlyDivider(
                color: isWhite ? null : AppColor.auGreyBackground),
          )
        : null,
  );
}

AppBar getTitleEditAppBar(BuildContext context,
    {required TextEditingController controller,
    required FocusNode focusNode,
    required Function(String value) onSubmit,
    String backTitle = 'BACK',
    bool hasBack = true,
    Widget? icon,
    Widget? titleIcon,
    bool hasAction = true,
    bool isWhite = true}) {
  final theme = Theme.of(context);

  final primaryColor = isWhite ? AppColor.auGrey : AppColor.white;
  final secondaryColor = isWhite ? AppColor.white : AppColor.primaryBlack;
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: secondaryColor,
        statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
        statusBarBrightness: isWhite ? Brightness.light : Brightness.dark),
    centerTitle: true,
    leadingWidth: 44,
    leading: hasBack
        ? Semantics(
            label: 'BACK',
            child: IconButton(
              onPressed: () {},
              constraints: const BoxConstraints(maxWidth: 36),
              icon: SvgPicture.asset(
                'assets/images/icon_back.svg',
                colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              ),
            ),
          )
        : const SizedBox(),
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (titleIcon != null) ...[titleIcon, const SizedBox(width: 10)],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: TextField(
            autocorrect: false,
            focusNode: focusNode,
            controller: controller,
            style: theme.textTheme.ppMori700Black16,
            onSubmitted: onSubmit,
            decoration: null,
          ),
        ),
      ],
    ),
    actions: [
      if (hasAction)
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: IconButton(
            tooltip: 'AppbarAction',
            constraints: const BoxConstraints(maxWidth: 36),
            onPressed: () {},
            icon: icon ??
                Icon(
                  Icons.more_horiz,
                  color: primaryColor,
                ),
          ),
        )
    ],
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: addOnlyDivider(color: isWhite ? null : AppColor.auGreyBackground),
    ),
  );
}

AppBar getCloseAppBar(
  BuildContext context, {
  required Function()? onClose,
  String title = '',
  TextStyle? titleStyle,
  Widget? icon,
  Widget? disableIcon,
  bool withBottomDivider = true,
  bool isWhite = true,
  Color? statusBarColor,
  bool isTitleCenter = true,
}) {
  final theme = Theme.of(context);
  final primaryColor = isWhite ? AppColor.primaryBlack : AppColor.white;
  final secondaryColor = isWhite ? AppColor.white : AppColor.primaryBlack;
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: statusBarColor ?? secondaryColor,
      statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
      statusBarBrightness: isWhite ? Brightness.light : Brightness.dark,
    ),
    centerTitle: isTitleCenter,
    automaticallyImplyLeading: false,
    title: Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: titleStyle ??
          theme.textTheme.ppMori400Black16.copyWith(color: primaryColor),
      textAlign: TextAlign.center,
    ),
    actions: [
      if (onClose != null)
        IconButton(
          tooltip: 'CLOSE',
          onPressed: onClose,
          icon: icon ?? closeIcon(color: primaryColor),
        )
      else
        IconButton(onPressed: () {}, icon: disableIcon ?? const SizedBox()),
    ],
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    bottom: withBottomDivider
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: addOnlyDivider(
                color: isWhite ? null : AppColor.auGreyBackground),
          )
        : null,
  );
}

AppBar getDarkEmptyAppBar() => AppBar(
      systemOverlayStyle: systemUiOverlayDarkStyle,
      toolbarHeight: 0,
      shadowColor: Colors.transparent,
      elevation: 0,
    );

AppBar getLightEmptyAppBar([Color? statusBarColor]) => AppBar(
      systemOverlayStyle: systemUiOverlayLightStyle(statusBarColor),
      backgroundColor: Colors.transparent,
      toolbarHeight: 0,
      shadowColor: Colors.transparent,
      elevation: 0,
    );

SystemUiOverlayStyle get systemUiOverlayDarkStyle => const SystemUiOverlayStyle(
      statusBarColor: AppColor.primaryBlack,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

SystemUiOverlayStyle systemUiOverlayLightStyle(Color? statusBarColor) =>
    SystemUiOverlayStyle(
      statusBarColor: statusBarColor ?? AppColor.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    );

AppBar getDoneAppBar(
  BuildContext context, {
  required String title,
  Function()? onDone,
  Function()? onCancel,
  PreferredSize? bottom,
  bool isWhite = true,
}) {
  final theme = Theme.of(context);
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: isWhite ? AppColor.white : AppColor.primaryBlack,
      statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
      statusBarBrightness: isWhite ? Brightness.light : Brightness.dark,
    ),
    elevation: 1,
    shadowColor: Colors.transparent,
    leadingWidth: 80,
    leading: GestureDetector(
      onTap: onCancel,
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Center(
          child: Text(
            tr('cancel'),
            style: theme.textTheme.ppMori400Black14,
          ),
        ),
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 14),
        child: GestureDetector(
          onTap: onDone,
          child: Center(
            child: Text(
              tr('done'),
              style: (onDone != null)
                  ? theme.textTheme.ppMori700Black14
                  : theme.textTheme.ppMori700Black14
                      .copyWith(color: AppColor.disabledColor),
            ),
          ),
        ),
      ),
    ],
    backgroundColor: theme.colorScheme.background,
    automaticallyImplyLeading: false,
    centerTitle: true,
    title: Text(
      title,
      style: theme.textTheme.ppMori400Black14,
    ),
    bottom: bottom,
  );
}

AppBar getCustomDoneAppBar(
  BuildContext context, {
  required Widget title,
  Function()? onDone,
  Function()? onCancel,
  PreferredSize? bottom,
  bool isWhite = true,
}) {
  final theme = Theme.of(context);
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: isWhite ? AppColor.white : AppColor.primaryBlack,
      statusBarIconBrightness: isWhite ? Brightness.dark : Brightness.light,
      statusBarBrightness: isWhite ? Brightness.light : Brightness.dark,
    ),
    shadowColor: Colors.transparent,
    elevation: 1,
    leadingWidth: 80,
    leading: GestureDetector(
      onTap: onCancel,
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Center(
          child: Text(
            tr('cancel'),
            style: theme.textTheme.ppMori400Black14,
          ),
        ),
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 14),
        child: GestureDetector(
          onTap: onDone,
          child: Center(
            child: Text(
              tr('done'),
              style: (onDone != null)
                  ? theme.textTheme.ppMori700Black14
                  : theme.textTheme.ppMori700Black14
                      .copyWith(color: AppColor.disabledColor),
            ),
          ),
        ),
      ),
    ],
    backgroundColor: theme.colorScheme.background,
    automaticallyImplyLeading: false,
    centerTitle: true,
    title: title,
    bottom: bottom,
  );
}

AppBar getFFAppBar(
  BuildContext context, {
  required Function()? onBack,
  Widget? title,
  Widget? action,
}) {
  const secondaryColor = AppColor.primaryBlack;
  return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: secondaryColor,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark),
      centerTitle: true,
      leadingWidth: 44,
      leading: onBack != null
          ? Semantics(
              label: 'BACK',
              child: IconButton(
                constraints: const BoxConstraints(maxWidth: 34),
                onPressed: onBack,
                icon: SvgPicture.asset(
                  'assets/images/ff_back_dark.svg',
                ),
              ))
          : const SizedBox(width: 36),
      automaticallyImplyLeading: false,
      title: title,
      actions: [
        if (action != null) action else const SizedBox(width: 36),
      ],
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0);
}

// class MomaPallet to save colors
// Path: lib/util/style.dart
