import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_tv_proto/models/canvas_device.dart';
import 'package:collection/collection.dart';

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

class CanvasDeviceCastSingleEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final String tokenId;

  CanvasDeviceCastSingleEvent(this.device, this.tokenId);
}

class CanvasDeviceUncastingSingleEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceUncastingSingleEvent(this.device);
}

class CanvasDeviceRotateEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final bool clockwise;

  CanvasDeviceRotateEvent(this.device, {this.clockwise = true});
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

  CanvasDeviceState replaceDeviceState(
      {required CanvasDevice device, required DeviceState deviceState}) {
    final newDeviceState = devices.map((e) {
      if (e.device == device) {
        return deviceState;
      }
      return e;
    }).toList();
    return copyWith(devices: newDeviceState);
  }

  List<CanvasDevice> get playingDevice {
    return devices
        .map((e) {
          if (e.status == DeviceStatus.playing) {
            return e.device;
          }
        })
        .whereNotNull()
        .toList();
  }

  bool get isCasting {
    return devices.firstWhereOrNull((deviceState) {
          return deviceState.status == DeviceStatus.playing;
        }) !=
        null;
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
      final devices = await _canvasClientService.getConnectingDevices();
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

    on<CanvasDevicePlayEvent>((event, emit) async {});

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

    on<CanvasDeviceCastSingleEvent>((event, emit) async {
      final device = event.device;
      try {
        emit(state.replaceDeviceState(
            device: device,
            deviceState:
                DeviceState(device: device, status: DeviceStatus.loading)));
        await _canvasClientService.castSingleArtwork(device, event.tokenId);
        emit(state.replaceDeviceState(
            device: device,
            deviceState:
                DeviceState(device: device, status: DeviceStatus.playing)));
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device,
            deviceState:
                DeviceState(device: device, status: DeviceStatus.error)));
      }
    });

    on<CanvasDeviceUncastingSingleEvent>((event, emit) async {
      final device = event.device;
      try {
        await _canvasClientService.uncastSingleArtwork(device);
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      } catch (_) {}
    });

    on<CanvasDeviceRotateEvent>((event, emit) async {
      final device = event.device;
      try {
        await _canvasClientService.rotateCanvas(device,
            clockwise: event.clockwise);
      } catch (_) {}
    });
  }
}
