import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/objectbox.g.dart';

class BluetoothDeviceHelper {
  static Box<FFBluetoothDevice> _pairedDevicesBox =
      ObjectBox.bluetoothPairedDevicesBox;

  static List<FFBluetoothDevice> get pairedDevices {
    final devices = _pairedDevicesBox.getAll();
    return devices;
  }

  static void addDevice(FFBluetoothDevice device) {
    try {
      _pairedDevicesBox.put(device);
    } catch (e) {
      print('Error adding device $e');
    }
  }
}
