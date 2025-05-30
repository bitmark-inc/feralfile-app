import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';

class DeviceRealtimeMetricHelper {
  factory DeviceRealtimeMetricHelper() {
    return _instance;
  }

  DeviceRealtimeMetricHelper._internal();

  // singleton
  static final DeviceRealtimeMetricHelper _instance =
      DeviceRealtimeMetricHelper._internal();

  final Map<String, StreamController<DeviceRealtimeMetrics>>
      _deviceRealtimeMetricsControllers = {};

  final Map<String, Timer> _deviceTimers = {};

  Stream<DeviceRealtimeMetrics> getDeviceRealtimeMetricsStream(
      BaseDevice device) {
    final controller =
        _deviceRealtimeMetricsControllers[device.deviceId]?.stream;
    if (controller != null) {
      return controller;
    } else {
      final newController = StreamController<DeviceRealtimeMetrics>.broadcast();
      _deviceRealtimeMetricsControllers[device.deviceId] = newController;
      return newController.stream;
    }
  }

  void addMetrics(BaseDevice device, DeviceRealtimeMetrics metrics) {
    if (!_deviceRealtimeMetricsControllers.containsKey(device.deviceId)) {
      _deviceRealtimeMetricsControllers[device.deviceId] =
          StreamController<DeviceRealtimeMetrics>.broadcast();
    }
    _deviceRealtimeMetricsControllers[device.deviceId]!.add(metrics);
  }

  void dispose() {
    // Cancel all timers
    for (var timer in _deviceTimers.values) {
      timer.cancel();
    }
    _deviceTimers.clear();

    // Close all stream controllers
    for (var controller in _deviceRealtimeMetricsControllers.values) {
      controller.close();
    }
    _deviceRealtimeMetricsControllers.clear();
  }

  Stream<DeviceRealtimeMetrics> startMetrics(BaseDevice device) {
    if (_deviceTimers.containsKey(device.deviceId)) {
      return _deviceRealtimeMetricsControllers[device.deviceId]!.stream;
    }

    final controller = _deviceRealtimeMetricsControllers[device.deviceId] ??
        StreamController<DeviceRealtimeMetrics>.broadcast();
    _deviceRealtimeMetricsControllers[device.deviceId] = controller;

    // Simulate periodic metrics updates
    final timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final metrics = await injector<CanvasClientServiceV2>()
          .getDeviceRealtimeMetrics(device);

      controller.add(metrics);
    });

    _deviceTimers[device.deviceId] = timer;
    return controller.stream;
  }

  void stopMetrics(BaseDevice device) {
    if (_deviceTimers.containsKey(device.deviceId)) {
      _deviceTimers[device.deviceId]!.cancel();
      _deviceTimers.remove(device.deviceId);
    }
    if (_deviceRealtimeMetricsControllers.containsKey(device.deviceId)) {
      _deviceRealtimeMetricsControllers[device.deviceId]!.close();
      _deviceRealtimeMetricsControllers.remove(device.deviceId);
    }
  }
}
