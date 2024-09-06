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
    await injector.get<SelectedCanvasDeviceStore>().delete(objId);
  }
}

class SelectedCanvasDeviceStore
    extends HiveStoreObjectServiceImpl<CanvasDevice> {
  static const String _key = 'local.selected_canvas_device';

  @override
  Future<void> init(String key) async {
    await super.init(_key);
  }
}
