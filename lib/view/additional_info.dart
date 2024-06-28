import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class ExhibitionAdditionalInfo extends StatelessWidget {
  const ExhibitionAdditionalInfo({
    required this.info,
    super.key,
    this.isFull = false,
  });

  final AdditionalInfo info;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
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
              info.title,
              style: theme.textTheme.ppMori400White12,
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: isFull ? double.infinity : 400),
              child: ClipRect(
                child: HtmlWidget(
                  isFull
                      ? info.content
                      : '<div style="max-lines: 16; text-overflow: ellipsis">${info.content.split('<br />').first}</div>',
                  textStyle: theme.textTheme.ppMori400White14,
                  customStylesBuilder: auHtmlStyle,
                ),
              ),
            ),
            if (info.canReadMore == true && !isFull) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRouter.exhibitionAdditionalInfo,
                    arguments: info,
                  );
                },
                child: Text(
                  'read_more'.tr(),
                  style: theme.textTheme.ppMori400White14.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColor.white,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
