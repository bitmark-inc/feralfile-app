import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/shared_postcard.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/mdns_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart' as my_device;
import 'package:collection/collection.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

class CanvasClientService {
  final AppDatabase _db;

  CanvasClientService(this._db);

  final List<CanvasDevice> _viewingDevices = [];
  late final String _deviceId;
  late final String _deviceName;
  bool _didInitialized = false;

  final _connectDevice = Lock();
  final AccountService _accountService = injector<AccountService>();
  final NavigationService _navigationService = injector<NavigationService>();
  final MDnsService _mdnsService = MDnsService();

  Offset currentCursorOffset = Offset.zero;

  CallOptions get _callOptions => CallOptions(
      compression: const GzipCodec(), timeout: const Duration(seconds: 3));

  Future<void> init() async {
    if (_didInitialized) {
      return;
    }
    final device = my_device.DeviceInfo.instance;
    _deviceName = await device.getMachineName() ?? 'Autonomy App';
    final account = await _accountService.getDefaultAccount();
    _deviceId = await account.getAccountDID();
    _didInitialized = true;
  }

  Future<void> shutdownAll() async {
    await Future.wait(_viewingDevices.map((e) => shutDown(e)));
  }

  Future<void> shutDown(CanvasDevice device) async {
    final channel = _getChannel(device);
    await channel.shutdown();
  }

  ClientChannel _getChannel(CanvasDevice device) => ClientChannel(
        device.ip,
        port: device.port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );

  CanvasControlClient _getStub(CanvasDevice device) {
    final channel = _getChannel(device);
    return CanvasControlClient(channel);
  }

  Future<bool> connectToDevice(CanvasDevice device,
          {bool isLocal = false}) async =>
      _connectDevice
          .synchronized(() async => await _connectToDevice(device, isLocal));

  Future<bool> _connectToDevice(CanvasDevice device, bool isLocal) async {
    final stub = _getStub(device);
    try {
      final request = ConnectRequest()
        ..device = (DeviceInfo()
          ..deviceId = _deviceId
          ..deviceName = _deviceName);

      final response = await stub.connect(
        request,
        options: _callOptions,
      );
      log.info('CanvasClientService received: ${response.ok}');
      final index =
          _viewingDevices.indexWhere((element) => element.ip == device.ip);
      if (response.ok) {
        log.info('CanvasClientService: Connected to device');
        device.isConnecting = true;
        if (index == -1) {
          _viewingDevices.add(device);
        } else {
          _viewingDevices[index].isConnecting = true;
        }
        if (!isLocal) {
          await _db.canvasDeviceDao.insertCanvasDevice(device);
        }
        return true;
      } else {
        log.info('CanvasClientService: Failed to connect to device');
        if (index != -1) {
          _viewingDevices[index].isConnecting = false;
        }
        return false;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      rethrow;
    }
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

  Future<void> syncDevices() async {
    final devices = await getAllDevices();
    final List<CanvasDevice> devicesToAdd = [];
    await Future.forEach<CanvasDevice>(devices, (device) async {
      final status = await checkDeviceStatus(device);
      switch (status.first) {
        case CanvasServerStatus.playing:
        case CanvasServerStatus.connected:
          device.playingSceneId = status.second;
          device.isConnecting = true;
          devicesToAdd.add(device);
          break;
        case CanvasServerStatus.open:
          device.playingSceneId = status.second;
          device.isConnecting = false;
          devicesToAdd.add(device);
          break;
        case CanvasServerStatus.notServing:
          break;
        case CanvasServerStatus.error:
          break;
      }
    });
    _viewingDevices
      ..clear()
      ..addAll(devicesToAdd)
      ..unique((element) => element.ip);
    log.info(
        'CanvasClientService sync device available ${_viewingDevices.length}');
  }

  Future<List<CanvasDevice>> getAllDevices() async => _viewingDevices;

  Future<List<CanvasDevice>> getConnectingDevices({bool doSync = false}) async {
    if (doSync) {
      await syncDevices();
    } else {
      for (var device in _viewingDevices) {
        final status = await checkDeviceStatus(device);
        device.playingSceneId = status.second;
      }
    }
    return _viewingDevices;
  }

  Future<bool> castSingleArtwork(CanvasDevice device, String tokenId) async {
    final stub = _getStub(device);
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final playingDevice = _viewingDevices.firstWhereOrNull(
      (element) => element.playingSceneId != null,
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
      final lst = _viewingDevices.firstWhereOrNull(
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
    final uncastRequest = UncastSingleRequest()..id = '';
    final response = await stub.uncastSingleArtwork(uncastRequest);
    if (response.ok) {
      _viewingDevices
          .firstWhereOrNull((element) => element == device)
          ?.playingSceneId = null;
    }
  }

  Future<bool> castCollection(
      CanvasDevice device, PlayListModel playlist) async {
    if (playlist.tokenIDs == null || playlist.tokenIDs!.isEmpty) {
      return false;
    }
    final stub = _getStub(device);

    final castRequest = CastCollectionRequest()
      ..id = playlist.id ?? const Uuid().v4()
      ..artworks.addAll(playlist.tokenIDs!.map((e) => PlayArtwork()
        ..id = e
        ..duration = playlist.playControlModel?.timer ?? 10));
    final response = await stub.castCollection(castRequest);
    if (response.ok) {
      _viewingDevices
          .firstWhereOrNull((element) => element == device)
          ?.playingSceneId = playlist.id;
    } else {
      log.info('CanvasClientService: Failed to cast collection');
    }
    return response.ok;
  }

  Future<void> unCast(CanvasDevice device) async {
    final stub = _getStub(device);
    final unCastRequest = UnCastRequest()..id = '';
    final response = await stub.unCastArtwork(unCastRequest);
    if (response.ok) {
      _viewingDevices
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
        log.info('CanvasClientService: Keyboard Event Success $code');
      } else {
        log.info('CanvasClientService: Keyboard Event Failed $code');
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
      log.info('CanvasClientService: Rotate Canvas Success ${response.degree}');
    } catch (e) {
      log.info('CanvasClientService: Rotate Canvas Failed');
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

  Future<List<CanvasDevice>> _findRawDevices() async {
    final devices = <CanvasDevice>[];
    final discoverDevices = await _mdnsService.findCanvas();
    final localDevices = await _db.canvasDeviceDao.getCanvasDevices();
    devices
      ..addAll(discoverDevices)
      ..addAll(localDevices)
      ..unique((element) => element.ip);
    return devices;
  }

  Future<List<CanvasDevice>> fetchDevices() async {
    final devices = await _findRawDevices();

    // remove devices that are not available
    _viewingDevices.removeWhere(
        (element) => !devices.any((current) => current.ip == element.ip));

    // add new devices
    for (var element in devices) {
      final index =
          _viewingDevices.indexWhere((current) => current.ip == element.ip);
      if (index == -1) {
        _viewingDevices.add(element);
      }
    }

    return _viewingDevices;
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
