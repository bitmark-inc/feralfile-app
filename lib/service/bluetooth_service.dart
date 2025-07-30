import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_ext.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/bluetooth_manager.dart';
import 'package:autonomy_flutter/util/byte_builder_ext.dart';
import 'package:autonomy_flutter/util/exception_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/timezone.dart';
import 'package:collection/collection.dart';
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
  keepWifi,
  factoryReset,
  sendLog,
  setTimezone;

  String get name {
    switch (this) {
      case BluetoothCommand.sendWifiCredentials:
        return 'connect_wifi';
      case BluetoothCommand.scanWifi:
        return 'scan_wifi';
      case BluetoothCommand.keepWifi:
        return 'keep_wifi';
      case BluetoothCommand.factoryReset:
        return 'factory_reset';
      case BluetoothCommand.sendLog:
        return 'send_log';
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

  NotificationCallback _keepWifiCallback(
    Completer<KeepWifiResponse> completer,
  ) {
    return (data) {
      if (data.errorCode != 0) {
        log.warning('Error keeping wifi: ${data.errorCode}');
        final error = FFBluetoothError.fromErrorCode(data.errorCode);
        completer.completeError(
          error,
        );
      }
      final topicId = data.data[0];
      completer.complete(KeepWifiResponse(topicId: topicId));
    };
  }

  NotificationCallback _sendWifiCredentialsCallback(
    Completer<SendWifiCredentialResponse> completer,
  ) {
    return (data) {
      if (data.errorCode != 0) {
        log.warning('Error sending wifi credentials: ${data.errorCode}');
        final error = FFBluetoothError.fromErrorCode(data.errorCode);
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

  NotificationCallback _factoryResetCallback(
    Completer<FactoryResetResponse> completer,
  ) {
    return (data) {
      if (data.errorCode != 0) {
        log.warning('Error resetting factory: ${data.errorCode}');
        final error = FFBluetoothError.fromErrorCode(data.errorCode);
        completer.completeError(
          error,
        );
      }
      completer.complete(FactoryResetResponse());
    };
  }

  NotificationCallback _sendLogCallback(
    Completer<SendLogResponse> completer,
  ) {
    return (data) {
      if (data.errorCode != 0) {
        log.warning('Error sending log: ${data.errorCode}');
        final error = FFBluetoothError.fromErrorCode(data.errorCode);
        completer.completeError(
          error,
        );
      }
      completer.complete(SendLogResponse());
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
      case BluetoothCommand.keepWifi:
        return Completer<KeepWifiResponse>();
      case BluetoothCommand.factoryReset:
        return Completer<FactoryResetResponse>();
      case BluetoothCommand.sendLog:
        return Completer<SendLogResponse>();
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
      case BluetoothCommand.keepWifi:
        return _keepWifiCallback(
          completer as Completer<KeepWifiResponse>,
        );
      case BluetoothCommand.factoryReset:
        return _factoryResetCallback(
          completer as Completer<FactoryResetResponse>,
        );
      case BluetoothCommand.sendLog:
        return _sendLogCallback(
          completer as Completer<SendLogResponse>,
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
          // add safe delay to ensure connection is stable
          await Future.delayed(const Duration(seconds: 1));
          await device.discoverCharacteristics();
          if (_connectCompleter?.isCompleted == false) {
            _connectCompleter?.complete();
          }
          _connectCompleter = null;
        } catch (e, s) {
          log.warning('Failed to discover characteristics: $e');
          unawaited(
            Sentry.captureException(
              'Failed to discover characteristics: $e',
              stackTrace: s,
            ),
          );
          log.info(
            'Disconnecting from device: ${device.remoteId.str} due to error $e',
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
    bool shouldWaitForReply = true,
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
    if (shouldWaitForReply) {
      final cb = command.notificationCallback(completer);
      BluetoothNotificationService().subscribe(replyId, cb);
      log.info(
        '[sendCommand] Subscribed to replyId: $replyId',
      );
    }
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
      final res = (shouldWaitForReply)
          ? await completer.future.timeout(
              timeout,
              onTimeout: () {
                Sentry.captureMessage(
                  '[sendCommand] Timeout waiting for reply: $replyId',
                );
                throw TimeoutException('Timeout  waiting for reply $replyId');
              },
            )
          : const EmptyBluetoothResponse();
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
      shouldWaitForReply: false,
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

  Future<String> keepWifi(BluetoothDevice device) async {
    final request = KeepWifiRequest();
    final res = await sendCommand(
      device: device,
      command: BluetoothCommand.keepWifi,
      request: request.toJson(),
    );

    if (res is! KeepWifiResponse) {
      log.warning('Failed to keep Wi-Fi');
      throw Exception('Failed to keep Wi-Fi');
    }

    final keepWifiResponse = res;
    return keepWifiResponse.topicId;
  }

  Future<String?> sendWifiCredentials({
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

    // Update device with topicId
    return sendWifiCredentialResponse.topicId;
  }

  // completer for connectToDevice
  Completer<void>? _connectCompleter;

  // completer for multi call connectToDevice
  Completer<void>? _multiConnectCompleter;

  Future<void> connectToDevice(
    BluetoothDevice device, {
    bool shouldShowError = true,
    bool? autoConnect,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_multiConnectCompleter?.isCompleted == false) {
      log.info(
        '''
[connectToDevice] Already connecting to device: ${device.remoteId.str}''',
      );
      return _multiConnectCompleter?.future;
    }

    _multiConnectCompleter = Completer<void>();

    _connectDevice(device, shouldShowError: shouldShowError, timeout: timeout)
        .then((_) {
      log.info('Connected to device: ${device.remoteId.str}');

      _multiConnectCompleter?.complete();
      _multiConnectCompleter = null;
    }).catchError((Object e) {
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
    Duration timeout = const Duration(seconds: 30),
  }) async {
    log.info('_connectDevice');
    await _connect(
      device,
      shouldShowError: shouldShowError,
      autoConnect: false,
      timeout: timeout,
    );
  }

  Future<void> _connect(
    BluetoothDevice device, {
    bool shouldShowError = true,
    bool autoConnect = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // connect to device
    if (device.isDisconnected ||
        (autoConnect && !device.isAutoConnectEnabled)) {
      // if (!autoConnect) {
      //   log.info('Disconnecting from device: ${device.remoteId.str}');
      //   await device.disconnect();
      //   log.info('[_connect] device.disconnect() finished');
      // }

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
          timeout: timeout,
          autoConnect: autoConnect,
          mtu: null,
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
          const Duration(seconds: 30),
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
    if (!injector<AuthService>().isBetaTester() && !forceScan) {
      return;
    }
    final haftTimeout = timeout ~/ 2;
    bool deviceFound = await _startScan(
      timeout: haftTimeout,
      onData: onData,
      onError: onError,
    );

    if (deviceFound) {
      log.info('Device found during initial scan');
      return;
    }
    deviceFound = await _startScan(
      timeout: haftTimeout,
      onData: onData,
      onError: onError,
    );
    if (!deviceFound) {
      log.info('No device found during second scan');
      Sentry.captureMessage(
        'Device scan completed: device not found',
      );
    }
  }

  Future<bool> _startScan({
    Duration timeout = const Duration(seconds: 30),
    FutureOr<bool> Function(List<BluetoothDevice>)? onData,
    FutureOr<void> Function(dynamic)? onError,
  }) async {
    bool foundDevice = false;
    try {
      await listenForAdapterState();

      await FlutterBluePlus.stopScan();

      await Future.delayed(Duration(milliseconds: 500)); // safe delay

      final connectedDevices = FlutterBluePlus.connectedDevices;
      final shouldStop = await onData?.call(connectedDevices);
      if (shouldStop == true) {
        log.info('BluetoothConnectEventScan startScan: already connected');
        return true;
      }
      StreamSubscription<List<ScanResult>>? scanSubscription;

      final now = DateTime.now();

      scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) async {
          log.info(
            'BluetoothConnectEventScan onScanResults: ${results.map((r) => '${r.device.advName}-${r.advertisementData.serviceUuids.join(',')}').join(',\n')}',
          );
          final devices = results.map((result) => result.device).toList();
          final shouldStopScan = await onData
              ?.call(devices..addAll(FlutterBluePlus.connectedDevices));
          if (shouldStopScan == true) {
            log.info(
                'Scanned Times: ${DateTime.now().difference(now).inSeconds} seconds');
            foundDevice = true;
            await FlutterBluePlus.stopScan();
          }
        },
        onError: (Object error) {
          log.info(
            'BluetoothConnectEventScan onScanResults error: $error',
          );
          Sentry.captureException(
            'BluetoothConnectEventScan onScanResults error: $error',
          );
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
      return foundDevice;
    }
  }

  Future<void> factoryReset(FFBluetoothDevice device) async {
    if (device.isDisconnected) {
      await connectToDevice(device, timeout: Duration(seconds: 10));
    }

    final res = await sendCommand(
        device: device,
        command: BluetoothCommand.factoryReset,
        request: FactoryResetRequest().toJson(),
        timeout: const Duration(seconds: 30));
    log.info('[factoryReset] res: $res');
  }

  Future<void> sendLog(FFBluetoothDevice device) async {
    if (device.isDisconnected) {
      await connectToDevice(device, timeout: Duration(seconds: 10));
    }
    final userId = injector<AuthService>().getUserId();
    final message = device.getName;
    final request = SendLogRequest(userId: userId!, title: message);
    final res = await sendCommand(
        device: device,
        command: BluetoothCommand.sendLog,
        request: request.toJson(),
        timeout: const Duration(seconds: 30));

    log.info('[sendLog] res: $res');
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
      if (e is FlutterBluePlusException && e.canIgnore) {
        log.info('[writeWithRetry] Error code 14, ignoring');
        return;
      }
      final device = this.device;
      final isDataLongError = e is Exception && e.isDataLongerThanAllowed;
      if (device.isConnected) {
        if (!isDataLongError) {
          await device.discoverCharacteristics();
        }
        try {
          await write(value, allowLongWrite: isDataLongError);
        } catch (e) {
          log.warning(
            '[writeWithRetry] Failed to write after retry: $e',
          );
          if (e is FlutterBluePlusException && e.canIgnore) {
            log.info('[writeWithRetry] Error code 14, ignoring');
            return;
          }
          unawaited(Sentry.captureException(
            'Failed to write after retry: $e',
          ));
          rethrow;
        }
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

class EmptyBluetoothResponse extends BluetoothResponse {
  const EmptyBluetoothResponse();
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

class FactoryResetRequest extends BluetoothRequest {
  Map<String, dynamic> toJson() {
    return {};
  }
}

class FactoryResetResponse extends BluetoothResponse {}

class SendLogRequest implements Request {
  SendLogRequest({required this.userId, required this.title});

  factory SendLogRequest.fromJson(Map<String, dynamic> json) => SendLogRequest(
        userId: json['userId'] as String,
        title: json['title'] as String?,
      );

  final String userId;
  final String? title;

  @override
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'title': title,
      };
}

class SendLogResponse extends BluetoothResponse {}

enum FFBluetoothErrorCode {
  userEnterWrongPassword(1),
  wifiConnectedButNoInternet(2),
  wifiConnectedButCannotReachServer(3),
  // BLE_ERR_CODE_WIFI_REQUIRED
  wifiRequired(4),
  // BLE_ERR_CODE_DEVICE_UPDATING
  deviceUpdating(5),
  // BLE_ERR_CODE_VERSION_CHECK_FAILED
  versionCheckFailed(6),
  unknownError(255);

  const FFBluetoothErrorCode(this.code);

  final int code;
}

class FFBluetoothError implements Exception {
  FFBluetoothError(this.message, {this.title = 'Error'});

  final String message;
  final String title;

  static FFBluetoothError fromErrorCode(int errorCode) {
    final error = FFBluetoothErrorCode.values
        .firstWhereOrNull((e) => e.code == errorCode);
    switch (error) {
      case FFBluetoothErrorCode.userEnterWrongPassword:
        // user enter wrong password
        return FFBluetoothError(
            title: 'Incorrect Wi-Fi Password',
            'Failed to connect to Wi-Fi. Please check your password and try again.');
      case FFBluetoothErrorCode.wifiConnectedButCannotReachServer:
        return FFBluetoothError(
          title: 'Server Unreachable',
          'Connected to Wi-Fi but cannot reach our server. Please check your internet connection.',
        );
      case FFBluetoothErrorCode.wifiConnectedButNoInternet:
        return FFBluetoothError(
          title: 'No Internet Access',
          'Connected to Wi-Fi but no internet access. Please check your internet connection.',
        );
      case FFBluetoothErrorCode.wifiRequired:
        return FFBluetoothError(
          title: 'Wi-Fi Required',
          'This device requires a Wi-Fi connection to function properly. Please connect to a Wi-Fi network.',
        );
      case FFBluetoothErrorCode.deviceUpdating:
        return DeviceUpdatingError();

      case FFBluetoothErrorCode.versionCheckFailed:
        return DeviceVersionCheckFailedError();
      default:
        return FFBluetoothError(
          title: 'Wi-Fi Connection Error',
          'Unknown error occurred while connecting to Wi-Fi. Error code: $errorCode',
        );
    }
  }

  // toString() {
  String toString() {
    return message;
  }
}

class DeviceUpdatingError extends FFBluetoothError {
  DeviceUpdatingError()
      : super(
          'The device is currently updating. Please wait for the update to complete and try again.',
          title: 'Device Updating',
        );
}

class DeviceVersionCheckFailedError extends FFBluetoothError {
  DeviceVersionCheckFailedError()
      : super(
          'The device version check failed. Please try again or contact support.',
          title: 'Version Check Failed',
        );
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

class KeepWifiRequest extends BluetoothRequest {
  const KeepWifiRequest();

  // toJson
  Map<String, dynamic> toJson() {
    return {};
  }
}

class KeepWifiResponse extends BluetoothResponse {
  const KeepWifiResponse({
    required this.topicId,
  });

  final String topicId;
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

void handleBluetoothError({
  FFBluetoothError? error,
  bool shouldShowError = true,
}) {}

extension FlutterBluePlusExceptionExt on FlutterBluePlusException {
  bool get canIgnore {
    return code == 14 ||
        code == 133 ||
        (description?.contains('GATT') ?? false);
  }
}
