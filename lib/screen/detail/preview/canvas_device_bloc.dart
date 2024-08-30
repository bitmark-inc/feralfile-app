//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_store.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/cast_request_ext.dart';
import 'package:autonomy_flutter/util/device_status_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/transformers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/json_rpc.dart';

abstract class CanvasDeviceEvent {}

class CanvasDeviceGetDevicesEvent extends CanvasDeviceEvent {
  final bool retry;

  CanvasDeviceGetDevicesEvent({this.retry = false});
}

class CanvasDeviceAppendDeviceEvent extends CanvasDeviceEvent {
  final CanvasDevice device;

  CanvasDeviceAppendDeviceEvent(this.device);
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
  final bool callRPC;

  CanvasDeviceDisconnectEvent(this.devices, {this.callRPC = true});
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

class CanvasDeviceCastExhibitionEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final CastExhibitionRequest castRequest;

  CanvasDeviceCastExhibitionEvent(this.device, this.castRequest);
}

class CanvasDeviceCastDailyWorkEvent extends CanvasDeviceEvent {
  final CanvasDevice device;
  final CastDailyWorkRequest castRequest;

  CanvasDeviceCastDailyWorkEvent(this.device, this.castRequest);
}

class CanvasDeviceState {
  final List<DeviceState> devices;
  final Map<String, CheckDeviceStatusReply> canvasDeviceStatus;

  final _selectedCanvasDeviceStore = injector<SelectedCanvasDeviceStore>();

  // final String sceneId;
  final RPCError? rpcError;

  CanvasDeviceState({
    required this.devices,
    Map<String, CheckDeviceStatusReply>? canvasDeviceStatus,
    this.rpcError,
  }) : canvasDeviceStatus = canvasDeviceStatus ?? {};

  CanvasDeviceState copyWith(
          {List<DeviceState>? devices,
          Map<String, CheckDeviceStatusReply>? controllingDeviceStatus,
          RPCError? rpcError}) =>
      CanvasDeviceState(
          devices: devices ?? this.devices,
          canvasDeviceStatus: controllingDeviceStatus ?? canvasDeviceStatus,
          rpcError: rpcError ?? this.rpcError);

  Future<void> updateOnCast(
      {required CanvasDevice device, required String displayKey}) async {
    await _selectedCanvasDeviceStore.save(device, displayKey);
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

  CanvasDevice? lastSelectedActiveDeviceForKey(String key) {
    final lastActiveDevice = _selectedCanvasDeviceStore.get(key);
    if (lastActiveDevice != null) {
      if (isDeviceAlive(lastActiveDevice)) {
        return lastActiveDevice;
      } else {
        unawaited(_selectedCanvasDeviceStore.delete(key));
      }
    }
    final activeDevice = _activeDeviceForKey(key);
    if (activeDevice != null) {
      unawaited(_selectedCanvasDeviceStore.save(activeDevice, key));
    }
    return activeDevice;
  }

  Duration? castingSpeed(String key) {
    CanvasDevice? lastActiveDevice = lastSelectedActiveDeviceForKey(key);
    final lastActiveDeviceStatus =
        canvasDeviceStatus[lastActiveDevice?.deviceId];
    final durationInMillisecond =
        lastActiveDeviceStatus?.artworks.first.duration;
    if (durationInMillisecond != null) {
      return Duration(milliseconds: durationInMillisecond);
    }
    return null;
  }

  CheckDeviceStatusReply? statusOf(CanvasDevice device) =>
      canvasDeviceStatus[device.deviceId];

  bool isDeviceAlive(CanvasDevice device) {
    final status = statusOf(device);
    return status != null;
  }

  CanvasDevice? _activeDeviceForKey(String key) {
    final id = canvasDeviceStatus.entries
        .firstWhereOrNull((element) => element.value.playingArtworkKey == key)
        ?.key;
    return devices
        .firstWhereOrNull((element) => element.device.deviceId == id)
        ?.device;
  }
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
  final CanvasClientServiceV2 _canvasClientServiceV2;

  // constructor
  CanvasDeviceBloc(this._canvasClientServiceV2)
      : super(CanvasDeviceState(devices: [])) {
    on<CanvasDeviceGetDevicesEvent>(
      (event, emit) async {
        log.info('CanvasDeviceBloc: adding devices');
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
      transformer: debounceSequential(const Duration(seconds: 5)),
    );

    on<CanvasDeviceAppendDeviceEvent>((event, emit) async {
      final newState = state.copyWith(
          devices: state.devices
            ..removeWhere(
                (element) => element.device.deviceId == event.device.deviceId)
            ..add(DeviceState(device: event.device)));
      emit(newState);
    });

    on<CanvasDeviceRotateEvent>((event, emit) async {
      final device = event.device;
      try {
        await _canvasClientServiceV2.rotateCanvas(device,
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
              '${device.deviceId}, ${device.name}, ${device.deviceId}');
          if (event.callRPC) {
            await _canvasClientServiceV2.disconnectDevice(device);
          }
          add(CanvasDeviceGetDevicesEvent());
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
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final status =
            await _canvasClientServiceV2.getDeviceCastingStatus(device);
        final newStatus = state.canvasDeviceStatus;
        newStatus[device.deviceId] = status;
        final displayKey = event.artwork.playArtworksHashCode.toString();
        await state.updateOnCast(device: device, displayKey: displayKey);
        emit(
          state
              .replaceDeviceState(
                  device: device,
                  deviceState: currentDeviceState.copyWith(isPlaying: true))
              .copyWith(controllingDeviceStatus: newStatus),
        );
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      }
    });

    on<CanvasDeviceCastExhibitionEvent>((event, emit) async {
      final device = event.device;
      try {
        final ok = await _canvasClientServiceV2.castExhibition(
            device, event.castRequest);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final status =
            await _canvasClientServiceV2.getDeviceCastingStatus(device);
        final newStatus = state.canvasDeviceStatus;
        newStatus[device.deviceId] = status;
        final displayKey = event.castRequest.displayKey;
        await state.updateOnCast(device: device, displayKey: displayKey);
        emit(
          state
              .replaceDeviceState(
                  device: device,
                  deviceState: currentDeviceState.copyWith(isPlaying: true))
              .copyWith(controllingDeviceStatus: newStatus),
        );
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      }
    });

    on<CanvasDeviceCastDailyWorkEvent>((event, emit) async {
      final device = event.device;
      try {
        final ok = await _canvasClientServiceV2.castDailyWork(
            device, event.castRequest);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
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
                  deviceState: currentDeviceState.copyWith(isPlaying: true))
              .copyWith(controllingDeviceStatus: newStatus),
        );
      } catch (_) {
        emit(state.replaceDeviceState(
            device: device, deviceState: DeviceState(device: device)));
      }
    });

    on<CanvasDeviceNextArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
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
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
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
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
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
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
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
        final currentDeviceState = state.devices.firstWhereOrNull(
            (element) => element.device.deviceId == device.deviceId);
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

        emit(state
            .copyWith(controllingDeviceStatus: controllingDeviceStatus)
            .replaceDeviceState(
                device: device,
                deviceState: currentDeviceState.copyWith(isPlaying: true)));
      } catch (_) {}
    });
  }
}
