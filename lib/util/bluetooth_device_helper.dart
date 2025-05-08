import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/objectbox.g.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';

class BluetoothDeviceHelper {
  static Box<FFBluetoothDevice> get _pairedDevicesBox =>
      ObjectBox.bluetoothPairedDevicesBox;

  static List<FFBluetoothDevice> get pairedDevices {
    return [
      FFBluetoothDevice(
          name: "Test FF-X1",
          remoteID: "remoteId",
          locationId: "2G9jXY7fwlIjYF8u8rRjaWOmXbcunC",
          topicId: "2zgNcQyTnyoqlNofJzM35iL4uPgbJ")
    ];
    final devices = _pairedDevicesBox.getAll();
    return devices.toSet().toList();
  }

  static Future<void> addDevice(
    FFBluetoothDevice device,
  ) async {
    await _pairedDevicesBox.removeAllAsync();
    await _pairedDevicesBox.putAsync(device);
    injector<FFBluetoothService>().castingBluetoothDevice = device;
  }
}
