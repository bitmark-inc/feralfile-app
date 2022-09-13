//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class BadgeView extends StatelessWidget {
  final int number;
  const BadgeView({Key? key, required this.number}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.secondary)),
        alignment: Alignment.center,
        child: Text(
          number > 9 ? '9+' : '$number',
          textAlign: TextAlign.center,
          style: theme.textTheme.atlasWhite.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.33,
          ),
        ));
  }
}
