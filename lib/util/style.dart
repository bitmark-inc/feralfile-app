//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/text_style_ext.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html/dom.dart' as dom;

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

MarkdownStyleSheet markDownLightStyle(BuildContext context,
    {bool isDetailPage = false}) {
  return isDetailPage
      ? markDownDetailPageStyle(context, AppColor.primaryBlack)
      : markDownStyle(context, AppColor.primaryBlack);
}

MarkdownStyleSheet markDownBlackStyle(BuildContext context) {
  return markDownStyle(context, AppColor.white);
}

MarkdownStyleSheet markDownStyle(BuildContext context, Color textColor) {
  final theme = Theme.of(context);
  final bodyText2 = theme.textTheme.ppMori400Black16.copyWith(color: textColor);
  return MarkdownStyleSheet(
    a: TextStyle(
      fontFamily: AppTheme.atlasGrotesk,
      color: Colors.transparent,
      fontWeight: FontWeight.w500,
      shadows: [Shadow(color: textColor, offset: const Offset(0, -1))],
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationColor: textColor,
      decorationThickness: 1,
    ),
    p: bodyText2,
    pPadding: const EdgeInsets.only(bottom: 15),
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori700Black16.copyWith(color: textColor),
    h1Padding: const EdgeInsets.only(bottom: 40),
    h2: theme.textTheme.ppMori700Black16.copyWith(color: textColor),
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.ppMori700Black16.copyWith(color: textColor),
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.ppMori700Black16.copyWith(color: textColor),
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.ppMori700Black16.copyWith(color: textColor),
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.ppMori700Black16.copyWith(color: textColor),
    h6Padding: EdgeInsets.zero,
    em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
    strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
    del: TextStyle(decoration: TextDecoration.lineThrough, color: textColor),
    blockquote: bodyText2,
    img: bodyText2,
    checkbox: bodyText2.copyWith(color: theme.colorScheme.secondary),
    blockSpacing: 15.0,
    listIndent: 24.0,
    listBullet: bodyText2,
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

MarkdownStyleSheet markDownRightStyle(BuildContext context) {
  final theme = Theme.of(context);
  final bodyText2 = theme.textTheme.ppMori400White14;
  return MarkdownStyleSheet(
    a: TextStyle(
      fontFamily: AppTheme.ppMori,
      color: theme.auSuperTeal,
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
    p: theme.textTheme.ppMori400White14,
    pPadding: EdgeInsets.zero,
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori400White16,
    h1Padding: EdgeInsets.zero,
    h2: theme.textTheme.ppMori400White16,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.ppMori400White16,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.ppMori400White16,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.ppMori400White16,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.ppMori400White16,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.normal, color: Colors.white),
    strong: theme.textTheme.ppMori400White14,
    del: const TextStyle(
        decoration: TextDecoration.lineThrough, color: Colors.white),
    blockquote: bodyText2,
    img: bodyText2,
    checkbox: bodyText2.copyWith(color: theme.colorScheme.secondary),
    blockSpacing: 16.0,
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
          width: 0.5,
          color: theme.disableColor,
        ),
      ),
    ),
  );
}

MarkdownStyleSheet markDownAnnouncementStyle(BuildContext context) {
  final theme = Theme.of(context);
  final bodyText2 = theme.textTheme.ppMori400White12;
  return MarkdownStyleSheet(
    a: TextStyle(
      fontFamily: AppTheme.ppMori,
      color: theme.auSuperTeal,
      fontWeight: FontWeight.w400,
      fontSize: 14,
    ),
    p: theme.textTheme.ppMori400Black14,
    pPadding: EdgeInsets.zero,
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori700Black14,
    h1Padding: EdgeInsets.zero,
    h2: theme.textTheme.ppMori700Black14,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.ppMori700Black14,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.ppMori700Black14,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.ppMori700Black14,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.ppMori700White14,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.normal, color: Colors.black),
    strong: theme.textTheme.ppMori700Black14,
    del: const TextStyle(
        decoration: TextDecoration.lineThrough, color: Colors.black),
    blockquote: bodyText2,
    img: bodyText2,
    checkbox: bodyText2.copyWith(color: theme.colorScheme.primary),
    blockSpacing: 16.0,
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
          width: 0.5,
          color: theme.disableColor,
        ),
      ),
    ),
  );
}

MarkdownStyleSheet markDownDetailPageStyle(
    BuildContext context, Color textColor) {
  final theme = Theme.of(context);
  final bodyText2 = theme.textTheme.ppMori400Black16.copyWith(color: textColor);
  return MarkdownStyleSheet(
    a: TextStyle(
      fontFamily: AppTheme.atlasGrotesk,
      color: Colors.transparent,
      fontWeight: FontWeight.w500,
      shadows: [Shadow(color: textColor, offset: const Offset(0, -1))],
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationColor: textColor,
      decorationThickness: 1,
    ),
    p: bodyText2,
    pPadding: EdgeInsets.zero,
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori700Black16,
    h1Padding: EdgeInsets.zero,
    h2: theme.textTheme.ppMori700Black16,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.ppMori700Black16,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.ppMori700Black16,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.ppMori700Black16,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.ppMori700Black16,
    h6Padding: EdgeInsets.zero,
    em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
    strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
    del: TextStyle(decoration: TextDecoration.lineThrough, color: textColor),
    blockquote: bodyText2,
    img: bodyText2,
    checkbox: bodyText2.copyWith(color: theme.colorScheme.secondary),
    blockSpacing: 16.0,
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
          color: theme.dividerColor,
        ),
      ),
    ),
  );
}

MarkdownStyleSheet editorialMarkDownStyle(BuildContext context,
    {TextStyle? preferredStyle, EdgeInsets? pPadding, double? adjustSize}) {
  const textColor = AppColor.white;
  final theme = Theme.of(context);
  final size = adjustSize ?? 0;
  final textStyleWhite =
      theme.textTheme.ppMori400White12.copyWith(fontSize: 17).adjustSize(size);
  preferredStyle = preferredStyle ?? textStyleWhite;
  return MarkdownStyleSheet(
    a: preferredStyle.merge(
      const TextStyle(
        color: AppColor.auSuperTeal,
      ),
    ),
    p: preferredStyle,
    pPadding: pPadding ?? const EdgeInsets.only(bottom: 16),
    code: textStyleWhite.copyWith(backgroundColor: Colors.transparent),
    h1: preferredStyle
        .copyWith(fontSize: 24, fontWeight: FontWeight.w700)
        .adjustSize(size),
    h1Padding: const EdgeInsets.only(bottom: 24),
    h2: preferredStyle
        .copyWith(fontSize: 20, fontWeight: FontWeight.w700)
        .adjustSize(size),
    h2Padding: EdgeInsets.zero,
    h3: preferredStyle,
    h3Padding: EdgeInsets.zero,
    h4: preferredStyle,
    h4Padding: EdgeInsets.zero,
    h5: preferredStyle,
    h5Padding: EdgeInsets.zero,
    h6: preferredStyle,
    h6Padding: EdgeInsets.zero,
    em: preferredStyle.copyWith(fontStyle: FontStyle.italic),
    strong: preferredStyle.copyWith(fontWeight: FontWeight.bold),
    del: preferredStyle.copyWith(
        decoration: TextDecoration.lineThrough, color: textColor),
    blockquote: preferredStyle.copyWith(color: AppColor.white),
    img: preferredStyle
        .copyWith(fontSize: 12, color: AppColor.disabledColor)
        .adjustSize(size),
    checkbox: textStyleWhite.copyWith(color: theme.colorScheme.secondary),
    blockSpacing: 15.0,
    listIndent: 24.0,
    listBullet: textStyleWhite.copyWith(color: textColor),
    listBulletPadding: const EdgeInsets.only(right: 4),
    tableHead: const TextStyle(fontWeight: FontWeight.w600),
    tableBody: textStyleWhite,
    tableHeadAlign: TextAlign.center,
    tableBorder: TableBorder.all(
      color: theme.dividerColor,
    ),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    tableCellsDecoration: const BoxDecoration(),
    blockquotePadding: const EdgeInsets.only(left: 20),
    blockquoteDecoration: const BoxDecoration(
      border: Border(
        left: BorderSide(width: 2, color: AppColor.auSuperTeal),
      ),
    ),
    codeblockPadding: const EdgeInsets.all(8.0),
    codeblockDecoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(2.0),
    ),
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(
        top: BorderSide(
          color: AppColor.auSuperTeal,
        ),
      ),
    ),
  );
}

MarkdownStyleSheet markDownChangeLogStyle(BuildContext context) {
  const textColor = AppColor.primaryBlack;
  final theme = Theme.of(context);
  final textStyleBody = theme.textTheme.ppMori400Black16;
  final textStyleGrey = theme.textTheme.ppMori400Grey12;
  return MarkdownStyleSheet(
    a: const TextStyle(
      fontFamily: AppTheme.ppMori,
      color: Colors.transparent,
      fontWeight: FontWeight.w500,
      shadows: [Shadow(offset: Offset(0, -1))],
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationColor: textColor,
      decorationThickness: 1,
    ),
    p: textStyleBody,
    pPadding: const EdgeInsets.only(bottom: 16),
    code: textStyleBody.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori700Black36.copyWith(fontSize: 24),
    h1Padding: const EdgeInsets.only(bottom: 24),
    h2: theme.textTheme.ppMori700Black36.copyWith(fontSize: 20),
    h2Padding: const EdgeInsets.symmetric(vertical: 15),
    h3: theme.textTheme.ppMori700Black36.copyWith(fontSize: 20),
    h3Padding: const EdgeInsets.symmetric(vertical: 15),
    h4: theme.textTheme.ppMori700Black36.copyWith(fontSize: 20),
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.ppMori700Black36.copyWith(fontSize: 20),
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.ppMori700Black36.copyWith(fontSize: 20),
    h6Padding: EdgeInsets.zero,
    em: textStyleGrey,
    strong: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
    del: const TextStyle(
        decoration: TextDecoration.lineThrough, color: textColor),
    blockquote: textStyleBody,
    img: textStyleBody,
    checkbox: textStyleBody.copyWith(color: theme.colorScheme.secondary),
    blockSpacing: 15.0,
    listIndent: 24.0,
    listBullet: textStyleBody.copyWith(color: textColor),
    listBulletPadding: const EdgeInsets.only(right: 4),
    tableHead: const TextStyle(fontWeight: FontWeight.w600),
    tableBody: textStyleBody,
    tableHeadAlign: TextAlign.center,
    tableBorder: TableBorder.all(
      color: theme.dividerColor,
    ),
    tableColumnWidth: const FlexColumnWidth(),
    tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    tableCellsDecoration: const BoxDecoration(),
    blockquotePadding: const EdgeInsets.only(left: 20),
    blockquoteDecoration: const BoxDecoration(
      border: Border(
        left: BorderSide(width: 2, color: AppColor.auSuperTeal),
      ),
    ),
    codeblockPadding: const EdgeInsets.all(8.0),
    codeblockDecoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(2.0),
    ),
    horizontalRuleDecoration: CustomBoxDecoration(
      color: AppColor.auSuperTeal,
    ),
  );
}

MarkdownStyleSheet markDownStyleTipCard(BuildContext context) {
  final theme = Theme.of(context);
  final bodyText2 = theme.textTheme.ppMori400Black14.copyWith(height: 1.7);
  return MarkdownStyleSheet(
    a: const TextStyle(
      fontFamily: AppTheme.atlasGrotesk,
      color: Colors.transparent,
      fontWeight: FontWeight.w400,
      shadows: [Shadow(offset: Offset(0, -1))],
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationColor: AppColor.primaryBlack,
      decorationThickness: 1,
    ),
    p: bodyText2,
    pPadding: const EdgeInsets.only(bottom: 15),
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori700Black16,
    h1Padding: const EdgeInsets.only(bottom: 40),
    h2: theme.textTheme.ppMori700Black16,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.ppMori700Black16,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.ppMori700Black16,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.ppMori700Black16,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.ppMori700Black16,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(
        fontStyle: FontStyle.italic, color: AppColor.primaryBlack),
    strong: const TextStyle(
        fontWeight: FontWeight.bold, color: AppColor.primaryBlack),
    del: const TextStyle(
        decoration: TextDecoration.lineThrough, color: AppColor.primaryBlack),
    blockquote: bodyText2,
    img: bodyText2,
    checkbox: bodyText2.copyWith(color: theme.colorScheme.secondary),
    blockSpacing: 15.0,
    listIndent: 24.0,
    listBullet: bodyText2,
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

class CustomBoxDecoration extends ShapeDecoration {
  CustomBoxDecoration({
    color,
  }) : super(
          shape: const Border(),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              color,
              color,
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0.0, 0.495, 0.495, 0.505, 0.505, 1.0],
          ),
        );

  @override
  EdgeInsetsGeometry get padding => const EdgeInsets.symmetric(vertical: 22.0);
}

SizedBox addTitleSpace() {
  return const SizedBox(height: 60);
}

Divider addDivider({double height = 32, Color? color}) {
  return Divider(
    height: height,
    thickness: 1.0,
    color: color,
  );
}

Divider headDivider() {
  return const Divider(
    height: 30,
    thickness: 3,
    color: AppColor.auSuperTeal,
  );
}

Divider addOnlyDivider({Color? color}) {
  return Divider(
    height: 1.0,
    thickness: 1.0,
    color: color,
  );
}

Divider addBoldDivider() {
  return const Divider(
    height: 1.0,
    thickness: 1.0,
    color: Colors.black,
  );
}

Divider addDialogDivider({double height = 32}) {
  return Divider(
    height: height,
    thickness: 1,
    color: Colors.white,
  );
}

Widget loadingIndicator({
  double size = 27,
  Color valueColor = Colors.black,
  Color backgroundColor = Colors.black54,
  double strokeWidth = 2.0,
}) {
  return SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      backgroundColor: backgroundColor,
      color: valueColor,
      strokeWidth: strokeWidth,
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

Widget redDotIcon({Color color = Colors.red}) {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
  );
}

Widget iconWithRedDot(
    {required Widget icon,
    Color color = Colors.red,
    EdgeInsetsGeometry? padding,
    bool withReddot = true}) {
  return withReddot
      ? Stack(
          alignment: Alignment.topRight,
          children: [
            Padding(
              padding: padding ?? const EdgeInsets.only(right: 5),
              child: icon,
            ),
            redDotIcon(color: color),
          ],
        )
      : icon;
}

var grantPermissions = [
  "view_account".tr(),
  'request_approval'.tr(),
];

String polishSource(String source) {
  switch (source) {
    case 'feralfile':
      return 'feral_file'.tr();
    case 'ArtBlocks':
      return "art_blocks".tr();
    default:
      return source;
  }
}

Future<void> enableLandscapeMode() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

Future<void> disableLandscapeMode() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

class MomaPallet {
  static const pink = Color.fromRGBO(233, 60, 172, 1);
  static const red = Color.fromRGBO(228, 0, 43, 1);
  static const brick = Color.fromRGBO(255, 88, 93, 1);
  static const lightBrick = Color.fromRGBO(255, 179, 171, 1);
  static const orange = Color.fromRGBO(255, 143, 28, 1);
  static const lightYellow = Color.fromRGBO(255, 205, 0, 1);
  static const bananaYellow = Color.fromRGBO(206, 220, 0, 1);
  static const green = Color.fromRGBO(0, 177, 64, 1);
  static const riverGreen = Color.fromRGBO(140, 226, 208, 1);
  static const cloudBlue = Color.fromRGBO(0, 175, 215, 1);
  static const blue = Color.fromRGBO(0, 87, 184, 1);
  static const purple = Color.fromRGBO(117, 59, 189, 1);
  static const black = Color.fromRGBO(0, 0, 0, 1);
  static const white = Color.fromRGBO(255, 255, 255, 1);
}

Map<String, String>? auHtmlStyle(dom.Element element) {
  if (element.localName == "a") {
    const linkColor = AppColor.auSuperTeal;
    // convert linkColor to hex string
    String hexColor =
        "#${(linkColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}";
    return {
      "color": hexColor,
      "text-decoration": "none",
    };
  }
  return null;
}
