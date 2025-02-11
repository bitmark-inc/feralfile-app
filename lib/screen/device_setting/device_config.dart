import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';

enum ScreenOrientation {
  landscape,
  landscapeReverse,
  portrait,
  portraitReverse;

  String get name {
    switch (this) {
      case ScreenOrientation.landscape:
        return 'landscape';
      case ScreenOrientation.landscapeReverse:
        return 'landscapeReverse';
      case ScreenOrientation.portrait:
        return 'portrait';
      case ScreenOrientation.portraitReverse:
        return 'portraitReverse';
    }
  }

  static ScreenOrientation fromString(String value) {
    switch (value) {
      case 'landscape':
        return ScreenOrientation.landscape;
      case 'landscapeReverse':
        return ScreenOrientation.landscapeReverse;
      case 'portrait':
        return ScreenOrientation.portrait;
      case 'portraitReverse':
        return ScreenOrientation.portraitReverse;
      default:
        throw ArgumentError('Invalid screen orientation: $value');
    }
  }
}

class ConfigureDevice extends StatefulWidget {
  const ConfigureDevice({
    super.key,
    required this.device,
  });

  final BluetoothDevice device;

  @override
  State<ConfigureDevice> createState() => ConfigureDeviceState();
}

class ConfigureDeviceState extends State<ConfigureDevice> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: 'configure_device'.tr(),
        isWhite: false,
      ),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pageEdgeInsets,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 20,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _displayOrientation(context),
                  ),
                  const SliverToBoxAdapter(
                    child: Divider(
                      color: AppColor.auGreyBackground,
                      thickness: 1,
                      height: 40,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _canvasSetting(context),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: PrimaryAsyncButton(
                  onTap: () async {
                    injector<NavigationService>()
                        .popUntil(AppRouter.bluetoothDevicePortalPage);
                    injector<NavigationService>().goBack();
                  },
                  text: 'finish'.tr(),
                  color: AppColor.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _displayOrientation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'display_orientation'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 30),
        SelectDeviceConfigView(selectedIndex: 0, items: [
          DeviceConfigItem(
            title: 'landscape'.tr(),
            icon: SvgPicture.asset(
              'assets/images/landscape.svg',
            ),
            iconOnUnselected: SvgPicture.asset(
              'assets/images/landscape_inactive.svg',
            ),
            onSelected: () {
              final device = widget.device.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>()
                  .updateOrientation(device, ScreenOrientation.landscape);
            },
          ),
          DeviceConfigItem(
            title: 'landscape_flipped'.tr(),
            icon: SvgPicture.asset(
              'assets/images/landscape.svg',
            ),
            iconOnUnselected: SvgPicture.asset(
              'assets/images/landscape_inactive.svg',
            ),
            onSelected: () {
              final device = widget.device.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>().updateOrientation(
                  device, ScreenOrientation.landscapeReverse);
            },
          ),
          DeviceConfigItem(
            title: 'portrait_left'.tr(),
            icon: SvgPicture.asset(
              'assets/images/portrait.svg',
            ),
            iconOnUnselected: SvgPicture.asset(
              'assets/images/portrait_inactive.svg',
            ),
            onSelected: () {
              final device = widget.device.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>()
                  .updateOrientation(device, ScreenOrientation.portrait);
            },
          ),
          DeviceConfigItem(
            title: 'portrait_right'.tr(),
            icon: SvgPicture.asset(
              'assets/images/portrait.svg',
            ),
            iconOnUnselected: SvgPicture.asset(
              'assets/images/portrait_inactive.svg',
            ),
            onSelected: () {
              final device = widget.device.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>()
                  .updateOrientation(device, ScreenOrientation.portraitReverse);
            },
          ),
        ])
      ],
    );
  }

  Widget _canvasSetting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'canvas'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 30),
        SelectDeviceConfigView(selectedIndex: 0, items: [
          DeviceConfigItem(
            title: 'fit'.tr(),
            icon: Image.asset('assets/images/fit.png', width: 100, height: 100),
            onSelected: () {
              final device = widget.device.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>()
                  .updateArtFraming(device, ArtFraming.fitToScreen);
            },
          ),
          DeviceConfigItem(
            title: 'fill'.tr(),
            icon: Image.asset(
              'assets/images/fill.png',
              width: 100,
              height: 100,
            ),
            onSelected: () {
              final device = widget.device.toFFBluetoothDevice();
              injector<CanvasClientServiceV2>()
                  .updateArtFraming(device, ArtFraming.cropToFill);
            },
          ),
        ])
      ],
    );
  }
}

class DeviceConfigItem {
  DeviceConfigItem({
    required this.title,
    this.titleStyle,
    this.titleStyleOnUnselected,
    required this.icon,
    this.iconOnUnselected,
    this.onSelected,
  });

  final String title;
  final TextStyle? titleStyle;
  final TextStyle? titleStyleOnUnselected;
  final Widget icon;
  final Widget? iconOnUnselected;

  final FutureOr<void> Function()? onSelected;
}

class SelectDeviceConfigView extends StatefulWidget {
  const SelectDeviceConfigView(
      {required this.items, required this.selectedIndex, super.key});

  final List<DeviceConfigItem> items;
  final int selectedIndex;

  @override
  State<SelectDeviceConfigView> createState() => SelectItemState();
}

class SelectItemState extends State<SelectDeviceConfigView> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15),
      itemCount: widget.items.length,
      padding: const EdgeInsets.all(0),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = _selectedIndex == index;
        final activeTitleStyle =
            item.titleStyle ?? Theme.of(context).textTheme.ppMori400White14;
        final deactiveTitleStyle =
            item.titleStyleOnUnselected ?? activeTitleStyle;
        final titleStyle = isSelected ? activeTitleStyle : deactiveTitleStyle;
        return GestureDetector(
          onTap: () async {
            setState(() {
              _selectedIndex = index;
            });
            if (item.onSelected != null) {
              await item.onSelected!();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColor.white : AppColor.disabledColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: item.icon,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SvgPicture.asset(
                      isSelected
                          ? 'assets/images/check_box_true.svg'
                          : 'assets/images/check_box_false.svg',
                      height: 12,
                      width: 12,
                      colorFilter: const ColorFilter.mode(
                          AppColor.white, BlendMode.srcIn)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item.title,
                      style: titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
