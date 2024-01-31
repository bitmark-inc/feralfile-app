import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class Tipcard extends StatelessWidget {
  final String titleText;
  final Function()? onPressed;
  final Function()? onClosed;
  final String? buttonText;
  final Widget content;
  final ValueNotifier<bool> listener;

  const Tipcard({
    required this.titleText,
    required this.content,
    required this.listener,
    super.key,
    this.onPressed,
    this.buttonText,
    this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    final metricClient = injector<MetricClientService>();
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: listener,
      builder: (context, value, Widget? child) => value
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: AppColor.feralFileHighlight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(titleText, style: theme.textTheme.ppMori700Black14),
                      const Spacer(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        icon: const Icon(
                          Icons.close,
                        ),
                        color: AppColor.primaryBlack,
                        onPressed: () {
                          if (onClosed != null) {
                            onClosed!();
                          }
                          unawaited(metricClient
                              .addEvent(MixpanelEvent.closeTipcard, data: {
                            'title': titleText,
                          }));
                          listener.value = false;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  content,
                  if (buttonText != null || onPressed != null) ...[
                    const SizedBox(height: 15),
                    OutlineButton(
                        color: AppColor.feralFileHighlight,
                        textColor: AppColor.primaryBlack,
                        borderColor: AppColor.primaryBlack,
                        text: buttonText ?? 'close'.tr(),
                        onTap: () {
                          () {};
                          unawaited(metricClient
                              .addEvent(MixpanelEvent.pressTipcard, data: {
                            'title': titleText,
                          }));
                          listener.value = false;
                        }),
                  ]
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}
