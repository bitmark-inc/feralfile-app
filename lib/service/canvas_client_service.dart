//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

class CanvasClientService {
  final AppDatabase _db;
  final DeviceInfoService _deviceInfoService;

  CanvasClientService(this._db, this._deviceInfoService);

  final List<CanvasDevice> _viewingDevices = [];

  final _connectDevice = Lock();
  final NavigationService _navigationService = injector<NavigationService>();

  Offset currentCursorOffset = Offset.zero;

  CallOptions get _callOptions => CallOptions(
      compression: const GzipCodec(), timeout: const Duration(seconds: 10));

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
          ..deviceId = _deviceInfoService.deviceId
          ..deviceName = _deviceInfoService.deviceName);

      final response = await stub.connect(
        request,
        options: _callOptions,
      );
      log.info('CanvasClientService connect: ${response.ok}');
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
      final request = CheckingStatus()..deviceId = _deviceInfoService.deviceId;
      final response = await stub.status(
        request,
        options: _callOptions,
      );
      log.info('CanvasClientService received: ${response.status}');
      switch (response.status) {
        case ResponseStatus_ServingStatus.NOT_SERVING:
        case ResponseStatus_ServingStatus.SERVICE_UNKNOWN:
          status = CanvasServerStatus.notServing;
        case ResponseStatus_ServingStatus.SERVING:
          if (response.sceneId.isNotEmpty) {
            status = CanvasServerStatus.playing;
            sceneId = response.sceneId;
          } else {
            status = CanvasServerStatus.connected;
          }
        case ResponseStatus_ServingStatus.UNKNOWN:
          status = CanvasServerStatus.open;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      status = CanvasServerStatus.error;
    }
    return Pair(status, sceneId);
  }

  Future<List<CanvasDevice>> _findRawDevices() async {
    final devices = <CanvasDevice>[];
    final localDevices = await _db.canvasDeviceDao.getCanvasDevices();
    devices.addAll(await refreshDevices(localDevices));
    return devices;
  }

  /// This method will check the status of the devices by calling grpc
  Future<List<CanvasDevice>> refreshDevices(List<CanvasDevice> devices) async {
    final List<CanvasDevice> workingDevices = [];
    await Future.forEach<CanvasDevice>(devices, (device) async {
      final status = await checkDeviceStatus(device);
      switch (status.first) {
        case CanvasServerStatus.playing:
        case CanvasServerStatus.connected:
          device.playingSceneId = status.second;
          device.isConnecting = true;
          workingDevices.add(device);
        case CanvasServerStatus.open:
          device.playingSceneId = status.second;
          device.isConnecting = false;
          workingDevices.add(device);
        case CanvasServerStatus.notServing:
          break;
        case CanvasServerStatus.error:
          break;
      }
    });
    log.info('CanvasClientService refresh device ${workingDevices.length}');
    return workingDevices;
  }

  /// This method will get devices saved in memory, no status check
  Future<List<CanvasDevice>> getConnectingDevices() async => _viewingDevices;

  /// This method will get devices via mDNS and local db, for local db devices
  /// it will check the status of the device by calling grpc,
  /// it will return the devices that are available and save in memory
  Future<List<CanvasDevice>> scanDevices() async {
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

  Future<void> unCastSingleArtwork(CanvasDevice device) async {
    final stub = _getStub(device);
    final unCastRequest = UncastSingleRequest()..id = '';
    final response = await stub.uncastSingleArtwork(unCastRequest);
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
