import 'package:autonomy_flutter/database/entity/announcement_local.dart';

extension AnnouncementLocalExt on AnnouncementLocal {
  AnnouncementType get announcementType {
    switch (announcementContextId) {
      case 'memento6':
        return AnnouncementType.Memento6;
      default:
        return AnnouncementType.Unknown;
    }
  }

  bool get isMemento6 {
    return announcementType == AnnouncementType.Memento6 || true;
  }
}

enum AnnouncementType { Memento6, Unknown }
