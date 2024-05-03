import 'dart:ui' as ui;

import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class StreamDrawerItem extends StatelessWidget {
  final OptionItem item;
  final Color backgroundColor;
  const StreamDrawerItem(
      {required this.item, required this.backgroundColor, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(50),
          ),
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Text(
              item.title ?? '',
              style: Theme.of(context).textTheme.ppMori400Black14,
            ),
          ),
        ),
        onTap: () => item.onTap?.call(),
      );
}

class PlaylistControl extends StatefulWidget {
  const PlaylistControl({super.key});

  @override
  State<PlaylistControl> createState() => _PlaylistControlState();
}

class _PlaylistControlState extends State<PlaylistControl> {
  final speedValues = [
    '1min',
    '2min',
    '5min',
    '10min',
    '15min',
    '30min',
    '1hr',
    '4hr',
    '12hr',
    '24hr',
  ];
  double _currentSliderValue = 0;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColor.primaryBlack,
      ),
      child: Column(
        children: [
          _buildPlayControls(context),
          const SizedBox(height: 15),
          _buildSpeedControl(context),
        ],
      ));

  Widget _buildPlayButton({required String icon, required Function() onTap}) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: AppColor.auGreyBackground,
            ),
            child: SvgPicture.asset(
              'assets/images/$icon.svg',
            ),
          ),
        ),
      );

  Widget _buildPlayControls(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'play_collection'.tr(),
            style: Theme.of(context).textTheme.ppMori400White12,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildPlayButton(icon: 'chevron_left_icon', onTap: () => {}),
              const SizedBox(width: 15),
              _buildPlayButton(icon: 'stream_play_icon', onTap: () => {}),
              const SizedBox(width: 15),
              _buildPlayButton(icon: 'chevron_right_icon', onTap: () => {}),
            ],
          )
        ],
      );

  Widget _buildSpeedControl(BuildContext context) => Column(
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
                  speedValues.last,
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
                        max: speedValues.length.toDouble() - 1,
                        divisions: speedValues.length,
                        label: speedValues[_currentSliderValue.round()],
                        onChanged: (double value) {
                          setState(() {
                            _currentSliderValue = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  speedValues.first,
                  style: Theme.of(context).textTheme.ppMori400White12,
                ),
              ],
            ),
          )
        ],
      );
}
