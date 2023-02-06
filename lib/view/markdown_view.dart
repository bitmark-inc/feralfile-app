//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/view/tag_markdown.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AuMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;
  final MarkdownTapLinkCallback? onTapLink;

  const AuMarkdown({
    Key? key,
    required this.data,
    required this.styleSheet,
    this.onTapLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Markdown(
      key: const Key("githubMarkdown"),
      data: data,
      softLineBreak: true,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      styleSheet: styleSheet,
      builders: <String, MarkdownElementBuilder>{
        'AuCaption': AuCaptionBuilder(),
      },
      blockSyntaxes: [
        AuCaptionSyntax(),
      ],
      onTapLink: onTapLink ??
          (text, href, title) async {
            if (href == null) return;
            if (await canLaunchUrlString(href)) {
              launchUrlString(href, mode: LaunchMode.externalApplication);
            }
          },
    );
  }
}
