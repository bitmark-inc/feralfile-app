import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class ExhibitionNoteView extends StatelessWidget {
  const ExhibitionNoteView({
    required this.exhibition,
    required this.width,
    super.key,
  });

  final Exhibition exhibition;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColor.auGreyBackground,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'curators_note'.tr(),
              style: theme.textTheme.ppMori400White12,
            ),
            const SizedBox(height: 30),
            Text(
              exhibition.noteTitle,
              style: theme.textTheme.ppMori700White14,
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: HtmlWidget(
                exhibition.noteBrief,
                textStyle: theme.textTheme.ppMori400White14,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {},
              child: Text(
                'read_more'.tr(),
                style: theme.textTheme.ppMori400White14
                    .copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


