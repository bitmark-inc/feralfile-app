import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectBloc
    extends AuBloc<BluetoothConnectEvent, BluetoothConnectState> {
  BluetoothConnectBloc() : super(BluetoothConnectState()) {
    on<BluetoothConnectEventScan>((event, emit) async {
      if (!injector<AuthService>().isBetaTester()) {
        return;
      }
      emit(state.copyWith(isScanning: true));
      StreamSubscription<List<ScanResult>>? scanSubscription;

      // start scanning

      if (state.bluetoothAdapterState != BluetoothAdapterState.on) {
        log.info('BluetoothConnectEventScan BluetoothAdapterState is not on');
        return;
      }

      await injector<FFBluetoothService>().startScan(
        timeout: Duration(seconds: 15),
        onData: (results) async {
          final filteredResults = results.where((result) {
            return result.advertisementData.serviceUuids
                .map((uuid) => uuid.toString().toLowerCase())
                .contains(
                  injector<FFBluetoothService>().advertisingUuid.toLowerCase(),
                );
          }).toList();
          try {
            final currentState = state.copyWith(scanResults: filteredResults);
            emit(currentState);
          } catch (e) {
            log.info('Failed to connect to bonded devices: $e');
            emit(state.copyWith(error: e.toString()));
          }
          injector<CanvasDeviceBloc>().add(
            CanvasDeviceGetDevicesEvent(),
          );
          return false;
        },
        onError: (error) {
          emit(state.copyWith(isScanning: false));
          scanSubscription?.cancel();
        },
      );
      emit(state.copyWith(isScanning: false));
    });

    on<BluetoothConnectEventStopScan>((event, emit) async {
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
      if (!injector<AuthService>().isBetaTester()) {
        return;
      }
      emit(state.copyWith(bluetoothAdapterState: event.bluetoothAdapterState));
      switch (event.bluetoothAdapterState) {
        case BluetoothAdapterState.on:
          add(BluetoothConnectEventScan());
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

    //   on<BluetoothConnectEventGetBluetoothStatus>((event, emit) async {
    //     // Check if Bluetooth is supported
    //     if (await FlutterBluePlus.isSupported == false) {
    //       add(BluetoothConnectEventUpdateBluetoothState(
    //           BluetoothAdapterState.unavailable));
    //       return;
    //     }
    //
    //     addBluetoothConnectEventGetBluetoothStatus();
    //
    //     // Auto-enable Bluetooth on Android
    //     if (Platform.isAndroid) {
    //       try {
    //         await FlutterBluePlus.turnOn();
    //       } catch (e) {
    //         emit(state.copyWith(error: 'Failed to enable Bluetooth'));
    //       }
    //     }
    //   });
  }

  @override
  void add(BluetoothConnectEvent event) {
    if (injector<AuthService>().isBetaTester()) {
      super.add(event);
    } else {
      log.info(
          'BluetoothConnectBloc user is not beta tester, ignoring event ${event.runtimeType}');
    }
  }

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

// void addBluetoothConnectEventGetBluetoothStatus() {
//   _adapterStateSubscription?.cancel();
//   _adapterStateSubscription = FlutterBluePlus.adapterState
//       .listen((BluetoothAdapterState bluetoothState) {
//     add(BluetoothConnectEventUpdateBluetoothState(bluetoothState));
//   });
// }
}
