//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  static bool get isMobile =>
      AutonomyApp.maxWidth < Constants.kTabletBreakpoint ||
      DeviceInfo.instance.isPhone;

  static bool get isTablet =>
      AutonomyApp.maxWidth < Constants.kDesktopBreakpoint &&
      AutonomyApp.maxWidth >= Constants.kTabletBreakpoint &&
      !DeviceInfo.instance.isPhone;

  static bool get isDesktop =>
      AutonomyApp.maxWidth >= Constants.kDesktopBreakpoint &&
      !DeviceInfo.instance.isPhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isMobile
          ? mobile
          : isTablet
              ? tablet ?? mobile
              : desktop ?? tablet ?? mobile,
    );
  }

  static EdgeInsets get getPadding => isMobile
      ? Constants.paddingMobile
      : isTablet
          ? Constants.paddingTablet
          : Constants.paddingTabletLandScape;

  static double get paddingVertical => isMobile
      ? 12
      : isTablet
          ? 20
          : 30;

  static double get paddingHorizontal => isMobile
      ? 12
      : isTablet
          ? 20
          : 30;

  static EdgeInsets get pageEdgeInsets => EdgeInsets.only(
        top: paddingVertical,
        left: paddingVertical,
        right: paddingVertical,
      );

  static EdgeInsets get pageEdgeInsetsWithSubmitButton => EdgeInsets.fromLTRB(
        paddingVertical,
        paddingVertical,
        paddingVertical,
        32,
      );

  static EdgeInsets get pageHorizontalEdgeInsetsWithSubmitButton =>
      EdgeInsets.fromLTRB(
        paddingVertical,
        0,
        paddingVertical,
        32,
      );

  static EdgeInsets get pageEdgeInsetsNotBottom => EdgeInsets.fromLTRB(
        paddingVertical,
        paddingVertical,
        paddingVertical,
        0,
      );

  static EdgeInsets get tappableForwardRowEdgeInsets => EdgeInsets.fromLTRB(
        paddingVertical,
        20,
        paddingVertical,
        20,
      );

  static EdgeInsets get pageHorizontalEdgeInsets =>
      EdgeInsets.symmetric(horizontal: paddingHorizontal);
  static EdgeInsets get paddingAll => EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      );
}
