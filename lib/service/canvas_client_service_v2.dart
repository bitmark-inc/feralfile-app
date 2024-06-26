//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/gateway/tv_cast_api.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/hive_store_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/tv_cast_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart' as my_device;
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';

class CanvasClientServiceV2 {
  final HiveStoreObjectService<CanvasDevice> _db;
  final DeviceInfoService _deviceInfoService;
  final TvCastApi _tvCastApi;
  final NavigationService _navigationService;
  Timer? _timer;
  final dragOffsets = <CursorOffset>[];

  CanvasClientServiceV2(this._db, this._deviceInfoService, this._tvCastApi,
      this._navigationService);

  Offset currentCursorOffset = Offset.zero;

  DeviceInfoV2 get clientDeviceInfo => DeviceInfoV2(
        deviceId: _deviceInfoService.deviceId,
        deviceName: _deviceInfoService.deviceName,
        platform: _platform,
      );

  TvCastService _getStub(CanvasDevice device) =>
      TvCastServiceImpl(_tvCastApi, device);

  Future<CheckDeviceStatusReply> getDeviceCastingStatus(
          CanvasDevice device) async =>
      _getDeviceCastingStatus(device);

  Future<CheckDeviceStatusReply> _getDeviceCastingStatus(
      CanvasDevice device) async {
    final stub = _getStub(device);
    final request = CheckDeviceStatusRequest();
    final response = await stub.status(request);
    log.info(
        'CanvasClientService2 status: ${response.connectedDevice?.deviceId}');
    return response;
  }

  DevicePlatform get _platform {
    final device = my_device.DeviceInfo.instance;
    if (device.isAndroid) {
      return DevicePlatform.android;
    } else if (device.isIOS) {
      return DevicePlatform.iOS;
    } else {
      return DevicePlatform.other;
    }
  }

  Future<Pair<CanvasDevice, CheckDeviceStatusReply>?> addQrDevice(
      CanvasDevice device) async {
    final deviceStatus = await _getDeviceStatus(device);
    if (deviceStatus != null) {
      await _db.save(device, device.deviceId);
      log.info('CanvasClientService: Added device to db ${device.name}');
      return deviceStatus;
    }
    return null;
  }

  Future<ConnectReplyV2> connect(CanvasDevice device) async {
    final stub = _getStub(device);
    final deviceInfo = clientDeviceInfo;
    final request = ConnectRequestV2(clientDevice: deviceInfo);
    final response = await stub.connect(request);
    return response;
  }

  Future<bool> connectToDevice(CanvasDevice device) async {
    try {
      final response = await connect(device);
      return response.ok;
    } catch (e) {
      log.info('CanvasClientService: connectToDevice error: $e');
      return false;
    }
  }

  Future<void> disconnectDevice(CanvasDevice device) async {
    final stub = _getStub(device);
    await stub.disconnect(DisconnectRequestV2());
  }

  Future<bool> castListArtwork(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    try {
      final canConnect = await connectToDevice(device);
      if (!canConnect) {
        return false;
      }
      final stub = _getStub(device);
      final castRequest = CastListArtworkRequest(artworks: artworks);

      final response = await stub.castListArtwork(castRequest);
      return response.ok;
    } catch (e) {
      log.info('CanvasClientService: castListArtwork error: $e');
      return false;
    }
  }

  Future<bool> pauseCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.pauseCasting(PauseCastingRequest());
    return response.ok;
  }

  Future<bool> resumeCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.resumeCasting(ResumeCastingRequest());
    return response.ok;
  }

  Future<bool> nextArtwork(CanvasDevice device, {String? startTime}) async {
    final stub = _getStub(device);
    final request = NextArtworkRequest(
        startTime: startTime == null ? null : int.tryParse(startTime));

    final response = await stub.nextArtwork(request);
    return response.ok;
  }

  Future<bool> moveToArtwork(CanvasDevice device,
      {required String artworkId, String? startTime}) async {
    final stub = _getStub(device);
    final artwork =
        PlayArtworkV2(token: CastAssetToken(id: artworkId), duration: 0);
    final request = MoveToArtworkRequest(artwork: artwork);
    final reply = await stub.moveToArtwork(request);
    return reply.ok;
  }

  Future<bool> previousArtwork(CanvasDevice device, {String? startTime}) async {
    final stub = _getStub(device);
    final request = PreviousArtworkRequest(
        startTime: startTime == null ? null : int.tryParse(startTime));
    final response = await stub.previousArtwork(request);
    return response.ok;
  }

  Future<bool> appendListArtwork(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    final stub = _getStub(device);
    final response = await stub.appendListArtwork(
        AppendArtworkToCastingListRequest(artworks: artworks));
    return response.ok;
  }

  Future<bool> castExhibition(
      CanvasDevice device, CastExhibitionRequest castRequest) async {
    final canConnect = await connectToDevice(device);
    if (!canConnect) {
      return false;
    }
    final stub = _getStub(device);
    final response = await stub.castExhibition(castRequest);
    return response.ok;
  }

  Future<UpdateDurationReply> updateDuration(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    final stub = _getStub(device);
    final response =
        await stub.updateDuration(UpdateDurationRequest(artworks: artworks));
    return response;
  }

  List<CanvasDevice> _findRawDevices() {
    final devices = _db.getAll();
    return devices;
  }

  /// This method will get devices via mDNS and local db, for local db devices
  /// it will check the status of the device by calling grpc
  Future<List<Pair<CanvasDevice, CheckDeviceStatusReply>>> scanDevices() async {
    final rawDevices = _findRawDevices();
    final List<Pair<CanvasDevice, CheckDeviceStatusReply>> devices =
        await _getDeviceStatuses(rawDevices);
    devices.sort((a, b) => a.first.name.compareTo(b.first.name));
    return devices;
  }

  Future<List<Pair<CanvasDevice, CheckDeviceStatusReply>>> _getDeviceStatuses(
      List<CanvasDevice> devices) async {
    final List<Pair<CanvasDevice, CheckDeviceStatusReply>> statuses = [];
    await Future.wait(devices.map((device) async {
      try {
        final status = await _getDeviceStatus(device);
        if (status != null) {
          statuses.add(status);
        }
      } catch (e) {
        log.info('CanvasClientService: _getDeviceStatus error: $e');
      }
    }));
    return statuses;
  }

  Future<Pair<CanvasDevice, CheckDeviceStatusReply>?> _getDeviceStatus(
      CanvasDevice device) async {
    try {
      final status = await _getDeviceCastingStatus(device);
      return Pair(device, status);
    } catch (e) {
      log.info('CanvasClientService: _getDeviceStatus error: $e');
      return null;
    }
  }

  Future<void> sendKeyBoard(List<CanvasDevice> devices, int code) async {
    for (var device in devices) {
      final stub = _getStub(device);
      final sendKeyboardRequest = KeyboardEventRequest(code: code);
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
    final rotateCanvasRequest = RotateRequest(clockwise: clockwise);
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
      await stub.tap(tapRequest);
    }
  }

  Future<void> drag(
      List<CanvasDevice> devices, Offset offset, Size touchpadSize) async {
    final dragOffset = CursorOffset(
        dx: offset.dx,
        dy: offset.dy,
        coefficientX: 1 / touchpadSize.width,
        coefficientY: 1 / touchpadSize.height);

    currentCursorOffset += offset;
    dragOffsets.add(dragOffset);
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer(const Duration(milliseconds: 300), () {
        for (var device in devices) {
          final stub = _getStub(device);
          final dragRequest = DragGestureRequest(cursorOffsets: dragOffsets);
          stub.drag(dragRequest);
        }
        dragOffsets.clear();
      });
    }
  }

  Future<Offset> getCursorOffset(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.getCursorOffset(GetCursorOffsetRequest());
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final cursorOffset = response.cursorOffset;
    final dx = size.width * cursorOffset.coefficientX * cursorOffset.dx;
    final dy = size.height * cursorOffset.coefficientY * cursorOffset.dy;
    return Offset(dx, dy);
  }

  Future<void> setCursorOffset(CanvasDevice device) async {
    final stub = _getStub(device);
    final size =
        MediaQuery.of(_navigationService.navigatorKey.currentContext!).size;
    final dx = currentCursorOffset.dx / size.width;
    final dy = currentCursorOffset.dy / size.height;
    final cursorOffset = CursorOffset(
        dx: dx,
        dy: dy,
        coefficientX: 1 / size.width,
        coefficientY: 1 / size.height);

    final request = SetCursorOffsetRequest(cursorOffset: cursorOffset);

    await stub.setCursorOffset(request);
  }
}
