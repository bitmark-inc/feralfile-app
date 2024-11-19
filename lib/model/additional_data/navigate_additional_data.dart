import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class NavigateAdditionalData extends AdditionalData {
  final String navigationRoute;
  final int? homeIndex;

  NavigateAdditionalData({
    required this.navigationRoute,
    required super.notificationType,
    super.announcementContentId,
    super.cta,
    this.homeIndex,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('NavigationPath: handle tap: $navigationRoute');
    if (navigationRoute == AppRouter.supportCustomerPage &&
        announcementContentId != null) {
      final announcement = injector<AnnouncementService>()
          .getAnnouncement(announcementContentId);
      if (announcement != null) {
        await injector<NavigationService>().navigateTo(
          AppRouter.supportThreadPage,
          arguments: ChatSupportPayload(announcement: announcement),
        );
      }
      return;
    }
    await injector<NavigationService>().navigatePath(navigationRoute);
  }
}
