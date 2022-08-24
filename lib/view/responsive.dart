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
}
