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
      {Key? key,
      this.leftWidget,
      this.rightWidget,
      required this.onTap,
      this.forwardIcon,
      this.padding = const EdgeInsets.symmetric(vertical: 16)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: _contentRow(),
    );
  }

  Widget _contentRow() {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: leftWidget ?? const SizedBox()),
          Row(
            children: [
              rightWidget ?? const SizedBox(),
              if (onTap != null) ...[
                const SizedBox(width: 8.0),
                forwardIcon ??
                    SvgPicture.asset('assets/images/iconForward.svg'),
              ],
            ],
          )
        ],
      ),
    );
  }
}

class TappableForwardRowWithContent extends StatelessWidget {
  final Widget leftWidget;
  final Widget? rightWidget;
  final Widget bottomWidget;
  final Function()? onTap;

  const TappableForwardRowWithContent(
      {Key? key,
      required this.leftWidget,
      this.rightWidget,
      required this.bottomWidget,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: _content(),
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _contentRow(),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: bottomWidget)]),
        ],
      ),
    );
  }

  Widget _contentRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: leftWidget),
        Row(
          children: [
            rightWidget ?? const SizedBox(),
            if (onTap != null) ...[
              const SizedBox(width: 8.0),
              SvgPicture.asset('assets/images/iconForward.svg'),
            ],
          ],
        )
      ],
    );
  }
}
