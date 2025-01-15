import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectBloc
    extends AuBloc<BluetoothConnectEvent, BluetoothConnectState> {
  BluetoothConnectBloc() : super(BluetoothConnectState()) {
    on<BluetoothConnectEventScan>((event, emit) async {
      emit(state.copyWith(isScanning: true));
      StreamSubscription<List<ScanResult>>? scanSubscription;

      // start scanning

      final timer = Timer(const Duration(seconds: 60), () {
        emit(state.copyWith(isScanning: false));
        scanSubscription?.cancel();
      });

      var currentState = state;

      scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          // Filter results to only include devices advertising our service UUID
          final filteredResults = results.where((result) {
            return result.advertisementData.serviceUuids
                .map((uuid) => uuid.toString().toLowerCase())
                .contains(
                  injector<FFBluetoothService>().advertisingUuid.toLowerCase(),
                );
          }).toList();
          currentState = currentState.copyWith(scanResults: filteredResults);
          emit(currentState);
        },
        onError: (error) {
          emit(state.copyWith(isScanning: false));
          timer.cancel();
          scanSubscription?.cancel();
        },
      );

      FlutterBluePlus.cancelWhenScanComplete(scanSubscription);

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30), // Updated to 60 seconds
        androidUsesFineLocation: true,
      );
      // wait for scan to complete
      while (timer.isActive) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      emit(currentState.copyWith(isScanning: false));
    });
    on<BluetoothConnectEventStopScan>((event, emit) async {
      emit(state.copyWith(isScanning: false));
    });
    on<BluetoothConnectEventConnect>((event, emit) async {
      emit(state.copyWith(connectingDevice: event.device));

      final device = event.device;

      try {
        if (device.isDisconnected) {
          await injector<FFBluetoothService>().connectToDevice(device);
        }
        injector<FFBluetoothService>().connectedDevice = device;
        await event.onConnectSuccess?.call(device);
        emit(state.copyWith(connectingDevice: null, connectedDevice: device));
      } catch (e) {
        await event.onConnectFailure?.call(device);
        emit(state.copyWith(connectedDevice: null, error: e.toString()));
        return;
      }
    });
  }
}
