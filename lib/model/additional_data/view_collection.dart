import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';

class ViewCollection extends AdditionalData {
  ViewCollection({
    required super.notificationType,
    super.announcementContentId,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(
      BuildContext context, PageController? pageController) async {
    log.info('ViewCollection: handle tap');
    if (pageController != null) {
      Navigator.of(context).popUntil((route) =>
          route.settings.name == AppRouter.homePage ||
          route.settings.name == AppRouter.homePageNoTransition);
      pageController.jumpToPage(HomeNavigatorTab.collection.index);
    }
  }
}
