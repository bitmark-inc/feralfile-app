//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/tag_markdown.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

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

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "release_notes".tr(),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        color: theme.backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Markdown(
                data: widget.releaseNotes,
                softLineBreak: true,
                padding: const EdgeInsets.only(bottom: 50, top: 32),
                styleSheet: markDownChangeLogStyle(context),
                builders: <String, MarkdownElementBuilder>{
                  '#': TagBuilder(),
                },
                blockSyntaxes: [
                  TagBlockSyntax(),
                ],
                onTapLink: (text, href, title) async {
                  if (href == null) return;
                  if (DEEP_LINKS.any((prefix) => href.startsWith(prefix))) {
                    injector<DeeplinkService>()
                        .handleDeeplink(href, delay: Duration.zero);
                  } else if (await canLaunchUrlString(href)) {
                    launchUrlString(href);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
