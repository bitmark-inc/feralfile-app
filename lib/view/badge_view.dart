//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class BadgeView extends StatelessWidget {
  final int number;
  const BadgeView({Key? key, required this.number}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        width: 29,
        height: 27,
        decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: AppColor.auQuickSilver)),
        alignment: Alignment.center,
        child: Text(
          number > 9 ? '9+' : '$number',
          textAlign: TextAlign.center,
          style: theme.textTheme.ppMori400White14.copyWith(
            color: AppColor.auQuickSilver,
          ),
        ));
  }
}
