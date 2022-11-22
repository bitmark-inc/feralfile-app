import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/play_control_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class PlaylistControl extends StatefulWidget {
  final Function()? onPlayTap;
  final Function()? onTimerTap;
  final Function()? onShuffleTap;
  final Function()? onLoopTap;
  final bool showPlay;
  const PlaylistControl({
    Key? key,
    this.onPlayTap,
    this.onTimerTap,
    this.onShuffleTap,
    this.onLoopTap,
    this.showPlay = true,
  }) : super(key: key);

  @override
  State<PlaylistControl> createState() => _PlaylistControlState();
}

class _PlaylistControlState extends State<PlaylistControl> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playControlListen = injector.get<ValueNotifier<PlayControlService>>();

    return ValueListenableBuilder(
      builder: (BuildContext context, value, Widget? child) {
        final playControl = playControlListen.value;
        return Container(
          color: theme.colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ControlItem(
                  icon: SvgPicture.asset(
                    'assets/images/time_off_icon.svg',
                    width: 24,
                  ),
                  iconFocus: Stack(
                    children: [
                      SvgPicture.asset(
                        'assets/images/time_off_icon.svg',
                        width: 24,
                        color: theme.colorScheme.secondary,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Visibility(
                          visible: playControl.timer != 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              playControl.timer.toString(),
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  isActive: playControl.timer != 0,
                  onTap: () {
                    playControlListen.value = playControl.onChangeTime();
                  },
                ),
                const SizedBox(
                  width: 15,
                ),
                ControlItem(
                  icon: SvgPicture.asset(
                    'assets/images/shuffle_icon.svg',
                    width: 24,
                  ),
                  iconFocus: SvgPicture.asset(
                    'assets/images/shuffle_icon.svg',
                    width: 24,
                    color: theme.colorScheme.secondary,
                  ),
                  isActive: playControl.isShuffle,
                  onTap: () {
                    playControlListen.value =
                        playControl.copyWith(isShuffle: !playControl.isShuffle);
                    widget.onShuffleTap?.call();
                  },
                ),
                const SizedBox(
                  width: 15,
                ),
                ControlItem(
                  icon: SvgPicture.asset(
                    'assets/images/loop_icon.svg',
                    width: 24,
                  ),
                  iconFocus: SvgPicture.asset(
                    'assets/images/loop_icon.svg',
                    width: 24,
                    color: theme.colorScheme.secondary,
                  ),
                  isActive: playControl.isLoop,
                  onTap: () {
                    playControlListen.value =
                        playControl.copyWith(isLoop: !playControl.isLoop);
                  },
                ),
                if (widget.showPlay) ...[
                  const SizedBox(
                    width: 15,
                  ),
                  ControlItem(
                    icon: SvgPicture.asset(
                      'assets/images/play_icon.svg',
                      width: 24,
                      color: theme.colorScheme.secondary,
                    ),
                    iconFocus: SvgPicture.asset(
                      'assets/images/play_icon.svg',
                      width: 24,
                      color: theme.colorScheme.secondary,
                    ),
                    onTap: () {
                      widget.onPlayTap?.call();
                    },
                  ),
                ]
              ],
            ),
          ),
        );
      },
      valueListenable: playControlListen,
    );
  }
}

class ControlItem extends StatefulWidget {
  final Widget icon;
  final Widget iconFocus;
  final bool isActive;
  final Function()? onTap;

  const ControlItem({
    Key? key,
    required this.icon,
    required this.iconFocus,
    this.isActive = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<ControlItem> createState() => _ControlItemState();
}

class _ControlItemState extends State<ControlItem> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: widget.isActive ? widget.iconFocus : widget.icon,
          ),
          Visibility(
            visible: widget.isActive,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary,
              ),
            ),
          )
        ],
      ),
    );
  }
}
