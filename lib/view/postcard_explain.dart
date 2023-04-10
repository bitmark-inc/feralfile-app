import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PostcardExplainView extends StatelessWidget {
  final Color? textColor;
  final Color? dividerColor;
  final Color? backgroundColor;
  const PostcardExplainView(
      {Key? key,
      this.textColor = AppColor.primaryBlack,
      this.backgroundColor = AppColor.white,
      this.dividerColor = AppColor.auGrey})
      : super(key: key);

  Widget _explainRow(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explainTextList = [
      'postcard_explain_1',
      'postcard_explain_2',
      'postcard_explain_3',
      'postcard_explain_4',
      'postcard_explain_5',
      'postcard_explain_6',
      'postcard_explain_7',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      color: backgroundColor,
      child: Column(
        children: explainTextList
            .mapIndexed((index, text) {
              return [
                _explainRow(
                  context,
                  "${index + 1}",
                  text.tr(),
                ),
                if (index != explainTextList.length - 1)
                  addOnlyDivider(color: dividerColor)
              ];
            })
            .flattened
            .toList(),
      ),
    );
  }
}
