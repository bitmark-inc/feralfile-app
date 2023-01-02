//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final bodyText2 = ResponsiveLayout.isMobile
      ? theme.textTheme.ibmGreyNormal16.copyWith(color: textColor)
      : theme.textTheme.ibmGreyNormal20.copyWith(color: textColor);
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
    p: theme.textTheme.bodyText1?.copyWith(color: textColor),
    pPadding: const EdgeInsets.only(bottom: 15),
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.headline1?.copyWith(color: textColor),
    h1Padding: const EdgeInsets.only(bottom: 40),
    h2: theme.textTheme.headline4?.copyWith(color: textColor),
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.headline3?.copyWith(color: textColor),
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.headline4?.copyWith(color: textColor),
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.subtitle2?.copyWith(color: textColor),
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.headline6?.copyWith(color: textColor),
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
  final bodyText2 = theme.textTheme.ppMori400White12;
  return MarkdownStyleSheet(
    a: TextStyle(
      fontFamily: AppTheme.ppMori,
      color: theme.auSuperTeal,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    ),
    p: theme.textTheme.ppMori400White12,
    pPadding: EdgeInsets.zero,
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori400White14,
    h1Padding: EdgeInsets.zero,
    h2: theme.textTheme.ppMori400White14,
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.ppMori400White14,
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.ppMori400White14,
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.ppMori400White14,
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.ppMori400White14,
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

MarkdownStyleSheet markDownDetailPageStyle(
    BuildContext context, Color textColor) {
  final theme = Theme.of(context);
  final bodyText2 = ResponsiveLayout.isMobile
      ? theme.textTheme.ibmGreyNormal16.copyWith(color: textColor)
      : theme.textTheme.ibmGreyNormal20.copyWith(color: textColor);
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
    p: theme.textTheme.bodyText1?.copyWith(color: textColor),
    pPadding: EdgeInsets.zero,
    code: bodyText2.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.headline1?.copyWith(color: textColor),
    h1Padding: EdgeInsets.zero,
    h2: theme.textTheme.headline4?.copyWith(color: textColor),
    h2Padding: EdgeInsets.zero,
    h3: theme.textTheme.headline3?.copyWith(color: textColor),
    h3Padding: EdgeInsets.zero,
    h4: theme.textTheme.headline4?.copyWith(color: textColor),
    h4Padding: EdgeInsets.zero,
    h5: theme.textTheme.subtitle2?.copyWith(color: textColor),
    h5Padding: EdgeInsets.zero,
    h6: theme.textTheme.headline6?.copyWith(color: textColor),
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

MarkdownStyleSheet editorialMarkDownStyle(BuildContext context) {
  const textColor = AppColor.white;
  final theme = Theme.of(context);
  final textStyleWhite =
      theme.textTheme.ppMori400White12.copyWith(fontSize: 17);
  final textStyleGreen =
      theme.textTheme.ppMori400Green12.copyWith(fontSize: 17);
  return MarkdownStyleSheet(
    a: const TextStyle(
      fontFamily: AppTheme.ppMori,
      color: Colors.transparent,
      fontWeight: FontWeight.w500,
      shadows: [Shadow(color: textColor, offset: Offset(0, -1))],
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
      decorationColor: textColor,
      decorationThickness: 1,
    ),
    p: textStyleWhite,
    pPadding: const EdgeInsets.only(bottom: 16),
    code: textStyleWhite.copyWith(backgroundColor: Colors.transparent),
    h1: theme.textTheme.ppMori700White24,
    h1Padding: const EdgeInsets.only(bottom: 24),
    h2: theme.textTheme.ppMori700White24.copyWith(fontSize: 20),
    h2Padding: EdgeInsets.zero,
    h3: textStyleGreen,
    h3Padding: EdgeInsets.zero,
    h4: textStyleGreen,
    h4Padding: EdgeInsets.zero,
    h5: textStyleGreen,
    h5Padding: EdgeInsets.zero,
    h6: textStyleGreen,
    h6Padding: EdgeInsets.zero,
    em: const TextStyle(fontStyle: FontStyle.italic, color: textColor),
    strong: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
    del: const TextStyle(
        decoration: TextDecoration.lineThrough, color: textColor),
    blockquote: textStyleWhite,
    img: textStyleWhite,
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
        return SvgPicture.asset(
          snapshot.data == true
              ? "assets/images/logo_dev.svg"
              : "assets/images/penrose_moma.svg",
          width: 50,
        );
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
