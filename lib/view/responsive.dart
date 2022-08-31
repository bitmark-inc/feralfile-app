//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/util/constants.dart';
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
      AutonomyApp.maxWidth < Constants.kTabletBreakpoint;

  static bool get isTablet =>
      AutonomyApp.maxWidth < Constants.kDesktopBreakpoint &&
      AutonomyApp.maxWidth >= Constants.kTabletBreakpoint;

  static bool get isDesktop =>
      AutonomyApp.maxWidth >= Constants.kDesktopBreakpoint;

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
  static double get padding => isMobile
      ? 14
      : isTablet
          ? 20
          : 30;

  static EdgeInsets get pageEdgeInsets => EdgeInsets.only(
        top: padding,
        left: padding,
        right: padding,
        bottom: 20.0,
      );
  static EdgeInsets get pageEdgeInsetsWithSubmitButton => EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        32,
      );
  static EdgeInsets get pageEdgeInsetsNotBottom => EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        0,
      );
}
