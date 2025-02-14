import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/byte_builder_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sentry/sentry.dart';

const displayingCommand = [
  CastCommand.castDaily,
  CastCommand.castListArtwork,
  CastCommand.castExhibition,
];

const updateDeviceStatusCommand = [
  CastCommand.updateOrientation,
  CastCommand.rotate,
  CastCommand.updateArtFraming,
];

class FFBluetoothService {
  FFBluetoothService() {}

  Future<void> init() async {
    if (!(await FlutterBluePlus.isSupported)) {
      log.info('Bluetooth is not supported');
      injector<BluetoothConnectBloc>().add(
        BluetoothConnectEventUpdateBluetoothState(
          BluetoothAdapterState.unavailable,
        ),
      );
      return;
    }

    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = FlutterBluePlus.adapterState
        .listen((BluetoothAdapterState bluetoothState) {
      _bluetoothAdapterState = bluetoothState;
      injector<BluetoothConnectBloc>()
          .add(BluetoothConnectEventUpdateBluetoothState(bluetoothState));
    });
  }

  // connected device
  FFBluetoothDevice? _castingBluetoothDevice;
  ValueNotifier<BluetoothDeviceStatus?> _bluetoothDeviceStatus =
      ValueNotifier(null);

  ValueNotifier<BluetoothDeviceStatus?> get bluetoothDeviceStatus {
    if (_bluetoothDeviceStatus.value == null &&
        castingBluetoothDevice != null) {
      fetchBluetoothDeviceStatus(castingBluetoothDevice!.toFFBluetoothDevice());
    }
    return _bluetoothDeviceStatus;
  }

  set castingBluetoothDevice(BluetoothDevice? device) {
    final ffdevice = FFBluetoothDevice(
      remoteID: device!.remoteId.str,
      name: device.advName,
    );
    _castingBluetoothDevice = ffdevice;
    fetchBluetoothDeviceStatus(ffdevice);
    BluetoothDeviceHelper.saveLastConnectedDevice(ffdevice);
  }

  FFBluetoothDevice? get castingBluetoothDevice {
    if (_castingBluetoothDevice != null) {
      return _castingBluetoothDevice;
    }
    final lastCastingBluetoothDevice =
        BluetoothDeviceHelper.getLastConnectedDevice(checkAvailability: true);
    if (lastCastingBluetoothDevice != null) {
      castingBluetoothDevice = lastCastingBluetoothDevice;
    } else {
      _castingBluetoothDevice = BluetoothDeviceHelper.pairedDevices.firstOrNull;
    }
    return _castingBluetoothDevice;
  }

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.unknown;

  bool get isBluetoothOn => _bluetoothAdapterState == BluetoothAdapterState.on;

  final String advertisingUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  // For scanning
  final String serviceUuid = 'f7826da6-4fa2-4e98-8024-bc5b71e0893e';

  String commandCharUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // command characteristic

  String wifiConnectCharUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // wifi connect characteristic

  StreamSubscription<List<int>>? _commandCharSub;

  // characteristic for sending commands to Peripheral
  Map<String, BluetoothCharacteristic> _commandCharacteristic = {};

  // characteristic to send Wi-Fi credentials to Peripheral
  Map<String, BluetoothCharacteristic> _wifiConnectCharacteristic = {};

  void setCommandCharacteristic(BluetoothCharacteristic characteristic) {
    _commandCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  void clearCommandCharacteristic({required String remoteId}) {
    _commandCharacteristic.remove(remoteId);
  }

  void setWifiConnectCharacteristic(BluetoothCharacteristic characteristic) {
    _wifiConnectCharacteristic[characteristic.remoteId.str] = characteristic;
  }

  void clearWifiConnectCharacteristic({required String remoteId}) {
    _wifiConnectCharacteristic.remove(remoteId);
  }

  BluetoothCharacteristic? getCommandCharacteristic(String remoteId) =>
      _commandCharacteristic[remoteId];

  BluetoothCharacteristic? getWifiConnectCharacteristic(String remoteId) =>
      _wifiConnectCharacteristic[remoteId];

  Future<Map<String, dynamic>> sendCommand({
    required BluetoothDevice device,
    required String command,
    required Map<String, dynamic> request,
  }) async {
    log.info(
        '[sendCommand] Sending command: $command to device: ${device.remoteId.str}');

    // Check if the device is connected
    if (!device.isConnected) {
      await connectToDevice(device);
      await device.discoverServices();
      if (!device.isConnected) {
        throw Exception('Device not connected after reconnection');
      }
    }

    final commandChar = getCommandCharacteristic(device.remoteId.str);
    // Check if the command characteristic is available
    if (commandChar == null) {
      throw Exception('Command characteristic not found');
    }

    // Generate random 4 char replyId
    final replyId = String.fromCharCodes(
      List.generate(4, (_) => Random().nextInt(26) + 97),
    );

    final bytes = _buildCommandMessage(command, request, replyId);
    final chunks = _prepareChunks(device, bytes);

    return _sendChunksAndWaitForResponse(
      device: device,
      commandChar: commandChar,
      chunks: chunks,
      replyId: replyId,
      command: command,
    );
  }

  void _setupNotificationSubscriptions({
    required String replyId,
    required String ackReplyId,
    required Completer<Map<String, dynamic>> responseCompleter,
    required List<Completer<void>> chunkCompleters,
  }) {
    BluetoothNotificationService().subscribe(ackReplyId, (data) {
      final chunkIndex = data['chunkIndex'] as int;
      if (chunkIndex >= 0 &&
          chunkIndex < chunkCompleters.length &&
          !chunkCompleters[chunkIndex].isCompleted) {
        log.info('[sendCommand] completing chunk $chunkIndex');
        chunkCompleters[chunkIndex].complete();
      }
    });

    BluetoothNotificationService().subscribe(replyId, (data) {
      responseCompleter.complete(data);
      _cleanupSubscriptions(replyId, ackReplyId);
    });
  }

  void _cleanupSubscriptions(String replyId, String ackReplyId) {
    BluetoothNotificationService().unsubscribe(replyId, (data) {});
    BluetoothNotificationService().unsubscribe(ackReplyId, (data) {});
  }

  BytesBuilder _buildCommandMessage(
    String command,
    Map<String, dynamic> request,
    String replyId,
  ) {
    final commandBytes = ascii.encode(command);
    final bodyString = json.encode(request);
    final bodyBytes = ascii.encode(bodyString);
    final replyIdBytes = ascii.encode(replyId);

    return BytesBuilder()
      ..writeVarint(command.length)
      ..add(commandBytes)
      ..writeVarint(bodyBytes.length)
      ..add(bodyBytes)
      ..writeVarint(replyIdBytes.length)
      ..add(replyIdBytes);
  }

  List<List<int>> _prepareChunks(
      BluetoothDevice device, BytesBuilder bytesBuilder) {
    const maxChunks = 10;
    const chunkHeaderSize = 12;
    final maxChunkPayloadSize = _getMaxPayloadSize(device) - chunkHeaderSize;
    final chunks =
        _splitIntoChunks(bytesBuilder.takeBytes(), maxChunkPayloadSize);
    if (chunks.length > maxChunks) {
      throw Exception(
        'Message too large: would require ${chunks.length} chunks (max: $maxChunks)',
      );
    }
    return chunks;
  }

  Future<Map<String, dynamic>> _sendChunksAndWaitForResponse({
    required BluetoothDevice device,
    required BluetoothCharacteristic commandChar,
    required List<List<int>> chunks,
    required String replyId,
    required String command,
  }) async {
    final responseCompleter = Completer<Map<String, dynamic>>();
    final chunkCompleters =
        List.generate(chunks.length, (_) => Completer<void>());
    final ackReplyId = '${replyId}C';

    _setupNotificationSubscriptions(
      replyId: replyId,
      ackReplyId: ackReplyId,
      responseCompleter: responseCompleter,
      chunkCompleters: chunkCompleters,
    );

    try {
      await _sendChunks(
        chunks: chunks,
        commandChar: commandChar,
        ackReplyId: ackReplyId,
        chunkCompleters: chunkCompleters,
      );

      log.info('[sendCommand] Waiting for final response');
      final res = await responseCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _cleanupSubscriptions(replyId, ackReplyId);
          log.warning('[sendCommand] Timeout waiting for final response');
          return fakeReply(command).toJson();
        },
      );
      log.info('[sendCommand] Received final response');

      if (displayingCommand
          .any((element) => element == CastCommand.fromString(command))) {
        castingBluetoothDevice = device;
      }

      if (updateDeviceStatusCommand
          .any((element) => element == CastCommand.fromString(command))) {
        // ignore: unawaited_futures
        fetchBluetoothDeviceStatus(device);
      }

      return res;
    } catch (e) {
      _cleanupSubscriptions(replyId, ackReplyId);
      unawaited(Sentry.captureException(e));
      log.info('[sendCommand] Error sending command: $e');
      rethrow;
    }
  }

  Future<void> _sendChunks({
    required List<List<int>> chunks,
    required BluetoothCharacteristic commandChar,
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
        commandChar: commandChar,
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
              'Timeout waiting for chunk $chunkIndex acknowledgment');
        },
      );
      log.info('[sendCommand] Received ack for chunk ${chunkIndex + 1}');
    } catch (e) {
      log.warning(
          '[sendCommand] Retrying chunk ${chunkIndex + 1} after timeout');
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

  Future<void> sendWifiCredentials({
    required BluetoothDevice device,
    required String ssid,
    required String password,
  }) async {
    // Check if the device is connected
    if (!device.isConnected) {
      await connectToDevice(device);
      if (!device.isConnected) {
        return;
      }
    }

    final wifiConnectChar = getWifiConnectCharacteristic(device.remoteId.str);
    // Check if the wifi connect characteristic is available
    if (wifiConnectChar == null) {
      log.warning('Wi-Fi connect characteristic not found');
      return;
    }

    // Convert SSID and password to ASCII bytes
    final ssidBytes = ascii.encode(ssid);
    final passwordBytes = ascii.encode(password);

    // Create a BytesBuilder to construct the message
    final builder = BytesBuilder()
      // Write SSID length as varint
      ..writeVarint(ssidBytes.length)
      // Write SSID bytes
      ..add(ssidBytes)

      // Write password length as varint
      ..writeVarint(passwordBytes.length)
      // Write password bytes
      ..add(passwordBytes);

    // Write the data to the characteristic
    final bytes = builder.takeBytes();
    final bytesInHex = bytes.map((e) => e.toRadixString(16)).join(' ');
    log.info('[sendWifiCredentials] Sending bytes: $bytesInHex');
    try {
      await wifiConnectChar.write(bytes, withoutResponse: false);
      log.info('[sendWifiCredentials] Wi-Fi credentials sent');
    } catch (e) {
      Sentry.captureException(e);
      log.info('[sendWifiCredentials] Error sending Wi-Fi credentials: $e');
    }
    fetchBluetoothDeviceStatus(device);
  }

  Future<void> connectToDevice(BluetoothDevice device,
      {bool shouldUpdateConnectedDevice = false}) async {
    List<BluetoothService> services = [];
    if (device.isDisconnected) {
      final connectCompleter = Completer<void>();

      log.info('Connecting to device: ${device.remoteId.str}');
      final subscription = device.connectionState.listen((state) {
        log.info(
          'Connection state update for ${device.remoteId.str}: ${state.name}',
        );
        if (state == BluetoothConnectionState.connected) {
          connectCompleter.complete();
        }
        if (state == BluetoothConnectionState.disconnected) {
          log.warning('Device disconnected reason: ${device.disconnectReason}');
        }
      });

      device.cancelWhenDisconnected(subscription, delayed: true, next: true);

      try {
        await device.connect();
      } catch (e) {
        log.warning('Failed to connect to device: $e');
        rethrow;
      }

      await connectCompleter.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          log.warning('Connection timeout');
          return;
        },
      );

      // Discover services
      // Note: You must call discoverServices after every re-connection!
      final discoveredServices = await device.discoverServices();
      services.clear();
      services.addAll(discoveredServices);
    } else {
      log.info('Device already connected: ${device.remoteId.str}');
    }

    if (getCommandCharacteristic(device.remoteId.str) == null ||
        getWifiConnectCharacteristic(device.remoteId.str) == null) {
      final commandService = services.firstWhereOrNull(
        (service) => service.uuid.toString() == serviceUuid,
      );
      if (commandService == null) {
        Sentry.captureMessage('Command service not found');
        return;
      }
      final commandChar = commandService.characteristics.firstWhere(
        (characteristic) => characteristic.uuid.toString() == commandCharUuid,
      );
      final wifiConnectChar = commandService.characteristics.firstWhere(
        (characteristic) =>
            characteristic.uuid.toString() == wifiConnectCharUuid,
      );
      // Set the command and wifi connect characteristics
      setCommandCharacteristic(commandChar);
      setWifiConnectCharacteristic(wifiConnectChar);
    }

    final commandCharacteristic = getCommandCharacteristic(device.remoteId.str);

    if (commandCharacteristic == null) {
      log.warning('Command characteristic not found');
      return;
    }

    log.info('Command char properties: ${commandCharacteristic.properties}');
    if (!commandCharacteristic.properties.notify) {
      log.warning('Command characteristic does not support notifications!');
      return;
    }

    try {
      await commandCharacteristic.setNotifyValue(true);
      log.info('Successfully enabled notifications for command char');
    } catch (e) {
      log.warning('Failed to enable notifications for command char: $e');
      Sentry.captureException(e);
      return;
    }

    final commandCharSub = commandCharacteristic.onValueReceived.listen(
      (value) {
        log.info('Received data from command characteristic: $value');
        BluetoothNotificationService().handleNotification(value);
      },
      onError: (error) {
        log.warning('Error in command char subscription: $error');
        Sentry.captureException(error);
      },
    );

    device.cancelWhenDisconnected(commandCharSub, delayed: true);
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 30),
    FutureOr<bool> Function(List<ScanResult>)? onData,
    FutureOr<void> Function(dynamic)? onError,
    bool forceScan = false,
  }) async {
    if (!injector<AuthService>().isBetaTester() && !forceScan) {
      return;
    }
    StreamSubscription<List<ScanResult>>? scanSubscription;

    // if (state.bluetoothAdapterState != BluetoothAdapterState.on) {
    //   log.info('BluetoothConnectEventScan BluetoothAdapterState is not on');
    //   return;
    // }
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
      androidUsesFineLocation: true,
      withServices: [
        Guid(injector<FFBluetoothService>().serviceUuid),
      ],
    );
    // wait for scan to complete
    while (FlutterBluePlus.isScanningNow) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  Future<void> findCharacteristics(BluetoothDevice devices) async {
    final List<BluetoothService> services = await devices.discoverServices();
    for (var service in services) {
      log.info(
        'Discovered service UUID: ${service.uuid.toString().toLowerCase()}',
      );
      if (service.uuid.toString().toLowerCase() == serviceUuid) {
        for (final characteristic in service.characteristics) {
          log.info(
            'Found characteristic UUID: '
            '${characteristic.uuid.toString().toLowerCase()}',
          );

          if (characteristic.uuid.toString().toLowerCase() == commandCharUuid) {
            setCommandCharacteristic(characteristic);
            log.info('Found command characteristic');
          }
          // if the characteristic UUID matches the target characteristic UUID
          if (characteristic.uuid.toString().toLowerCase() ==
              wifiConnectCharUuid) {
            setWifiConnectCharacteristic(characteristic);

            // Set up notifications
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                final receivedText = utf8.decode(value);
              });
            }

            // return; // Found what we need
          }
        }
      }
    }
  }

  Reply fakeReply(String commandString) {
    final command = CastCommand.fromString(commandString);

    switch (command) {
      case CastCommand.checkStatus:
        return CheckDeviceStatusReply(artworks: []);
      case CastCommand.castListArtwork:
        return CastListArtworkReply(
          ok: true,
        );
      case CastCommand.castDaily:
        return CastDailyWorkReply(
          ok: true,
        );
      case CastCommand.pauseCasting:
        return PauseCastingReply(
          ok: true,
        );
      case CastCommand.resumeCasting:
        return ResumeCastingReply(
          ok: true,
        );
      case CastCommand.nextArtwork:
        return NextArtworkReply(
          ok: true,
        );
      case CastCommand.previousArtwork:
        return PreviousArtworkReply(
          ok: true,
        );
      case CastCommand.updateDuration:
        return UpdateDurationReply(
          artworks: [],
        );
      case CastCommand.castExhibition:
        return CastExhibitionReply(
          ok: true,
        );
      case CastCommand.connect:
        return ConnectReplyV2(
          ok: true,
        );
      case CastCommand.disconnect:
        return DisconnectReplyV2(
          ok: true,
        );

      case CastCommand.sendKeyboardEvent:
        return KeyboardEventReply(
          ok: true,
        );
      case CastCommand.rotate:
        return RotateReply(
          degree: 1,
        );
      case CastCommand.sendLog:
        return SendLogReply(
          ok: true,
        );
      case CastCommand.tapGesture:
        return GestureReply(
          ok: true,
        );
      case CastCommand.dragGesture:
        return GestureReply(
          ok: true,
        );
      case CastCommand.updateOrientation:
        return UpdateOrientationReply();
      case CastCommand.getVersion:
        return GetVersionReply(
          version: 'No response',
        );
      case CastCommand.getBluetoothDeviceStatus:
        return GetBluetoothDeviceStatusReply(
          deviceStatus: BluetoothDeviceStatus(
            version: 'No response',
            ipAddress: 'No response',
            connectedWifi: 'No response',
            screenRotation: ScreenOrientation.portrait,
            isConnectedToWifi: false,
          ),
        );
      case CastCommand.updateArtFraming:
        return UpdateArtFramingReply();
      default:
        throw ArgumentError('Unknown command: $commandString');
    }
  }

  Future<BluetoothDeviceStatus> fetchBluetoothDeviceStatus(
    BluetoothDevice device,
  ) async {
    final res = await injector<CanvasClientServiceV2>()
        .getBluetoothDeviceStatus(device.toFFBluetoothDevice());
    _bluetoothDeviceStatus.value = res;
    return res;
  }

  List<List<int>> _splitIntoChunks(List<int> data, int chunkSize) {
    final chunks = <List<int>>[];
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  int _getMaxPayloadSize(BluetoothDevice device) {
    // ATT protocol overhead
    const attOverhead = 3;
    return device.mtuNow - attOverhead;
  }
}
