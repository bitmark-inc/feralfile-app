import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/device_setting/device_config.dart';
import 'package:autonomy_flutter/screen/device_setting/enter_wifi_password.dart';
import 'package:autonomy_flutter/screen/device_setting/scan_wifi_network_page.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BluetoothConnectedDeviceConfig extends StatefulWidget {
  const BluetoothConnectedDeviceConfig({super.key, required this.device});

  final BluetoothDevice device;

  @override
  State<BluetoothConnectedDeviceConfig> createState() =>
      BluetoothConnectedDeviceConfigState();
}

class BluetoothConnectedDeviceConfigState
    extends State<BluetoothConnectedDeviceConfig>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<BluetoothConnectedDeviceConfig> {
  BluetoothDeviceStatus? status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    status = injector<FFBluetoothService>().bluetoothDeviceStatus.value;
    injector<FFBluetoothService>()
        .bluetoothDeviceStatus
        .addListener(_statusListener);

    injector<FFBluetoothService>().fetchBluetoothDeviceStatus(widget.device);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    // injector<FFBluetoothService>().checkVersionCompatibility(widget.device);
  }

  void _statusListener() {
    final status = injector<FFBluetoothService>().bluetoothDeviceStatus.value;
    setState(() {
      this.status = status;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    injector<FFBluetoothService>()
        .bluetoothDeviceStatus
        .removeListener(_statusListener);
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(context, onBack: () {
        injector<NavigationService>().goBack();
      }, title: 'configure_device'.tr(), isWhite: false),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _emptyView(BuildContext context) {
    return Center(
      child: Text(
        'no_device_connected'.tr(),
        style: Theme.of(context).textTheme.ppMori400White14,
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (widget.device == null) {
      return _emptyView(context);
    }
    return _deviceConfig(context);
  }

  Widget _deviceConfig(BuildContext context) {
    final theme = Theme.of(context);
    final device = widget.device!;
    return Padding(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.paddingOf(context).top + 32,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _displayOrientation(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 40,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _canvasSetting(context),
            ),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(
              height: 20,
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 1,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _wifiConfig(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              color: AppColor.auGreyBackground,
              thickness: 1,
              height: 1,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 20,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets,
              child: _deviceInfo(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayOrientationPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.auGreyBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 200,
      child: Center(
        child: _displayOrientationPreviewImage(),
      ),
    );
  }

  Widget _displayOrientationPreviewImage() {
    if (status == null) {
      return const SizedBox.shrink();
    }
    final screenRotation = status!.screenRotation;
    switch (screenRotation) {
      case ScreenOrientation.landscape:
        return SvgPicture.asset('assets/images/landscape.svg', width: 150);
      case ScreenOrientation.landscapeReverse:
        return SvgPicture.asset(
          'assets/images/landscape.svg',
          width: 150,
        );
      case ScreenOrientation.portrait:
        return SvgPicture.asset(
          'assets/images/portrait.svg',
          height: 150,
        );
      case ScreenOrientation.portraitReverse:
        return SvgPicture.asset(
          'assets/images/portrait.svg',
          height: 150,
        );
    }
  }

  Widget _displayOrientation(BuildContext context) {
    final blDevice = widget.device!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'display_orientation'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 16),
        _displayOrientationPreview(),
        const SizedBox(height: 16),
        PrimaryAsyncButton(
          text: 'rotate'.tr(),
          color: AppColor.white,
          onTap: () async {
            final device = blDevice.toFFBluetoothDevice();
            await injector<CanvasClientServiceV2>().rotateCanvas(device);
            // update orientation
          },
        )
      ],
    );
  }

  Widget _canvasSetting(BuildContext context) {
    final blDevice = widget.device!;
    final defaultArtFramingIndex =
        (status?.artFraming == ArtFraming.cropToFill) ? 1 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'canvas'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
        ),
        const SizedBox(height: 30),
        SelectDeviceConfigView(selectedIndex: defaultArtFramingIndex, items: [
          DeviceConfigItem(
            title: 'fit'.tr(),
            icon: Image.asset('assets/images/fit.png', width: 100, height: 100),
            onSelected: () {
              final device = blDevice.toFFBluetoothDevice();
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
              final device = blDevice.toFFBluetoothDevice();
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
        TappableForwardRow(
          leftWidget: Row(
            children: [
              Text(
                'configure_wifi'.tr(),
                style: Theme.of(context).textTheme.ppMori400White14,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
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
    final blDevice = widget.device!;
    log.info('onWifiSelected: $accessPoint');
    final payload = SendWifiCredentialsPagePayload(
        wifiAccessPoint: accessPoint,
        device: blDevice,
        onSubmitted: () {
          injector<NavigationService>()
              .popUntil(AppRouter.bluetoothConnectedDeviceConfig);
        });
    injector<NavigationService>()
        .navigateTo(AppRouter.sendWifiCredentialPage, arguments: payload);
  }

  Widget _deviceInfo(BuildContext context) {
    final version = status?.version;
    final installedVersion = status?.installedVersion ?? version;
    final latestVersion = status?.latestVersion;
    final isUpToDate =
        installedVersion == latestVersion || latestVersion == null;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (installedVersion != null)
          RichText(
              text: TextSpan(
            children: [
              TextSpan(
                text: 'v.$installedVersion',
                style: theme.textTheme.ppMori400Grey14,
              ),
              if (isUpToDate)
                TextSpan(
                  text: ' - Up to date',
                  style: theme.textTheme.ppMori400Grey14,
                )
              else
                TextSpan(
                  text: ' - Update available',
                  style: theme.textTheme.ppMori400Grey14,
                ),
            ],
          )),
        if (!isUpToDate && latestVersion != null) ...[
          const SizedBox(height: 16),
          PrimaryAsyncButton(
            text: 'Update to latest version v.$latestVersion',
            color: AppColor.white,
            onTap: () async {
              final device = widget.device!.toFFBluetoothDevice();
              await injector<CanvasClientServiceV2>()
                  .updateToLatestVersion(device);
            },
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }
}
