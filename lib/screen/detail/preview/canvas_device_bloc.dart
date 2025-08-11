//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/device/base_device.dart';
import 'package:autonomy_flutter/model/device/device_display_setting.dart';
import 'package:autonomy_flutter/model/device/device_status.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/device_status_ext.dart';
import 'package:autonomy_flutter/util/int_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/view/now_displaying_view.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/transformers.dart';

abstract class CanvasDeviceEvent {}

class CanvasDeviceUpdateCastingStatusEvent extends CanvasDeviceEvent {
  CanvasDeviceUpdateCastingStatusEvent(
    this.device,
    this.status,
  );

  final BaseDevice device;
  final CheckCastingStatusReply status;
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

class CanvasDeviceUpdateArtFramingEvent extends CanvasDeviceEvent {
  CanvasDeviceUpdateArtFramingEvent(
    this.device,
    this.artFraming,
    this.onErrorCallback,
    this.onDoneCallback,
  );

  final BaseDevice device;
  final ArtFraming artFraming;

  final FutureOr<void> Function(Object error)? onErrorCallback;
  final FutureOr<void> Function()? onDoneCallback;
}

/*
* Version V2
*/

class CanvasDeviceDisconnectedEvent extends CanvasDeviceEvent {
  CanvasDeviceDisconnectedEvent(this.device, {this.callRPC = true});

  final BaseDevice device;
  final bool callRPC;
}

class CanvasDeviceCastListArtworkEvent extends CanvasDeviceEvent {
  CanvasDeviceCastListArtworkEvent(this.device, this.artwork, {this.onDone});

  final BaseDevice device;
  final List<PlayArtworkV2> artwork;
  final FutureOr<void> Function()? onDone;
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
  CanvasDeviceCastExhibitionEvent(this.device, this.castRequest, {this.onDone});

  final BaseDevice device;
  final CastExhibitionRequest castRequest;
  final FutureOr<void> Function()? onDone;
}

class CanvasDeviceUpdateConnectionEvent extends CanvasDeviceEvent {
  CanvasDeviceUpdateConnectionEvent(this.device, this.isConnected);

  final BaseDevice device;
  final bool isConnected;
}

class CanvasDeviceCastDailyWorkEvent extends CanvasDeviceEvent {
  CanvasDeviceCastDailyWorkEvent(this.device, this.castRequest);

  final BaseDevice device;
  final CastDailyWorkRequest castRequest;
}

class CanvasDeviceState {
  CanvasDeviceState({
    Map<String, CheckCastingStatusReply>? canvasDeviceStatus,
    Map<String, BaseDevice>? lastSelectedActiveDeviceMap,
    Map<String, bool>? deviceAliveMap,
    Map<String, DeviceStatus>? deviceInfoMap,
  })  : canvasDeviceStatus = canvasDeviceStatus ?? {},
        lastSelectedActiveDeviceMap = lastSelectedActiveDeviceMap ?? {},
        deviceAliveMap = deviceAliveMap ?? {},
        deviceInfoMap = deviceInfoMap ?? {};

  final Map<String, CheckCastingStatusReply> canvasDeviceStatus;
  final Map<String, BaseDevice> lastSelectedActiveDeviceMap;
  final Map<String, bool> deviceAliveMap;
  final Map<String, DeviceStatus> deviceInfoMap;

  CanvasDeviceState copyWith({
    Map<String, CheckCastingStatusReply>? controllingDeviceStatus,
    Map<String, BaseDevice>? lastActiveDevice,
    Map<String, bool>? deviceAliveMap,
    Map<String, DeviceStatus>? deviceInfoMap,
  }) =>
      CanvasDeviceState(
        canvasDeviceStatus: controllingDeviceStatus ?? canvasDeviceStatus,
        lastSelectedActiveDeviceMap:
            lastActiveDevice ?? lastSelectedActiveDeviceMap,
        deviceAliveMap: deviceAliveMap ?? this.deviceAliveMap,
        deviceInfoMap: deviceInfoMap ?? this.deviceInfoMap,
      );

  CanvasDeviceState updateOnCast({
    required BaseDevice device,
    required String displayKey,
  }) {
    final newLastSelectedActiveDeviceMap = lastSelectedActiveDeviceMap.copy()
      ..removeWhere((key, value) => value == device);
    newLastSelectedActiveDeviceMap[displayKey] = device;
    return copyWith(
      lastActiveDevice: newLastSelectedActiveDeviceMap,
    );
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
    final duration = lastActiveDeviceStatus?.artworks.firstOrNull?.duration;
    return duration;
  }

  List<BaseDevice> get devices => BluetoothDeviceManager.pairedDevices;

  CheckCastingStatusReply? statusOf(BaseDevice device) =>
      canvasDeviceStatus[device.deviceId];

  bool isDeviceAlive(BaseDevice device) {
    final isAlive =
        deviceAliveMap[device.deviceId] == true && statusOf(device) != null;
    return isAlive;
  }

  CanvasDeviceState updateDeviceAlive(
    BaseDevice device,
    bool isAlive,
  ) {
    final newDeviceAliveMap = deviceAliveMap.copy();
    newDeviceAliveMap[device.deviceId] = isAlive;

    return copyWith(
      deviceAliveMap: newDeviceAliveMap,
    );
  }

  List<BaseDevice> get activeDevices {
    return devices.where((element) => isDeviceAlive(element)).toList();
  }

  BaseDevice? _activeDeviceForKey(String key) {
    final id = canvasDeviceStatus.entries
        .firstWhereOrNull((element) => element.value.playingArtworkKey == key)
        ?.key;
    return devices.firstWhereOrNull(
        (element) => element.deviceId == id && isDeviceAlive(element));
  }

  DeviceDisplaySetting? deviceDisplaySettingOf(BaseDevice device) {
    final status = statusOf(device);
    return status?.deviceSettings;
  }
}

EventTransformer<Event> debounceSequential<Event>(Duration duration) =>
    (events, mapper) => events.throttleTime(duration).asyncExpand(mapper);

class CanvasDeviceBloc extends AuBloc<CanvasDeviceEvent, CanvasDeviceState> {
  // constructor
  CanvasDeviceBloc(this._canvasClientServiceV2) : super(CanvasDeviceState()) {
    on<CanvasDeviceUpdateCastingStatusEvent>(
      (event, emit) {
        final device = event.device;
        final status = event.status;
        final key = status.playingArtworkKey;
        final newState = state.canvasDeviceStatus.copy()
          ..[device.deviceId] = status;
        emit(state
            .updateOnCast(device: device, displayKey: key)
            .copyWith(controllingDeviceStatus: newState));
        NowDisplayingManager().updateDisplayingNow();
      },
    );

    on<CanvasDeviceUpdateConnectionEvent>(
      (event, emit) {
        final device = event.device;
        final isConnected = event.isConnected;
        final newState = state.updateDeviceAlive(device, isConnected);
        emit(newState);
        if (!isConnected) {
          NowDisplayingManager().addStatus(
            DeviceDisconnected(device),
          );
        }
      },
    );

    on<CanvasDeviceRotateEvent>((event, emit) async {
      final device = event.device;
      try {
        final response = await _canvasClientServiceV2.rotateCanvas(
          device,
          clockwise: event.clockwise,
        );
        if (response != null) {
          final newStatusMap = state.canvasDeviceStatus.copy();
          final currentStatus = newStatusMap[device.deviceId];
          if (currentStatus != null) {
            newStatusMap[device.deviceId] = currentStatus.copyWith(
              deviceSettings: currentStatus.deviceSettings?.copyWith(
                screenOrientation: response,
              ),
            );
          }

          emit(state.copyWith(controllingDeviceStatus: newStatusMap));
        }

        await event.onDoneCallback?.call();
      } catch (e, s) {
        log.info('CanvasDeviceBloc: error while rotate device: $e', s);
      }
    });

    /*
    * Version V2
    */

    on<CanvasDeviceDisconnectedEvent>((event, emit) async {
      final device = event.device;
      final newState = state.canvasDeviceStatus.copy()..remove(device.deviceId);
      emit(state.copyWith(controllingDeviceStatus: newState));
    });

    on<CanvasDeviceCastListArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final ok =
            await _canvasClientServiceV2.castListArtwork(device, event.artwork);
        if (!ok) {
          throw Exception('Failed to cast to device');
        }
        final currentDeviceState = state.canvasDeviceStatus[device.deviceId];
        final status = CheckCastingStatusReply(
          artworks: event.artwork,
          index: 0,
          isPaused: false,
          connectedDevice: currentDeviceState?.connectedDevice,
        );
        add(CanvasDeviceUpdateCastingStatusEvent(
          device,
          status,
        ));
      } catch (_) {
      } finally {
        unawaited(NowDisplayingManager().updateDisplayingNow());
        await event.onDone?.call();
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
          (element) => element.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final currentDeviceStatus = state.canvasDeviceStatus[device.deviceId];
        final status = CheckCastingStatusReply(
          artworks: [],
          exhibitionId: event.castRequest.exhibitionId,
          catalogId: event.castRequest.catalogId,
          catalog: event.castRequest.catalog,
          connectedDevice: currentDeviceStatus?.connectedDevice,
        );
        add(CanvasDeviceUpdateCastingStatusEvent(
          device,
          status,
        ));
      } catch (_) {
      } finally {
        unawaited(NowDisplayingManager().updateDisplayingNow());
        await event.onDone?.call();
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
          (element) => element.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final currentDeviceStatus = state.canvasDeviceStatus[device.deviceId];
        final status = CheckCastingStatusReply(
          artworks: [],
          displayKey: CastDailyWorkRequest.displayKey,
          connectedDevice: currentDeviceStatus?.connectedDevice,
        );
        add(CanvasDeviceUpdateCastingStatusEvent(
          device,
          status,
        ));
      } catch (_) {}
    });

    on<CanvasDeviceNextArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        //  must get the current device status before calling nextArtwork
        final currentDeviceStatus = state.canvasDeviceStatus[device.deviceId];

        await _canvasClientServiceV2.nextArtwork(device);

        if (currentDeviceStatus == null) {
          log.info(
            'CanvasDeviceBloc, CanvasDeviceNextArtworkEvent currentDeviceStatus is null for device: ${device.deviceId}',
          );
          return;
        }
        final status = CheckCastingStatusReply(
          artworks: currentDeviceStatus.artworks,
          index: (currentDeviceStatus.index! + 1) %
              currentDeviceStatus.artworks.length,
          connectedDevice: currentDeviceStatus.connectedDevice,
          isPaused: false,
        );
        final newStatus = state.canvasDeviceStatus.copy();
        newStatus[device.deviceId] = status;
        emit(
          state.copyWith(controllingDeviceStatus: newStatus),
        );
        unawaited(NowDisplayingManager().updateDisplayingNow());
      } catch (_) {}
    });

    on<CanvasDevicePreviousArtworkEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        // must get the current device status before calling previousArtwork
        final currentDeviceStatus = state.canvasDeviceStatus[device.deviceId];

        await _canvasClientServiceV2.previousArtwork(device);

        if (currentDeviceStatus == null) {
          log.info(
            'CanvasDeviceBloc, CanvasDevicePreviousArtworkEvent currentDeviceStatus is null for device: ${device.deviceId}',
          );
          return;
        }
        final status = CheckCastingStatusReply(
          artworks: currentDeviceStatus.artworks,
          index: (currentDeviceStatus.index! -
                  1 +
                  currentDeviceStatus.artworks.length) %
              currentDeviceStatus.artworks.length,
          connectedDevice: currentDeviceStatus.connectedDevice,
          isPaused: false,
        );
        final newStatus = state.canvasDeviceStatus.copy();
        newStatus[device.deviceId] = status;
        emit(
          state.copyWith(controllingDeviceStatus: newStatus),
        );
        unawaited(NowDisplayingManager().updateDisplayingNow());
      } catch (_) {}
    });

    on<CanvasDevicePauseCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final currentDeviceStatus = state.canvasDeviceStatus[device.deviceId];
        if (currentDeviceStatus == null) {
          log.info(
            'CanvasDeviceBloc, CanvasDevicePauseCastingEvent currentDeviceStatus is null for device: ${device.deviceId}',
          );
          return;
        }
        final status = currentDeviceStatus.copyWith(isPaused: true);
        await _canvasClientServiceV2.pauseCasting(device);
        final newStatus = state.canvasDeviceStatus.copy();
        newStatus[device.deviceId] = status;
        emit(
          state.copyWith(
            controllingDeviceStatus: newStatus,
          ),
        );
      } catch (_) {}
    });

    on<CanvasDeviceResumeCastingEvent>((event, emit) async {
      final device = event.device;
      try {
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final currentDeviceStatus = state.canvasDeviceStatus[device.deviceId];
        if (currentDeviceStatus == null) {
          log.info(
            'CanvasDeviceBloc, CanvasDeviceResumeCastingEvent currentDeviceStatus is null for device: ${device.deviceId}',
          );
          return;
        }
        final status = currentDeviceStatus.copyWith(isPaused: false);
        await _canvasClientServiceV2.resumeCasting(device);
        final newStatus = state.canvasDeviceStatus.copy();
        newStatus[device.deviceId] = status;
        emit(
          state.copyWith(
            controllingDeviceStatus: newStatus,
          ),
        );
      } catch (_) {}
    });

    on<CanvasDeviceUpdateDurationEvent>((event, emit) async {
      final device = event.device;
      final artworks = event.artwork;
      try {
        await _canvasClientServiceV2.updateDuration(device, artworks);
        final currentDeviceState = state.devices.firstWhereOrNull(
          (element) => element.deviceId == device.deviceId,
        );
        if (currentDeviceState == null) {
          throw Exception('Device not found');
        }
        final controllingStatus = state.canvasDeviceStatus[device.deviceId];
        if (controllingStatus == null) {
          throw Exception('Device not found');
        }
        final newControllingStatus = CheckCastingStatusReply(artworks: artworks)
          ..index = controllingStatus.index
          ..connectedDevice = controllingStatus.connectedDevice;

        final controllingDeviceStatus =
            state.canvasDeviceStatus.map((key, value) {
          if (key == device.deviceId) {
            return MapEntry(key, newControllingStatus);
          }
          return MapEntry(key, value);
        });

        emit(
          state.copyWith(controllingDeviceStatus: controllingDeviceStatus),
        );
      } catch (e) {
        log.info('CanvasDeviceBloc: error while update duration: $e');
      }
    });

    on<CanvasDeviceUpdateArtFramingEvent>((event, emit) async {
      final device = event.device;
      final artFraming = event.artFraming;
      try {
        final ok =
            await _canvasClientServiceV2.updateArtFraming(device, artFraming);
        if (!ok) {
          throw Exception('Failed to update art framing');
        }

        final newStatus = state.canvasDeviceStatus.copy();
        final currentStatus = newStatus[device.deviceId];
        if (currentStatus != null) {
          newStatus[device.deviceId] = currentStatus.copyWith(
            deviceSettings: currentStatus.deviceSettings?.copyWith(
              scaling: artFraming,
            ),
          );
        }
        emit(state.copyWith(controllingDeviceStatus: newStatus));
        event.onDoneCallback?.call();
      } catch (e) {
        log.info('CanvasDeviceBloc: error while update art framing: $e');
        event.onErrorCallback?.call(e);
      }
    });
  }

  final CanvasClientServiceV2 _canvasClientServiceV2;

  void clear() {
    state.devices.clear();
    state.canvasDeviceStatus.clear();
    state.lastSelectedActiveDeviceMap.clear();
  }
}
