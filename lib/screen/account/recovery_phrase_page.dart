//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RecoveryPhrasePage extends StatelessWidget {
  final List<String> words;

  const RecoveryPhrasePage({Key? key, required this.words}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemsEachRow = words.length ~/ 2;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
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
                    Text(
                      "your_recovery_phrase".tr(),
                      style: theme.textTheme.headline1,
                    ),
                    addTitleSpace(),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyText1,
                        children: <TextSpan>[
                          TextSpan(
                            text: 'yrp_we’ve_safely'.tr(),
                            //'We’ve safely and securely backed up your recovery phrase to your',
                          ),
                          TextSpan(
                              text: 'icloud_keychain'.tr(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: 'yrp_you_may_also'.tr(),
                            //'. You may also back it up to use it in another BIP-39 standard wallet:',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.primary)),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRow(context, 0, itemsEachRow),
                          _buildRow(context, itemsEachRow, itemsEachRow)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int offset, int itemsEachRow) {
    final theme = Theme.of(context);

    return Column(
      children: List.generate(itemsEachRow, (index) {
        final word = words[index + offset];
        return SizedBox(
          width: 140,
          child: Column(children: [
            Row(children: [
              Container(
                  width: 28,
                  alignment: Alignment.centerRight,
                  child: Text("${index + offset + 1}. ",
                      style: theme.textTheme.headline4)),
              Text(word, style: theme.textTheme.headline4),
            ]),
            const SizedBox(height: 4),
          ]),
        );
      }),
    );
  }
}
