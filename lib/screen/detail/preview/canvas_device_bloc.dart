import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_tv_proto/models/canvas_device.dart';

abstract class CanvasDeviceEvent {}

class CanvasDeviceGetDevicesEvent extends CanvasDeviceEvent {
  final String sceneId;

  // constructor
  CanvasDeviceGetDevicesEvent(this.sceneId);
}

class CanvasDevicePlayEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDevicePlayEvent(this.device);
}

class CanvasDeviceDisconnectEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceDisconnectEvent(this.device);
}

class CanvasDeviceAddEvent extends CanvasDeviceEvent {
  final DeviceState device;

  CanvasDeviceAddEvent(this.device);
}

class CanvasDeviceState {
  final List<DeviceState> devices;
  final String sceneId;
  final bool isConnectError;

  CanvasDeviceState({
    required this.devices,
    this.sceneId = "",
    this.isConnectError = false,
  });

  CanvasDeviceState copyWith({
    List<DeviceState>? devices,
    String? sceneId,
    bool? isConnectError,
  }) {
    return CanvasDeviceState(
      devices: devices ?? this.devices,
      sceneId: sceneId ?? this.sceneId,
      isConnectError: isConnectError ?? false,
    );
  }
}

class DeviceState {
  final CanvasDevice device;
  DeviceStatus status;

  // constructor
  DeviceState({
    required this.device,
    this.status = DeviceStatus.connected,
  });

  //
  DeviceState copyWith({
    CanvasDevice? device,
    DeviceStatus? status,
  }) {
    return DeviceState(
      device: device ?? this.device,
      status: status ?? this.status,
    );
  }
}

enum DeviceStatus {
  connected,
  loading,
  playing,
  error,
}

class CanvasDeviceBloc extends AuBloc<CanvasDeviceEvent, CanvasDeviceState> {
  final CanvasClientService _canvasClientService;

  // constructor
  CanvasDeviceBloc(this._canvasClientService)
      : super(CanvasDeviceState(devices: [])) {
    on<CanvasDeviceGetDevicesEvent>((event, emit) async {
      emit(CanvasDeviceState(devices: state.devices, sceneId: event.sceneId));
      final devices = _canvasClientService.getConnectingDevices();
      emit(CanvasDeviceState(
          devices: devices
              .map((e) => DeviceState(
                  device: e,
                  status: e.isConnecting && e.playingSceneId != null
                      ? DeviceStatus.playing
                      : DeviceStatus.connected))
              .toList()));
    });

    on<CanvasDeviceAddEvent>((event, emit) async {
      final newState = state.copyWith(
          devices: state.devices
            ..removeWhere(
                (element) => element.device.id == event.device.device.id)
            ..add(DeviceState(device: event.device.device)));
      emit(newState);
    });

    on<CanvasDevicePlayEvent>((event, emit) async {
    });

    on<CanvasDeviceDisconnectEvent>((event, emit) async {
      final index = state.devices
          .indexWhere((element) => element.device.id == event.device.id);
      final loadingState =
          state.copyWith(devices: state.devices, sceneId: state.sceneId);
      loadingState.devices[index].status = DeviceStatus.loading;
      emit(loadingState);
      await _canvasClientService
          .disconnectToDevice(state.devices[index].device);
      final finalState =
          state.copyWith(devices: state.devices, sceneId: state.sceneId);
      finalState.devices.removeAt(index);
      emit(finalState);
    });
  }
}
