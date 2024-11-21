import 'package:autonomy_flutter/model/additional_data/additional_data.dart';

class AnnouncementData extends AdditionalData {
  AnnouncementData({
    required super.notificationType,
    super.announcementContentId,
    super.cta,
    super.title,
    super.listCustomCta,
  });
}
