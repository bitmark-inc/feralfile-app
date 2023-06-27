//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class RecoveryPhrasePage extends StatelessWidget {
  final List<String> words;

  const RecoveryPhrasePage({Key? key, required this.words}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemsEachRow = words.length ~/ 2;
    final roundNumber = words.length ~/ 2;
    final theme = Theme.of(context);
    final customLinkStyle = theme.textTheme.ppMori400Black14
        .copyWith(decoration: TextDecoration.underline);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: "your_recovery_phrase".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: ResponsiveLayout.pageEdgeInsets,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    addTitleSpace(),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.ppMori400Black14,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'yrp_we’ve_safely'.tr(),
                            //'We’ve safely and securely backed up your recovery phrase to your',
                          ),
                          Platform.isIOS
                              ? TextSpan(
                                  text: 'icloud_keychain'.tr(),
                                  style: customLinkStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context)
                                            .pushNamed(AppRouter.githubDocPage,
                                                arguments: {
                                              "prefix":
                                                  "/bitmark-inc/autonomy.io/main/apps/docs/",
                                              "document": "security-ios.md",
                                              "title": ""
                                            }),
                                )
                              : TextSpan(
                                  text: 'android_block_store'.tr(),
                                  style: customLinkStyle,
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.of(context)
                                            .pushNamed(AppRouter.githubDocPage,
                                                arguments: {
                                              "prefix":
                                                  "/bitmark-inc/autonomy.io/main/apps/docs/",
                                              "document": "security-android.md",
                                              "title": ""
                                            }),
                                ),
                          TextSpan(
                            text: 'yrp_you_may_also'.tr(),
                            //'. You may also back it up to use it in another BIP-39 standard wallet:',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Table(
                      children: List.generate(
                        roundNumber,
                        (index) {
                          return _tableRow(context, index, itemsEachRow);
                        },
                      ),
                      border: TableBorder.all(
                          color: AppColor.auLightGrey,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final word = words[index];
    NumberFormat formatter = NumberFormat("00");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.centerRight,
            child: Text(formatter.format(index + 1),
                style: theme.textTheme.ppMori400Grey14),
          ),
          const SizedBox(width: 16),
          Text(word, style: theme.textTheme.ppMori400Black14),
        ],
      ),
    );
  }

  TableRow _tableRow(BuildContext context, int index, int itemsEachCol) {
    return TableRow(children: [
      _rowItem(context, index),
      _rowItem(context, index + itemsEachCol),
    ]);
  }
}
