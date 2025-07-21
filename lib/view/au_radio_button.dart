//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AuRadio<T> extends StatelessWidget {
  const AuRadio({
    required this.onTap,
    required this.value,
    required this.groupValue,
    super.key,
    this.color,
  });

  final Function(T value) onTap;
  final T value;
  final T groupValue;
  final Color? color;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          onTap(value);
        },
        child: (value == groupValue)
            ? SvgPicture.asset(
                'assets/images/radio_selected.svg',
                colorFilter: color != null
                    ? ColorFilter.mode(color!, BlendMode.srcIn)
                    : null,
              )
            : SvgPicture.asset(
                'assets/images/radio_unselected.svg',
                colorFilter: color != null
                    ? ColorFilter.mode(color!, BlendMode.srcIn)
                    : null,
              ),
      );
}
