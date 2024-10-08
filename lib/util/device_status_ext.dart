import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';

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
