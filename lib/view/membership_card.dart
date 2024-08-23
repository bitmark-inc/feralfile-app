import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class MembershipCard extends StatelessWidget {
  final MembershipCardType type;
  final String price;
  final bool isProcessing;
  final bool isEnable;
  final Function(MembershipCardType type) onTap;
  final String? buttonText;

  const MembershipCard({
    required this.type,
    required this.price,
    required this.isProcessing,
    required this.isEnable,
    required this.onTap,
    this.buttonText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...type.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          feature,
                          style: theme.textTheme.ppMori400Black14,
                        ),
                      )),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    text: buttonText ?? 'select'.tr(),
                    isProcessing: isProcessing,
                    enabled: !isProcessing && isEnable,
                    onTap: () => onTap(type),
                    color: AppColor.feralFileLightBlue,
                  )
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

  String get title {
    switch (this) {
      case MembershipCardType.essential:
        return 'essential'.tr();
      case MembershipCardType.premium:
        return 'premium'.tr();
    }
  }

  List<String> get features {
    switch (this) {
      case MembershipCardType.essential:
        return [
          'feature_1'.tr(),
          'feature_2'.tr(),
        ];
      case MembershipCardType.premium:
        return [
          'feature_3'.tr(),
          'feature_4'.tr(),
        ];
    }
  }
}
