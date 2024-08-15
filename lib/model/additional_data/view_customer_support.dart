import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class ViewCustomerSupport extends AdditionalData {
  final String issueID;

  ViewCustomerSupport({required this.issueID, required super.notificationType});

  @override
  Future<void> handleTap(
      BuildContext context, PageController? pageController) async {
    log.info('ViewCustomerSupport: handle tap: $issueID');
    final announcement = await injector<CustomerSupportService>()
        .findAnnouncementFromIssueId(issueID);
    if (!context.mounted) {
      return;
    }
    unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.supportThreadPage,
      (route) =>
          route.settings.name == AppRouter.homePage ||
          route.settings.name == AppRouter.homePageNoTransition,
      arguments: DetailIssuePayload(
          reportIssueType: '', issueID: issueID, announcement: announcement),
    ));
  }
}
