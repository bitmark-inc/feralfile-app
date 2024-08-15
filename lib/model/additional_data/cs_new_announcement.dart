import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class CsNewAnnouncement extends AdditionalData {
  final String announcementId;

  CsNewAnnouncement(
      {required this.announcementId, required super.notificationType});

  @override
  Future<void> handleTap(
      BuildContext context, PageController? pageController) async {
    log.info('CsNewAnnouncement: handle tap: $announcementId');
    await injector<CustomerSupportService>().fetchAnnouncement();
    final announcement = await injector<CustomerSupportService>()
        .findAnnouncement(announcementId);
    if (announcement != null) {
      if (!context.mounted) {
        return;
      }
      unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.supportThreadPage,
        (route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition,
        arguments: NewIssuePayload(
          reportIssueType: ReportIssueType.Announcement,
          announcement: announcement,
        ),
      ));
    }
  }
}
