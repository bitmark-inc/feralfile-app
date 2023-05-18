import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart' as my_device;
import 'package:autonomy_tv_proto/autonomy_tv_proto.dart';
import 'package:synchronized/synchronized.dart';

class CanvasClientService {
  final AppDatabase _db;

  CanvasClientService(this._db);

  final List<CanvasDevice> _devices = [];
  late final String _deviceId;
  late final String _deviceName;

  final _connectDevice = Lock();

  CallOptions get _callOptions => CallOptions(
      compression: const GzipCodec(), timeout: const Duration(seconds: 3));

  Future<void> init() async {
    final device = my_device.DeviceInfo.instance;
    _deviceName = await device.getMachineName() ?? "Autonomy App";
    final account = await injector<AccountService>().getDefaultAccount();
    _deviceId = await account.getAccountDID();
    await syncDevices();
  }

  Future<void> shutdownAll() async {
    await Future.wait(_devices.map((e) => shutDown(e)));
  }

  Future<void> shutDown(CanvasDevice device) async {
    final channel = _getChannel(device);
    await channel.shutdown();
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
    return _connectDevice.synchronized(() async {
      return await _connectToDevice(device);
    });
  }

  Future<bool> _connectToDevice(CanvasDevice device) async {
    final stub = _getStub(device);
    try {
      final index = _devices.indexWhere((element) =>
          element.id == device.id &&
          element.ip == device.ip &&
          element.port == device.port);
      final request = ConnectRequest(
          device: DeviceInfo(deviceId: _deviceId, deviceName: _deviceName));
      final response = await stub.connect(
        request,
        options: _callOptions,
      );
      log.info('CanvasClientService received: ${response.status}');
      if (response.status) {
        log.info('CanvasClientService: Connected to device');
        device.isConnecting = true;
        await _db.canvasDeviceDao.insertCanvasDevice(device);
        if (index == -1) {
          _devices.add(device);
        } else {
          _devices[index].isConnecting = true;
        }
        return true;
      } else {
        log.info('CanvasClientService: Failed to connect to device');
        if (index != -1) {
          _devices[index].isConnecting = false;
        }
        return false;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      return false;
    }
  }

  Future<void> disconnectToDevice(CanvasDevice device) async {
    _devices.remove(device);
    final request = DisconnectRequest(deviceId: _deviceId);
    final stub = _getStub(device);
    await stub.disconnect(request);
    await _disconnectLocalDevice(device);
    final channel = _getChannel(device);
    await channel.shutdown();
    log.info('CanvasClientService: Disconnected to device');
  }

  Future<Pair<CanvasServerStatus, String?>> checkDeviceStatus(
      CanvasDevice device) async {
    final stub = _getStub(device);
    String? sceneId;
    late CanvasServerStatus status;
    try {
      final request = CheckingStatus(deviceId: _deviceId);
      final response = await stub.status(
        request,
        options: _callOptions,
      );
      log.info('CanvasClientService received: ${response.status}');
      switch (response.status) {
        case ResponseStatus_ServingStatus.NOT_SERVING:
        case ResponseStatus_ServingStatus.SERVICE_UNKNOWN:
          status = CanvasServerStatus.notServing;
          break;
        case ResponseStatus_ServingStatus.SERVING:
          if (response.sceneId.isNotEmpty) {
            status = CanvasServerStatus.playing;
            sceneId = response.sceneId;
          } else {
            status = CanvasServerStatus.connected;
          }
          break;
        case ResponseStatus_ServingStatus.UNKNOWN:
          status = CanvasServerStatus.open;
          break;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      status = CanvasServerStatus.error;
    }
    return Pair(status, sceneId);
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
    _devices.removeRange(0, _devices.length);
    for (final device in devices) {
      if (device.isConnecting) {
        final status = await checkDeviceStatus(device);
        switch (status.first) {
          case CanvasServerStatus.playing:
          case CanvasServerStatus.connected:
            device.playingSceneId = status.second;
            await _db.canvasDeviceDao.insertCanvasDevice(device);
            _devices.add(device);
            break;
          case CanvasServerStatus.open:
          case CanvasServerStatus.notServing:
            await _disconnectLocalDevice(device);
            break;
          case CanvasServerStatus.error:
            break;
        }
      }
    }
  }

  Future<List<CanvasDevice>> getAllDevices() async {
    final devices = await _db.canvasDeviceDao.getCanvasDevices();
    return devices;
  }

  List<CanvasDevice> getConnectingDevices() {
    return _devices;
  }

  Future<void> _disconnectLocalDevice(CanvasDevice device) async {
    final updatedDevice = device.copyWith(isConnecting: false);
    updatedDevice.playingSceneId = null;
    await _db.canvasDeviceDao.updateCanvasDevice(updatedDevice);
  }

  Future<void> castSingleArtwork(CanvasDevice device, String tokenId) async {
    final stub = _getStub(device);
    final castRequest = CastSingleRequest(id: tokenId);
    final response = await stub.castSingleArtwork(castRequest);
    if (response.status) {
      final lst = _devices.firstWhere(
        (element) {
          final isEqual = element == device;
          return isEqual;
        },
      );
      lst.playingSceneId = tokenId;
    }
  }

  Future<void> uncastSingleArtwork(CanvasDevice device) async {
    final stub = _getStub(device);
    final uncastRequest = UncastSingleRequest(id: "");
    final response = await stub.uncastSingleArtwork(uncastRequest);
    if (response.status) {
      _devices.firstWhere((element) => element == device).playingSceneId = null;
    }
  }
}

enum CanvasServerStatus {
  open,
  connected,
  playing,
  notServing,
  error,
}
