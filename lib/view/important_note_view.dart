//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ImportantNoteView extends StatelessWidget {
  final String note;
  final String? title;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final TextStyle? noteStyle;

  const ImportantNoteView({
    required this.note,
    super.key,
    this.title,
    this.backgroundColor,
    this.titleStyle,
    this.noteStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColor.feralFileHighlight,
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'important'.tr(),
            style: titleStyle ?? theme.textTheme.ppMori700Black14,
          ),
          const SizedBox(height: 15),
          Text(
            note,
            style: noteStyle ?? theme.textTheme.ppMori400Black14,
          ),
        ],
      ),
    );
  }
}
