import 'dart:async';
import 'dart:ui' as ui;

import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

final speedValues = {
  '5sec': const Duration(seconds: 5),
  '10sec': const Duration(seconds: 10),
  '15sec': const Duration(seconds: 15),
  '30sec': const Duration(seconds: 30),
  '1min': const Duration(minutes: 1),
  '2min': const Duration(minutes: 2),
  // '5min': const Duration(minutes: 5),
  // '10min': const Duration(minutes: 10),
  // '15min': const Duration(minutes: 15),
  // '30min': const Duration(minutes: 30),
  // '1hr': const Duration(hours: 1),
  // '4hr': const Duration(hours: 4),
  // '12hr': const Duration(hours: 12),
  // '24hr': const Duration(hours: 24),
};

class StreamDrawerItem extends StatelessWidget {
  final OptionItem item;
  final Color backgroundColor;

  const StreamDrawerItem(
      {required this.item, required this.backgroundColor, super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        width: MediaQuery.of(context).size.width,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            splashFactory: InkSparkle.splashFactory,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  item.title ?? '',
                  style: Theme.of(context).textTheme.ppMori400Black14,
                ),
              ),
            ),
            onTap: () => item.onTap?.call(),
          ),
        ),
      );
}

class PlaylistControl extends StatefulWidget {
  const PlaylistControl({super.key});

  @override
  State<PlaylistControl> createState() => _PlaylistControlState();
}

class _PlaylistControlState extends State<PlaylistControl> {
  late double _currentSliderValue;
  Timer? _timer;
  late CanvasDeviceBloc _canvasDeviceBloc;

  @override
  void initState() {
    super.initState();
    _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
    final castingDuration = _canvasDeviceBloc.state.castingSpeed;
    final index = castingDuration != null
        ? speedValues.values.toList().indexOf(castingDuration)
        : 0;
    _currentSliderValue = index.toDouble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<CanvasDeviceBloc, CanvasDeviceState>(
        bloc: _canvasDeviceBloc,
        listener: (context, state) {
          final castingSpeed = state.controllingDeviceStatus?.values.firstOrNull
              ?.artworks.firstOrNull?.duration;
          if (castingSpeed != null) {
            final castingDuration = Duration(milliseconds: castingSpeed);
            final index = speedValues.values.toList().indexOf(castingDuration);
            setState(() {
              _currentSliderValue = index.toDouble();
            });
          }
        },
        builder: (context, state) {
          return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColor.primaryBlack,
              ),
              child: Column(
                children: [
                  _buildPlayControls(context, state),
                  const SizedBox(height: 15),
                  _buildSpeedControl(context, state),
                ],
              ));
        },
      );

  Widget _buildPlayButton({required String icon, required Function() onTap}) =>
      Expanded(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColor.auGreyBackground,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              splashFactory: InkSparkle.splashFactory,
              borderRadius: BorderRadius.circular(5),
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: SvgPicture.asset(
                  icon,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildPlayControls(BuildContext context, CanvasDeviceState state) {
    final isCasting = state.isCasting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'play_collection'.tr(),
          style: Theme.of(context).textTheme.ppMori400White12,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildPlayButton(
                icon: 'assets/images/chevron_left_icon.svg',
                onTap: () => {
                      onPrevious(context),
                    }),
            const SizedBox(width: 15),
            _buildPlayButton(
                icon: isCasting
                    ? 'assets/images/stream_pause_icon.svg'
                    : 'assets/images/stream_play_icon.svg',
                onTap: () => {
                      onPauseOrResume(context),
                    }),
            const SizedBox(width: 15),
            _buildPlayButton(
                icon: 'assets/images/chevron_right_icon.svg',
                onTap: () => {
                      onNext(context),
                    }),
          ],
        )
      ],
    );
  }

  void onPrevious(BuildContext context) {
    final controllingDevice = _canvasDeviceBloc.state.controllingDevice;
    if (controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc.add(CanvasDevicePreviousArtworkEvent(controllingDevice));
  }

  void onNext(BuildContext context) {
    final controllingDevice = _canvasDeviceBloc.state.controllingDevice;
    if (controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc.add(CanvasDeviceNextArtworkEvent(controllingDevice));
  }

  void onPause(BuildContext context) {
    final controllingDevice = _canvasDeviceBloc.state.controllingDevice;
    if (controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc.add(CanvasDevicePauseCastingEvent(controllingDevice));
  }

  void onResume(BuildContext context) {
    final controllingDevice = _canvasDeviceBloc.state.controllingDevice;
    if (controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc.add(CanvasDeviceResumeCastingEvent(controllingDevice));
  }

  void onPauseOrResume(BuildContext context) {
    // final _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
    final isCasting = _canvasDeviceBloc.state.isCasting;
    if (isCasting) {
      onPause(context);
    } else {
      onResume(context);
    }
  }

  void changeSpeed(Duration duration) {
    final controllingDevice = _canvasDeviceBloc.state.controllingDevice;
    if (controllingDevice == null) {
      return;
    }
    final canvasStatus =
        _canvasDeviceBloc.state.controllingDeviceStatus?.values.firstOrNull;
    if (canvasStatus == null) {
      return;
    }
    final playArtworks = canvasStatus.artworks;
    final playArtworkWithNewDuration = playArtworks.map((e) {
      return e.copy(duration: Duration(milliseconds: duration.inMilliseconds));
    }).toList();
    _canvasDeviceBloc.add(CanvasDeviceUpdateDurationEvent(
        controllingDevice, playArtworkWithNewDuration));
  }

  Widget _buildSpeedControl(BuildContext context, CanvasDeviceState state) {
    final speedTitles = speedValues.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'autoplay_speed'.tr(),
          style: Theme.of(context).textTheme.ppMori400White12,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColor.auGreyBackground,
          ),
          child: Row(
            children: [
              Text(
                speedTitles.last,
                style: Theme.of(context).textTheme.ppMori400White12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    activeTrackColor: AppColor.white,
                    inactiveTrackColor: AppColor.white,
                    trackHeight: 1,
                    trackShape: RectangularSliderTrackShape(),
                    thumbColor: AppColor.white,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                    valueIndicatorColor: AppColor.white,
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                  ),
                  child: Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: Slider(
                      value: _currentSliderValue,
                      max: speedTitles.length.toDouble() - 1,
                      divisions: speedTitles.length,
                      label: speedTitles[_currentSliderValue.round()],
                      onChanged: (double value) {
                        setState(() {
                          _currentSliderValue = value;
                        });
                        final controllingDeviceIds =
                            state.controllingDeviceStatus?.keys.toList();
                        if (controllingDeviceIds == null ||
                            controllingDeviceIds.isEmpty) {
                          return;
                        }
                        _timer?.cancel();
                        _timer = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            changeSpeed(speedValues[
                                speedTitles[_currentSliderValue.round()]]!);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                speedTitles.first,
                style: Theme.of(context).textTheme.ppMori400White12,
              ),
            ],
          ),
        )
      ],
    );
  }
}

extension PlayArtworkExt on PlayArtworkV2 {
  PlayArtworkV2 copy({
    CastAssetToken? token,
    CastArtwork? artwork,
    Duration? duration,
  }) {
    return PlayArtworkV2(
      token: token ?? this.token,
      artwork: artwork ?? this.artwork,
      duration: duration?.inMilliseconds ?? this.duration,
    );
  }
}
