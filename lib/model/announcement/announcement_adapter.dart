import 'package:autonomy_flutter/model/announcement/announcement_local.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AnnouncementLocalAdapter extends TypeAdapter<AnnouncementLocal> {
  @override
  final int typeId = 10;

  @override
  AnnouncementLocal read(BinaryReader reader) => AnnouncementLocal(
        announcementContentId: reader.readString(),
        content: reader.readString(),
        additionalData: reader.readMap().cast<String, dynamic>(),
        startedAt: reader.readInt(),
        endedAt: reader.readInt(),
        read: reader.readBool(),
      );

  @override
  void write(BinaryWriter writer, AnnouncementLocal obj) {
    writer
      ..writeString(obj.announcementContentId)
      ..writeString(obj.content)
      ..writeMap(obj.additionalData)
      ..writeInt(obj.startedAt)
      ..writeInt(obj.endedAt)
      ..writeBool(obj.read);
  }
}
