//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';

class AutonomyButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 14;

    Path path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - radius)
      ..lineTo(size.width - radius, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AutonomyTopRightRectangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 14;

    Path path = Path()
      ..lineTo(0, 0)
      ..lineTo(size.width - radius, 0)
      ..lineTo(size.width, radius)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AutonomyOutlineButtonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 14;
    double border = 2;

    Path path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - radius)
      ..lineTo(size.width - radius, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, border)
      ..lineTo(border, border)
      ..lineTo(border, size.height - border)
      ..lineTo(size.width - radius - 1, size.height - border)
      ..lineTo(size.width - border, size.height - radius - 1)
      ..lineTo(size.width - border, border)
      ..lineTo(0, border)
      ..lineTo(0, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
