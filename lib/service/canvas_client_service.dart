import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart' as my_device;
import 'package:autonomy_tv_proto/autonomy_tv_proto.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class CanvasClientService {
  final AppDatabase _db;

  CanvasClientService(this._db);

  final List<CanvasDevice> _devices = [];
  late final String _deviceId;
  late final String _deviceName;
  bool _didInitialized = false;

  final _connectDevice = Lock();
  final AccountService _accountService = injector<AccountService>();
  final NavigationService _navigationService = injector<NavigationService>();

  Offset currentCursorOffset = Offset.zero;

  CallOptions get _callOptions => CallOptions(
      compression: const GzipCodec(), timeout: const Duration(seconds: 3));

  Future<void> init() async {
    if (_didInitialized) {
      return;
    }
    final device = my_device.DeviceInfo.instance;
    _deviceName = await device.getMachineName() ?? "Autonomy App";
    final account = await _accountService.getDefaultAccount();
    _deviceId = await account.getAccountDID();
    await syncDevices();
    _didInitialized = true;
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
      final index = _devices.indexWhere((element) => element.id == device.id);
      final request = ConnectRequest()
        ..device = (DeviceInfo()
          ..deviceId = _deviceId
          ..deviceName = _deviceName);

      final response = await stub.connect(
        request,
        options: _callOptions,
      );
      log.info('CanvasClientService received: ${response.ok}');
      if (response.ok) {
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
      rethrow;
    }
  }

  Future<void> disconnectToDevice(CanvasDevice device) async {
    _devices.remove(device);
    final request = DisconnectRequest()..deviceId = _deviceId;
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
      final request = CheckingStatus()..deviceId = _deviceId;
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
    _devices.clear();
    for (final device in devices) {
      if (device.isConnecting) {
        final status = await checkDeviceStatus(device);
        switch (status.first) {
          case CanvasServerStatus.playing:
          case CanvasServerStatus.connected:
            device.playingSceneId = status.second;
            device.isConnecting = true;
            await _db.canvasDeviceDao.updateCanvasDevice(device);
            _devices.add(device);
            break;
          case CanvasServerStatus.open:
            device.playingSceneId = status.second;
            device.isConnecting = false;
            await _db.canvasDeviceDao.updateCanvasDevice(device);
            _devices.add(device);
            break;
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

  Future<List<CanvasDevice>> getConnectingDevices() async {
    for (var device in _devices) {
      final status = await checkDeviceStatus(device);
      device.playingSceneId = status.second;
    }
    return _devices;
  }

  Future<void> _disconnectLocalDevice(CanvasDevice device) async {
    final updatedDevice = device.copyWith(isConnecting: false);
    updatedDevice.playingSceneId = null;
    await _db.canvasDeviceDao.updateCanvasDevice(updatedDevice);
  }

  Future<bool> castSingleArtwork(CanvasDevice device, String tokenId) async {
    final stub = _getStub(device);
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final playingDevice = _devices.firstWhereOrNull(
      (element) {
        return element.playingSceneId != null;
      },
    );
    if (playingDevice != null) {
      currentCursorOffset = await getCursorOffset(playingDevice);
    }
    final castRequest = CastSingleRequest()
      ..id = tokenId
      ..cursorDrag = (DragGestureRequest()
        ..dx = currentCursorOffset.dx
        ..dy = currentCursorOffset.dy
        ..coefficientX = 1 / size.width
        ..coefficientY = 1 / size.height);
    final response = await stub.castSingleArtwork(castRequest);
    if (response.ok) {
      final lst = _devices.firstWhereOrNull(
        (element) {
          final isEqual = element == device;
          return isEqual;
        },
      );
      lst?.playingSceneId = tokenId;
    } else {
      log.info('CanvasClientService: Failed to cast single artwork');
    }
    return response.ok;
  }

  Future<void> uncastSingleArtwork(CanvasDevice device) async {
    final stub = _getStub(device);
    final uncastRequest = UncastSingleRequest()..id = "";
    final response = await stub.unCastSingleArtwork(uncastRequest);
    if (response.ok) {
      _devices
          .firstWhereOrNull((element) => element == device)
          ?.playingSceneId = null;
    }
  }

  Future<void> sendKeyBoard(List<CanvasDevice> devices, int code) async {
    for (var device in devices) {
      final stub = _getStub(device);
      final sendKeyboardRequest = KeyboardEventRequest()..code = code;
      final response = await stub.keyboardEvent(sendKeyboardRequest);
      if (response.ok) {
        log.info("Canvas Client Service: Keyboard Event Success $code");
      } else {
        log.info("Canvas Client Service: Keyboard Event Failed $code");
      }
    }
  }

  // function to rotate canvas
  Future<void> rotateCanvas(CanvasDevice device,
      {bool clockwise = true}) async {
    final stub = _getStub(device);
    final rotateCanvasRequest = RotateRequest()..clockwise = clockwise;
    try {
      final response = await stub.rotate(rotateCanvasRequest);
      log.info(
          "Canvas Client Service: Rotate Canvas Success ${response.degree}");
    } catch (e) {
      log.info("Canvas Client Service: Rotate Canvas Failed");
    }
  }

  Future<void> tap(List<CanvasDevice> devices) async {
    for (var device in devices) {
      final stub = _getStub(device);
      final tapRequest = TapGestureRequest();
      await stub.tapGesture(tapRequest);
    }
  }

  Future<void> drag(
      List<CanvasDevice> devices, Offset offset, Size touchpadSize) async {
    final dragRequest = DragGestureRequest()
      ..dx = offset.dx
      ..dy = offset.dy
      ..coefficientX = 1 / touchpadSize.width
      ..coefficientY = 1 / touchpadSize.height;
    currentCursorOffset += offset;
    for (var device in devices) {
      final stub = _getStub(device);
      await stub.dragGesture(dragRequest);
    }
  }

  Future<Offset> getCursorOffset(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.getCursorOffset(Empty());
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final dx = size.width * response.coefficientX * response.dx;
    final dy = size.height * response.coefficientY * response.dy;
    return Offset(dx, dy);
  }

  Future<void> setCursorOffset(CanvasDevice device) async {
    final stub = _getStub(device);
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final dx = currentCursorOffset.dx / size.width;
    final dy = currentCursorOffset.dy / size.height;
    final request = CursorOffset()
      ..dx = dx
      ..dy = dy
      ..coefficientX = 1 / size.width
      ..coefficientY = 1 / size.height;

    await stub.setCursorOffset(request);
  }
}

enum CanvasServerStatus {
  open,
  connected,
  playing,
  notServing,
  error;

  DeviceStatus get toDeviceStatus {
    switch (this) {
      case CanvasServerStatus.error:
      case CanvasServerStatus.notServing:
      case CanvasServerStatus.open:
      case CanvasServerStatus.connected:
        return DeviceStatus.connected;
      case CanvasServerStatus.playing:
        return DeviceStatus.playing;
    }
  }
}

extension CanvasServerStatusExt on CanvasServerStatus {}
