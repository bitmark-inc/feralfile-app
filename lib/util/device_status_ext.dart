import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/log.dart';

extension ListDeviceStatusExtension
    on List<Pair<BaseDevice, CheckDeviceStatusReply>> {
  Map<String, CheckDeviceStatusReply> get controllingDevices {
    final canvasClientServiceV2 = injector<CanvasClientServiceV2>();
    final Map<String, CheckDeviceStatusReply> controllingDeviceStatus = {};
    final thisDevice = canvasClientServiceV2.clientDeviceInfo;
    for (final devicePair in this) {
      final status = devicePair.second;
      if (status.connectedDevice?.deviceId == thisDevice.deviceId ||
          devicePair.first is FFBluetoothDevice) {
        controllingDeviceStatus[devicePair.first.deviceId] = status;
      } else {
        log.info(
            'Device ${devicePair.first.deviceId} is not controlling device');
      }
    }
    return controllingDeviceStatus;
  }
}

extension DeviceStatusExtension on CheckDeviceStatusReply {
  String? get playingArtworkKey {
    if (artworks.isEmpty && exhibitionId == null) {
      return null;
    }
    if (exhibitionId != null) {
      return exhibitionId.toString();
    }

    final hashCode = artworks.playArtworksHashCode;
    return hashCode.toString();
  }
}

extension PlayArtworksExtension on List<PlayArtworkV2> {
  int get playArtworksHashCode {
    final hashCodes = map((e) => e.playArtworkHashCode);
    final hashCode = hashCodes.reduce((value, element) => value ^ element);
    return hashCode;
  }
}

extension PlayArtworkExtension on PlayArtworkV2 {
  int get playArtworkHashCode {
    final id = token?.id ?? artwork?.url ?? '';
    return id.hashCode;
  }
}
