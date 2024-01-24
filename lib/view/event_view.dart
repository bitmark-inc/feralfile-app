import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class ExhibitionEventView extends StatelessWidget {
  final ExhibitionEvent exhibitionEvent;
  final double width;

  const ExhibitionEventView({
    required this.exhibitionEvent,
    required this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final mediaImageUrl = exhibitionEvent.mediaUri?.type == 'image'
        ? exhibitionEvent.mediaUri?.url
        : null;
    final mediaVideoUrl = exhibitionEvent.mediaUri?.type == 'video'
        ? exhibitionEvent.mediaUri?.url
        : null;
    final eventLink = exhibitionEvent.links?.isNotEmpty == true
        ? exhibitionEvent.links!.values.first
        : null;
    final watchMoreUrl = mediaVideoUrl ?? eventLink;

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
              'event'.tr(),
              style: theme.textTheme.ppMori400White12,
            ),
            const SizedBox(height: 30),
            if (mediaImageUrl != null) ...[
              Image.network(
                mediaImageUrl,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 20),
            ],
            Text(exhibitionEvent.title,
                style: theme.textTheme.ppMori400White14),
            const SizedBox(height: 20),
            if (exhibitionEvent.dateTime != null) ...[
              Text(
                'Date: ${dateFormat.format(exhibitionEvent.dateTime!)}',
                style: theme.textTheme.ppMori400White14,
              ),
              Text(
                'Time: ${timeFormat.format(exhibitionEvent.dateTime!)}',
                style: theme.textTheme.ppMori400White14,
              ),
            ],
            if (exhibitionEvent.description != null) ...[
              HtmlWidget(
                exhibitionEvent.description!,
                textStyle: theme.textTheme.ppMori400White14,
              ),
              const SizedBox(height: 20),
            ],
            if (watchMoreUrl != null && watchMoreUrl.isNotEmpty)
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).pushNamed(
                      AppRouter.inappWebviewPage,
                      arguments: InAppWebViewPayload(watchMoreUrl));
                },
                child: Text(
                  'watch'.tr(),
                  style: theme.textTheme.ppMori400White14.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
