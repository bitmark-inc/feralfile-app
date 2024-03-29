import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';

abstract class CanvasDeviceEvent {}

class CanvasDeviceGetDevicesEvent extends CanvasDeviceEvent {
  final String sceneId;
  final bool syncAll;

  // constructor
  CanvasDeviceGetDevicesEvent(this.sceneId, {this.syncAll = true});
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

class CanvasDeviceCastCollectionEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final PlayListModel playlist;

  CanvasDeviceCastCollectionEvent(this.device, this.playlist);
}

class CanvasDeviceUnCastingEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final bool isCollection;

  CanvasDeviceUnCastingEvent(this.device, this.isCollection);
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
  final bool isLoaded;

  CanvasDeviceState({
    required this.devices,
    required this.isLoaded,
    this.sceneId = '',
    this.isConnectError = false,
  });

  CanvasDeviceState copyWith({
    List<DeviceState>? devices,
    String? sceneId,
    bool? isConnectError,
    bool? isLoaded,
  }) =>
      CanvasDeviceState(
        devices: devices ?? this.devices,
        sceneId: sceneId ?? this.sceneId,
        isConnectError: isConnectError ?? false,
        isLoaded: isLoaded ?? this.isLoaded,
      );

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

  List<CanvasDevice> get playingDevice => devices
      .map((e) {
        if (e.status == DeviceStatus.playing) {
          return e.device;
        }
      })
      .whereNotNull()
      .toList();

  bool get isCasting =>
      devices.firstWhereOrNull((deviceState) =>
          deviceState.status == DeviceStatus.playing &&
          deviceState.device.playingSceneId == sceneId) !=
      null;
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
  }) =>
      DeviceState(
        device: device ?? this.device,
        status: status ?? this.status,
      );
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
      : super(CanvasDeviceState(devices: [], isLoaded: false)) {
    on<CanvasDeviceGetDevicesEvent>((event, emit) async {
      emit(CanvasDeviceState(
          devices: state.devices,
          sceneId: event.sceneId,
          isLoaded: state.devices.isNotEmpty));
      final devices = await _canvasClientService.getConnectingDevices(
          doSync: event.syncAll);
      emit(state.copyWith(
          devices: devices
              .map((e) => DeviceState(
                  device: e,
                  status: e.isConnecting && e.playingSceneId != null
                      ? DeviceStatus.playing
                      : DeviceStatus.connected))
              .toList(),
          isLoaded: true));
    });

    on<CanvasDeviceAddEvent>((event, emit) async {
      final newState = state.copyWith(
          devices: state.devices
            ..removeWhere(
                (element) => element.device.id == event.device.device.id)
            ..add(DeviceState(device: event.device.device)));
      emit(newState);
    });

    on<CanvasDeviceCastSingleEvent>((event, emit) async {
      final device = event.device;
      try {
        emit(state.replaceDeviceState(
            device: device,
            deviceState:
                DeviceState(device: device, status: DeviceStatus.loading)));
        final connected = await _canvasClientService.connectToDevice(device);
        if (!connected) {
          throw Exception('Failed to connect to device');
        }
        final ok =
            await _canvasClientService.castSingleArtwork(device, event.tokenId);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
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

    on<CanvasDeviceCastCollectionEvent>((event, emit) async {
      final device = event.device;
      try {
        emit(state.replaceDeviceState(
            device: device,
            deviceState:
                DeviceState(device: device, status: DeviceStatus.loading)));
        final connected = await _canvasClientService.connectToDevice(device);
        if (!connected) {
          throw Exception('Failed to connect to device');
        }
        final ok =
            await _canvasClientService.castCollection(device, event.playlist);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
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

    on<CanvasDeviceUnCastingEvent>((event, emit) async {
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
