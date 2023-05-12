import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/canvas_device.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/src/generated/canvas_control/canvas_control.pbgrpc.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:grpc/grpc.dart';

class CanvasClientService {
  final AppDatabase _db;

  CanvasClientService(this._db);

  final List<CanvasDevice> _devices = [];
  late final String _deviceId;
  late final String _deviceName;

  CallOptions get _callOptions => CallOptions(compression: const GzipCodec());

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
        options: _callOptions,
      );
      log.info('CanvasClientService received: ${response.message}');
      if (response.message == "connect_accepted") {
        log.info('CanvasClientService: Connected to device');
        await _db.canvasDeviceDao.insertCanvasDevice(device);
        _devices.add(device);
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
    _devices.remove(device);
    await _disconnectLocalDevice(device);
    final channel = _getChannel(device);
    await channel.shutdown();
  }

  Future<Pair<CanvasServerStatus, String?>> checkDeviceStatus(
      CanvasDevice device) async {
    final stub = _getStub(device);
    late CanvasServerStatus status;
    try {
      final request = CheckingStatus(deviceId: _deviceId);
      final response = await stub.status(
        request,
        options: _callOptions,
      );
      log.info('CanvasClientService received: ${response.status}');
      switch (response.status) {
        case "disconnected":
          status = CanvasServerStatus.disconnected;
          break;
        case "connected":
          status = CanvasServerStatus.connected;
          break;
        case "occupied":
          status = CanvasServerStatus.occupied;
          break;
        default:
          status = CanvasServerStatus.error;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      status = CanvasServerStatus.error;
    }
    return Pair(status, device.playingSceneId);
  }

  Future<void> updateDevices() async {
    // check if device is still connected, if not, disconnect and remove from list devices
    for (final device in _devices) {
      final status = await checkDeviceStatus(device);
      if (status.first != CanvasServerStatus.connected) {
        await disconnectToDevice(device);
      }
    }
  }

  Future<void> syncDevices() async {
    final devices = await _db.canvasDeviceDao.getCanvasDevices();
    for (final device in devices) {
      if (device.isConnecting) {
        final status = await checkDeviceStatus(device);
        switch (status.first) {
          case CanvasServerStatus.connected:
            device.playingSceneId = status.second;
            await _db.canvasDeviceDao.insertCanvasDevice(device);
            _devices.add(device);
            break;
          case CanvasServerStatus.disconnected:
          case CanvasServerStatus.occupied:
            await _disconnectLocalDevice(device);
            break;
          default:
            break;
        }
      }
    }
  }

  Future<List<CanvasDevice>> getAllDevices() async {
    final devices = await _db.canvasDeviceDao.getCanvasDevices();
    return devices;
  }

  Future<void> _disconnectLocalDevice(CanvasDevice device) async {
    final updatedDevice = device.copyWith(isConnecting: false);
    updatedDevice.playingSceneId = null;
    await _db.canvasDeviceDao.insertCanvasDevice(updatedDevice);
  }
}

enum CanvasServerStatus {
  disconnected,
  connected,
  occupied,
  error,
}
