import 'package:autonomy_flutter/model/device/ff_bluetooth_device.dart';

class MockFFBluetoothDevice {
  static FFBluetoothDevice get device1 {
    return FFBluetoothDevice(
      name: 'Mock FF-X1 1',
      remoteID: 'mock-remote-id-1',
      topicId: 'mock-topic-id-1',
      deviceId: 'mock-device-id-1',
    );
  }

  static FFBluetoothDevice get device2 {
    return FFBluetoothDevice(
      name: 'Mock FF-X1 2',
      remoteID: 'mock-remote-id-2',
      topicId: 'mock-topic-id-2',
      deviceId: 'mock-device-id-2',
    );
  }

  static FFBluetoothDevice get device3 {
    return FFBluetoothDevice(
      name: 'Mock FF-X1 3',
      remoteID: 'mock-remote-id-3',
      topicId: 'mock-topic-id-3',
      deviceId: 'mock-device-id-3',
    );
  }

  static List<FFBluetoothDevice> get allDevices => [
        device1,
        device2,
        device3,
      ];
}
