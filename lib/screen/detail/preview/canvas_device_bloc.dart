import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:web3dart/json_rpc.dart';

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

/*
* Version V2
*/

class CanvasDeviceDisconnectEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceDisconnectEvent(this.device);
}

class CanvasDeviceCastListArtworkEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final List<PlayArtworkV2> artwork;

  CanvasDeviceCastListArtworkEvent(this.device, this.artwork);
}

class CanvasDeviceCancelCastingEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceCancelCastingEvent(this.device);
}

class CanvasDevicePauseCastingEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDevicePauseCastingEvent(this.device);
}

class CanvasDeviceResumeCastingEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceResumeCastingEvent(this.device);
}

class CanvasDeviceNextArtworkEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceNextArtworkEvent(this.device);
}

class CanvasDevicePreviousArtworkEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDevicePreviousArtworkEvent(this.device);
}

class CanvasDeviceUpdateDurationEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final List<PlayArtworkV2> artwork;

  CanvasDeviceUpdateDurationEvent(this.device, this.artwork);
}

class CanvasDeviceState {
  final List<DeviceState> devices;
  final List<String> controllingDeviceIds;

  // final String sceneId;
  final RPCError? rpcError;
  final bool isLoaded;

  CanvasDeviceState({
    required this.devices,
    this.controllingDeviceIds = const [],
    this.isLoaded = false,
    this.rpcError,
  });

  CanvasDeviceState copyWith(
          {List<DeviceState>? devices,
          List<String>? controllingDeviceIds,
          bool? isLoaded,
          RPCError? rpcError}) =>
      CanvasDeviceState(
          devices: devices ?? this.devices,
          controllingDeviceIds:
              controllingDeviceIds ?? this.controllingDeviceIds,
          isLoaded: isLoaded ?? this.isLoaded,
          rpcError: rpcError ?? this.rpcError);

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

  List<CanvasDevice> get playingDevice => [];

  CanvasDevice? get connectingDevice => devices
      .firstWhereOrNull((deviceState) => deviceState.device.isConnecting)
      ?.device;

  bool get isCasting => connectingDevice != null;
}

class DeviceState {
  final CanvasDevice device;
  final Duration? duration;
  final bool? isPlaying;

  // constructor
  DeviceState({
    required this.device,
    this.duration,
    this.isPlaying,
  });

  //
  DeviceState copyWith({
    CanvasDevice? device,
    Duration? duration,
    bool? isPlaying,
  }) =>
      DeviceState(
        device: device ?? this.device,
        duration: duration ?? this.duration,
        isPlaying: isPlaying ?? this.isPlaying,
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
  final CanvasClientServiceV2 _canvasClientServiceV2;

  // constructor
  CanvasDeviceBloc(this._canvasClientService, this._canvasClientServiceV2)
      : super(CanvasDeviceState(devices: [], isLoaded: false)) {
    on<CanvasDeviceGetDevicesEvent>((event, emit) async {
      // emit(CanvasDeviceState(
      //     devices: state.devices,
      //     sceneId: event.sceneId,
      //     isLoaded: state.devices.isNotEmpty));
      // final devices = await _canvasClientService.getConnectingDevices(
      //     doSync: event.syncAll);
      emit(
        state.copyWith(
            // devices: devices
            //     .map((e) => DeviceState(
            //         device: e,
            //         status: e.isConnecting && e.playingSceneId != null
            //             ? DeviceStatus.playing
            //             : DeviceStatus.connected))
            //     .toList(),
            devices: [
              DeviceState(
                device: CanvasDevice(
                    id: '411f861a-3c81-4eed-821a-634116bccf45',
                    ip: '192.168.31.116',
                    port: 50051,
                    name: 'SM-S908E',
                    isConnecting: false,
                    playingSceneId: ''),
                duration: Duration(seconds: 10),
                isPlaying: true,
              ),
              DeviceState(
                device: CanvasDevice(
                    id: '0',
                    ip: '192.168.31.1',
                    port: 4200,
                    name: 'LG-423',
                    isConnecting: true,
                    playingSceneId: ''),
                duration: Duration(seconds: 10),
                isPlaying: true,
              ),
              DeviceState(
                device: CanvasDevice(
                    id: '1',
                    ip: '192.168.31.2',
                    port: 4200,
                    name: "Sean's iPad Pro",
                    isConnecting: false,
                    playingSceneId: ''),
                duration: Duration(seconds: 10),
                isPlaying: true,
              ),
              DeviceState(
                device: CanvasDevice(
                    id: '2',
                    ip: '192.168.31.3',
                    port: 4200,
                    name: 'LG-424',
                    isConnecting: false,
                    playingSceneId: ''),
                duration: Duration(seconds: 10),
                isPlaying: true,
              ),
            ],
            isLoaded: true),
      );
    });

    on<CanvasDeviceAddEvent>((event, emit) async {
      final newState = state.copyWith(
          devices: state.devices
            ..removeWhere(
                (element) => element.device.id == event.device.device.id)
            ..add(DeviceState(
                device: event.device.device,
                duration: null,
                isPlaying: false)));
      emit(newState);
    });

    on<CanvasDeviceCastSingleEvent>((event, emit) async {
      final device = event.device;
      try {
        emit(state.replaceDeviceState(
            device: device,
            deviceState: DeviceState(
              device: device,
            )));
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
            device: device, deviceState: DeviceState(device: device)));
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      }
    });

    on<CanvasDeviceCastCollectionEvent>((event, emit) async {
      final device = event.device;
      try {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
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
            device: device, deviceState: DeviceState(device: device)));
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
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

    /*
    * Version V2
    */

    on<CanvasDeviceDisconnectEvent>((event, emit) async {
      final device = event.device;
      try {
        await _canvasClientServiceV2.disconnectDevice(device);
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      } catch (_) {}
    });

    on<CanvasDeviceCastListArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
        final connected = await _canvasClientServiceV2.connectToDevice(device);
        if (!connected) {
          throw Exception('Failed to connect to device');
        }
        final ok =
            await _canvasClientServiceV2.castListArtwork(device, event.artwork);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      }
    });

    on<CanvasDeviceCancelCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        await _canvasClientServiceV2.cancelCasting(device);
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      } catch (_) {}
    });
  }
}
