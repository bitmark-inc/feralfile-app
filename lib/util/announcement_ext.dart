import 'package:autonomy_flutter/database/entity/announcement_local.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:easy_localization/easy_localization.dart';

extension AnnouncementLocalExt on AnnouncementLocal {
  AnnouncementType get announcementType {
    switch (announcementContextId) {
      case 'memento6':
        return AnnouncementType.Memento6;
      default:
        return AnnouncementType.Unknown;
    }
  }

  String get notificationTitle {
    switch (announcementType) {
      case AnnouncementType.Memento6:
        return 'memento6_announcement_title'.tr();
      default:
        return 'au_has_announcement'.tr();
    }
  }
}

enum AnnouncementType {
  Memento6,
  Unknown;

  @override
  String toString() {
    switch (this) {
      case AnnouncementType.Memento6:
        return 'memento6';
      default:
        return 'unknown';
    }
  }

  static AnnouncementType fromString(String type) {
    switch (type) {
      case 'memento6':
        return AnnouncementType.Memento6;
      default:
        return AnnouncementType.Unknown;
    }
  }
}

class ShowAnouncementNotificationInfo {
  Map<String, int> showAnnouncementMap = {};

  ShowAnouncementNotificationInfo();

  ShowAnouncementNotificationInfo.withMap({required this.showAnnouncementMap});

  ShowAnouncementNotificationInfo merge(ShowAnouncementNotificationInfo other) {
    showAnnouncementMap.addAll(other.showAnnouncementMap);
    return this;
  }

  // toJson
  Map<String, dynamic> toJson() => showAnnouncementMap;

  // fromJson
  factory ShowAnouncementNotificationInfo.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return ShowAnouncementNotificationInfo();
    }
    return ShowAnouncementNotificationInfo.withMap(
        showAnnouncementMap: json.map((key, value) =>
            MapEntry(key, int.tryParse(value.toString()) ?? 0)));
  }
}
