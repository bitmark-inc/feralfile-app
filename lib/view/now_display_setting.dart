import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/bloc/artist_artwork_display_settings/artist_artwork_display_setting_bloc.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NowDisplaySettingView extends StatefulWidget {
  const NowDisplaySettingView({
    this.artistName,
    this.tokenConfiguration,
    super.key,
  });
  final String? artistName;
  final ArtistDisplaySetting? tokenConfiguration;

  @override
  State<NowDisplaySettingView> createState() => _NowDisplaySettingViewState();
}

class _NowDisplaySettingViewState extends State<NowDisplaySettingView> {
  late ArtFraming selectedFitment;
  late ScreenOrientation currentOrientation;
  late FFBluetoothDevice? connectedDevice;
  late BluetoothDeviceStatus? deviceSettings;
  late bool overridable;

  @override
  void initState() {
    super.initState();
    initDisplaySettings();
    connectedDevice = injector<FFBluetoothService>().castingBluetoothDevice;
  }

  void initDisplaySettings() {
    overridable = widget.tokenConfiguration?.overridable ?? true;
    deviceSettings = injector<FFBluetoothService>().bluetoothDeviceStatus.value;

    if (overridable) {
      selectedFitment = deviceSettings?.artFraming ??
          widget.tokenConfiguration?.artFraming ??
          ArtFraming.cropToFill;
      currentOrientation = _isPortraitOrientation(
        deviceSettings?.screenRotation ??
            widget.tokenConfiguration?.screenOrientation,
      )
          ? ScreenOrientation.portrait
          : ScreenOrientation.landscape;
    } else {
      // Use artist's settings when not overridable
      selectedFitment = widget.tokenConfiguration!.artFraming;
      currentOrientation = widget.tokenConfiguration!.screenOrientation;
    }
  }

  bool _isPortraitOrientation(ScreenOrientation? orientation) {
    return [
      ScreenOrientation.portrait,
      ScreenOrientation.portraitReverse,
    ].contains(orientation);
  }

  OptionItem fitmentOption(ArtFraming fitment) {
    return OptionItem(
      title: fitment == ArtFraming.fitToScreen ? 'fit'.tr() : 'fill'.tr(),
      icon: SvgPicture.asset(
        fitment == selectedFitment
            ? 'assets/images/radio_selected.svg'
            : 'assets/images/radio_unselected.svg',
      ),
      onTap: () async {
        if (fitment == selectedFitment) {
          return;
        }

        if (connectedDevice == null) {
          log.warning(
            'NowDisplaySetting: fitmentOption: connectedDevice is null',
          );
          return;
        }

        try {
          await injector<CanvasClientServiceV2>().updateArtFraming(
            connectedDevice!,
            fitment,
          );

          setState(() {
            selectedFitment = fitment;
          });
        } catch (e) {
          log.warning(
            'NowDisplaySetting: updateDisplaySettings error: $e',
          );
        }
      },
    );
  }

  OptionItem restoreSettingsOption() {
    return OptionItem(
      builder: (context, item) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.white),
              borderRadius: BorderRadius.circular(47),
            ),
            child: Center(
              child: Text(
                'restore_artist_preference'.tr(),
                style: Theme.of(context).textTheme.ppMori400White14,
              ),
            ),
          ),
        );
      },
    );
  }

  List<OptionItem> _settingOptions() {
    return overridable
        ? [
            OptionItem(
              title: 'Rotate',
              icon: SvgPicture.asset(
                'assets/images/icon_rotate_white.svg',
              ),
              onTap: () async {
                if (connectedDevice == null) {
                  log.warning(
                    'NowDisplaySetting: fitmentOption: connectedDevice is null',
                  );
                  return;
                }

                try {
                  await injector<CanvasClientServiceV2>()
                      .rotateCanvas(connectedDevice!);
                  final newOrientation =
                      currentOrientation == ScreenOrientation.portrait
                          ? ScreenOrientation.landscape
                          : ScreenOrientation.portrait;

                  // await injector<CanvasClientServiceV2>().updateDisplaySettings(
                  //   connectedDevice!,
                  //   DisplaySettings(
                  //     tokenId: widget.tokenId,
                  //     setting: ArtistDisplaySetting(
                  //       screenOrientation: newOrientation,
                  //     ),
                  //   ),
                  // );
                  setState(() {
                    currentOrientation = newOrientation;
                  });
                } catch (e) {
                  log.warning(
                      'NowDisplaySetting: updateDisplaySettings error: $e');
                }
              },
            ),
            fitmentOption(ArtFraming.fitToScreen),
            fitmentOption(ArtFraming.cropToFill),
            restoreSettingsOption(),
          ]
        : [];
  }

  Widget _artistPreferenceNote() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColor.feralFileLightBlue,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                overridable
                    ? 'assets/images/unlock_icon.svg'
                    : 'assets/images/lock_icon.svg',
                height: 12,
              ),
              const SizedBox(width: 10),
              Text(
                'artist_display_preference'.tr(),
                style: Theme.of(context).textTheme.ppMori700Black14,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            (overridable
                    ? 'artist_display_preference_unlock_desc'.tr()
                    : 'artist_display_preference_lock_desc'.tr())
                .replaceAll(
              'artist_name',
              widget.artistName ?? 'Artist',
            ),
            style: Theme.of(context).textTheme.ppMori400Black14,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (connectedDevice == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return _artistPreferenceNote();
            }

            final option = _settingOptions()[index - 1];
            if (option.builder != null) {
              return option.builder!.call(context, option);
            }
            return DrawerItem(
              item: option,
              color: AppColor.white,
            );
          },
          itemCount: _settingOptions().length + 1,
          separatorBuilder: (context, index) => index == 0
              ? const SizedBox()
              : const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColor.primaryBlack,
                ),
        ),
      ],
    );
  }
}
