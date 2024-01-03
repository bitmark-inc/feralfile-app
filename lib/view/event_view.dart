import 'package:autonomy_flutter/model/ff_exhibition.dart';
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
            Text(exhibitionEvent.title,
                style: theme.textTheme.ppMori400White14),
            const SizedBox(height: 20),
            Text(
              'Date: ${dateFormat.format(exhibitionEvent.dateTime)}',
              style: theme.textTheme.ppMori400White14,
            ),
            Text(
              'Time: ${timeFormat.format(exhibitionEvent.dateTime)}',
              style: theme.textTheme.ppMori400White14,
            ),
            Text(
              exhibitionEvent.description,
              style: theme.textTheme.ppMori400White14,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {},
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
