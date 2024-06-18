import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/util/range_input_formatter.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rxdart/rxdart.dart';

final speedValues = {
  // '5sec': const Duration(seconds: 5),
  // '10sec': const Duration(seconds: 10),
  // '15sec': const Duration(seconds: 15),
  // '30sec': const Duration(seconds: 30),
  '1min': const Duration(minutes: 1),
  '2min': const Duration(minutes: 2),
  '5min': const Duration(minutes: 5),
  '10min': const Duration(minutes: 10),
  '15min': const Duration(minutes: 15),
  '30min': const Duration(minutes: 30),
  '1hr': const Duration(hours: 1),
  '4hr': const Duration(hours: 4),
  '12hr': const Duration(hours: 12),
  '24hr': const Duration(hours: 24),
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
  final String displayKey;

  const PlaylistControl({required this.displayKey, super.key});

  @override
  State<PlaylistControl> createState() => _PlaylistControlState();
}

class _PlaylistControlState extends State<PlaylistControl> {
  Timer? _timer;
  late CanvasDeviceBloc _canvasDeviceBloc;
  CanvasDevice? _controllingDevice;

  @override
  void initState() {
    super.initState();
    _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
        bloc: _canvasDeviceBloc,
        builder: (context, state) {
          _controllingDevice = state.castingDeviceForKey(widget.displayKey);
          return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColor.auGreyBackground,
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
            color: AppColor.primaryBlack,
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
    final isCasting = _controllingDevice != null;
    return Row(
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
    );
  }

  Widget _buildSpeedControl(BuildContext context, CanvasDeviceState state) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'autoplay_duration'.tr(),
            style: Theme.of(context).textTheme.ppMori400White12,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: AppColor.primaryBlack,
            ),
            child: ArtworkDurationControl(
              duration: state.castingSpeed(widget.displayKey),
            ),
          )
        ],
      );

  void onPrevious(BuildContext context) {
    if (_controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc
        .add(CanvasDevicePreviousArtworkEvent(_controllingDevice!));
  }

  void onNext(BuildContext context) {
    if (_controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc.add(CanvasDeviceNextArtworkEvent(_controllingDevice!));
  }

  void onPause(BuildContext context) {
    if (_controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc.add(CanvasDevicePauseCastingEvent(_controllingDevice!));
  }

  void onResume(BuildContext context) {
    if (_controllingDevice == null) {
      return;
    }
    _canvasDeviceBloc.add(CanvasDeviceResumeCastingEvent(_controllingDevice!));
  }

  void onPauseOrResume(BuildContext context) {
    // final _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
    final isCasting = _controllingDevice != null;
    if (isCasting) {
      onPause(context);
    } else {
      onResume(context);
    }
  }
}

class ArtworkDurationControl extends StatefulWidget {
  final Duration? duration;

  const ArtworkDurationControl({super.key, this.duration});

  @override
  State<ArtworkDurationControl> createState() => _ArtworkDurationControlState();
}

class _ArtworkDurationControlState extends State<ArtworkDurationControl> {
  late FocusNode dayFocusNode;
  late FocusNode hourFocusNode;
  late FocusNode minFocusNode;
  late TextEditingController dayTextController;
  late TextEditingController hourTextController;
  late TextEditingController minTextController;
  late bool isAnyFieldFocused = false;
  final _durationSubject = PublishSubject<Duration>();
  final _canvasDeviceBloc = injector.get<CanvasDeviceBloc>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    dayFocusNode = FocusNode();
    hourFocusNode = FocusNode();
    minFocusNode = FocusNode();

    int? day;
    int? hour;
    int? min;

    if (widget.duration != null) {
      day = widget.duration!.inDays;
      hour = widget.duration!.inHours % 24;
      min = widget.duration!.inMinutes % 60;
    }

    dayTextController =
        TextEditingController(text: day?.toString().padLeft(2, '0'));
    hourTextController =
        TextEditingController(text: hour?.toString().padLeft(2, '0'));
    minTextController =
        TextEditingController(text: min?.toString().padLeft(2, '0'));

    dayFocusNode.addListener(_focusChanged);
    hourFocusNode.addListener(_focusChanged);
    minFocusNode.addListener(_focusChanged);

    _durationSubject.stream
        .debounceTime(const Duration(milliseconds: 1000))
        .listen((duration) {
      _durationChanged(duration);
    });
  }

  void _focusChanged() {
    setState(() {
      isAnyFieldFocused = dayFocusNode.hasFocus ||
          hourFocusNode.hasFocus ||
          minFocusNode.hasFocus;
    });
  }

  @override
  Future<void> dispose() async {
    dayFocusNode.dispose();
    hourFocusNode.dispose();
    minFocusNode.dispose();
    dayTextController.dispose();
    hourTextController.dispose();
    minTextController.dispose();
    _timer?.cancel();
    await _durationSubject.close();
    super.dispose();
  }

  void _durationChanged(Duration duration) {
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 300),
      () {
        changeSpeed(duration);
      },
    );
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
    final playArtworkWithNewDuration = playArtworks
        .map((e) =>
            e.copy(duration: Duration(milliseconds: duration.inMilliseconds)))
        .toList();
    _canvasDeviceBloc.add(CanvasDeviceUpdateDurationEvent(
        controllingDevice, playArtworkWithNewDuration));
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _durationWidget(
              suffixText: 'Days',
              focusNode: dayFocusNode,
              textController: dayTextController,
              onValueChanged: (value) {
                _durationSubject.add(
                  Duration(
                    days: value,
                    hours: int.tryParse(hourTextController.text) ?? 0,
                    minutes: int.tryParse(minTextController.text) ?? 0,
                  ),
                );
              }),
          _durationWidget(
              suffixText: 'Hours',
              maxValue: 23,
              focusNode: hourFocusNode,
              textController: hourTextController,
              onValueChanged: (value) {
                _durationSubject.add(
                  Duration(
                    days: int.tryParse(dayTextController.text) ?? 0,
                    hours: value,
                    minutes: int.tryParse(minTextController.text) ?? 0,
                  ),
                );
              }),
          _durationWidget(
              suffixText: 'Mins',
              maxValue: 59,
              focusNode: minFocusNode,
              textController: minTextController,
              onValueChanged: (value) {
                _durationSubject.add(
                  Duration(
                    days: int.tryParse(dayTextController.text) ?? 0,
                    hours: int.tryParse(hourTextController.text) ?? 0,
                    minutes: value,
                  ),
                );
              }),
        ],
      );

  Widget _durationWidget({
    required String suffixText,
    required Function(int value) onValueChanged,
    required FocusNode focusNode,
    required TextEditingController textController,
    int? maxValue,
  }) {
    final textStyle = isAnyFieldFocused && !focusNode.hasFocus
        ? Theme.of(context).textTheme.ppMori400Grey12
        : Theme.of(context).textTheme.ppMori400White12;

    return IntrinsicWidth(
      child: TextField(
        enableInteractiveSelection: false,
        controller: textController,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        style: textStyle,
        cursorWidth: 1,
        decoration: InputDecoration(
          hintText: '00',
          hintStyle: textStyle,
          isCollapsed: true,
          isDense: true,
          border: InputBorder.none,
          suffixIcon: Container(
            margin: const EdgeInsets.only(left: 8, top: 1),
            child: Text(
              suffixText,
              style: textStyle,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(),
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          RangeTextInputFormatter(min: 0, max: maxValue),
        ],
        onTapOutside: (event) => focusNode.unfocus(),
        onChanged: (value) {
          onValueChanged(int.tryParse(value) ?? 0);
        },
      ),
    );
  }
}

extension PlayArtworkExt on PlayArtworkV2 {
  PlayArtworkV2 copy({
    CastAssetToken? token,
    CastArtwork? artwork,
    Duration? duration,
  }) =>
      PlayArtworkV2(
        token: token ?? this.token,
        artwork: artwork ?? this.artwork,
        duration: duration?.inMilliseconds ?? this.duration,
      );
}
