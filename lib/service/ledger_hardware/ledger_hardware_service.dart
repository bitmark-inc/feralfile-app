import 'dart:typed_data';
import 'package:autonomy_flutter/service/ledger_hardware/ledger_hardware_transport.dart';
import 'package:flutter_blue/flutter_blue.dart';

enum DeviceModelId {
  blue,
  nanoS,
  nanoSP,
  nanoX,
}

class LedgerHardwareService {
  static const String serviceUuid = "13d63400-2c97-0004-0000-4c6564676572";
  static const String notifyUuid = "13d63400-2c97-0004-0001-4c6564676572";
  static const String writeUuid = "13d63400-2c97-0004-0002-4c6564676572";
  static const String writeCmdUuid = "13d63400-2c97-0004-0003-4c6564676572";

  // ADPUs
  // final getAppVersion = transport(0xe0, 0x01, 0x00, 0x00);
  // final getAppAndVersion = transport(0xb0, 0x01, 0x00, 0x00);

  final FlutterBlue flutterBlue = FlutterBlue.instance;

  Stream<Iterable<LedgerHardwareWallet>> scanForLedgerWallet() {
    FlutterBlue.instance.startScan(
        withServices: [Guid(serviceUuid)], timeout: Duration(seconds: 4));

    return FlutterBlue.instance.scanResults.map((event) => event
        .map((e) => LedgerHardwareWallet(e.device.name, e.device))
        .toList());
  }

  Future<LedgerHardwareWallet> connect(LedgerHardwareWallet d) async {
    await d.device.connect(autoConnect: true);
    List<BluetoothService> services = await d.device.discoverServices();
    await Future.forEach(services, (s) async {
      final service = s as BluetoothService;
      if (service.uuid == Guid(serviceUuid)) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid == Guid(notifyUuid)) {
            d.notifyCharacteristic = characteristic;
            await d.notifyCharacteristic!.setNotifyValue(true);
          } else if (characteristic.uuid == Guid(writeUuid)) {
            d.writeCharacteristic = characteristic;
          } else if (characteristic.uuid == Guid(writeCmdUuid)) {
            d.writeCMDCharacteristic = characteristic;
          }
        }
      }
    });
    return d;
  }

  Future<void> disconnect(LedgerHardwareWallet d) async {
    await d.device.disconnect();
  }
}
