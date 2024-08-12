import 'package:autonomy_flutter/service/hive_store_service.dart';
import 'package:feralfile_app_tv_proto/models/canvas_device.dart';

class CanvasDeviceStore extends HiveStoreObjectServiceImpl<CanvasDevice> {
  static const String _key = 'local.canvas_device';

  @override
  Future<void> init(String key) async {
    await super.init(_key);
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
