import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/cupertino.dart';

class ViewExhibitionData extends AdditionalData {
  final String exhibitionId;

  ViewExhibitionData({
    required this.exhibitionId,
    required super.notificationType,
    super.announcementContentId,
  });

  @override
  bool get isTappable => true;

  @override
  Future<void> handleTap(BuildContext context) async {
    log.info('ViewExhibition: handle tap: $exhibitionId');
    await injector<NavigationService>().gotoExhibitionDetailsPage(exhibitionId);
  }
}
