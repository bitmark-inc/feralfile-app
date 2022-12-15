//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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
  final Map<String, LedgerHardwareWallet> _connectedLedgers =
      <String, LedgerHardwareWallet>{};

  Future<bool> _isAvailable() async {
    final isOn = await FlutterBlue.instance.isOn;
    final isAvailable = await FlutterBlue.instance.isAvailable;
    log.info("isOn: $isOn, isAvailable: $isAvailable");

    return isOn && isAvailable;
  }

  Future<bool> scanForLedgerWallet() async {
    FlutterBlue.instance.setLogFunc(
        (level, message) => log.info("[LedgerHardwareService] $message"));
    if (!(await _isAvailable())) {
      log.info(
          "[LedgerHardwareService] BLE is not available on the first check."
          " Do the second attempt.");
      // Delay 300 milisecond and perform the second check
      await Future.delayed(const Duration(microseconds: 300));
      if (!(await _isAvailable())) {
        return false;
      }
    }

    await FlutterBlue.instance.startScan(
        withServices: [Guid(serviceUuid)],
        timeout: const Duration(seconds: 10));
    log.info("[LedgerHardwareService] Start scanning for ledgers");

    return true;
  }

  Stream<Iterable<LedgerHardwareWallet>> ledgerWallets() {
    final readyDevices = FlutterBlue.instance.scanResults.map((event) => event
        .map((e) => LedgerHardwareWallet(e.device.name, e.device))
        .toList());
    return readyDevices
        .map((event) => event + _connectedLedgers.values.toList());
  }

  Future<dynamic> stopScanning() {
    log.info("[LedgerHardwareService] Stop scanning for ledgers");
    return FlutterBlue.instance.stopScan();
  }

  Future<bool> connect(LedgerHardwareWallet ledger) async {
    await stopScanning();
    await ledger.device.connect();
    List<BluetoothService> services = await ledger.device.discoverServices();

    for (var s in services) {
      final service = s;
      if (service.uuid == Guid(serviceUuid)) {
        await ledger.connect(service);
      }
    }

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
