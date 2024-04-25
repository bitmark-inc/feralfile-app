import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class GetStartedBanner extends StatelessWidget {
  final Function? onClose;
  final Function? onGetStarted;
  final String title;

  const GetStartedBanner(
      {required this.title, super.key, this.onGetStarted, this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColor.auGreyBackground),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.ppMori400White14,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () {
                  onClose?.call();
                },
                iconSize: 18,
                constraints: const BoxConstraints(maxHeight: 18, maxWidth: 18),
                icon: const Icon(
                  AuIcon.close,
                  color: AppColor.white,
                ),
                padding: EdgeInsets.zero,
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          PrimaryAsyncButton(
            onTap: () {
              onGetStarted?.call();
            },
            text: 'get_started'.tr(),
          )
        ],
      ),
    );
  }
}
