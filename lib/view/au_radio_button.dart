//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AuRadio<T> extends StatelessWidget {
  final Function(T value) onTap;
  final T value;
  final T groupValue;
  final Color? color;

  const AuRadio({
    Key? key,
    required this.onTap,
    required this.value,
    required this.groupValue,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(value);
      },
      child: (value == groupValue)
          ? SvgPicture.asset(
              'assets/images/radio_true.svg',
              color: color,
            )
          : SvgPicture.asset(
              'assets/images/radio_false.svg',
              color: color,
            ),
    );
  }
}
