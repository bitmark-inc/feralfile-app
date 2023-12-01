//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TappableForwardRow extends StatelessWidget {
  final Widget? leftWidget;
  final Widget? rightWidget;
  final Function()? onTap;
  final EdgeInsets padding;
  final Widget? forwardIcon;

  const TappableForwardRow(
      {required this.onTap,
      super.key,
      this.leftWidget,
      this.rightWidget,
      this.forwardIcon,
      this.padding = const EdgeInsets.symmetric(vertical: 16)});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: _contentRow(),
      );

  Widget _contentRow() => Padding(
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: leftWidget ?? const SizedBox()),
            Row(
              children: [
                rightWidget ?? const SizedBox(),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  forwardIcon ??
                      SvgPicture.asset('assets/images/iconForward.svg'),
                ],
              ],
            )
          ],
        ),
      );
}

class TappableForwardRowWithContent extends StatelessWidget {
  final Widget leftWidget;
  final Widget? rightWidget;
  final Widget bottomWidget;
  final Function()? onTap;
  final EdgeInsets padding;

  const TappableForwardRowWithContent(
      {required this.leftWidget,
      required this.bottomWidget,
      required this.onTap,
      super.key,
      this.rightWidget,
      this.padding = const EdgeInsets.symmetric(vertical: 16)});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: _content(),
      );

  Widget _content() => Padding(
        padding: padding,
        child: Column(
          children: [
            _contentRow(),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: bottomWidget)]),
          ],
        ),
      );

  Widget _contentRow() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: leftWidget),
          Row(
            children: [
              rightWidget ?? const SizedBox(),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                SvgPicture.asset('assets/images/iconForward.svg'),
              ],
            ],
          )
        ],
      );
}
