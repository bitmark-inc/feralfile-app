import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/hive_store_service.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';

class CanvasDeviceStore extends HiveStoreObjectServiceImpl<CanvasDevice> {
  static const String _key = 'local.canvas_device';

  @override
  Future<void> init(String key) async {
    await super.init(_key);
  }

  @override
  Future<void> delete(String objId) async {
    await super.delete(objId);
    injector.get<SelectedCanvasDeviceStore>().getMap().forEach((key, value) {
      if (value.deviceId == objId) {
        injector.get<SelectedCanvasDeviceStore>().delete(key);
      }
    });
  }
}

class SelectedCanvasDeviceStore
    extends HiveStoreObjectServiceImpl<CanvasDevice> {
  static const String _key = 'local.selected_canvas_device';

  @override
  Future<void> init(String key) async {
    await super.init(_key);
  }

  @override
  Future<void> save(CanvasDevice obj, String objId) async {
    final currentDeviceIds = injector
        .get<CanvasDeviceStore>()
        .getAll()
        .map((e) => e.deviceId)
        .toList();
    if (currentDeviceIds.contains(obj.deviceId)) {
      getMap().forEach((key, value) {
        if (value.deviceId == obj.deviceId) {
          delete(key);
        }
      });
      await super.save(obj, objId);
    }
  }
}
