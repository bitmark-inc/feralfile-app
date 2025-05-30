import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/bluetooth_manager.dart';
import 'package:autonomy_flutter/util/byte_builder_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/util/timezone.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart';

const displayingCommand = [
  CastCommand.castDaily,
  CastCommand.castListArtwork,
  CastCommand.castExhibition,
];

const updateCastInfoCommand = [
  ...displayingCommand,
  CastCommand.updateDuration,
  CastCommand.nextArtwork,
  CastCommand.previousArtwork,
  CastCommand.resumeCasting,
  CastCommand.pauseCasting,
];

const updateDeviceStatusCommand = [
  CastCommand.rotate,
  CastCommand.updateArtFraming,
  CastCommand.updateToLatestVersion,
];

enum BluetoothCommand {
  sendWifiCredentials,
  scanWifi,
  setTimezone;

  String get name {
    switch (this) {
      case BluetoothCommand.sendWifiCredentials:
        return 'connect_wifi';
      case BluetoothCommand.scanWifi:
        return 'scan_wifi';
      case BluetoothCommand.setTimezone:
        return 'set_time';
    }
  }

  NotificationCallback _scanWifiCallback(
    Completer<ScanWifiResponse> completer,
  ) {
    return (data) {
      if (data.errorCode != 0) {
        log.warning('Error scanning wifi: ${data.errorCode}');
      }
      final listSsid = data.data;
      completer.complete(ScanWifiResponse(result: listSsid));
    };
  }

  NotificationCallback _sendWifiCredentialsCallback(
    Completer<SendWifiCredentialResponse> completer,
  ) {
    return (data) {
      if (data.errorCode != 0) {
        log.warning('Error sending wifi credentials: ${data.errorCode}');
        final error = SendWifiCredentialError.fromErrorCode(data.errorCode);
        completer.completeError(
          error,
        );
        return;
      }
      final topicId = data.data[0];
      completer.complete(
        SendWifiCredentialResponse(
          topicId: topicId,
        ),
      );
    };
  }

  // cb for setTimezone
  NotificationCallback _setTimezoneCallback(
    Completer<SetTimezoneReply> completer,
  ) {
    return (data) {
      completer.complete(SetTimezoneReply());
    };
  }

  Completer<BluetoothResponse> generateCompleter() {
    switch (this) {
      case BluetoothCommand.sendWifiCredentials:
        return Completer<SendWifiCredentialResponse>();
      case BluetoothCommand.scanWifi:
        return Completer<ScanWifiResponse>();
      case BluetoothCommand.setTimezone:
        return Completer<SetTimezoneReply>();
    }
  }

  NotificationCallback notificationCallback(
    Completer<BluetoothResponse> completer,
  ) {
    switch (this) {
      case BluetoothCommand.sendWifiCredentials:
        return _sendWifiCredentialsCallback(
          completer as Completer<SendWifiCredentialResponse>,
        );
      case BluetoothCommand.scanWifi:
        return _scanWifiCallback(
          completer as Completer<ScanWifiResponse>,
        );
      case BluetoothCommand.setTimezone:
        return _setTimezoneCallback(
          completer as Completer<SetTimezoneReply>,
        );
    }
  }
}

class FFBluetoothService {
  FFBluetoothService();

  bool _listeningForAdapterState = false;

  void startListen() {
    log.info('Start listening to bluetooth events');
    FlutterBluePlus.events.onDiscoveredServices.listen((event) {
      log.info('Discovered services: $event');
    });
    FlutterBluePlus.events.onConnectionStateChanged.listen((event) async {
      final device = event.device;
      final state = event.connectionState;
      log.info(
        'Connection state update for ${device.remoteId.str}: ${state.name}',
      );
      if (state == BluetoothConnectionState.connected) {
        try {
          if (Platform.isAndroid) {
            // await device.requestMtu(512);
          }
          await device.discoverCharacteristics();
          if (_connectCompleter?.isCompleted == false) {
            _connectCompleter?.complete();
          }
          _connectCompleter = null;
          NowDisplayingManager().addStatus(ConnectSuccess(device));
        } catch (e, s) {
          log.warning('Failed to discover characteristics: $e');
          unawaited(
            Sentry.captureException(
              'Failed to discover characteristics: $e',
              stackTrace: s,
            ),
          );
          await device.disconnect();
          if (_connectCompleter?.isCompleted == false) {
            _connectCompleter?.completeError(e);
          }
          _connectCompleter = null;
        }
      } else if (state == BluetoothConnectionState.disconnected) {
        log.warning('Device disconnected reason: ${device.disconnectReason}');
        if (_connectCompleter?.isCompleted == false) {
          _connectCompleter?.completeError(
            'Device disconnected reason: ${device.disconnectReason}',
          );
        }
        NowDisplayingManager().addStatus(
          ConnectionLostAndReconnecting(device),
        );
      }
    });

    FlutterBluePlus.events.onServicesReset.listen((event) {
      log.info('Services reset: $event');
      event.device.discoverCharacteristics();
    });
    FlutterBluePlus.events.onCharacteristicReceived.listen(
      (event) {
        final characteristic = event.characteristic;
        final device = event.device;
        final value = event.value;
        if (characteristic.isWifiConnectCharacteristic) {
          BluetoothNotificationService().handleNotification(value, device);
        }
      },
      onError: (Object e) {
        log.warning('Error receiving characteristic: $e');
      },
    );
  }

  Future<void> init() async {
    FlutterBluePlus.logs.listen((event) {
      log.info('[FlutterBluePlus]: $event');
    });
    if (await Permission.bluetooth.isGranted ||
        BluetoothDeviceManager().castingBluetoothDevice != null) {
      await listenForAdapterState();
    }
  }

  Future<void> listenForAdapterState() async {
    if (_listeningForAdapterState) {
      return;
    }
    _listeningForAdapterState = true;
    if (!(await FlutterBluePlus.isSupported)) {
      log.info('Bluetooth is not supported');
      injector<BluetoothConnectBloc>().add(
        BluetoothConnectEventUpdateBluetoothState(
          BluetoothAdapterState.unavailable,
        ),
      );
      return;
    }
    final stateNow = FlutterBluePlus.adapterStateNow;
    injector<BluetoothConnectBloc>()
        .add(BluetoothConnectEventUpdateBluetoothState(stateNow));
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState bluetoothState) {
      _bluetoothAdapterState = bluetoothState;
      injector<BluetoothConnectBloc>()
          .add(BluetoothConnectEventUpdateBluetoothState(bluetoothState));
    });
  }

  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.unknown;

  bool get isBluetoothOn => _bluetoothAdapterState == BluetoothAdapterState.on;

  Future<BluetoothResponse> sendCommand({
    required BluetoothDevice device,
    required BluetoothCommand command,
    required Map<String, dynamic> request,
    Duration timeout = const Duration(seconds: 10),
    bool shouldShowError = true,
  }) async {
    log.info(
      '[sendCommand] Sending command: $command to device: ${device.remoteId.str}',
    );

    if (device.isDisconnected) {
      log.info('[sendCommand] Device is disconnected');
      unawaited(
        injector<NavigationService>().showCannotConnectToBluetoothDevice(
          device,
          'Device is disconnected',
        ),
      );
      throw Exception('Device is disconnected');
    }

    // Generate random 4 char replyId
    final replyId = String.fromCharCodes(
      List.generate(4, (_) => Random().nextInt(26) + 97),
    );

    final byteBuilder = _buildCommandMessage(command.name, request, replyId);

    final completer = command.generateCompleter();
    final cb = command.notificationCallback(completer);
    BluetoothNotificationService().subscribe(replyId, cb);
    log.info(
      '[sendCommand] Subscribed to replyId: $replyId',
    );
    try {
      final bytes = byteBuilder.takeBytes();

      final wifiChar = device.wifiConnectCharacteristic;
      if (wifiChar == null) {
        log.warning('Command characteristic not found');
        unawaited(Sentry.captureMessage('Command characteristic not found'));
        throw Exception('Command characteristic not found');
      }

      await wifiChar.writeWithRetry(bytes);

      // Wait for reply with timeout
      final res = await completer.future.timeout(
        timeout,
        onTimeout: () {
          Sentry.captureMessage(
            '[sendCommand] Timeout waiting for reply: $replyId',
          );
          throw TimeoutException('Timeout  waiting for reply $replyId');
        },
      );
      // if (displayingCommand
      //     .any((element) => element == CastCommand.fromString(command))) {
      //   castingBluetoothDevice = device;
      // }
      // if (updateDeviceStatusCommand
      //     .any((element) => element == CastCommand.fromString(command))) {
      //   unawaited(fetchBluetoothDeviceStatus(device));
      // }
      return res;
    } catch (e, s) {
      // BluetoothNotificationService().unsubscribe(replyId, cb);
      unawaited(Sentry.captureException(e, stackTrace: s));
      log.info(
        '[sendCommand] Error sending command $command(replyId is $replyId): $e',
      );
      rethrow;
    }
  }

  BytesBuilder _buildCommandMessage(
    String command,
    Map<String, dynamic> request,
    String replyId,
  ) {
    final commandBytes = ascii.encode(command);
    final replyIdBytes = ascii.encode(replyId);

    // Prepare the BytesBuilder to collect all data
    final builder = BytesBuilder()
      ..writeVarint(commandBytes.length)
      ..add(commandBytes)
      ..writeVarint(replyIdBytes.length)
      ..add(replyIdBytes);

    // Loop through the request map and handle each key-value pair
    for (final entry in request.entries) {
      final value = entry.value;

      final valueBytes = ascii.encode(value.toString());

      builder
        ..writeVarint(valueBytes.length)
        ..add(valueBytes);
    }

    return builder;
  }

  Future<void> setTimezone(BluetoothDevice device) async {
    final timezone = await TimezoneHelper.getTimeZone();
    log.info('[setTimezone] timezone: $timezone');
    final res = await sendCommand(
      device: device,
      command: BluetoothCommand.setTimezone,
      request: SetTimezoneRequest(timezone: timezone).toJson(),
      timeout: const Duration(seconds: 5),
    );
    log.info(
      '[setTimezone] set timezone to $timezone for device: ${device.remoteId.str} with res: $res',
    );
  }

  Future<List<String>> scanWifi(BluetoothDevice device) async {
    const request = ScanWifiRequest();
    final res = await sendCommand(
      device: device,
      command: BluetoothCommand.scanWifi,
      request: request.toJson(),
    );

    if (res is! ScanWifiResponse) {
      log.warning('Failed to scan Wi-Fi');
      throw Exception('Failed to scan Wi-Fi');
    }

    final scanWifiResponse = res;
    final wifiList = scanWifiResponse.result;
    return wifiList;
  }

  Future<FFBluetoothDevice?> sendWifiCredentials({
    required BluetoothDevice device,
    required String ssid,
    required String password,
  }) async {
    if (device.isDisconnected) {
      log.info('[sendWifi] Device is disconnected');
      unawaited(
        injector<NavigationService>().showCannotConnectToBluetoothDevice(
          device,
          'Device is disconnected',
        ),
      );
      return null;
    }

    final res = await sendCommand(
      device: device,
      command: BluetoothCommand.sendWifiCredentials,
      request: SendWifiCredentialRequest(
        ssid: ssid,
        password: password,
      ).toJson(),
      timeout: const Duration(seconds: 30),
    );

    if (res is! SendWifiCredentialResponse) {
      log.warning('Failed to send Wi-Fi credentials');
      unawaited(Sentry.captureMessage('Failed to send Wi-Fi credentials'));
      return null;
    }

    final sendWifiCredentialResponse = res;

    log.info(
      '[sendWifi] sendWifiCredentials success, topicId: ${sendWifiCredentialResponse.topicId}',
    );

    final ffBluetoothDevice = device.toFFBluetoothDevice(
      topicId: sendWifiCredentialResponse.topicId,
    );

    log.info(
      '[sendWifi] sendWifiCredentials success. FFBluetoothDevice: ${ffBluetoothDevice.toJson()}',
    );

    // Update device with topicId
    return ffBluetoothDevice;
  }

  // completer for connectToDevice
  Completer<void>? _connectCompleter;

  // completer for multi call connectToDevice
  Completer<void>? _multiConnectCompleter;

  Future<void> connectToDevice(
    BluetoothDevice device, {
    bool shouldShowError = true,
    bool shouldChangeNowDisplayingStatus = false,
    bool? autoConnect,
  }) async {
    if (_multiConnectCompleter?.isCompleted == false) {
      log.info(
        '''
[connectToDevice] Already connecting to device: ${device.remoteId.str}''',
      );
      return _multiConnectCompleter?.future;
    }

    _multiConnectCompleter = Completer<void>();
    if (shouldChangeNowDisplayingStatus) {
      NowDisplayingManager().addStatus(ConnectingToDevice(device));
    }

    _connectDevice(device, shouldShowError: shouldShowError).then((_) {
      log.info('Connected to device: ${device.remoteId.str}');
      if (shouldChangeNowDisplayingStatus) {
        NowDisplayingManager().addStatus(ConnectSuccess(device));
      }
      _multiConnectCompleter?.complete();
      _multiConnectCompleter = null;
    }).catchError((Object e) {
      if (shouldChangeNowDisplayingStatus) {
        NowDisplayingManager().addStatus(ConnectFailed(device, e));
      }
      log.severe('Failed to connect to device: $e');
      unawaited(Sentry.captureException('Failed to connect to device: $e'));

      _multiConnectCompleter?.completeError(e);
      _multiConnectCompleter = null;
    });
    return _multiConnectCompleter?.future;
  }

  /*
    * Connect to device
    * If autoConnect is true, it will try to connect to device with autoConnect
    * If autoConnect is false, it will try to connect to device without autoConnect
    * If autoConnect is null, it will try to connect to device with autoConnect first, then without autoConnect
   */
  Future<void> _connectDevice(
    BluetoothDevice device, {
    bool shouldShowError = true,
  }) async {
    log.info('_connectDevice');
    await _connect(
      device,
      shouldShowError: shouldShowError,
      autoConnect: false,
    );
  }

  Future<void> _connect(
    BluetoothDevice device, {
    bool shouldShowError = true,
    bool autoConnect = true,
  }) async {
    // connect to device
    if (device.isDisconnected ||
        (autoConnect && !device.isAutoConnectEnabled)) {
      if (!autoConnect) {
        log.info('Disconnecting from device: ${device.remoteId.str}');
        await device.disconnect();
        log.info('[_connect] device.disconnect() finished');
      }

      if (_connectCompleter?.isCompleted == false) {
        log.info(
          '[connect] Already connecting to device: ${device.remoteId.str}',
        );
        return _connectCompleter?.future;
      }
      _connectCompleter = Completer<void>();
      log.info('[connect] Connecting to device: ${device.remoteId.str}');
      try {
        await device.connect(
          timeout: const Duration(seconds: 10),
          autoConnect: autoConnect,
          mtu: autoConnect ? null : 512,
        );
      } catch (e) {
        log.warning('Failed to connect to device: $e');
        unawaited(Sentry.captureException('Failed to connect to device: $e'));
        if (shouldShowError) {
          unawaited(
            injector<NavigationService>().showCannotConnectToBluetoothDevice(
              device,
              e,
            ),
          );
        }
        _connectCompleter = null;
        rethrow;
      }

      log.info(
        '''
[_connect] Wait for connection to complete, autoConnect = $autoConnect, device.isConnected = ${device.isConnected}
''',
      );
      // Wait for connection to complete
      if (autoConnect && device.isConnected) {
        _connectCompleter?.complete();
        _connectCompleter = null;
      } else {
        if (_connectCompleter == null) {
          log.info('[_connect] _connectCompleter is null');
          return;
        }

        await _connectCompleter?.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            log.warning('Timeout waiting for connection to complete');
            if (shouldShowError) {
              unawaited(
                injector<NavigationService>()
                    .showCannotConnectToBluetoothDevice(
                  device,
                  TimeoutException('Taking too long to connect to device'),
                ),
              );
            }
            throw TimeoutException('Taking too long to connect to device');
          },
        ).catchError((Object e) {
          log.warning('Error waiting for connection to complete: $e');
          unawaited(
            Sentry.captureException(
              'Error waiting for connection to complete: $e',
            ),
          );
          if (shouldShowError) {
            unawaited(
              injector<NavigationService>().showCannotConnectToBluetoothDevice(
                device,
                e,
              ),
            );
          }
          throw e;
        });
        log.info('Connected to device: ${device.remoteId.str}');
      }
    } else {
      log.info('Device already connected: ${device.remoteId.str}');
    }
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 30),
    FutureOr<bool> Function(List<BluetoothDevice>)? onData,
    FutureOr<void> Function(dynamic)? onError,
    bool forceScan = false,
  }) async {
    try {
      if (!injector<AuthService>().isBetaTester() && !forceScan) {
        return;
      }

      await listenForAdapterState();

      final connectedDevices = FlutterBluePlus.connectedDevices;
      final shouldStop = await onData?.call(connectedDevices);
      if (shouldStop == true) {
        log.info('BluetoothConnectEventScan startScan: already connected');
        return;
      }
      StreamSubscription<List<ScanResult>>? scanSubscription;

      scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) async {
          final devices = results.map((result) => result.device).toList();
          final shouldStopScan = await onData
              ?.call(devices..addAll(FlutterBluePlus.connectedDevices));
          if (shouldStopScan == true) {
            FlutterBluePlus.stopScan();
          }
        },
        onError: (Object error) {
          onError?.call(error);
          scanSubscription?.cancel();
        },
      );

      FlutterBluePlus.cancelWhenScanComplete(scanSubscription);
      log.info('BluetoothConnectEventScan startScan');
      await FlutterBluePlus.startScan(
        timeout: timeout, // Updated to 60 seconds
        withServices: [
          Guid(BluetoothManager.serviceUuid),
        ],
      );
      // wait for scan to complete
      while (FlutterBluePlus.isScanningNow) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } catch (e) {
      log.warning('Failed to start scan: $e');
      onError?.call(e);
    } finally {
      log.info('BluetoothConnectEventScan stopScan');
      await FlutterBluePlus.stopScan();
    }
  }
}

extension BluetoothCharacteristicExt on BluetoothCharacteristic {
  bool get isWifiConnectCharacteristic {
    return uuid.toString() == BluetoothManager.wifiConnectCharUuid;
  }

  String generateReplyId() {
    final replyId = String.fromCharCodes(
      List.generate(4, (_) => Random().nextInt(26) + 97),
    );
    return replyId;
  }

  Future<void> writeWithRetry(List<int> value) async {
    try {
      await write(value);
    } catch (e) {
      log
        ..info('[writeWithRetry] Error writing: $e')
        ..info('[writeWithRetry] Retrying...');
      if (e is FlutterBluePlusException && e.code == 14) {
        return;
      }
      final device = this.device;
      if (device.isConnected) {
        await device.discoverCharacteristics();
        await write(value);
      }
    }
  }
}

abstract class BluetoothRequest {
  const BluetoothRequest();
}

abstract class BluetoothResponse {
  const BluetoothResponse();
}

class SendWifiCredentialRequest extends BluetoothRequest {
  const SendWifiCredentialRequest({
    required this.ssid,
    required this.password,
  });

  final String ssid;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
    };
  }
}

class SendWifiCredentialResponse extends BluetoothResponse {
  const SendWifiCredentialResponse({
    required this.topicId,
  });

  final String topicId;
}

enum SendWifiCredentialErrorCode {
  userEnterWrongPassword(1),
  wifiConnectedButCannotReachServer(2),
  unknownError(-1);

  const SendWifiCredentialErrorCode(this.code);

  final int code;
}

class SendWifiCredentialError implements Exception {
  SendWifiCredentialError(this.message);

  final String message;

  static SendWifiCredentialError fromErrorCode(int errorCode) {
    final error = SendWifiCredentialErrorCode.values
        .firstWhere((e) => e.code == errorCode);
    switch (error) {
      case SendWifiCredentialErrorCode.userEnterWrongPassword:
        // user enter wrong password
        return SendWifiCredentialError(
            'Failed to connect to Wi-Fi. Please check your password and try again.');
      case SendWifiCredentialErrorCode.wifiConnectedButCannotReachServer:
        return SendWifiCredentialError(
          'Connected to Wi-Fi but cannot reach our server. Please check your internet connection.',
        );
      default:
        // A generic error
        return SendWifiCredentialError(
          'Unknown error occurred while sending wifi credentials. Error code: $errorCode',
        );
    }
  }

  // toString() {
  String toString() {
    return message;
  }
}

class ScanWifiRequest extends BluetoothRequest {
  const ScanWifiRequest();

  Map<String, dynamic> toJson() {
    return {};
  }
}

class ScanWifiResponse extends BluetoothResponse {
  const ScanWifiResponse({
    required this.result,
  });

  final List<String> result;
}

class SetTimezoneRequest implements BluetoothRequest {
  SetTimezoneRequest({required this.timezone, DateTime? time})
      : time = time ?? DateTime.now();

  // datetime formatter in YYYY-MM-DD HH:MM:SS format
  static final DateFormat _dateTimeFormatter =
      DateFormat('yyyy-MM-dd HH:mm:ss');

  final String timezone;
  final DateTime time;

  Map<String, dynamic> toJson() => {
        'timezone': timezone,
        'time': _dateTimeFormatter.format(time),
      };
}

class SetTimezoneReply extends BluetoothResponse {
  SetTimezoneReply();

  factory SetTimezoneReply.fromJson(Map<String, dynamic> _) =>
      SetTimezoneReply();
}
