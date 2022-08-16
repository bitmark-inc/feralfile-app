//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

TextStyle makeLinkStyle(TextStyle style) {
  final color = style.color ?? AppColor.primaryBlack;
  return style.copyWith(
    color: Colors.transparent,
    shadows: [Shadow(color: color, offset: const Offset(0, -1))],
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.solid,
    decorationColor: color,
    decorationThickness: 1.2,
  );
}

MarkdownStyleSheet markDownLightStyle(BuildContext context) {
  return markDownStyle(context, AppColor.primaryBlack);
}

MarkdownStyleSheet markDownBlackStyle(BuildContext context) {
  return markDownStyle(context, AppColor.white);
}

MarkdownStyleSheet markDownStyle(BuildContext context, Color textColor) {
  final theme = Theme.of(context);
  final bodyText2 = theme.textTheme.ibmGreyNormal16;
  return MarkdownStyleSheet(
    a: const TextStyle(
      color: AppColor.primaryBlack,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    ),
    p: theme.textTheme.bodyText1?.copyWith(color: textColor),
    pPadding: const EdgeInsets.only(bottom: 15),
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.headline1,
    h1Padding: const EdgeInsets.only(bottom: 40),
    h2: theme.textTheme.headline2,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.headline3,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.headline4,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.subtitle2,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.headline6,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.italic),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    blockquote: bodyText2,
    img: bodyText2,
    checkbox: bodyText2.copyWith(color: theme.colorScheme.secondary),
    blockSpacing: 15.0,
    listIndent: 24.0,
    listBullet: bodyText2.copyWith(color: Colors.black),
    listBulletPadding: const EdgeInsets.only(right: 4),
    tableHead: const TextStyle(fontWeight: FontWeight.w600),
    tableBody: bodyText2,
    tableHeadAlign: TextAlign.center,
    tableBorder: TableBorder.all(
      color: theme.dividerColor,
    ),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    tableCellsDecoration: const BoxDecoration(),
    blockquotePadding: const EdgeInsets.all(8.0),
    blockquoteDecoration: BoxDecoration(
      color: Colors.blue.shade100,
      borderRadius: BorderRadius.circular(2.0),
    ),
    codeblockPadding: const EdgeInsets.all(8.0),
    codeblockDecoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(2.0),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          width: 5.0,
          color: theme.dividerColor,
        ),
      ),
    ),
  );
}

SizedBox addTitleSpace() {
  return const SizedBox(height: 40);
}

Divider addDivider({double height = 32}) {
  return Divider(
    height: height,
    thickness: 1.0,
  );
}

Divider addOnlyDivider() {
  return const Divider(
    height: 1.0,
    thickness: 1.0,
  );
}

Divider addDialogDivider({double height = 32}) {
  return Divider(
    height: height,
    thickness: 1,
    color: Colors.white,
  );
}

Widget get autonomyLogo {
  return FutureBuilder<bool>(
      future: isAppCenterBuild(),
      builder: (context, snapshot) {
        return SvgPicture.asset(snapshot.data == true
            ? "assets/images/penrose_appcenter.svg"
            : "assets/images/penrose.svg");
      });
}

Widget loadingIndicator({
  double size = 27,
  Color valueColor = Colors.black,
  Color backgroundColor = Colors.black54,
}) {
  return SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      backgroundColor: backgroundColor,
      color: valueColor,
      strokeWidth: 2,
    ),
  );
}

Widget closeIcon({Color color = Colors.black}) {
  return SvgPicture.asset(
    'assets/images/iconClose.svg',
    color: color,
    width: 32,
    height: 32,
  );
}

const pageEdgeInsets =
    EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0);
const pageEdgeInsetsWithSubmitButton = EdgeInsets.fromLTRB(16, 16, 16, 32);
const pageEdgeInsetsNotBottom = EdgeInsets.fromLTRB(16, 16, 16, 0);

const grantPermissions = [
  'View account balance and NFTs',
  'Request approval for transactions',
];

String polishSource(String source) {
  switch (source) {
    case 'feralfile':
      return 'Feral File';
    case 'ArtBlocks':
      return 'Art Blocks';
    default:
      return source;
  }
}

void enableLandscapeMode() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

void disableLandscapeMode() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}
