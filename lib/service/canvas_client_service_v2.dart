import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/mdns_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart' as my_device;
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class CanvasClientServiceV2 {
  final AppDatabase _db;
  final MDnsService _mdnsService;

  CanvasClientServiceV2(this._db, this._mdnsService);

  final List<CanvasDevice> _viewingDevices = [];
  late final String _deviceId;
  late final String _deviceName;
  bool _didInitialized = false;

  final _connectDevice = Lock();
  final AccountService _accountService = injector<AccountService>();

  Offset currentCursorOffset = Offset.zero;

  CallOptions get _callOptions => CallOptions(
      compression: const GzipCodec(), timeout: const Duration(seconds: 5));

  Future<void> init() async {
    if (_didInitialized) {
      return;
    }
    final device = my_device.DeviceInfo.instance;
    _deviceName = await device.getMachineName() ?? 'Feral File App';
    final account = await _accountService.getDefaultAccount();
    _deviceId = await account.getAccountDID();
    await _mdnsService.start();
    _didInitialized = true;
  }

  DeviceInfoV2 get clientDeviceInfo => DeviceInfoV2()
    ..deviceId = _deviceId
    ..deviceName = _deviceName
    ..platform = _platform;

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

  CanvasControlV2Client _getStub(CanvasDevice device) {
    final channel = _getChannel(device);
    return CanvasControlV2Client(channel);
  }

  Future<CheckDeviceStatusReply> getDeviceCastingStatus(
      CanvasDevice device) async {
    final stub = _getStub(device);
    final request = CheckDeviceStatusRequest();
    final response = await stub.status(
      request,
      options: _callOptions,
    );
    return response;
  }

  Future<bool> isConnectable(CanvasDevice device) async {
    try {
      await getDeviceCastingStatus(device);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> connectToDevice(CanvasDevice device,
          {bool isLocal = false}) async =>
      _connectDevice
          .synchronized(() async => await _connectToDevice(device, isLocal));

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

  Future<ConnectReplyV2> connect(CanvasDevice device) async {
    final stub = _getStub(device);
    final deviceInfo = clientDeviceInfo;
    final request = ConnectRequestV2()..clientDevice = deviceInfo;
    final response = await stub.connect(request, options: _callOptions);
    return response;
  }

  Future<bool> _connectToDevice(CanvasDevice device, bool isLocal) async {
    try {
      final response = await connect(device);
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

  Future<void> disconnectDevice(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.disconnect(
      DisconnectRequestV2(),
      options: _callOptions,
    );
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

      final response = await stub.castListArtwork(
        castRequest,
        options: _callOptions,
      );
      return response.ok;
    } catch (e) {
      log.info('CanvasClientService: Caught error: $e');
      return false;
    }
  }

  Future<bool> cancelCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.cancelCasting(
      CancelCastingRequest(),
      options: _callOptions,
    );
    return response.ok;
  }

  Future<bool> pauseCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.pauseCasting(
      PauseCastingRequest(),
      options: _callOptions,
    );
    return response.ok;
  }

  Future<bool> resumeCasting(CanvasDevice device) async {
    final stub = _getStub(device);
    final response = await stub.resumeCasting(
      ResumeCastingRequest(),
      options: _callOptions,
    );
    return response.ok;
  }

  Future<bool> nextArtwork(CanvasDevice device, {String? startTime}) async {
    final stub = _getStub(device);
    final request = NextArtworkRequest();
    if (startTime != null) {
      request.startTime = $fixnum.Int64(int.parse(startTime));
    }
    final response = await stub.nextArtwork(
      request,
      options: _callOptions,
    );
    return response.ok;
  }

  Future<bool> previousArtwork(CanvasDevice device, {String? startTime}) async {
    final stub = _getStub(device);
    final request = PreviousArtwortRequest();
    if (startTime != null) {
      request.startTime = $fixnum.Int64(int.parse(startTime));
    }
    final response = await stub.previousArtwork(
      request,
      options: _callOptions,
    );
    return response.ok;
  }

  Future<bool> appendListArtwork(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    final stub = _getStub(device);
    final response = await stub.appendListArtwork(
      AppendArtworkToCastingListRequest()..artworks.addAll(artworks),
      options: _callOptions,
    );
    return response.ok;
  }

  Future<bool> castExhibition(CanvasDevice device, String exhibitionId) async {
    throw UnimplementedError();
  }

  Future<UpdateDurationReply> updateDuration(
      CanvasDevice device, List<PlayArtworkV2> artworks) async {
    final stub = _getStub(device);
    final response = await stub.updateDuration(
      UpdateDurationRequest()..artworks.addAll(artworks),
      options: _callOptions,
    );
    return response;
  }

  Future<List<CanvasDevice>> _findRawDevices() async {
    final devices = <CanvasDevice>[];
    final discoverDevices = await _mdnsService.findCanvas();
    final localDevices = await _db.canvasDeviceDao.getCanvasDevices();
    localDevices.removeWhere((l) => discoverDevices.any((d) => d.ip == l.ip));
    devices
      ..addAll(discoverDevices)
      ..addAll(await refreshDevices(localDevices));
    return devices;
  }

  /// This method will check the status of the devices by calling grpc
  Future<List<CanvasDevice>> refreshDevices(List<CanvasDevice> devices) async {
    final List<CanvasDevice> workingDevices = [];
    await Future.forEach<CanvasDevice>(devices, (device) async {
      final isAvailable = await isConnectable(device);
      if (isAvailable) {
        workingDevices.add(device);
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
}
