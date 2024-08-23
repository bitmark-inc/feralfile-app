import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
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
    this.homeIndex,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('NavigationPath: handle tap: $navigationRoute');
    await injector<NavigationService>().navigatePath(navigationRoute);
  }
}
