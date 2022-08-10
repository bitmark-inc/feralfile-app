//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';

const appTextTheme = TextTheme(
  headline1: TextStyle(
      color: Colors.black,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk"),
  headline2: TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk"),
  headline3: TextStyle(
      color: Colors.black,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk"),
  headline4: TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      fontFamily: "AtlasGrotesk-Bold",
      height: 1.377),
  headline5:
      TextStyle(color: Colors.black, fontSize: 12, fontFamily: "AtlasGrotesk"),
  button: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFamily: "IBMPlexMono"),
  caption: TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontFamily: "IBMPlexMono"),
  bodyText1: TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontFamily: "AtlasGrotesk-Light",
      fontWeight: FontWeight.w300,
      height: 1.377),
  bodyText2: TextStyle(
      color: Color(0xFF6D6B6B), fontSize: 16, fontFamily: "IBMPlexMono"),
);

const copiedTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 12,
  fontFamily: "AtlasGrotesk-Bold",
  fontWeight: FontWeight.bold,
);

const bodySmall = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontFamily: "AtlasGrotesk",
    fontWeight: FontWeight.w300,
    height: 1.377);

const labelSmall = TextStyle(
    color: Colors.black,
    fontSize: 12,
    fontFamily: "AtlasGrotesk",
    fontWeight: FontWeight.w300,
    height: 1.377);

const linkStyle = TextStyle(
  color: Colors.transparent,
  fontSize: 14,
  fontFamily: "AtlasGrotesk-Medium",
  height: 1.377,
  fontWeight: FontWeight.w400,
  shadows: [Shadow(offset: Offset(0, -1))],
  decoration: TextDecoration.underline,
  decorationStyle: TextDecorationStyle.solid,
  decorationColor: Colors.black,
  decorationThickness: 1.1,
);

const linkStyle2 = TextStyle(
  color: Colors.transparent,
  fontSize: 12,
  fontFamily: "AtlasGrotesk-Bold",
  height: 1.377,
  fontWeight: FontWeight.w500,
  shadows: [Shadow(offset: Offset(0, -1))],
  decoration: TextDecoration.underline,
  decorationStyle: TextDecorationStyle.solid,
  decorationColor: Colors.black,
  decorationThickness: 1.1,
);

const whitelinkStyle = TextStyle(
  color: Colors.transparent,
  fontSize: 14,
  fontFamily: "AtlasGrotesk-Medium",
  height: 1.377,
  shadows: [Shadow(color: Colors.white, offset: Offset(0, -1))],
  decoration: TextDecoration.underline,
  decorationStyle: TextDecorationStyle.solid,
  decorationColor: Colors.white,
  decorationThickness: 1.1,
);

ButtonStyle get textButtonNoPadding {
  return TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap);
}

const paragraph = TextStyle(
    color: AppColorTheme.secondaryDimGrey,
    fontSize: 12,
    fontFamily: "AtlasGrotesk",
    fontWeight: FontWeight.w400,
    height: 1.4);

TextStyle makeLinkStyle(TextStyle style) {
  final color = style.color ?? Colors.black;
  return style.copyWith(
    color: Colors.transparent,
    shadows: [Shadow(color: color, offset: const Offset(0, -1))],
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.solid,
    decorationColor: color,
    decorationThickness: 1.2,
  );
}

MarkdownStyleSheet get markDownLightStyle {
  return markDownStyle(AuThemeManager.mainTheme, Colors.black);
}

MarkdownStyleSheet get markDownBlackStyle {
  return markDownStyle(AuThemeManager.sheetTheme, Colors.white);
}

MarkdownStyleSheet markDownStyle(ThemeData theme, Color textColor) {
  final bodyText2 = theme.textTheme.bodyText2
      ?.copyWith(fontFamily: "AtlasGrotesk", fontWeight: FontWeight.w300);
  return MarkdownStyleSheet(
    a: const TextStyle(
        color: Colors.black,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w600),
    p: bodyText2?.copyWith(color: textColor),
    pPadding: const EdgeInsets.only(bottom: 15),
    code: bodyText2!.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.headline1,
    h1Padding: const EdgeInsets.only(bottom: 40),
    h2: theme.textTheme.headline2,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.headline3,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.headline4,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.headline5,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.headline6,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.italic),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    blockquote: bodyText2,
    img: bodyText2,
    checkbox: bodyText2.copyWith(
      color: theme.primaryColor,
    ),
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

class AppColorTheme {
  static const scaffoldBackgroundColor = Colors.white;
  static const secondaryHeaderColor = Color(0xFF6D6B6B);
  static const primaryColor = Colors.grey;
  static const barBackgroundColor = Color(0xFF6D6B6B);
  static const errorColor = Color(0xFFA1200A);
  static const textColor = Colors.grey;
  static const secondaryDimGrey = Color(0xFF6D6B6B);
  static const secondaryDimGreyBackground = Color(0xFFEDEDED);
  static const secondarySpanishGrey = Color(0xFF999999);
  static const chatDateDividerColor = Color(0xFFC2C2C2);
  static const chatSecondaryColor = Color(0xFF6D6B6B);
  static const chatPrimaryColor = Color(0xFFEDEDED);
}

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
