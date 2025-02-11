import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';
import 'package:autonomy_flutter/screen/device_setting/enter_wifi_password.dart';
import 'package:autonomy_flutter/screen/device_setting/scan_wifi_network_page.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/svg.dart';

class BluetoothConnectedDeviceConfig extends StatefulWidget {
  final BluetoothDevice device;

  const BluetoothConnectedDeviceConfig({Key? key, required this.device})
      : super(key: key);

  @override
  State<BluetoothConnectedDeviceConfig> createState() =>
      BluetoothConnectedDeviceConfigState();
}

class BluetoothConnectedDeviceConfigState
    extends State<BluetoothConnectedDeviceConfig>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pageEdgeInsets,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 20,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'connected'.tr(),
                      style: theme.textTheme.ppMori700White24,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.device.name,
                      style: theme.textTheme.ppMori700White24,
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
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
              SliverToBoxAdapter(
                child: Divider(
                  color: AppColor.auGreyBackground,
                  thickness: 1,
                  height: 40,
                ),
              ),
              SliverToBoxAdapter(
                child: _wifiConfig(context),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                ),
              ),
              SliverToBoxAdapter(
                child: _deviceInfo(context),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 80,
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

  Widget _wifiConfig(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'configure_wifi'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 30),
        PrimaryButton(
          text: 'configure'.tr(),
          onTap: () {
            injector<NavigationService>().navigateTo(
                AppRouter.scanWifiNetworkPage,
                arguments: onWifiSelected);
          },
        ),
      ],
    );
  }

  FutureOr<void> onWifiSelected(WifiPoint accessPoint) {
    log.info('onWifiSelected: $accessPoint');
    final payload = SendWifiCredentialsPagePayload(
        wifiAccessPoint: accessPoint,
        device: widget.device,
        onSubmitted: () {
          injector<NavigationService>()
              .popUntil(AppRouter.bluetoothConnectedDeviceConfig);
        });
    injector<NavigationService>()
        .navigateTo(AppRouter.sendWifiCredentialPage, arguments: payload);
  }

  Widget _deviceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'device_info'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
