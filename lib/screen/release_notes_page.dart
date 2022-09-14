//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ReleaseNotesPage extends StatefulWidget {
  final String releaseNotes;
  const ReleaseNotesPage({required this.releaseNotes, Key? key})
      : super(key: key);

  @override
  State<ReleaseNotesPage> createState() => _ReleaseNotesPageState();
}

class _ReleaseNotesPageState extends State<ReleaseNotesPage> {
  @override
  void dispose() {
    super.dispose();
    UIHelper.currentDialogTitle = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text("what_new".tr(), style: theme.primaryTextTheme.headline1),
          const SizedBox(height: 40),
          Expanded(
            child: Markdown(
              data: widget.releaseNotes.replaceAll('\n', '\u3164\n'),
              softLineBreak: true,
              padding: const EdgeInsets.only(bottom: 50),
              styleSheet: markDownBlackStyle(context),
            ),
          ),
          const SizedBox(height: 35),
          Row(
            children: [
              Expanded(
                child: AuFilledButton(
                  text: "close".tr(),
                  onPress: () => Navigator.of(context).pop(),
                  color: theme.colorScheme.secondary,
                  textStyle: theme.textTheme.button,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
