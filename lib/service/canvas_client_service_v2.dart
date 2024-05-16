//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/service/canvas_channel_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/mdns_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart' as my_device;
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:flutter/material.dart';
import 'package:retry/retry.dart';
import 'package:synchronized/synchronized.dart';

class CanvasClientServiceV2 {
  final AppDatabase _db;
  final MDnsService _mdnsService;
  final DeviceInfoService _deviceInfoService;
  final CanvasChannelService _channelService;

  CanvasClientServiceV2(this._db, this._mdnsService, this._deviceInfoService,
      this._channelService);

  final _connectDevice = Lock();
  final _retry = const RetryOptions(maxAttempts: 3);

  Offset currentCursorOffset = Offset.zero;

  CallOptions get _callOptions => CallOptions(
      compression: const IdentityCodec(),
      timeout: const Duration(seconds: 60),
      providers: [_grpcLoggingProvider]);

  DeviceInfoV2 get clientDeviceInfo => DeviceInfoV2()
    ..deviceId = _deviceInfoService.deviceId
    ..deviceName = _deviceInfoService.deviceName
    ..platform = _platform;

  CanvasControlV2Client _getStub(CanvasDevice device) =>
      _channelService.getStub(device);

  Future<CheckDeviceStatusReply> getDeviceCastingStatus(
      CanvasDevice device) async {
    final stub = _getStub(device);
    final request = CheckDeviceStatusRequest();
    final response = await _retryWrapper(() => stub.status(
          request,
          options: _callOptions,
        ));
    log.info(
        'CanvasClientService2 status ok: ${response.connectedDevice.deviceId}');
    return response;
  }

  Future<bool> connectToDevice(CanvasDevice device) async =>
      _connectDevice.synchronized(() async => await _connectToDevice(device));

  DeviceInfoV2_DevicePlatform get _platform {
    final device = my_device.DeviceInfo.instance;
    if (device.isAndroid) {
      return DeviceInfoV2_DevicePlatform.ANDROID;
    } else if (device.isIOS) {
      return DeviceInfoV2_DevicePlatform.IOS;
    } else {
      return DeviceInfoV2_DevicePlatform.OTHER;
    }
  }

  Future<Pair<CanvasDevice, CheckDeviceStatusReply>?> addQrDevice(
      CanvasDevice device) async {
    final deviceStatus = await _getDeviceStatus(device);
    if (deviceStatus != null) {
      await _db.canvasDeviceDao.insertCanvasDevice(device);
      log.info('CanvasClientService: Added device to db ${device.name}');
      return deviceStatus;
    }
    return null;
  }

  Future<ConnectReplyV2> connect(CanvasDevice device) async {
    final stub = _getStub(device);
    final deviceInfo = clientDeviceInfo;
    final request = ConnectRequestV2()..clientDevice = deviceInfo;
    final response =
        await _retryWrapper(() => stub.connect(request, options: _callOptions));
    return response;
  }

  Future<bool> _connectToDevice(CanvasDevice device) async {
    try {
      final response = await connect(device);
      log.info('CanvasClientService received: ${response.ok}');
      if (response.ok) {
        log.info('CanvasClientService: Connected to device ${device.name}');
        return true;
      } else {
        log.info('CanvasClientService: Failed to connect to device');
        return false;
      }
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      rethrow;
    }
  }

  Future<void> disconnectDevice(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await _retryWrapper(() => stub.disconnect(
          DisconnectRequestV2(),
          options: _callOptions,
        ));
    if (response.ok) {
      //TODO: implement on disconnected
    }
  }

  Future<bool> castListArtwork(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    try {
      await connect(device);
      final stub = _getStub(device);
      final castRequest = CastListArtworkRequest()..artworks.addAll(artworks);

      final response = await _retryWrapper(() => stub.castListArtwork(
            castRequest,
            options: _callOptions,
          ));
      return response.ok;
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      return false;
    }
  }

  Future<bool> cancelCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await _retryWrapper(() => stub.cancelCasting(
          CancelCastingRequest(),
          options: _callOptions,
        ));
    return response.ok;
  }

  Future<bool> pauseCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await _retryWrapper(() => stub.pauseCasting(
          PauseCastingRequest(),
          options: _callOptions,
        ));
    return response.ok;
  }

  Future<bool> resumeCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await _retryWrapper(() => stub.resumeCasting(
          ResumeCastingRequest(),
          options: _callOptions,
        ));
    return response.ok;
  }

  Future<bool> nextArtwork(CanvasDevice device, {String? startTime}) async {
    final stub = _getStub(device);
    final request = NextArtworkRequest();
    if (startTime != null) {
      request.startTime = $fixnum.Int64(int.parse(startTime));
    }
    final response = await _retryWrapper(() => stub.nextArtwork(
          request,
          options: _callOptions,
        ));
    return response.ok;
  }

  Future<bool> previousArtwork(CanvasDevice device, {String? startTime}) async {
    final stub = _getStub(device);
    final request = PreviousArtwortRequest();
    if (startTime != null) {
      request.startTime = $fixnum.Int64(int.parse(startTime));
    }
    final response = await _retryWrapper(() => stub.previousArtwork(
          request,
          options: _callOptions,
        ));
    return response.ok;
  }

  Future<bool> appendListArtwork(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    final stub = _getStub(device);
    final response = await _retryWrapper(() => stub.appendListArtwork(
          AppendArtworkToCastingListRequest()..artworks.addAll(artworks),
          options: _callOptions,
        ));
    return response.ok;
  }

  Future<bool> castExhibition(
      CanvasDevice device, CastExhibitionRequest castRequest) async {
    await connect(device);
    final stub = _getStub(device);
    final response = await _retryWrapper(() => stub.castExhibition(
          castRequest,
          options: _callOptions,
        ));
    return response.ok;
  }

  Future<UpdateDurationReply> updateDuration(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    final stub = _getStub(device);
    final response = await _retryWrapper(() => stub.updateDuration(
          UpdateDurationRequest()..artworks.addAll(artworks),
          options: _callOptions,
        ));
    return response;
  }

  Future<List<CanvasDevice>> _findRawDevices() async {
    final devices = <CanvasDevice>[];
    final futures = await Future.wait(
        [_mdnsService.findCanvas(), _db.canvasDeviceDao.getCanvasDevices()]);
    final localDevices = futures[1];
    final discoverDevices = futures[0];
    localDevices.removeWhere((l) => discoverDevices.any((d) => d.ip == l.ip));
    devices
      ..addAll(discoverDevices)
      ..addAll(localDevices);
    return devices;
  }

  /// This method will get devices via mDNS and local db, for local db devices
  /// it will check the status of the device by calling grpc
  Future<List<Pair<CanvasDevice, CheckDeviceStatusReply>>> scanDevices() async {
    final rawDevices = await _findRawDevices();
    final List<Pair<CanvasDevice, CheckDeviceStatusReply>> devices = [];
    await Future.forEach<CanvasDevice>(rawDevices, (device) async {
      try {
        final status = await _getDeviceStatus(device);
        if (status != null) {
          devices.add(status);
        }
      } catch (e) {
        log.info('CanvasClientService: Caught error: $e');
      }
    });
    devices.sort((a, b) => a.first.name.compareTo(b.first.name));
    return devices;
  }

  Future<Pair<CanvasDevice, CheckDeviceStatusReply>?> _getDeviceStatus(
      CanvasDevice device) async {
    try {
      final status = await getDeviceCastingStatus(device);
      return Pair(device, status);
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      return null;
    }
  }

  Future<void> addLocalDevice(CanvasDevice device) async {
    await _db.canvasDeviceDao.insertCanvasDevice(device);
  }

  Future<T> _retryWrapper<T>(Future<T> Function() fn) =>
      _retry.retry(() => fn.call(),
          retryIf: (e) => e is SocketException || e is TimeoutException,
          onRetry: (e) => log.info('CanvasClientService retry stub error $e'));

  void _grpcLoggingProvider(Map<String, String> metadata, String uri) {
    log.info('CanvasClientService call gRPC: metadata: $metadata, uri: $uri}');
  }
}
