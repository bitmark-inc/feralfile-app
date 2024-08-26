import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:hive/hive.dart';

class CanvasDeviceAdapter extends TypeAdapter<CanvasDevice> {
  @override
  final int typeId = 0;

  @override
  CanvasDevice read(BinaryReader reader) => CanvasDevice(
        deviceId: reader.readString(),
        locationId: reader.readString(),
        topicId: reader.readString(),
        name: reader.readString(),
      );

  @override
  void write(BinaryWriter writer, CanvasDevice obj) {
    writer
      ..writeString(obj.deviceId)
      ..writeString(obj.locationId)
      ..writeString(obj.topicId)
      ..writeString(obj.name);
  }
}
