//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/view/title_text.dart';
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
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: padding ?? const EdgeInsets.fromLTRB(12, 33, 12, 42),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TitleText(
                      title: title,
                      style: titleStyle,
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
