//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class BottomLink extends StatelessWidget {
  final String name;
  final String tag;
  final Function()? onTap;

  const BottomLink(
      {Key? key, required this.name, required this.tag, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: theme.textTheme.ppMori400Green12,
          ),
          Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: AppColor.greyMedium,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(64))),
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(tag, style: theme.textTheme.ppMori400Grey12),
          )
        ],
      ),
    );
  }
}
