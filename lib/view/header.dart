//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class HeaderView extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final Widget? action;
  final EdgeInsets? padding;

  const HeaderView({
    required this.title,
    this.titleStyle,
    this.padding,
    super.key,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        theme.textTheme.ppMori700White24.copyWith(fontSize: 36);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: padding ?? const EdgeInsets.fromLTRB(12, 33, 12, 42),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle ?? defaultStyle,
                  ),
                ),
                action ?? const SizedBox()
              ],
            ),
          ],
        ),
      ),
    );
  }
}
