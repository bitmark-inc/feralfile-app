import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/generated/protos/system_metrics.pb.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/chunk.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/bluetooth_manager.dart';
import 'package:autonomy_flutter/util/byte_builder_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/util/timezone.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  scanWifi;

  String get name {
    switch (this) {
      case BluetoothCommand.sendWifiCredentials:
        return 'connect_wifi';
      case BluetoothCommand.scanWifi:
        return 'scan_wifi';
    }
  }

  NotificationCallback _scanWifiCallback(
      Completer<ScanWifiResponse> completer) {
    return (data) {
      completer.complete(ScanWifiResponse(result: data));
    };
  }

  NotificationCallback _sendWifiCredentialsCallback(
      Completer<SendWifiCredentialResponse> completer) {
    return (data) {
      final locationId = data[0];
      final topicId = data[1];
      completer.complete(SendWifiCredentialResponse(
        topicId: topicId,
        locationId: locationId,
      ));
    };
  }

  Completer<dynamic> generateCompleter() {
    switch (this) {
      case BluetoothCommand.sendWifiCredentials:
        return Completer<SendWifiCredentialResponse>();
      case BluetoothCommand.scanWifi:
        return Completer<ScanWifiResponse>();
    }
  }

  NotificationCallback notificationCallback(Completer<dynamic> completer) {
    switch (this) {
      case BluetoothCommand.sendWifiCredentials:
        return _sendWifiCredentialsCallback(
            completer as Completer<SendWifiCredentialResponse>);
      case BluetoothCommand.scanWifi:
        return _scanWifiCallback(completer as Completer<ScanWifiResponse>);
    }
  }
}

class FFBluetoothService {
  FFBluetoothService();

  // Add a stream controller for system metrics
  final StreamController<DeviceRealtimeMetrics>
      _deviceRealtimeMetricsController =
      StreamController<DeviceRealtimeMetrics>.broadcast();

  Stream<DeviceRealtimeMetrics> get deviceRealtimeMetricsStream =>
      _deviceRealtimeMetricsController.stream;

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
            // await device.requestConnectionPriority(
            //     connectionPriorityRequest: ConnectionPriority.high);
          }
          await device.discoverCharacteristics();
          if (_connectCompleter?.isCompleted == false) {
            _connectCompleter?.complete();
          }
          _connectCompleter = null;
          // after connected, fetch device status
          final status =
              await fetchBluetoothDeviceStatus(device.toFFBluetoothDevice());
          NowDisplayingManager()
              .addStatus(ConnectSuccess(device.toFFBluetoothDevice()));

          injector<CanvasDeviceBloc>().add(
            CanvasDeviceGetDevicesEvent(
              onDoneCallback: () {
                if (status?.isConnectedToWifi ?? false) {
                  NowDisplayingManager().updateDisplayingNow();
                }
              },
            ),
          );
        } catch (e, s) {
          log.warning('Failed to discover characteristics: $e');
          unawaited(
            Sentry.captureException(
              'Failed to discover characteristics: $e',
              stackTrace: s,
            ),
          );
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
            ConnectionLostAndReconnecting(device.toFFBluetoothDevice()));
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
        } else if (characteristic.isEngineeringCharacteristic) {
          _handleEngineeringData(value);
        }
      },
      onError: (e) {
        log.warning('Error receiving characteristic: $e');
      },
    );
  }

  Future<void> init() async {
    FlutterBluePlus.logs.listen((event) {
      log.info('[FlutterBluePlus]: $event');
    });
    if (await Permission.bluetooth.isGranted ||
        castingBluetoothDevice != null) {
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

  // connected device
  FFBluetoothDevice? _castingBluetoothDevice;
  final ValueNotifier<BluetoothDeviceStatus?> _bluetoothDeviceStatus =
      ValueNotifier(null);

  ValueNotifier<BluetoothDeviceStatus?> get bluetoothDeviceStatus {
    if (_bluetoothDeviceStatus.value == null &&
        castingBluetoothDevice != null) {
      fetchBluetoothDeviceStatus(castingBluetoothDevice!);
    }
    return _bluetoothDeviceStatus;
  }

  set castingBluetoothDevice(FFBluetoothDevice? device) {
    if (device == null) {
      _castingBluetoothDevice = null;
      Sentry.captureException('Set Casting device value to null');
      return;
    }
    if (device.deviceId == _castingBluetoothDevice?.deviceId) {
      return;
    }
    _castingBluetoothDevice = device;
    fetchBluetoothDeviceStatus(device);
  }

  FFBluetoothDevice? get castingBluetoothDevice {
    if (_castingBluetoothDevice != null) {
      return _castingBluetoothDevice;
    }

    final device = BluetoothDeviceHelper.pairedDevices.firstOrNull;
    if (device != null) {
      castingBluetoothDevice = device;
    }
    return _castingBluetoothDevice;
  }

  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.unknown;

  bool get isBluetoothOn => _bluetoothAdapterState == BluetoothAdapterState.on;

  final String advertisingUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  // For scanning
  final String serviceUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  // wifi connect characteristic
  String wifiConnectCharUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  Future<dynamic> sendCommand({
    required FFBluetoothDevice device,
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
    // final cb = getCommandNotificationCallback(replyId, completer);
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
    } catch (e) {
      BluetoothNotificationService().unsubscribe(replyId, cb);
      unawaited(Sentry.captureException(e));
      log.info(
          '[sendCommand] Error sending command $command(replyId is $replyId): $e');
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

  Future<void> setTimezone(FFBluetoothDevice device) async {
    final timezone = await TimezoneHelper.getTimeZone();
    await injector<CanvasClientServiceV2>().setTimezone(device, timezone);
  }

  Future<List<String>> scanWifi(FFBluetoothDevice device) async {
    const request = ScanWifiRequest();
    final res = await sendCommand(
        device: device,
        command: BluetoothCommand.scanWifi,
        request: request.toJson());

    if (res is! ScanWifiResponse) {
      log.warning('Failed to scan Wi-Fi');
      throw Exception('Failed to scan Wi-Fi');
    }

    final scanWifiResponse = res;
    final wifiList = scanWifiResponse.result;
    return wifiList;
  }

  // _sendWifiCredentials

  Future<bool> sendWifiCredentials({
    required FFBluetoothDevice device,
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
      return false;
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
      return false;
    }

    final sendWifiCredentialResponse = res;

    // Update device with topicId and locationId
    device = device.copyWith(
      topicId: sendWifiCredentialResponse.topicId,
      locationId: sendWifiCredentialResponse.locationId,
    );

    return true;
  }

  // completer for connectToDevice
  Completer<void>? _connectCompleter;

  // completer for multi call connectToDevice
  Completer<void>? _multiConnectCompleter;

  Future<void> connectToDevice(
    FFBluetoothDevice device, {
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
    bool? autoConnect,
  }) async {
    log.info('_connectDevice');
    try {
      if (!(autoConnect ?? false)) {
        log.info('[_connectDevice] _connect with autoConnect is false');
        await _connect(device,
            shouldShowError: shouldShowError, autoConnect: false);
      }
    } catch (e) {}
    if (autoConnect ?? true) {
      log.info('[_connectDevice] _connect with autoConnect is true');
      await _connect(device, shouldShowError: shouldShowError);
    }
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
    FutureOr<bool> Function(List<ScanResult>)? onData,
    FutureOr<void> Function(dynamic)? onError,
    bool forceScan = false,
  }) async {
    try {
      if (!injector<AuthService>().isBetaTester() && !forceScan) {
        return;
      }
      await listenForAdapterState();

      onData?.call([]);
      StreamSubscription<List<ScanResult>>? scanSubscription;
      scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) async {
          final shouldStopScan = await onData?.call(results);
          if (shouldStopScan == true) {
            FlutterBluePlus.stopScan();
          }
        },
        onError: (error) {
          onError?.call(error);
          scanSubscription?.cancel();
        },
      );

      FlutterBluePlus.cancelWhenScanComplete(scanSubscription);
      log.info('BluetoothConnectEventScan startScan');
      await FlutterBluePlus.startScan(
        timeout: timeout, // Updated to 60 seconds
        withServices: [
          Guid(injector<FFBluetoothService>().serviceUuid),
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

  Future<BluetoothDeviceStatus?> fetchBluetoothDeviceStatus(
    BaseDevice device,
  ) async {
    try {
      final res = await injector<CanvasClientServiceV2>()
          .getBluetoothDeviceStatus(device);
      _bluetoothDeviceStatus.value = res;
      return res;
    } catch (e) {
      log.warning('Failed to get device status: $e');
      return null;
    }
  }

  // Map to store chunksfor each response
  final Map<String, List<ChunkInfo>> chunks = {};

  // NotificationCallback getCommandNotificationCallback(
  //     String replyId, Completer<Map<String, dynamic>> responseCompleter) {
  //   late NotificationCallback cb;
  //   cb = (Map<String, dynamic> data) {
  //     log.info('[sendCommand] Received data: $data');
  //     final isChunkData = data.containsKey('i') &&
  //         data.containsKey('d') &&
  //         data.containsKey('t');
  //
  //     if (isChunkData) {
  //       chunks[replyId] ??= [];
  //       final chunkInfo = ChunkInfo.fromData(data);
  //       log.info('[sendCommand] Received chunk: $chunkInfo');
  //       chunks[replyId]!.add(chunkInfo);
  //
  //       if (chunks[replyId]!.length == chunkInfo.total) {
  //         chunks[replyId]!.sort((a, b) => a.index.compareTo(b.index));
  //         final allChunkData = chunks[replyId]!
  //             .map((chunk) => chunk.data)
  //             .expand((data) => data)
  //             .toList();
  //
  //         final responseString = utf8.decode(allChunkData);
  //         final response = json.decode(responseString) as Map<String, dynamic>;
  //         log.info('[sendCommand] Received full response: $response');
  //
  //         responseCompleter.complete(response);
  //         BluetoothNotificationService().unsubscribe(replyId, cb);
  //         chunks.remove(replyId);
  //       }
  //     } else {
  //       responseCompleter.complete(data);
  //       BluetoothNotificationService().unsubscribe(replyId, cb);
  //     }
  //   };
  //   return cb;
  // }

  // Add method to handle engineering data
  void _handleEngineeringData(List<int> data) {
    try {
      final metrics = DeviceRealtimeMetrics.fromBuffer(data);
      _deviceRealtimeMetricsController.add(metrics);
      log.fine(
          'Received system metrics: CPU: ${metrics.cpuUsage.toStringAsFixed(2)}%, '
          'Memory: ${metrics.memoryUsage.toStringAsFixed(2)}%, '
          'CPU Temp: ${metrics.cpuTemperature.toStringAsFixed(1)}°C');
    } catch (e) {
      log.warning('Failed to parse engineering data: $e');
    }
  }

  // Add method to start monitoring system metrics
  Future<void> startSystemMetricsMonitoring(BaseDevice device) async {
    return;
    // TODO: Implement this method
    // try {
    //   final engineeringChar = device.engineeringCharacteristic;
    //   if (engineeringChar == null) {
    //     log.warning('Engineering characteristic not found');
    //     return;
    //   }
    //
    //   await engineeringChar.setNotifyValue(true);
    //   log.info('System metrics monitoring started');
    // } catch (e) {
    //   log.warning('Failed to start system metrics monitoring: $e');
    //   unawaited(
    //     Sentry.captureException(
    //       'Failed to start system metrics monitoring: $e',
    //     ),
    //   );
    // }
  }

  // Add method to stop monitoring system metrics
  Future<void> stopSystemMetricsMonitoring(BaseDevice device) async {
    return;
    // TODO: Implement this method
    // try {
    //   final engineeringChar = device.engineeringCharacteristic;
    //   if (engineeringChar == null) {
    //     log.warning('Engineering characteristic not found');
    //     return;
    //   }
    //   await engineeringChar.setNotifyValue(false);
    //   log.info('System metrics monitoring stopped');
    // } catch (e) {
    //   log.warning('Failed to stop system metrics monitoring: $e');
    //   unawaited(
    //     Sentry.captureException(
    //       'Failed to stop system metrics monitoring: $e',
    //     ),
    //   );
    // }
  }

  void dispose() {
    _deviceRealtimeMetricsController.close();
  }
}

extension BluetoothCharacteristicExt on BluetoothCharacteristic {
  bool get isWifiConnectCharacteristic {
    return uuid.toString() == BluetoothManager.wifiConnectCharUuid;
  }

  bool get isEngineeringCharacteristic {
    return uuid.toString() == BluetoothManager.engineeringCharUuid;
  }

  int _getMaxPayloadSize(BluetoothDevice device) {
    // ATT protocol overhead
    const attOverhead = 10; // it should be 5, but we are using 10 to be safe
    return device.mtuNow - attOverhead;
  }

  String generateReplyId() {
    final replyId = String.fromCharCodes(
      List.generate(4, (_) => Random().nextInt(26) + 97),
    );
    return replyId;
  }

  List<List<int>> _splitIntoChunks(List<int> data, int chunkSize) {
    final chunks = <List<int>>[];
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  List<List<int>> _prepareChunks(BluetoothDevice device, List<int> bytes) {
    const maxChunks = 30;
    const chunkHeaderSize = 12;
    final maxChunkPayloadSize = _getMaxPayloadSize(device) - chunkHeaderSize;
    final chunks = _splitIntoChunks(bytes, maxChunkPayloadSize);
    if (chunks.length > maxChunks) {
      throw Exception(
        'Message too large: would require ${chunks.length} chunks (max: $maxChunks)',
      );
    }
    return chunks;
  }

  Future<void> writeChunk(List<int> value) async {
    final chunks = _prepareChunks(device, value);
    final replyId = generateReplyId();
    final chunkCompleters =
        List.generate(chunks.length, (_) => Completer<void>());
    final ackReplyId = '${replyId}C';

    _setupChunkNotificationSubscriptions(
      ackReplyId: ackReplyId,
      chunkCompleters: chunkCompleters,
    );
    await _sendChunks(
      chunks: chunks,
      ackReplyId: ackReplyId,
      chunkCompleters: chunkCompleters,
    );
  }

  Future<void> writeWithRetry(List<int> value) async {
    try {
      await write(value);
    } on PlatformException catch (e) {
      log
        ..info('[writeWithRetry] Error writing chunk: $e')
        ..info('[writeWithRetry] Retrying...');
      final device = this.device;
      if (device.isConnected) {
        await device.discoverCharacteristics();
        await write(value);
      }
    }
  }

  Future<void> _sendChunks({
    required List<List<int>> chunks,
    required String ackReplyId,
    required List<Completer<void>> chunkCompleters,
  }) async {
    final ackReplyIdBytes = ascii.encode(ackReplyId);
    final totalChunksBytes = ascii.encode(chunks.length.toString());

    for (var i = 0; i < chunks.length; i++) {
      final chunkWithHeader = _buildChunkWithHeader(
        chunk: chunks[i],
        index: i,
        totalChunksBytes: totalChunksBytes,
        ackReplyIdBytes: ackReplyIdBytes,
      );

      await _sendChunkWithRetry(
        commandChar: this,
        chunkWithHeader: chunkWithHeader,
        chunkIndex: i,
        totalChunks: chunks.length,
        completer: chunkCompleters[i],
      );
    }
  }

  Future<void> _sendChunkWithRetry({
    required BluetoothCharacteristic commandChar,
    required BytesBuilder chunkWithHeader,
    required int chunkIndex,
    required int totalChunks,
    required Completer<void> completer,
  }) async {
    final bytes = chunkWithHeader.takeBytes();
    await commandChar.write(bytes, withoutResponse: true);
    log.info('[sendCommand] Sent chunk ${chunkIndex + 1}/$totalChunks');

    try {
      await completer.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          throw Exception(
            'Timeout waiting for chunk $chunkIndex acknowledgment',
          );
        },
      );
      log.info('[sendCommand] Received ack for chunk ${chunkIndex + 1}');
    } catch (e) {
      log.warning(
        '[sendCommand] Retrying chunk ${chunkIndex + 1} after timeout',
      );
      await commandChar.write(bytes, withoutResponse: true);
      await completer.future.timeout(const Duration(seconds: 1));
    }
  }

  BytesBuilder _buildChunkWithHeader({
    required List<int> chunk,
    required int index,
    required List<int> totalChunksBytes,
    required List<int> ackReplyIdBytes,
  }) {
    final chunkIndexBytes = ascii.encode(index.toString());
    return BytesBuilder()
      ..writeVarint(chunkIndexBytes.length)
      ..add(chunkIndexBytes)
      ..writeVarint(totalChunksBytes.length)
      ..add(totalChunksBytes)
      ..writeVarint(ackReplyIdBytes.length)
      ..add(ackReplyIdBytes)
      ..writeVarint(chunk.length)
      ..add(chunk);
  }

  NotificationCallback _setupChunkNotificationSubscriptions({
    required String ackReplyId,
    required List<Completer<void>> chunkCompleters,
  }) {
    late NotificationCallback cb;
    cb = (data) {
      // final chunkIndex = data['chunkIndex'] as int;
      // if (chunkIndex >= 0 &&
      //     chunkIndex < chunkCompleters.length &&
      //     !chunkCompleters[chunkIndex].isCompleted) {
      //   log.info('[sendCommand] Completing chunk $chunkIndex');
      //   chunkCompleters[chunkIndex].complete();
      // }
      // if (chunkCompleters.every((completer) => completer.isCompleted)) {
      //   BluetoothNotificationService().unsubscribe(ackReplyId, cb);
      // }
    };
    BluetoothNotificationService().subscribe(ackReplyId, cb);
    return cb;
  }
}

class SendWifiCredentialRequest {
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

class SendWifiCredentialResponse {
  const SendWifiCredentialResponse({
    required this.topicId,
    required this.locationId,
  });

  final String topicId;
  final String locationId;
}

class ScanWifiRequest {
  const ScanWifiRequest();

  Map<String, dynamic> toJson() {
    return {};
  }
}

class ScanWifiResponse {
  const ScanWifiResponse({
    required this.result,
  });

  final List<String> result;
}
