//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';

import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class ReportRenderingIssueWidget extends StatefulWidget {
  final AssetToken token;
  final Function onReported;

  const ReportRenderingIssueWidget(
      {Key? key, required this.token, required this.onReported})
      : super(key: key);

  @override
  State<ReportRenderingIssueWidget> createState() =>
      _ReportRenderingIssueWidgetState();
}

class _ReportRenderingIssueWidgetState
    extends State<ReportRenderingIssueWidget> {
  final List<String> _selectedTopices = [];
  bool _isSubmissionEnabled = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    var topics = [
      "viewing".tr(),
      'thumbnail_collection'.tr(),
      "thumbnail_detail".tr(),
      'rights'.tr(),
      'metadata'.tr(),
      'provenance'.tr()
    ];
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('select_topic_below'.tr().toUpperCase(),
                style: theme.primaryTextTheme.headline5),
            const SizedBox(height: 16),
            ListView.builder(
                shrinkWrap: true,
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _selectTopics(topics[index]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(topics[index],
                                  style: theme.primaryTextTheme.headline4),
                              RoundCheckBox(
                                  uncheckedColor: Colors.transparent,
                                  checkedColor: theme.colorScheme.secondary,
                                  checkedWidget: Icon(
                                    Icons.check,
                                    color: theme.colorScheme.primary,
                                    size: 16,
                                  ),
                                  animationDuration:
                                      const Duration(milliseconds: 100),
                                  isChecked:
                                      _selectedTopices.contains(topics[index]),
                                  size: 24,
                                  onTap: (_) => _selectTopics(topics[index])),
                            ],
                          ),
                        ),
                      ),
                      if (index != topics.length - 1) ...[
                        Divider(height: 0, color: theme.colorScheme.secondary),
                      ]
                    ],
                  );
                }),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "report_issue2".tr(),
                    onPress: () => _reportIssue(),
                    isProcessing: _isProcessing,
                    color: theme.colorScheme.secondary,
                    textStyle: _isSubmissionEnabled
                        ? theme.textTheme.button
                        : theme.textTheme.ibmGreyBold14,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "cancel".tr(),
                style: theme.primaryTextTheme.button,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _selectTopics(String topic) {
    setState(() {
      if (_selectedTopices.contains(topic)) {
        _selectedTopices.remove(topic);
      } else {
        _selectedTopices.add(topic);
      }

      _isSubmissionEnabled = _selectedTopices.isNotEmpty;
    });
  }

  void _reportIssue() async {
    if (!_isSubmissionEnabled) return;

    setState(() {
      _isSubmissionEnabled = false;
      _isProcessing = true;
    });

    final githubURL = await injector<CustomerSupportService>()
        .createRenderingIssueReport(widget.token, _selectedTopices);

    if (!mounted) return;
    Navigator.pop(context);
    widget.onReported(githubURL);
  }
}
