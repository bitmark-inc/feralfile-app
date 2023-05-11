import 'package:autonomy_flutter/database/entity/canvas_device.dart';
import 'package:autonomy_flutter/src/generated/canvas_control/canvas_control.pbgrpc.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:grpc/grpc.dart';
import 'package:uuid/uuid.dart';

class CanvasClientService {
  List<CanvasDevice> _devices = [];
  CanvasDevice? _currentDevice;
  ClientChannel? _channel;
  CanvasControlClient? _stub;

  CanvasDevice? get currentDevice => _currentDevice;

  Future<bool> connectToDevice(CanvasDevice device) async {
    if (_currentDevice == device) {
      return false;
    }
    if (_channel != null) {
      _channel!.shutdown();
    }
    _currentDevice = device;
    _channel = ClientChannel(
      device.ip,
      port: device.port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _stub = CanvasControlClient(
      _channel!,
    );
    try {
      final device = DeviceInfo.instance;
      String deviceName = await device.getMachineName() ?? "Autonomy App";
      String connectionId = const Uuid().v4();
      final request = ConnectRequest(
          deviceName: deviceName,
          connectionId: connectionId,
          message: "connect_request");
      final response = await _stub!.connect(
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
}
