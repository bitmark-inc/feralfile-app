import 'package:autonomy_flutter/common/database.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/objectbox.g.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceHelper {
  static Box<FFBluetoothDevice> get _pairedDevicesBox =>
      ObjectBox.bluetoothPairedDevicesBox;

  static List<FFBluetoothDevice> get pairedDevices {
    final devices = _pairedDevicesBox.getAll();
    return devices.toSet().toList();
  }

  static Future<void> addDevice(
    FFBluetoothDevice device,
  ) async {
    await _pairedDevicesBox.removeAllAsync();
    await _pairedDevicesBox.putAsync(device);
  }

  static Future<void> removeDevice(String remoteId) async {
    try {
      final devices = _pairedDevicesBox.getAll();
      final dupObjIds = devices
          .where((element) => element.deviceId == remoteId)
          .map((e) => e.objId)
          .toList();
      await _pairedDevicesBox.removeManyAsync(dupObjIds);
    } catch (e) {
      log.info('Error removing device $e');
    }
  }

  static bool isDeviceSaved(BluetoothDevice device) {
    final devices = pairedDevices;
    return devices
        .where((element) => element.deviceId == device.remoteId.str)
        .isNotEmpty;
  }

  static Future<void> saveLastConnectedDevice(FFBluetoothDevice device) async {
    try {
      final configurationService = injector<ConfigurationService>();
      await configurationService.saveLastConnectedDevice(device);
    } catch (e) {
      log.info('Error saving last connected device $e');
    }
  }

  static FFBluetoothDevice? getLastConnectedDevice({
    bool checkAvailability = false,
  }) {
    try {
      final configurationService = injector<ConfigurationService>();
      FFBluetoothDevice? device = configurationService.getLastConnectedDevice();
      if (checkAvailability) {
        final scanedDevices =
            injector<BluetoothConnectBloc>().state.scanedDevices;
        if (scanedDevices
            .where((element) => element.remoteId.str == device?.deviceId)
            .isNotEmpty) {
          return device;
        } else {
          return null;
        }
      }
      return device;
    } catch (e) {
      log.info('Error getting last connected device $e');
      return null;
    }
  }
}
