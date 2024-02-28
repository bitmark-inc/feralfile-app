import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class ExhibitionNoteView extends StatelessWidget {
  const ExhibitionNoteView(
      {required this.exhibition,
      this.width,
      super.key,
      this.onReadMore,
      this.isFull = false});

  final Exhibition exhibition;
  final double? width;
  final Function? onReadMore;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = isFull ? exhibition.note : exhibition.noteBrief;
    return Container(
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
            constraints:
                BoxConstraints(maxHeight: isFull ? double.infinity : 400),
            child: HtmlWidget(
              text,
              textStyle: theme.textTheme.ppMori400White14,
            ),
          ),
          const SizedBox(height: 20),
          if (onReadMore != null)
            GestureDetector(
              onTap: () async {
                await onReadMore!();
              },
              child: Text(
                'read_more'.tr(),
                style: theme.textTheme.ppMori400White14.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColor.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
