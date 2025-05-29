import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';

class DeviceRealtimeMetricHelper {
  factory DeviceRealtimeMetricHelper() {
    return _instance;
  }

  DeviceRealtimeMetricHelper._internal();

  // singleton
  static final DeviceRealtimeMetricHelper _instance =
      DeviceRealtimeMetricHelper._internal();

  final StreamController<DeviceRealtimeMetrics>
      _deviceRealtimeMetricsController =
      StreamController<DeviceRealtimeMetrics>.broadcast();

  Stream<DeviceRealtimeMetrics> get deviceRealtimeMetricsStream =>
      _deviceRealtimeMetricsController.stream;

  Timer? _timer;

  void startRealtimeMetrics({required FFBluetoothDevice device}) {
    // Simulate real-time metrics generation
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      final metrics = await injector<CanvasClientServiceV2>()
          .getDeviceRealtimeMetrics(device);
      _deviceRealtimeMetricsController.add(metrics);
    });
  }

  void stopRealtimeMetrics() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopRealtimeMetrics();
    _deviceRealtimeMetricsController.close();
  }
}
