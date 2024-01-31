import 'package:autonomy_flutter/view/postcard_explain.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class HowItWorksView extends StatelessWidget {
  final int counter;

  const HowItWorksView({required this.counter, super.key});

  @override
  Widget build(BuildContext context) {
    const textColor = AppColor.white;
    const dividerColor = AppColor.primaryBlack;
    const backgroundColor = AppColor.auGreyBackground;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
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
            counter: counter,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
