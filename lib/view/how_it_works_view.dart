import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class HowItWorksView extends StatelessWidget {
  const HowItWorksView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.auSuperTeal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Text(
              'how_it_works'.tr(),
              style: theme.textTheme.ppMori700Black14,
            ),
          ),
          RichText(
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: "introducing_the".tr(),
              style: theme.textTheme.ppMori400Black14,
              children: [
                TextSpan(
                  text: 'moma_postcard_project'.tr(),
                  style: theme.textTheme.ppMori400Black14.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextSpan(
                  text: 'a_collaborative'.tr(),
                  style: theme.textTheme.ppMori400Black14,
                ),
                TextSpan(
                  text: "your_objective".tr(),
                  style: theme.textTheme.ppMori400Black14,
                ),
                TextSpan(
                  text: "tap_accept_postcard_to_begin".tr(),
                  style: theme.textTheme.ppMori400Black14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
