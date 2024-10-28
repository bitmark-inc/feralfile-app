import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

class HavingTroubleView extends StatelessWidget {
  const HavingTroubleView({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: GestureDetector(
          onTap: () async {
            await Navigator.of(context).pushNamed(
              AppRouter.supportThreadPage,
              arguments: NewIssuePayload(
                reportIssueType: ReportIssueType.Bug,
              ),
            );
          },
          child: Text(
            'having_trouble'.tr(),
            style: Theme.of(context).textTheme.ppMori400Grey14.copyWith(
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      );
}
