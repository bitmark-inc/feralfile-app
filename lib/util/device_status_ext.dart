import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';

extension ListDeviceStatusExtension
    on List<Pair<CanvasDevice, CheckDeviceStatusReply>> {
  Map<String, CheckDeviceStatusReply> get controllingDevices {
    final canvasClientServiceV2 = injector<CanvasClientServiceV2>();
    final Map<String, CheckDeviceStatusReply> controllingDeviceStatus = {};
    final thisDevice = canvasClientServiceV2.clientDeviceInfo;
    for (final devicePair in this) {
      final status = devicePair.second;
      if (status.connectedDevice?.deviceId == thisDevice.deviceId) {
        controllingDeviceStatus[devicePair.first.deviceId] = status;
        break;
      }
    }
    return controllingDeviceStatus;
  }
}
