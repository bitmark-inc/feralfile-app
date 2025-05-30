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

  // Stream controller for combined notifications
  final _combinedNotificationController = StreamController<
      Pair<BaseDevice, NotificationRelayerMessage>>.broadcast();

  // Combined notification stream
  Stream<Pair<BaseDevice, NotificationRelayerMessage>>
      get combinedNotificationStream => _combinedNotificationController.stream;

  // start function: connect to all devices
  Future<void> start() async {
    final devices = BluetoothDeviceManager.pairedDevices;
    for (final device in devices) {
      try {
        await connect(device);
      } catch (e) {
        // Handle connection error for each device
        print('Error connecting to device ${device.deviceId}: $e');
      }
    }

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
        print('Error in combined notification stream: $error');
      },
      onDone: () {
        // Handle completion of the combined stream if needed
        print('Combined notification stream done');
      },
    );
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
          print('Error from device ${device.deviceId}: $error');
        },
        onDone: () {
          // Handle individual service stream completion if needed
          print('Device ${device.deviceId} stream done');
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
    final service = _services.remove(deviceId);
    if (service != null) {
      await service.disconnect();
      // Cancel the subscription for this device
      await _subscriptions.remove(deviceId)?.cancel();
    }
  }

  // Disconnect from all devices
  Future<void> disconnectAll() async {
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
    disconnectAll();
    _combinedNotificationController.close();
  }

// You might want methods to list connected devices, check connection status, etc.
}
