import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class Tipcard extends StatelessWidget {
  final String titleText;
  final Function() onPressed;
  final Function()? onClosed;
  final String buttonText;
  final Widget content;
  final ValueNotifier<bool> listener;

  const Tipcard({
    super.key,
    required this.titleText,
    required this.onPressed,
    required this.buttonText,
    required this.content,
    required this.listener,
    this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    final metricClient = injector<MetricClientService>();
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: listener,
      builder: (context, value, Widget? child) {
        return value
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColor.auSuperTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(titleText,
                            style: theme.textTheme.ppMori700Black14),
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
                            if (onClosed != null) onClosed!();
                            metricClient
                                .addEvent(MixpanelEvent.closeTipcard, data: {
                              'title': titleText,
                            });
                            listener.value = false;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    content,
                    const SizedBox(height: 15),
                    OutlineButton(
                        color: AppColor.auSuperTeal,
                        textColor: AppColor.primaryBlack,
                        borderColor: AppColor.primaryBlack,
                        text: buttonText,
                        onTap: () {
                          onPressed();
                          metricClient
                              .addEvent(MixpanelEvent.pressTipcard, data: {
                            'title': titleText,
                          });
                          listener.value = false;
                        }),
                  ],
                ),
              )
            : const SizedBox();
      },
    );
  }
}
