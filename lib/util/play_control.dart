import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class PlaylistControl extends StatelessWidget {
  final PlayControlModel playControl;
  final Function()? onPlayTap;
  final Function()? onTimerTap;
  final Function()? onShuffleTap;
  final bool showPlay;

  const PlaylistControl({
    Key? key,
    this.onPlayTap,
    this.onTimerTap,
    this.onShuffleTap,
    this.showPlay = true,
    required this.playControl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                colorFilter:
                    ColorFilter.mode(theme.disableColor, BlendMode.srcIn),
              ),
              iconFocus: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/images/time_off_icon.svg',
                    width: 24,
                    colorFilter: ColorFilter.mode(
                        theme.colorScheme.secondary, BlendMode.srcIn),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -1,
                    child: Visibility(
                      visible: playControl.timer != 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          playControl.timer.toString(),
                          style: TextStyle(
                            fontFamily: 'PPMori',
                            color: theme.colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              isActive: playControl.timer != 0,
              onTap: () {
                onTimerTap?.call();
              },
            ),
            const SizedBox(
              width: 15,
            ),
            ControlItem(
              icon: SvgPicture.asset(
                'assets/images/shuffle_icon.svg',
                width: 24,
                colorFilter:
                    ColorFilter.mode(theme.disableColor, BlendMode.srcIn),
              ),
              iconFocus: SvgPicture.asset(
                'assets/images/shuffle_icon.svg',
                width: 24,
                colorFilter: ColorFilter.mode(
                    theme.colorScheme.secondary, BlendMode.srcIn),
              ),
              isActive: playControl.isShuffle,
              onTap: () {
                onShuffleTap?.call();
              },
            ),
            if (showPlay) ...[
              const SizedBox(
                width: 15,
              ),
              ControlItem(
                icon: SvgPicture.asset(
                  'assets/images/play_icon.svg',
                  width: 24,
                  colorFilter: ColorFilter.mode(
                      theme.colorScheme.secondary, BlendMode.srcIn),
                ),
                iconFocus: SvgPicture.asset(
                  'assets/images/play_icon.svg',
                  width: 24,
                  colorFilter: ColorFilter.mode(
                      theme.colorScheme.secondary, BlendMode.srcIn),
                ),
                onTap: () {
                  onPlayTap?.call();
                },
              ),
            ]
          ],
        ),
      ),
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
          Container(
            width: 4,
            height: 4,
            decoration: widget.isActive
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.secondary,
                  )
                : null,
          )
        ],
      ),
    );
  }
}
