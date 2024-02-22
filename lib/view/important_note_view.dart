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

  const ImportantNoteView({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.feralFileHighlight,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'important'.tr(),
            style: theme.textTheme.ppMori700Black14,
          ),
          const SizedBox(height: 15),
          Text(
            note,
            style: theme.textTheme.ppMori400Black14,
          ),
        ],
      ),
    );
  }
}
