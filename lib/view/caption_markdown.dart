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

class CaptionInlineSyntax extends md.InlineSyntax {
  static const String _pattern = r'<caption>((.|\n)*)<\/caption>';

  @override
  RegExp get pattern => RegExp(_pattern);

  CaptionInlineSyntax() : super(_pattern);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final caption = match[1]!;
    final el = md.Element.text('Caption', caption);
    parser.addNode(el);

    return true;
  }
}

class CaptionBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final textStyleGrey = theme.textTheme.ppMori400Grey12;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AuMarkdown(
            data: element.textContent,
            styleSheet: editorialMarkDownStyle(
              context,
              preferredStyle: textStyleGrey.merge(preferredStyle),
              pPadding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}
