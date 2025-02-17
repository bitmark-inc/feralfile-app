//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/cast_request_ext.dart';
import 'package:autonomy_flutter/util/device_status_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/transformers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/json_rpc.dart';

abstract class CanvasDeviceEvent {}

class CanvasDeviceGetDevicesEvent extends CanvasDeviceEvent {
  CanvasDeviceGetDevicesEvent({this.retry = false});

  final bool retry;
}

class CanvasDeviceGetStatusEvent extends CanvasDeviceEvent {
  CanvasDeviceGetStatusEvent(this.device);

  final BaseDevice device;
}

class CanvasDeviceAppendDeviceEvent extends CanvasDeviceEvent {
  CanvasDeviceAppendDeviceEvent(this.device);

  final CanvasDevice device;
}

class CanvasDeviceRotateEvent extends CanvasDeviceEvent {
  CanvasDeviceRotateEvent(
    this.device, {
    this.clockwise = false,
    this.onDoneCallback,
  });

  final BaseDevice device;
  final bool clockwise;
  final FutureOr<void> Function()? onDoneCallback;
}

/*
* Version V2
*/

class CanvasDeviceDisconnectEvent extends CanvasDeviceEvent {
  CanvasDeviceDisconnectEvent(this.devices, {this.callRPC = true});

  final List<BaseDevice> devices;
  final bool callRPC;
}

class CanvasDeviceCastListArtworkEvent extends CanvasDeviceEvent {
  CanvasDeviceCastListArtworkEvent(this.device, this.artwork, {this.completer});

  final BaseDevice device;
  final List<PlayArtworkV2> artwork;
  final Completer<void>? completer;
}

class CanvasDevicePauseCastingEvent extends CanvasDeviceEvent {
  CanvasDevicePauseCastingEvent(this.device);

  final BaseDevice device;
}

class CanvasDeviceResumeCastingEvent extends CanvasDeviceEvent {
  CanvasDeviceResumeCastingEvent(this.device);

  final BaseDevice device;
}

class CanvasDeviceNextArtworkEvent extends CanvasDeviceEvent {
  CanvasDeviceNextArtworkEvent(this.device);

  final BaseDevice device;
}

class CanvasDevicePreviousArtworkEvent extends CanvasDeviceEvent {
  CanvasDevicePreviousArtworkEvent(this.device);

  final BaseDevice device;
}

class CanvasDeviceUpdateDurationEvent extends CanvasDeviceEvent {
  CanvasDeviceUpdateDurationEvent(this.device, this.artwork);

  final BaseDevice device;
  final List<PlayArtworkV2> artwork;
}

class CanvasDeviceCastExhibitionEvent extends CanvasDeviceEvent {
  CanvasDeviceCastExhibitionEvent(this.device, this.castRequest,
      {this.completer});

  final BaseDevice device;
  final CastExhibitionRequest castRequest;
  final Completer<void>? completer;
}

class CanvasDeviceCastDailyWorkEvent extends CanvasDeviceEvent {
  CanvasDeviceCastDailyWorkEvent(this.device, this.castRequest);

  final BaseDevice device;
  final CastDailyWorkRequest castRequest;
}

class CanvasDeviceState {
  CanvasDeviceState({
    required this.devices,
    Map<String, CheckDeviceStatusReply>? canvasDeviceStatus,
    Map<String, BaseDevice>? lastSelectedActiveDeviceMap,
    this.rpcError,
  })  : canvasDeviceStatus = canvasDeviceStatus ?? {},
        lastSelectedActiveDeviceMap = lastSelectedActiveDeviceMap ?? {};
  final List<DeviceState> devices;
  final Map<String, CheckDeviceStatusReply> canvasDeviceStatus;
  final Map<String, BaseDevice> lastSelectedActiveDeviceMap;

  // final String sceneId;
  final RPCError? rpcError;

  CanvasDeviceState copyWith({
    List<DeviceState>? devices,
    Map<String, CheckDeviceStatusReply>? controllingDeviceStatus,
    Map<String, BaseDevice>? lastActiveDevice,
    RPCError? rpcError,
  }) =>
      CanvasDeviceState(
        devices: devices ?? this.devices,
        canvasDeviceStatus: controllingDeviceStatus ?? canvasDeviceStatus,
        lastSelectedActiveDeviceMap:
            lastActiveDevice ?? lastSelectedActiveDeviceMap,
        rpcError: rpcError ?? this.rpcError,
      );

  CanvasDeviceState updateOnCast({
    required BaseDevice device,
    required String displayKey,
  }) {
    lastSelectedActiveDeviceMap.removeWhere((key, value) => value == device);
    lastSelectedActiveDeviceMap[displayKey] = device;
    return copyWith(
      lastActiveDevice: lastSelectedActiveDeviceMap,
    );
  }

  CanvasDeviceState replaceDeviceState({
    required BaseDevice device,
    required DeviceState deviceState,
  }) {
    final newDeviceState = devices.map((e) {
      if (e.device == device) {
        return deviceState;
      }
      return e;
    }).toList();
    return copyWith(devices: newDeviceState);
  }

  BaseDevice? lastSelectedActiveDeviceForKey(String key) {
    final lastActiveDevice = lastSelectedActiveDeviceMap[key];
    if (lastActiveDevice != null) {
      if (isDeviceAlive(lastActiveDevice)) {
        return lastActiveDevice;
      } else {
        lastSelectedActiveDeviceMap.remove(key);
      }
    }
    final activeDevice = _activeDeviceForKey(key);
    if (activeDevice != null) {
      lastSelectedActiveDeviceMap[key] = activeDevice;
    }
    return activeDevice;
  }

  Duration? castingSpeed(String key) {
    final lastActiveDevice = lastSelectedActiveDeviceForKey(key);
    final lastActiveDeviceStatus =
        canvasDeviceStatus[lastActiveDevice?.deviceId];
    final durationInMilisecond =
        lastActiveDeviceStatus?.artworks.firstOrNull?.duration;
    if (durationInMilisecond != null) {
      return Duration(milliseconds: durationInMilisecond);
    }
    return null;
  }

  CheckDeviceStatusReply? statusOf(BaseDevice device) =>
      canvasDeviceStatus[device.deviceId];

  bool isDeviceAlive(BaseDevice device) {
    final status = statusOf(device);
    return status != null;
  }

  BaseDevice? _activeDeviceForKey(String key) {
    final id = canvasDeviceStatus.entries
        .firstWhereOrNull((element) => element.value.playingArtworkKey == key)
        ?.key;
    return devices
        .firstWhereOrNull((element) => element.device.deviceId == id)
        ?.device;
  }
}

class DeviceState {
  // constructor
  DeviceState({
    required this.device,
    this.duration,
    this.isPlaying,
  });

  final BaseDevice device;
  final Duration? duration;
  final bool? isPlaying;

  //
  DeviceState copyWith({
    BaseDevice? device,
    Duration? duration,
    // for playlist: true: playing, false: pause
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
    (events, mapper) => events.throttleTime(duration).asyncExpand(mapper);

class CanvasDeviceBloc extends AuBloc<CanvasDeviceEvent, CanvasDeviceState> {
  // constructor
  CanvasDeviceBloc(this._canvasClientServiceV2)
      : super(CanvasDeviceState(devices: [])) {
    on<CanvasDeviceGetDevicesEvent>(
      (event, emit) async {
        log.info('CanvasDeviceGetDevicesEvent');
        try {
          final devices = await _canvasClientServiceV2.scanDevices();

          Map<String, CheckDeviceStatusReply>? controllingDeviceStatus = {};

          controllingDeviceStatus = devices.controllingDevices;

          final newState = state.copyWith(
            devices: devices.map((e) => DeviceState(device: e.first)).toList(),
            controllingDeviceStatus: controllingDeviceStatus,
          );
          log.info('CanvasDeviceBloc: get devices: ${newState.devices.length}, '
              'controllingDeviceStatus: ${newState.canvasDeviceStatus}');
          emit(newState);
        } catch (e) {
          log.info('CanvasDeviceBloc: error while get devices: $e');
          unawaited(Sentry.captureException(e));
          emit(state.copyWith());
        }
      },
      // transformer: debounceSequential(
      //   const Duration(seconds: 5),
      // ),
    );

    on<CanvasDeviceGetStatusEvent>(
      (event, emit) async {
        try {
          final status = await _canvasClientServiceV2.getDeviceCastingStatus(
            event.device,
          );
          final newStatuses = state.canvasDeviceStatus
            ..[event.device.deviceId] = status;
          final newState = state.copyWith(
            controllingDeviceStatus: newStatuses,
          );
          emit(newState);
        } catch (e) {
          log.info('CanvasDeviceBloc: error while get device status: $e');
          unawaited(Sentry.captureException(e));
          emit(state.copyWith());
        }
      },
      // transformer: debounceSequential(
      //   const Duration(seconds: 5),
      // ),
    );

    on<CanvasDeviceAppendDeviceEvent>((event, emit) async {
      final newState = state.copyWith(
        devices: state.devices
          ..removeWhere(
            (element) => element.device.deviceId == event.device.deviceId,
          )
          ..add(DeviceState(device: event.device)),
      );
      emit(newState);
    });

    on<CanvasDeviceRotateEvent>((event, emit) async {
      final device = event.device;
      try {
        await _canvasClientServiceV2.rotateCanvas(
          device,
          clockwise: event.clockwise,
        );
        await event.onDoneCallback?.call();
      } catch (e, s) {
        log.info('CanvasDeviceBloc: error while rotate device: $e', s);
      }
    });

    /*
    * Version V2
    */

    on<CanvasDeviceDisconnectEvent>((event, emit) async {
      final devices = event.devices;
      await Future.forEach<BaseDevice>(devices, (device) async {
        try {
          log.info('CanvasDeviceBloc: disconnect device: '
              '${device.deviceId}, ${device.deviceId}');
          if (event.callRPC) {
            await _canvasClientServiceV2.disconnectDevice(device);
          }
          add(CanvasDeviceGetDevicesEvent());
        } catch (e) {
          log.info('CanvasDeviceBloc: error while disconnect device: $e');
        }
      });

      emit(state.copyWith(controllingDeviceStatus: {}, lastActiveDevice: {}));
      add(CanvasDeviceGetDevicesEvent());
    });

    on<CanvasDeviceCastListArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final ok =
            await _canvasClientServiceV2.castListArtwork(device, event.artwork);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final status =
            await _canvasClientServiceV2.getDeviceCastingStatus(device);
        final newStatus = state.canvasDeviceStatus;
        newStatus[device.deviceId] = status;
        final displayKey = event.artwork.playArtworksHashCode.toString();
        emit(
          state
              .updateOnCast(device: device, displayKey: displayKey)
              .replaceDeviceState(
                device: device,
                deviceState: currentDeviceState.copyWith(isPlaying: true),
              )
              .copyWith(controllingDeviceStatus: newStatus),
        );
      } catch (_) {
        emit(
          state.replaceDeviceState(
            device: device,
            deviceState: DeviceState(device: device),
          ),
        );
      } finally {
        event.completer?.complete();
      }
    });

    on<CanvasDeviceCastExhibitionEvent>((event, emit) async {
      final device = event.device;
      try {
        final ok = await _canvasClientServiceV2.castExhibition(
          device,
          event.castRequest,
        );
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final status =
            await _canvasClientServiceV2.getDeviceCastingStatus(device);
        final newStatus = state.canvasDeviceStatus;
        newStatus[device.deviceId] = status;
        final displayKey = event.castRequest.displayKey;
        emit(
          state
              .updateOnCast(device: device, displayKey: displayKey)
              .replaceDeviceState(
                device: device,
                deviceState: currentDeviceState.copyWith(isPlaying: true),
              )
              .copyWith(controllingDeviceStatus: newStatus),
        );
      } catch (_) {
        emit(
          state.replaceDeviceState(
            device: device,
            deviceState: DeviceState(device: device),
          ),
        );
      } finally {
        event.completer?.complete();
      }
    });

    on<CanvasDeviceCastDailyWorkEvent>((event, emit) async {
      final device = event.device;
      try {
        final ok = await _canvasClientServiceV2.castDailyWork(
          device,
          event.castRequest,
        );
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final status =
            await _canvasClientServiceV2.getDeviceCastingStatus(device);
        final newStatus = state.canvasDeviceStatus;
        newStatus[device.deviceId] = status;
        final displayKey = CastDailyWorkRequest.displayKey;
        emit(
          state
              .updateOnCast(device: device, displayKey: displayKey)
              .replaceDeviceState(
                device: device,
                deviceState: currentDeviceState.copyWith(isPlaying: true),
              )
              .copyWith(controllingDeviceStatus: newStatus),
        );
      } catch (_) {
        emit(
          state.replaceDeviceState(
            device: device,
            deviceState: DeviceState(device: device),
          ),
        );
      }
    });

    on<CanvasDeviceNextArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.nextArtwork(device);
        emit(
          state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: true),
          ),
        );
      } catch (_) {}
    });

    on<CanvasDevicePreviousArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.previousArtwork(device);
        emit(
          state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: true),
          ),
        );
      } catch (_) {}
    });

    on<CanvasDevicePauseCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.pauseCasting(device);
        emit(
          state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: false),
          ),
        );
      } catch (_) {}
    });

    on<CanvasDeviceResumeCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        await _canvasClientServiceV2.resumeCasting(device);
        emit(
          state.replaceDeviceState(
            device: device,
            deviceState: currentDeviceState.copyWith(isPlaying: true),
          ),
        );
      } catch (_) {}
    });

    on<CanvasDeviceUpdateDurationEvent>((event, emit) async {
      final device = event.device;
      final artworks = event.artwork;
      try {
        final response =
            await _canvasClientServiceV2.updateDuration(device, artworks);
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.device.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final controllingStatus = state.canvasDeviceStatus[device.deviceId];
        if (controllingStatus == null) {
          throw Exception('Device not found');
        }
        final newControllingStatus = CheckDeviceStatusReply(artworks: artworks)
          ..startTime = response.startTime
          ..connectedDevice = controllingStatus.connectedDevice;

        final controllingDeviceStatus =
            state.canvasDeviceStatus.map((key, value) {
          if (key == device.deviceId) {
            return MapEntry(key, newControllingStatus);
          }
          return MapEntry(key, value);
        });

        emit(
          state
              .copyWith(controllingDeviceStatus: controllingDeviceStatus)
              .replaceDeviceState(
                device: device,
                deviceState: currentDeviceState.copyWith(isPlaying: true),
              ),
        );
      } catch (_) {}
    });
  }

  final CanvasClientServiceV2 _canvasClientServiceV2;

  void clear() {
    state.devices.clear();
    state.canvasDeviceStatus.clear();
    state.lastSelectedActiveDeviceMap.clear();
  }
}
