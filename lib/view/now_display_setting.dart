import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/display_settings.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/display_settings_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NowDisplaySettingView extends StatefulWidget {
  const NowDisplaySettingView({required this.settings, super.key});
  final DisplaySettings settings;

  @override
  State<NowDisplaySettingView> createState() => _NowDisplaySettingViewState();
}

class _NowDisplaySettingViewState extends State<NowDisplaySettingView> {
  late ArtFraming viewMode;
  late int rotationAngle;
  late FFBluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    viewMode = widget.settings.viewMode ?? ArtFraming.fitToScreen;
    rotationAngle = widget.settings.rotationAngle ?? 0;
    connectedDevice = injector<FFBluetoothService>().castingBluetoothDevice;
  }

  OptionItem viewModeOption(ArtFraming mode) {
    return OptionItem(
      title: mode == ArtFraming.fitToScreen ? 'fit'.tr() : 'fill'.tr(),
      icon: SvgPicture.asset(
        mode == viewMode
            ? 'assets/images/radio_selected.svg'
            : 'assets/images/radio_unselected.svg',
      ),
      onTap: () async {
        if (mode == viewMode) {
          return;
        }

        if (connectedDevice == null) {
          log.warning(
            'NowDisplaySetting: viewModeOption: connectedDevice is null',
          );
          return;
        }

        try {
          await injector<CanvasClientServiceV2>().updateDisplaySettings(
            connectedDevice!,
            DisplaySettings(
              tokenId: widget.settings.tokenId,
              viewMode: mode,
            ),
          );

          await injector<DisplaySettingsService>().updateDisplaySetting(
            widget.settings.copyWith(viewMode: mode),
          );

          setState(() {
            viewMode = mode;
          });
        } catch (e) {
          log.warning(
            'NowDisplaySetting: updateDisplaySettings error: $e',
          );
        }
      },
    );
  }

  List<OptionItem> _settingOptions() {
    return [
      OptionItem(
        title: 'Rotate',
        icon: SvgPicture.asset(
          'assets/images/icon_rotate_white.svg',
        ),
        onTap: () async {
          if (connectedDevice == null) {
            log.warning(
              'NowDisplaySetting: viewModeOption: connectedDevice is null',
            );
            return;
          }

          try {
            final newAngle = rotationAngle + 90;
            await injector<CanvasClientServiceV2>().updateDisplaySettings(
              connectedDevice!,
              DisplaySettings(
                tokenId: widget.settings.tokenId,
                rotationAngle: newAngle,
              ),
            );

            await injector<DisplaySettingsService>().updateDisplaySetting(
              widget.settings.copyWith(
                rotationAngle: newAngle,
              ),
            );

            setState(() {
              rotationAngle = newAngle;
            });
          } catch (e) {
            log.warning('NowDisplaySetting: updateDisplaySettings error: $e');
          }
        },
      ),
      viewModeOption(ArtFraming.fitToScreen),
      viewModeOption(ArtFraming.cropToFill),
      OptionItem(
        builder: (context, item) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRouter.bluetoothConnectedDeviceConfig,
                arguments: connectedDevice,
              );
            },
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.white),
                borderRadius: BorderRadius.circular(47),
              ),
              child: Center(
                child: Text(
                  'configure_device'.tr(),
                  style: Theme.of(context).textTheme.ppMori400White14,
                ),
              ),
            ),
          );
        },
      ),
    ];
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
            final option = _settingOptions()[index];
            if (option.builder != null) {
              return option.builder!.call(context, option);
            }
            return DrawerItem(
              item: option,
              color: AppColor.white,
            );
          },
          itemCount: _settingOptions().length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 1,
            color: AppColor.primaryBlack,
          ),
        ),
      ],
    );
  }
}
