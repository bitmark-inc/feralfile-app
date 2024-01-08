import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/help_us/inapp_webview.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    final eventMediaUrl = getFFUrl(exhibitionEvent.mediaUri?.url);
    final eventUrl = exhibitionEvent.links?.isNotEmpty == true
        ? exhibitionEvent.links!.values.first
        : null;

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
            if (eventMediaUrl != null) ...[
              Image.network(
                eventMediaUrl,
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
              Text(
                exhibitionEvent.description!,
                style: theme.textTheme.ppMori400White14,
              ),
              const SizedBox(height: 20),
            ],
            if (eventUrl != null)
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).pushNamed(
                      AppRouter.inappWebviewPage,
                      arguments: InAppWebViewPayload(eventUrl));
                },
                child: Text(
                  'watch_more'.tr(),
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
