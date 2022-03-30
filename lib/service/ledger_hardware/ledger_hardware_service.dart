import 'dart:typed_data';
import 'package:autonomy_flutter/service/ledger_hardware/ledger_hardware_transport.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue/flutter_blue.dart';

enum DeviceModelId {
  blue,
  nanoS,
  nanoSP,
  nanoX,
}

class LedgerHardwareService {
  static const String serviceUuid = "13d63400-2c97-0004-0000-4c6564676572";

  final FlutterBlue flutterBlue = FlutterBlue.instance;
  Map<String, LedgerHardwareWallet> _connectedLedgers =
      Map<String, LedgerHardwareWallet>();

  Stream<Iterable<LedgerHardwareWallet>> scanForLedgerWallet() {
    FlutterBlue.instance.startScan(
        withServices: [Guid(serviceUuid)], timeout: Duration(seconds: 10));
    log.info("Start scanning for ledgers");
    final readyDevices = FlutterBlue.instance.scanResults.map((event) => event
        .map((e) => LedgerHardwareWallet(e.device.name, e.device))
        .toList());
    return readyDevices
        .map((event) => event + _connectedLedgers.values.toList());
  }

  Future<dynamic> stopScanning() {
    log.info("Stop scanning for ledgers");
    return FlutterBlue.instance.stopScan();
  }

  Future<bool> connect(LedgerHardwareWallet ledger) async {
    await stopScanning();
    await ledger.device.connect(autoConnect: true);
    List<BluetoothService> services = await ledger.device.discoverServices();
    await Future.forEach(services, (s) async {
      final service = s as BluetoothService;
      if (service.uuid == Guid(serviceUuid)) {
        await ledger.connect(service);
      }
    });
    ledger.isConnected = (ledger.notifyCharacteristic != null &&
        ledger.writeCMDCharacteristic != null &&
        ledger.writeCharacteristic != null);
    if (ledger.isConnected) {
      _connectedLedgers[ledger.device.id.id] = ledger;
    }

    return ledger.isConnected;
  }

  Future<dynamic> disconnect([LedgerHardwareWallet? ledger]) async {
    if (ledger != null) {
      _connectedLedgers.remove(ledger.device.id.id);
      return await ledger.disconnect();
    } else {
      await Future.forEach(
          _connectedLedgers.values,
          (ledger) async =>
              await (ledger as LedgerHardwareWallet).disconnect());
      _connectedLedgers.removeWhere((key, value) => true);
    }
  }
}
