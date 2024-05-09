import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/transformers.dart';
import 'package:web3dart/json_rpc.dart';

abstract class CanvasDeviceEvent {}

class CanvasDeviceGetDevicesEvent extends CanvasDeviceEvent {
  CanvasDeviceGetDevicesEvent();
}

class CanvasDeviceAppendDeviceEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceAppendDeviceEvent(this.device);
}

class CanvasDeviceGetControllingStatusEvent extends CanvasDeviceEvent {}

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
  final List<CanvasDevice> devices;

  CanvasDeviceDisconnectEvent(this.devices);
}

class CanvasDeviceCastListArtworkEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final List<PlayArtworkV2> artwork;

  CanvasDeviceCastListArtworkEvent(this.device, this.artwork);
}

class CanvasDeviceChangeControlDeviceEvent extends CanvasDeviceEvent {
  final CanvasDevice newDevice;
  final List<PlayArtworkV2> artwork;

  CanvasDeviceChangeControlDeviceEvent(this.newDevice, this.artwork);
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
  final Map<String, CheckDeviceStatusReply>? controllingDeviceStatus;

  // final String sceneId;
  final RPCError? rpcError;
  final bool isLoaded;

  CanvasDeviceState({
    required this.devices,
    this.controllingDeviceStatus,
    this.isLoaded = false,
    this.rpcError,
  });

  CanvasDeviceState copyWith(
          {List<DeviceState>? devices,
          Map<String, CheckDeviceStatusReply>? controllingDeviceStatus,
          bool? isLoaded,
          RPCError? rpcError}) =>
      CanvasDeviceState(
          devices: devices ?? this.devices,
          controllingDeviceStatus:
              controllingDeviceStatus ?? this.controllingDeviceStatus,
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

  Duration? get castingSpeed {
    final controllingDevice = controllingDeviceStatus?.keys.first;
    if (controllingDevice == null) {
      return null;
    }
    final status = controllingDeviceStatus![controllingDevice];
    if (status == null) {
      return null;
    }
    return Duration(milliseconds: status.artworks.first.duration);
  }

  CanvasDevice? get controllingDevice => devices
      .firstWhereOrNull((deviceState) =>
          controllingDeviceStatus?.keys.contains(deviceState.device.id) ??
          false)
      ?.device;

  bool isDeviceControlling(CanvasDevice device) =>
      controllingDeviceStatus?.keys.contains(device.id) ?? false;

  List<DeviceState> get controllingDevices =>
      devices.where((element) => isDeviceControlling(element.device)).toList();

  bool get isCasting => devices.any((element) =>
      element.device == controllingDevice && element.isPlaying == true);
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

EventTransformer<Event> debounceSequential<Event>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).asyncExpand(mapper);

class CanvasDeviceBloc extends AuBloc<CanvasDeviceEvent, CanvasDeviceState> {
  final CanvasClientService _canvasClientService;
  final CanvasClientServiceV2 _canvasClientServiceV2;

  // constructor
  CanvasDeviceBloc(this._canvasClientService, this._canvasClientServiceV2)
      : super(CanvasDeviceState(devices: [])) {
    on<CanvasDeviceGetDevicesEvent>(
      (event, emit) async {
        emit(state.copyWith(
            devices: state.devices, isLoaded: state.devices.isNotEmpty));
        final devices = await _canvasClientServiceV2.scanDevices();

        final thisDevice = _canvasClientServiceV2.clientDeviceInfo;
        final Map<String, CheckDeviceStatusReply> controllingDeviceStatus = {};
        for (final device in devices) {
          if (device.second.connectedDevice.deviceId == thisDevice.deviceId) {
            controllingDeviceStatus[device.first.id] = device.second;
            break;
          }
        }
        final newState = state.copyWith(
            devices: devices.map((e) => DeviceState(device: e.first)).toList(),
            controllingDeviceStatus: controllingDeviceStatus,
            isLoaded: true);
        emit(newState);
      },
      transformer: debounceSequential(const Duration(seconds: 5)),
    );

    on<CanvasDeviceAppendDeviceEvent>((event, emit) async {
      final newState = state.copyWith(
          devices: state.devices
            ..removeWhere((element) => element.device.id == event.device.id)
            ..add(DeviceState(device: event.device)));
      emit(newState);
    });

    on<CanvasDeviceAddEvent>((event, emit) async {
      final newState = state.copyWith(
          devices: state.devices
            ..removeWhere(
                (element) => element.device.id == event.device.device.id)
            ..add(DeviceState(device: event.device.device, isPlaying: false)));
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
        await _canvasClientService.unCastSingleArtwork(device);
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
      final devices = event.devices;
      await Future.forEach<CanvasDevice>(devices, (device) async {
        try {
          log.info('CanvasDeviceBloc: disconnect device: '
              '${device.id}, ${device.name}, ${device.ip}');
          await _canvasClientServiceV2.disconnectDevice(device);
          emit(state.replaceDeviceState(
              device: device, deviceState: DeviceState(device: device)));
        } catch (e) {
          log.info('CanvasDeviceBloc: error while disconnect device: $e');
        }
      });
      emit(state.copyWith(controllingDeviceStatus: {}));
    });

    on<CanvasDeviceCastListArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final ok =
            await _canvasClientServiceV2.castListArtwork(device, event.artwork);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        final currentDeviceState = state.devices
            .firstWhereOrNull((element) => element.device.id == device.id);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final status =
            await _canvasClientServiceV2.getDeviceCastingStatus(device);
        emit(
          state
              .replaceDeviceState(
                  device: device,
                  deviceState: currentDeviceState.copyWith(isPlaying: true))
              .copyWith(controllingDeviceStatus: {device.id: status}),
        );
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      }
    });

    on<CanvasDeviceCancelCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices
            .firstWhereOrNull((element) => element.device.id == device.id);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.cancelCasting(device);
        emit(state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: false)));
      } catch (_) {}
    });

    on<CanvasDeviceNextArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices
            .firstWhereOrNull((element) => element.device.id == device.id);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.nextArtwork(device);
        emit(state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: true)));
      } catch (_) {}
    });

    on<CanvasDevicePreviousArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices
            .firstWhereOrNull((element) => element.device.id == device.id);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.previousArtwork(device);
        emit(state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: true)));
      } catch (_) {}
    });

    on<CanvasDevicePauseCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices
            .firstWhereOrNull((element) => element.device.id == device.id);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.pauseCasting(device);
        emit(state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: false)));
      } catch (_) {}
    });

    on<CanvasDeviceResumeCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices
            .firstWhereOrNull((element) => element.device.id == device.id);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.resumeCasting(device);
        emit(state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: true)));
      } catch (_) {}
    });

    on<CanvasDeviceChangeControlDeviceEvent>((event, emit) async {
      add(CanvasDeviceCastListArtworkEvent(event.newDevice, event.artwork));
    });

    on<CanvasDeviceUpdateDurationEvent>((event, emit) async {
      final device = event.device;
      final artworks = event.artwork;
      try {
        final response =
            await _canvasClientServiceV2.updateDuration(device, artworks);
        final currentDeviceState = state.devices
            .firstWhereOrNull((element) => element.device.id == device.id);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final controllingStatus = state.controllingDeviceStatus?[device.id];
        if (controllingStatus == null) {
          throw Exception('Device not found');
        }
        final newControllingStatus = CheckDeviceStatusReply();
        newControllingStatus.artworks.clear();
        newControllingStatus.artworks.addAll(artworks);
        newControllingStatus
          ..startTime = response.startTime
          ..connectedDevice = controllingStatus.connectedDevice;

        final controllingDeviceStatus =
            state.controllingDeviceStatus?.map((key, value) {
          if (key == device.id) {
            return MapEntry(key, newControllingStatus);
          }
          return MapEntry(key, value);
        });

        emit(state
            .copyWith(controllingDeviceStatus: controllingDeviceStatus)
            .replaceDeviceState(
                device: device,
                deviceState: currentDeviceState.copyWith(isPlaying: true)));
      } catch (_) {}
    });
  }
}
