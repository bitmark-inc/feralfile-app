import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class MembershipCard extends StatelessWidget {
  final MembershipCardType type;
  final String price;
  final bool isProcessing;
  final bool isEnable;
  final Function(MembershipCardType type)? onTap;
  final String? buttonText;
  final Widget Function(BuildContext context)? buttonBuilder;
  final bool isCompleted;
  final String? cancelAt;
  final String? renewDate;
  final Function()? onContinue;
  final String? renewPolicyText;
  final Widget Function(BuildContext context)? renewPolicyBuilder;

  const MembershipCard({
    required this.type,
    required this.price,
    required this.isProcessing,
    required this.isEnable,
    this.onTap,
    this.buttonText,
    this.buttonBuilder,
    this.isCompleted = false,
    this.cancelAt,
    this.renewDate,
    this.onContinue,
    this.renewPolicyText,
    this.renewPolicyBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featureTextStyle = theme.textTheme.ppMori400Black14;
    final activeTextStyle = theme.textTheme.ppMori400Black12;
    return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColor.white,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: theme.textTheme.ppMori700Black24,
                  ),
                  const Spacer(),
                  Text(
                    price,
                    style:
                        theme.textTheme.ppMori400Black16.copyWith(fontSize: 24),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: AppColor.primaryBlack,
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  ...type.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: featureTextStyle,
                            ),
                            Expanded(
                              child: Text(
                                feature,
                                style: featureTextStyle,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 10),
                  if (buttonBuilder != null)
                    buttonBuilder!.call(context)
                  else if (isCompleted)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (onContinue != null) ...[
                          PrimaryButton(
                            text: 'continue'.tr(),
                            onTap: onContinue,
                            color: AppColor.feralFileLightBlue,
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          children: [
                            dotIcon(color: AppColor.feralFileLightBlue),
                            const SizedBox(width: 10),
                            Text(
                              'premium'.tr(),
                              style: activeTextStyle,
                            ),
                            const Spacer(),
                            if (cancelAt != null) ...[
                              Text(
                                'cancel_at_'.tr(
                                  namedArgs: {'date': cancelAt!},
                                ),
                                style: activeTextStyle,
                              ),
                            ] else if (renewDate != null) ...[
                              Text(
                                'renews_'.tr(
                                  namedArgs: {'date': renewDate!},
                                ),
                                style: activeTextStyle,
                              ),
                            ]
                          ],
                        ),
                      ],
                    )
                  else if (onTap != null)
                    PrimaryButton(
                      text: buttonText ?? 'select'.tr(),
                      isProcessing: isProcessing,
                      enabled: !isProcessing && isEnable,
                      onTap: () => onTap!(type),
                      color: AppColor.feralFileLightBlue,
                    ),
                  if (renewPolicyText != null ||
                      renewPolicyBuilder != null) ...[
                    const SizedBox(height: 10),
                    if (renewPolicyBuilder != null)
                      renewPolicyBuilder!.call(context)
                    else
                      Text(
                        renewPolicyText!,
                        style: activeTextStyle,
                        textAlign: TextAlign.center,
                      ),
                  ],
                  if (type == MembershipCardType.essential) ...[
                    const SizedBox(height: 18),
                    TextButton(
                      text: 'restore_purchase'.tr(),
                      textStyle: activeTextStyle.copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColor.primaryBlack,
                      ),
                      activeTextStyle: activeTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      onTap: () async {
                        await injector<IAPService>().restore();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ));
  }
}

enum MembershipCardType {
  essential,
  premium,
  ;

  String get title => 'premium'.tr();

  List<String> get features => [
        'feature_1'.tr(),
        'feature_2'.tr(),
        'feature_3'.tr(),
        'feature_4'.tr(),
      ];
}

class TextButton extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  final TextStyle? activeTextStyle;
  final Function()? onTap;

  const TextButton({
    required this.text,
    required this.textStyle,
    required this.onTap,
    this.activeTextStyle,
    super.key,
  });

  @override
  State<TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<TextButton> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _isProcessing
        ? widget.activeTextStyle ?? widget.textStyle
        : widget.textStyle.copyWith(
            decoration: TextDecoration.underline,
          );
    return GestureDetector(
      onTap: () async {
        setState(() {
          _isProcessing = true;
        });
        await widget.onTap?.call();
        if (!mounted) {
          return;
        }
        setState(() {
          _isProcessing = false;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.text,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
