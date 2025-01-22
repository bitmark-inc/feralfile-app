import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectBloc
    extends AuBloc<BluetoothConnectEvent, BluetoothConnectState> {
  BluetoothConnectBloc() : super(BluetoothConnectState()) {
    Timer? _scanTimer;
    on<BluetoothConnectEventScan>((event, emit) async {
      emit(state.copyWith(isScanning: true));
      StreamSubscription<List<ScanResult>>? scanSubscription;

      // start scanning
      _scanTimer?.cancel();

      if (state.bluetoothAdapterState != BluetoothAdapterState.on) {
        log.info('BluetoothConnectEventScan BluetoothAdapterState is not on');
        return;
      }

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
          try {
            final devices = currentState.scanedDevices;
            for (final device in devices) {
              injector<FFBluetoothService>().connectToDeviceIfBonded(device);
            }
          } catch (e) {
            log.info('Failed to connect to bonded devices: $e');
            currentState = currentState.copyWith(error: e.toString());
          }
          emit(currentState);
          log.info(
              'BluetoothConnectEventScan emitted ${filteredResults.length}');
          injector<CanvasDeviceBloc>().add(
            CanvasDeviceGetDevicesEvent(),
          );
        },
        onError: (error) {
          emit(state.copyWith(isScanning: false));
          _scanTimer?.cancel();
          scanSubscription?.cancel();
        },
      );

      FlutterBluePlus.cancelWhenScanComplete(scanSubscription);
      log.info('BluetoothConnectEventScan startScan');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 60), // Updated to 60 seconds
        androidUsesFineLocation: true,
        withServices: [
          Guid(injector<FFBluetoothService>().serviceUuid),
        ],
      );
      // wait for scan to complete
      while (FlutterBluePlus.isScanningNow) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      emit(currentState.copyWith(isScanning: false));
    });

    on<BluetoothConnectEventStopScan>((event, emit) async {
      _scanTimer?.cancel();
      await FlutterBluePlus.stopScan();
      final newState = state.copyWith(isScanning: false);
      emit(newState);
      log.info(
          'BluetoothConnectEventStopScan emitted ${state.scanResults.length}');
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
        emit(state.copyWith(
            connectedDevice: device,
            connectingDevice: null,
            shouldOverrideConnectingDevice: true));
      } catch (e) {
        await event.onConnectFailure?.call(device);
        emit(state.copyWith(
            error: e.toString(),
            connectingDevice: null,
            shouldOverrideConnectingDevice: true));
        return;
      }
    });

    on<BluetoothConnectEventUpdateBluetoothState>((event, emit) async {
      emit(state.copyWith(bluetoothAdapterState: event.bluetoothAdapterState));
      switch (event.bluetoothAdapterState) {
        case BluetoothAdapterState.on:
          add(BluetoothConnectEventScan());
          break;
        case BluetoothAdapterState.off:
        case BluetoothAdapterState.unavailable:
        case BluetoothAdapterState.unauthorized:
        case BluetoothAdapterState.unknown:
          add(BluetoothConnectEventStopScan());
          final newState = state.copyWith(
            scanResults: [],
          );
          emit(newState);
          log.info(
              'BluetoothConnectEventUpdateBluetoothState emitted ${state.scanResults.length}');

          injector<CanvasDeviceBloc>().add(CanvasDeviceGetDevicesEvent());
          break;
        default:
          break;
      }
    });

    on<BluetoothConnectEventGetBluetoothStatus>((event, emit) async {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        add(BluetoothConnectEventUpdateBluetoothState(
            BluetoothAdapterState.unavailable));
        return;
      }

      addBluetoothConnectEventGetBluetoothStatus();

      // Auto-enable Bluetooth on Android
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          emit(state.copyWith(error: 'Failed to enable Bluetooth'));
        }
      }
    });
  }

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  void addBluetoothConnectEventGetBluetoothStatus() {
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = FlutterBluePlus.adapterState
        .listen((BluetoothAdapterState bluetoothState) {
      add(BluetoothConnectEventUpdateBluetoothState(bluetoothState));
    });
  }
}
