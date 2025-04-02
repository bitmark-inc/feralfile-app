import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/artist_display_setting.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ArtistDisplaySetting {
  ArtistDisplaySetting({
    this.screenOrientation = ScreenOrientation.portrait,
    this.artFraming = ArtFraming.fitToScreen,
    this.backgroundColour = AppColor.primaryBlack,
    this.margin = const EdgeInsets.all(0.0),
    this.autoPlay = true,
    this.loop = true,
    this.interactable = true,
    this.overridable = true,
  });

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

// toJson with format {
//   "scaling" : "fit|fill",
//   "backgroundColor": "#000000",
//   "marginLeft" : 0.1,
//   "marginRight" : 0.1,
//   "marginTop" : 0.1,
//   "marginBottom" : 0.1,
//   "autoPlay" : false,
//   "looping" : false,
//   "interactable" : true,
//   "overridable" : false
// }
  Map<String, dynamic> toJson() {
    return {
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
  });

  final ArtistDisplaySetting artistDisplaySetting;
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
  SaveArtistArtworkDisplaySettingEvent({this.seriesId});

  final String? seriesId;
}

class ArtistArtworkDisplaySettingBloc extends AuBloc<
    ArtistArtworkDisplaySettingEvent, ArtistArtworkDisplaySettingState> {
  ArtistArtworkDisplaySettingBloc()
      : super(ArtistArtworkDisplaySettingState(
            artistDisplaySetting: ArtistDisplaySetting())) {
    on<InitArtistArtworkDisplaySettingEvent>((event, emit) {
      emit(ArtistArtworkDisplaySettingState(
          artistDisplaySetting: event.artistDisplaySetting));
    });

    on<UpdateOrientationEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        screenOrientation: event.screenOrientation,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
    });

    on<UpdateArtFramingEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        artFraming: event.artFraming,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
    });

    on<UpdateBackgroundColourEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        backgroundColour: event.backgroundColour,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
    });

    on<UpdateMarginEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        margin: event.margin,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
    });

    on<UpdateAutoPlayEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        autoPlay: event.autoPlay,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
    });

    on<UpdateLoopEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        loop: event.loop,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
    });

    on<UpdateInteractableEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        interactable: event.interactable,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
    });

    on<UpdateOverridableEvent>((event, emit) {
      final newSetting = state.artistDisplaySetting.copyWith(
        overridable: event.overridable,
      );
      emit(ArtistArtworkDisplaySettingState(artistDisplaySetting: newSetting));
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
            'SaveArtistArtworkDisplaySettingEvent] saved artist artwork display setting');
        injector<NavigationService>().showArtistDisplaySettingSaved();
      } catch (e) {
        log.info(
            'SaveArtistArtworkDisplaySettingEvent] save artist artwork display setting, error: $e');
        injector<NavigationService>()
            .showArtistDisplaySettingSaveFailed(exception: e);
      }
    });
  }
}
