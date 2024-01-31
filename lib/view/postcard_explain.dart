import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class PostcardExplainView extends StatelessWidget {
  final Color? textColor;
  final Color? dividerColor;
  final Color? backgroundColor;
  final int counter;
  final String message;

  const PostcardExplainView(
      {required this.counter,
      super.key,
      this.message = '',
      this.textColor = AppColor.primaryBlack,
      this.backgroundColor = AppColor.white,
      this.dividerColor = AppColor.auGrey});

  Widget _explainRow(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.ppMori400Black14.copyWith(color: textColor),
          ),
          const SizedBox(width: 60),
          Expanded(
            child: Text(
              content,
              style:
                  theme.textTheme.ppMori400Black14.copyWith(color: textColor),
              overflow: TextOverflow.visible,
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }

  List<String> postcardExplainTexts(int counter) {
    if (counter == 0) {
      return [
        'mint_your_postcard'.tr(),
        'design_your_MoMA_stamp'.tr(),
        'sign_your_stamp'.tr(),
        'add_your_stamp'.tr(),
        'send_the_postcard'.tr(),
        'the_distance_traveled_between'.tr(),
        'each_receiver_adds_then_sends'.tr(),
        'your_postcard_journey_ends'.tr(),
        'the_postcard_win'.tr(),
      ];
    } else if (counter == MAX_STAMP_IN_POSTCARD - 1) {
      return [
        'accept_your_postcard'.tr(),
        'design_your_MoMA_stamp'.tr(),
        'sign_your_stamp'.tr(),
        'add_your_stamp'.tr(),
        'complete_postcard_journey'.tr(),
        'the_distance_traveled_all'.tr(),
        'the_postcard_win'.tr(),
      ];
    } else {
      return [
        'accept_your_postcard'.tr(),
        'design_your_MoMA_stamp'.tr(),
        'sign_your_stamp'.tr(),
        'add_your_stamp'.tr(),
        'send_the_postcard'.tr(),
        'the_distance_traveled_between'.tr(),
        'each_receiver_adds_then_sends'.tr(),
        'your_postcard_journey_ends'.tr(),
        'the_postcard_win'.tr(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final explainTexts = postcardExplainTexts(counter);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      color: backgroundColor,
      child: Column(
        children: [
          if (message.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Text(
                      message,
                      style: theme.textTheme.ppMori400Black14,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ...explainTexts
              .mapIndexed((index, text) => [
                    _explainRow(
                      context,
                      '${index + 1}',
                      text.tr(),
                    ),
                    if (index != explainTexts.length - 1)
                      addOnlyDivider(color: dividerColor)
                  ])
              .flattened
        ],
      ),
    );
  }
}
