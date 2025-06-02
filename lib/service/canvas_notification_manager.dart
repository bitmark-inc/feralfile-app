import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_notification.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/model/device/device_status.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/canvas_notification_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/device_realtime_metric_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';

class CanvasNotificationManager {
  factory CanvasNotificationManager() => _instance;

  CanvasNotificationManager._internal();

  // single ton
  static final CanvasNotificationManager _instance =
      CanvasNotificationManager._internal();

  // Map to hold connected CanvasNotificationService instances
  final Map<String, CanvasNotificationService> _services = {};

  // Map to hold subscriptions for each service's stream
  final Map<String, StreamSubscription<NotificationRelayerMessage>>
      _subscriptions = {};

  // Map to hold retry timers
  final Map<String, Timer> _retryTimers = {};

  // Stream controller for combined notifications
  final _combinedNotificationController = StreamController<
      Pair<BaseDevice, NotificationRelayerMessage>>.broadcast();

  // Combined notification stream
  Stream<Pair<BaseDevice, NotificationRelayerMessage>>
      get combinedNotificationStream => _combinedNotificationController.stream;

  StreamSubscription<FGBGType>? _fgbgSubscription;

  static const _maxRetryAttempts = 10;
  static const _retryDelay = Duration(seconds: 5);

  // start function: connect to all devices
  Future<void> start() async {
    await _reconnectAll();

    // Listen to app lifecycle changes
    _fgbgSubscription =
        FGBGEvents.instance.stream.listen(_handleForeBackground);

    combinedNotificationStream.listen(
      (Pair<BaseDevice, NotificationRelayerMessage> pair) {
        final device = pair.first;
        final notification = pair.second;
        final notificationType = notification.notificationType;
        // Handle the notification based on its type
        switch (notificationType) {
          case RelayerNotificationType.status:
            final message = notification.message;
            final status = CheckCastingStatusReply.fromJson(message);
            injector<CanvasDeviceBloc>().add(
              CanvasDeviceUpdateCastingStatusEvent(
                device,
                status,
              ),
            );

          case RelayerNotificationType.deviceStatus:
            final message = notification.message;
            final deviceStatus = DeviceStatus.fromJson(message);
            BluetoothDeviceManager().castingDeviceStatus.value = deviceStatus;

          case RelayerNotificationType.connection:
            final message = notification.message;
            final isConnected = message['isConnected'] as bool;
            injector<CanvasDeviceBloc>().add(
              CanvasDeviceUpdateConnectionEvent(device, isConnected),
            );

          case RelayerNotificationType.systemMetrics:
            final message = notification.message;
            final metrics = DeviceRealtimeMetrics.fromJson(message);
            DeviceRealtimeMetricHelper().addMetrics(device, metrics);
        }
      },
      onError: (error) {
        // Handle errors from the combined stream
        log.info('Error in combined notification stream: $error');
      },
      onDone: () {
        // Handle completion of the combined stream if needed
        log.info('Combined notification stream done');
      },
    );
  }

  void _handleForeBackground(FGBGType event) {
    switch (event) {
      case FGBGType.foreground:
        _reconnectAll();
      case FGBGType.background:
        _disconnectAll();
    }
  }

  Future<void> _reconnectAll() async {
    final devices = [
      if (BluetoothDeviceManager().castingBluetoothDevice != null)
        BluetoothDeviceManager().castingBluetoothDevice!
    ];
    for (final device in devices) {
      try {
        await connect(device);
      } catch (e) {
        log.warning('Error reconnecting to device ${device.deviceId}: $e');
        _scheduleRetry(device);
      }
    }
  }

  void _scheduleRetry(BaseDevice device) {
    _retryTimers[device.deviceId]?.cancel();
    int retryCount = 0;

    void retry() async {
      if (retryCount >= _maxRetryAttempts) {
        log.warning('Max retry attempts reached for device ${device.deviceId}');
        _retryTimers.remove(device.deviceId);
        return;
      }

      try {
        await connect(device);
        _retryTimers.remove(device.deviceId);
      } catch (e) {
        log.warning(
            'Retry attempt ${retryCount + 1} failed for device ${device.deviceId}: $e');
        retryCount++;
        _retryTimers[device.deviceId] = Timer(_retryDelay, retry);
      }
    }

    _retryTimers[device.deviceId] = Timer(_retryDelay, retry);
  }

  // Connect to a specific device
  Future<void> connect(BaseDevice device) async {
    final service = _services[device.deviceId];

    if (service == null) {
      final newService = CanvasNotificationService(device);
      _services[device.deviceId] = newService;
      // Subscribe to the new service's stream and add to the combined stream
      _subscriptions[device.deviceId] = newService.notificationStream.listen(
        (notification) {
          _combinedNotificationController.add(
            Pair<BaseDevice, NotificationRelayerMessage>(
              device,
              notification,
            ),
          );
        },
        onError: (error) {
          // Handle error from individual service stream if needed
          log.warning('Error from device ${device.deviceId}: $error');
          _scheduleRetry(device);
        },
        onDone: () {
          // Handle individual service stream completion if needed
          log.info('Device ${device.deviceId} stream done');
          _scheduleRetry(device);
        },
      );
      await newService.connect();
    } else {
      if (service.isConnected) {
        // Already connected, no need to reconnect
        return;
      } else {
        // Reconnect if the service is not connected
        await service.connect();
      }
    }
  }

  // Disconnect from a specific device
  Future<void> disconnect(String deviceId) async {
    _retryTimers[deviceId]?.cancel();
    _retryTimers.remove(deviceId);

    final service = _services.remove(deviceId);
    if (service != null) {
      await service.disconnect();
      // Cancel the subscription for this device
      await _subscriptions.remove(deviceId)?.cancel();
    }
  }

  // Disconnect from all devices
  Future<void> disconnectAll() async {
    await _disconnectAll();
  }

  Future<void> _disconnectAll() async {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();

    final futures =
        _services.values.map((service) => service.disconnect()).toList();
    _services.clear();
    // Cancel all subscriptions
    await Future.wait(_subscriptions.values.map((sub) => sub.cancel()));
    _subscriptions.clear();
    await Future.wait(futures);
  }

  // Get notification stream for a specific device
  Stream<NotificationRelayerMessage>? getNotificationStream(String deviceId) {
    return _services[deviceId]?.notificationStream;
  }

  // on message (This method seems redundant now with the combined stream approach, consider removing)
  // void onMessage(String deviceId, NotificationRelayerMessage notification) {}

  // Dispose method to clean up
  void dispose() {
    _fgbgSubscription?.cancel();
    _disconnectAll();
    _combinedNotificationController.close();
  }

// You might want methods to list connected devices, check connection status, etc.
}
