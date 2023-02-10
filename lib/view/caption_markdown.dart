//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/markdown_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class AuCaptionSyntax extends md.BlockSyntax {
  static const String _pattern = r'<caption>((.|\n)*)<\/caption>';

  @override
  RegExp get pattern => RegExp(_pattern);

  AuCaptionSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    var childLines = parseChildLines(parser);

    var content = childLines.join('\n');

    final md.Element el = md.Element('p', [
      md.Element('Caption', [
        md.Text(content),
      ]),
    ]);

    return el;
  }
}

class CaptionBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final textStyleGrey = theme.textTheme.ppMori400Grey12;
        return AuMarkdown(
          data: element.textContent,
          styleSheet: editorialMarkDownStyle(context,
              preferredStyle: textStyleGrey.merge(preferredStyle)),
        );
      },
    );
  }
}
