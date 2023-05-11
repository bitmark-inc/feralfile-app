import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/canvas_device.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/src/generated/canvas_control/canvas_control.pbgrpc.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:grpc/grpc.dart';

class CanvasClientService {
  final List<CanvasDevice> _devices = [];
  late final String _deviceId;
  late final String _deviceName;

  Future<void> init() async {
    final device = DeviceInfo.instance;
    _deviceName = await device.getMachineName() ?? "Autonomy App";
    final account = await injector<AccountService>().getDefaultAccount();
    _deviceId = await account.getAccountDID();
  }

  ClientChannel _getChannel(CanvasDevice device) {
    return ClientChannel(
      device.ip,
      port: device.port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
  }

  CanvasControlClient _getStub(CanvasDevice device) {
    final channel = _getChannel(device);
    return CanvasControlClient(channel);
  }

  Future<bool> connectToDevice(CanvasDevice device) async {
    if (_devices.contains(device)) {
      log.info('CanvasClientService: Already connected to device');
      return true;
    }
    final stub = _getStub(device);
    try {
      final request = ConnectRequest(
          deviceName: _deviceName,
          deviceId: _deviceId,
          message: "connect_request");
      final response = await stub.connect(
        request,
        options: CallOptions(compression: const GzipCodec()),
      );
      log.info('CanvasClientService received: ${response.message}');
      if (response.message == "connect_accepted") {
        log.info('CanvasClientService: Connected to device');
        return true;
      } else {
        log.info('CanvasClientService: Failed to connect to device');
        return false;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      return false;
    }
  }

  Future<void> disconnectToDevice(CanvasDevice device) async {
    final channel = _getChannel(device);
    await channel.shutdown();
  }

  Future<CanvasServerStatus> checkDeviceStatus(CanvasDevice device) async {
    final stub = _getStub(device);
    try {
      final request = CheckingStatus();
      final response = await stub.status(
        request,
        options: CallOptions(compression: const GzipCodec()),
      );
      log.info('CanvasClientService received: ${response.status}');
      if (response.status == "occupied") {
        return CanvasServerStatus.occupied;
      } else if (response.status == "connected") {
        return CanvasServerStatus.connected;
      } else {
        return CanvasServerStatus.notOpened;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      return CanvasServerStatus.notOpened;
    }
  }
}

enum CanvasServerStatus {
  notOpened,
  connected,
  occupied,
}
