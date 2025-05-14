//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/tv_cast_api.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/tv_cast_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart' as my_device;
import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';

class CanvasClientServiceV2 {
  CanvasClientServiceV2(
    this._deviceInfoService,
    this._tvCastApi,
  );

  final DeviceInfoService _deviceInfoService;
  final TvCastApi _tvCastApi;
  final dragOffsets = <CursorOffset>[];

  DeviceInfoV2 get clientDeviceInfo => DeviceInfoV2(
        deviceId: _deviceInfoService.deviceId,
        deviceName: _deviceInfoService.deviceName,
        platform: _platform,
      );

  TvCastServiceImpl _getTvCastStub(BaseDevice device) =>
      TvCastServiceImpl(_tvCastApi, device);

  TvCastService _getStub(
    BaseDevice device,
  ) {
    if (device is FFBluetoothDevice) {
      return _getTvCastStub(device);
    } else {
      throw Exception('Unknown device type');
    }
  }

  Future<CheckDeviceStatusReply> getDeviceCastingStatus(
    BaseDevice device, {
    bool shouldShowError = true,
  }) async =>
      _getDeviceCastingStatus(device, shouldShowError: shouldShowError);

  Future<CheckDeviceStatusReply> _getDeviceCastingStatus(
    BaseDevice device, {
    bool shouldShowError = true,
  }) async {
    final stub = _getStub(device);
    final request = CheckDeviceStatusRequest();
    final response =
        await stub.status(request, shouldShowError: shouldShowError);
    log.info(
      'CanvasClientService2 status: ${response.connectedDevice?.deviceId}',
    );
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

  Future<void> _mergeUser(
    String oldUserId,
  ) async {
    try {
      final metricClientService = injector<MetricClientService>();
      await metricClientService.mergeUser(oldUserId);
    } catch (e) {
      log.info('CanvasClientService: _mergeUser error: $e');
      unawaited(
        Sentry.captureException('CanvasClientService: _mergeUser error: $e'),
      );
    }
  }

  Future<ConnectReplyV2> _connect(
    BaseDevice device,
  ) async {
    final stub = _getStub(device);
    final deviceInfo = clientDeviceInfo;
    final userId = injector<AuthService>().getUserId();

    final request = ConnectRequestV2(
      clientDevice: deviceInfo,
      primaryAddress: userId ?? '',
    );
    final response = await stub.connect(request);
    await _mergeUser(device.deviceId);
    return response;
  }

  Future<bool> connectToDevice(
    BaseDevice device,
  ) async {
    try {
      final response = await _connect(device);
      return response.ok;
    } catch (e) {
      log.info('CanvasClientService: connectToDevice error: $e');
      return false;
    }
  }

  Future<void> disconnectDevice(
    BaseDevice device,
  ) async {
    final stub = _getStub(device);
    await stub.disconnect(DisconnectRequestV2());
  }

  Future<bool> castListArtwork(
    BaseDevice device,
    List<PlayArtworkV2> artworks,
  ) async {
    try {
      final canConnect = await connectToDevice(device);
      if (!canConnect) {
        // return false;
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

  Future<bool> pauseCasting(
    BaseDevice device,
  ) async {
    final stub = _getStub(device);
    final response = await stub.pauseCasting(PauseCastingRequest());
    return response.ok;
  }

  Future<bool> resumeCasting(
    BaseDevice device,
  ) async {
    final stub = _getStub(device);
    final response = await stub.resumeCasting(ResumeCastingRequest());
    return response.ok;
  }

  Future<bool> nextArtwork(
    BaseDevice device, {
    String? startTime,
  }) async {
    final stub = _getStub(device);
    final request = NextArtworkRequest(
      startTime: startTime == null ? null : int.tryParse(startTime),
    );

    final response = await stub.nextArtwork(request);
    return response.ok;
  }

  Future<bool> previousArtwork(
    BaseDevice device, {
    String? startTime,
  }) async {
    final stub = _getStub(device);
    final request = PreviousArtworkRequest(
      startTime: startTime == null ? null : int.tryParse(startTime),
    );
    final response = await stub.previousArtwork(request);
    return response.ok;
  }

  Future<bool> castExhibition(
    BaseDevice device,
    CastExhibitionRequest castRequest,
  ) async {
    final canConnect = await connectToDevice(device);
    if (!canConnect) {
      // return false;
    }
    final stub = _getStub(device);
    final response = await stub.castExhibition(castRequest);
    return response.ok;
  }

  Future<bool> castDailyWork(
    BaseDevice device,
    CastDailyWorkRequest castRequest,
  ) async {
    final canConnect = await connectToDevice(device);
    if (!canConnect) {
      // return false;
    }
    final stub = _getStub(device);
    final response = await stub.castDailyWork(castRequest);
    return response.ok;
  }

  Future<UpdateDurationReply> updateDuration(
    BaseDevice device,
    List<PlayArtworkV2> artworks,
  ) async {
    final stub = _getStub(device);
    final response =
        await stub.updateDuration(UpdateDurationRequest(artworks: artworks));
    return response;
  }

  Future<Pair<BaseDevice, CheckDeviceStatusReply>?> getDeviceStatus(
    BaseDevice device, {
    bool shouldShowError = true,
  }) async {
    final status =
        await getDeviceCastingStatus(device, shouldShowError: shouldShowError);
    return Pair(device, status);
  }

  Future<void> sendKeyBoard(List<BaseDevice> devices, int code) async {
    for (final device in devices) {
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
  Future<void> rotateCanvas(
    BaseDevice device, {
    bool clockwise = false,
  }) async {
    final stub = _getStub(device);
    final rotateCanvasRequest = RotateRequest(clockwise: clockwise);
    try {
      final response = await stub.rotate(rotateCanvasRequest);
      log.info('CanvasClientService: Rotate Canvas Success ${response.degree}');
    } catch (e) {
      log.info('CanvasClientService: Rotate Canvas Failed');
    }
  }

  Future<void> sendLog(BaseDevice device, String? title) async {
    final stub = _getStub(device);
    final user = injector<AuthService>().getUserId();
    final request = SendLogRequest(userId: user ?? '', title: title);
    final response = await stub.getSupport(request);
    log.info('CanvasClientService: Get Support Success ${response.ok}');
  }

  Future<BluetoothDeviceStatus> getBluetoothDeviceStatus(
    BaseDevice device,
  ) async {
    final stub = _getStub(device);
    final request = GetBluetoothDeviceStatusRequest();
    final response = await stub.getBluetoothDeviceStatus(request);
    return response.deviceStatus;
  }

  Future<void> updateArtFraming(
    BaseDevice device,
    ArtFraming artFraming,
  ) async {
    final stub = _getStub(device);
    final request = UpdateArtFramingRequest(artFraming: artFraming);
    final response = await stub.updateArtFraming(request);
    log.info(
      'CanvasClientService: Update Art Framing Success: response $response',
    );
  }

  Future<void> updateDisplaySettings(
    BaseDevice device,
    ArtistDisplaySetting displaySettings,
    final String tokenId, {
    bool isSaved = false,
  }) async {
    final stub = _getStub(device);
    final request = UpdateDisplaySettingsRequest(
      setting: displaySettings,
      tokenId: tokenId,
      isSaved: isSaved,
    );
    final response = await stub.updateDisplaySettings(request);
    log.info(
      'CanvasClientService: Update Display Settings Success: response $response',
    );
  }

  Future<void> setTimezone(BaseDevice device, String timezone) async {
    final stub = _getStub(device);
    final request = SetTimezoneRequest(timezone: timezone);
    final response = await stub.setTimezone(request);
    log.info('CanvasClientService: Set Timezone Success: response $response');
  }

  Future<void> updateToLatestVersion(BaseDevice device) async {
    final stub = _getStub(device);
    final request = UpdateToLatestVersionRequest();
    final response = await stub.updateToLatestVersion(request);
    log.info(
      'CanvasClientService: Update To Latest Version Success: response ${response.toJson()}',
    );
    if (device is FFBluetoothDevice) {
      await BluetoothDeviceManager().fetchBluetoothDeviceStatus(device);
    }
  }

  Future<void> tap(List<BaseDevice> devices) async {
    for (final device in devices) {
      final stub = _getStub(device);
      final tapRequest = TapGestureRequest();
      await stub.tap(tapRequest);
    }
  }

  Future<void> _sendDrag(
    List<BaseDevice> devices,
    List<CursorOffset> dragOffsets,
  ) async {
    await Future.forEach(devices, (device) async {
      try {
        final stub = _getStub(device);
        final dragRequest = DragGestureRequest(cursorOffsets: dragOffsets);
        await stub.drag(dragRequest);
      } catch (e) {
        log.info('CanvasClientService: Drag Failed');
        unawaited(
          Sentry.captureException(
            'CanvasClientService: Drag Failed to device: ${device.deviceId}',
          ),
        );
      }
    });
  }

  Future<void> drag(
    List<BaseDevice> devices,
    Offset offset,
    Size touchpadSize,
  ) async {
    final dragOffset = CursorOffset(
      dx: offset.dx,
      dy: offset.dy,
      coefficientX: 1 / touchpadSize.width,
      coefficientY: 1 / touchpadSize.height,
    );

    dragOffsets.add(dragOffset);
    if (dragOffsets.length > 5) {
      final offsets = List<CursorOffset>.from(dragOffsets);
      dragOffsets.clear();
      unawaited(_sendDrag(devices, offsets));
    }
  }

  Future<bool> showPairingQRCode(BaseDevice device, bool show) async {
    try {
      final stub = _getStub(device);
      final request = ShowPairingQRCodeRequest(show: show);
      final response = await stub.showPairingQRCode(request);
      log.info(
        'CanvasClientService: Show Pairing QR Code ${response.success}',
      );
      return response.success;
    } catch (e) {
      log.info('CanvasClientService: showPairingQRCode error: $e');
      unawaited(
        Sentry.captureException(
          'CanvasClientService: showPairingQRCode error: $e',
        ),
      );
      return false;
    }
  }

  Future<bool> safeShutdown(BaseDevice device) async {
    try {
      final stub = _getStub(device);
      final request = SafeShutdownRequest();
      await stub.safeShutdown(request);
      return true;
    } catch (e) {
      log.info('CanvasClientService: safeShutdown error: $e');
      unawaited(
        Sentry.captureException(
          'CanvasClientService: safeShutdown error: $e',
        ),
      );
      return false;
    }
  }

  Future<DeviceRealtimeMetrics> getDeviceRealtimeMetrics(
    BaseDevice device,
  ) async {
    final stub = _getStub(device);
    final request = DeviceRealtimeMetricsRequest();
    final response = await stub.deviceMetrics(request);
    return response.metrics;
  }
}
