import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/database/entity/canvas_device.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';

abstract class CanvasDeviceEvent {}

class CanvasDeviceGetDevicesEvent extends CanvasDeviceEvent {
  final String sceneId;

  // constructor
  CanvasDeviceGetDevicesEvent(this.sceneId);
}

class CanvasDevicePlayEvent extends CanvasDeviceEvent {
  final int index;

  CanvasDevicePlayEvent(this.index);
}

class CanvasDeviceDisconnectEvent extends CanvasDeviceEvent {
  final int index;

  CanvasDeviceDisconnectEvent(this.index);
}

class CanvasDeviceAddEvent extends CanvasDeviceEvent {
  final DeviceState device;

  CanvasDeviceAddEvent(this.device);
}

class CanvasDeviceState {
  final List<DeviceState> devices;
  final String sceneId;

  CanvasDeviceState({
    required this.devices,
    this.sceneId = "",
  });

  CanvasDeviceState copyWith({
    List<DeviceState>? devices,
    String? sceneId,
  }) {
    return CanvasDeviceState(
      devices: devices ?? this.devices,
      sceneId: sceneId ?? this.sceneId,
    );
  }
}

class DeviceState {
  final CanvasDevice device;
  final DeviceStatus status;

  // constructor
  DeviceState({
    required this.device,
    this.status = DeviceStatus.disconnected,
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
  connecting,
  playing,
  disconnected,
  error,
}

class CanvasDeviceBloc extends AuBloc<CanvasDeviceEvent, CanvasDeviceState> {
  final CanvasClientService _canvasClientService;

  // constructor
  CanvasDeviceBloc(this._canvasClientService)
      : super(CanvasDeviceState(devices: [])) {
    on<CanvasDeviceGetDevicesEvent>((event, emit) async {
      emit(CanvasDeviceState(devices: state.devices, sceneId: event.sceneId));
      final devices = await _canvasClientService.getAllDevices();
      emit(CanvasDeviceState(
          devices: devices.map((e) => DeviceState(device: e)).toList()));
    });

    on<CanvasDeviceAddEvent>((event, emit) async {
      final newState = state.copyWith(
          devices: state.devices
            ..removeWhere((element) => element.device.id == event.device.device.id)
            ..add(DeviceState(device: event.device.device)));
      emit(newState);
    });
  }
}
