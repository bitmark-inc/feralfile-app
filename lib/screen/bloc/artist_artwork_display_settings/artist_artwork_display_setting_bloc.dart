import 'dart:async';

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/artist_display_setting.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ArtistDisplaySetting {
  ArtistDisplaySetting({
    this.screenOrientation = ScreenOrientation.portrait,
    this.artFraming = ArtFraming.cropToFill,
    this.backgroundColour = AppColor.primaryBlack,
    this.margin = EdgeInsets.zero,
    this.autoPlay = true,
    this.loop = true,
    this.interactable = true,
    this.overridable = true,
  });

  // fromJson
  factory ArtistDisplaySetting.fromJson(Map<String, dynamic> json) {
    return ArtistDisplaySetting(
      screenOrientation:
          ScreenOrientation.fromString(json['orientation'] as String),
      artFraming: ArtFraming.fromString(json['scaling'] as String),
      backgroundColour: ColorExt.fromHex(json['backgroundColor'] as String),
      margin: EdgeInsets.only(
        left: (json['marginLeft'] as double) * 100,
        right: (json['marginRight'] as double) * 100,
        top: (json['marginTop'] as double) * 100,
        bottom: (json['marginBottom'] as double) * 100,
      ),
      autoPlay: json['autoPlay'] as bool,
      loop: json['looping'] as bool,
      interactable: json['interactable'] as bool,
      overridable: json['overridable'] as bool,
    );
  }

  final ScreenOrientation screenOrientation;
  final ArtFraming artFraming;
  final Color backgroundColour;
  final EdgeInsets margin; // margin in percentage
  final bool autoPlay;
  final bool loop;
  final bool interactable;
  final bool overridable;

  ArtistDisplaySetting copyWith({
    ScreenOrientation? screenOrientation,
    ArtFraming? artFraming,
    Color? backgroundColour,
    EdgeInsets? margin,
    bool? autoPlay,
    bool? loop,
    bool? interactable,
    bool? overridable,
  }) {
    return ArtistDisplaySetting(
      screenOrientation: screenOrientation ?? this.screenOrientation,
      artFraming: artFraming ?? this.artFraming,
      backgroundColour: backgroundColour ?? this.backgroundColour,
      margin: margin ?? this.margin,
      autoPlay: autoPlay ?? this.autoPlay,
      loop: loop ?? this.loop,
      interactable: interactable ?? this.interactable,
      overridable: overridable ?? this.overridable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orientation': screenOrientation.name,
      'scaling': artFraming.name,
      'backgroundColor': backgroundColour.toHex(),
      'marginLeft': margin.left / 100,
      'marginRight': margin.right / 100,
      'marginTop': margin.top / 100,
      'marginBottom': margin.bottom / 100,
      'autoPlay': autoPlay,
      'looping': loop,
      'interactable': interactable,
      'overridable': overridable,
    };
  }
}

class ArtistArtworkDisplaySettingState {
  ArtistArtworkDisplaySettingState({
    required this.artistDisplaySetting,
    required this.tokenId,
  });

  final String tokenId;
  final ArtistDisplaySetting artistDisplaySetting;

  // copyWith
  ArtistArtworkDisplaySettingState copyWith({
    ArtistDisplaySetting? artistDisplaySetting,
    String? tokenId,
  }) {
    return ArtistArtworkDisplaySettingState(
      artistDisplaySetting: artistDisplaySetting ?? this.artistDisplaySetting,
      tokenId: tokenId ?? this.tokenId,
    );
  }
}

class ArtistArtworkDisplaySettingEvent {}

class InitArtistArtworkDisplaySettingEvent
    extends ArtistArtworkDisplaySettingEvent {
  InitArtistArtworkDisplaySettingEvent(this.artistDisplaySetting);

  final ArtistDisplaySetting artistDisplaySetting;
}

class UpdateOrientationEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateOrientationEvent(this.screenOrientation);

  final ScreenOrientation screenOrientation;
}

class UpdateArtFramingEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateArtFramingEvent(this.artFraming);

  final ArtFraming artFraming;
}

class UpdateBackgroundColourEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateBackgroundColourEvent(this.backgroundColour);

  final Color backgroundColour;
}

class UpdateMarginEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateMarginEvent(this.margin);

  final EdgeInsets margin;
}

class UpdateAutoPlayEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateAutoPlayEvent(this.autoPlay);

  final bool autoPlay;
}

class UpdateLoopEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateLoopEvent(this.loop);

  final bool loop;
}

class UpdateInteractableEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateInteractableEvent(this.interactable);

  final bool interactable;
}

class UpdateOverridableEvent extends ArtistArtworkDisplaySettingEvent {
  UpdateOverridableEvent(this.overridable);

  final bool overridable;
}

class SaveArtistArtworkDisplaySettingEvent
    extends ArtistArtworkDisplaySettingEvent {
  SaveArtistArtworkDisplaySettingEvent({
    this.seriesId,
    this.onSuccess,
    this.onError,
  });

  final String? seriesId;
  final void Function()? onSuccess;
  final void Function(Object exception)? onError;
}

class ArtistArtworkDisplaySettingBloc extends AuBloc<
    ArtistArtworkDisplaySettingEvent, ArtistArtworkDisplaySettingState> {
  ArtistArtworkDisplaySettingBloc({required String tokenId})
      : super(
          ArtistArtworkDisplaySettingState(
            tokenId: tokenId,
            artistDisplaySetting: null,
          ),
        ) {
    on<InitArtistArtworkDisplaySettingEvent>((event, emit) {
      emit(
        ArtistArtworkDisplaySettingState(
          tokenId: state.tokenId,
          artistDisplaySetting: event.artistDisplaySetting,
        ),
      );
      updateToDevice();
    });

    on<UpdateOrientationEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        screenOrientation: event.screenOrientation,
      );
      emit(
        ArtistArtworkDisplaySettingState(
          tokenId: state.tokenId,
          artistDisplaySetting: newSetting,
        ),
      );
      updateToDevice();
    });

    on<UpdateArtFramingEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        artFraming: event.artFraming,
      );
      emit(state.copyWith(artistDisplaySetting: newSetting));
      updateToDevice();
    });

    on<UpdateBackgroundColourEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        backgroundColour: event.backgroundColour,
      );
      emit(state.copyWith(artistDisplaySetting: newSetting));
      updateToDevice();
    });

    on<UpdateMarginEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        margin: event.margin,
      );
      emit(state.copyWith(artistDisplaySetting: newSetting));
      updateToDevice();
    });

    on<UpdateAutoPlayEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        autoPlay: event.autoPlay,
      );
      emit(state.copyWith(artistDisplaySetting: newSetting));
      updateToDevice();
    });

    on<UpdateLoopEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        loop: event.loop,
      );
      emit(state.copyWith(artistDisplaySetting: newSetting));
      updateToDevice();
    });

    on<UpdateInteractableEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        interactable: event.interactable,
      );
      emit(state.copyWith(artistDisplaySetting: newSetting));
      updateToDevice();
    });

    on<UpdateOverridableEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        overridable: event.overridable,
      );
      emit(state.copyWith(artistDisplaySetting: newSetting));
      updateToDevice();
    });

    on<SaveArtistArtworkDisplaySettingEvent>((event, emit) async {
      final listAssetIds = <String>[];

      final seriesId = event.seriesId;
      if (seriesId != null && seriesId.isNotEmpty) {
        final listAssetIdsFromSeries = await injector<FeralFileService>()
            .getIndexerAssetIdsFromSeries(seriesId);
        listAssetIds.addAll(listAssetIdsFromSeries);
      }

      try {
        await injector<AuthService>()
            .configureArtwork(listAssetIds, state.artistDisplaySetting);

        log.info(
          'SaveArtistArtworkDisplaySettingEvent] saved artist artwork display setting',
        );
        injector<NavigationService>().showArtistDisplaySettingSaved();
        event.onSuccess?.call();
      } catch (e) {
        log.info(
          'SaveArtistArtworkDisplaySettingEvent] save artist artwork display setting, error: $e',
        );
        event.onError?.call(e);
        injector<NavigationService>()
            .showArtistDisplaySettingSaveFailed(exception: e);
      }
    });
  }

  Timer? _timer;

  Future<void> updateToDevice({bool isSaved = false}) async {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 5), () {
      _updateToDevice(isSaved: isSaved);
    });
  }

  Future<void> _updateToDevice({bool isSaved = false}) async {
    final connectedDevice =
        injector<FFBluetoothService>().castingBluetoothDevice;
    if (connectedDevice == null) {
      log.warning(
        'ArtistArtworkDisplaySettingBloc: updateToDevice: connectedDevice is null',
      );
      return;
    }

    try {
      await injector<CanvasClientServiceV2>().updateDisplaySettings(
        connectedDevice,
        state.artistDisplaySetting,
        state.tokenId,
        isSaved: isSaved,
      );
    } catch (e) {
      log.warning('ArtistArtworkDisplaySettingBloc: updateToDevice error: $e');
    }
  }
}
