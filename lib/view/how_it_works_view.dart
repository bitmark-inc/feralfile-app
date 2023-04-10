import 'package:autonomy_flutter/view/postcard_explain.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HowItWorksView extends StatelessWidget {
  const HowItWorksView({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppColor.white;
    final dividerColor = AppColor.primaryBlack;
    final backgroundColor = AppColor.auGreyBackground;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: Text(
              'how_it_works'.tr(),
              style: theme.textTheme.ppMori700Black14.copyWith(
                color: textColor,
              ),
            ),
          ),
          PostcardExplainView(
            textColor: textColor,
            backgroundColor: backgroundColor,
            dividerColor: dividerColor,
          ),
        ],
      ),
    );
  }
}
