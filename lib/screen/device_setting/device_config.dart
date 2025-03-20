import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/bluetooth_device_status.dart';
import 'package:autonomy_flutter/model/canvas_cast_request_reply.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/device_setting/enter_wifi_password.dart';
import 'package:autonomy_flutter/screen/device_setting/scan_wifi_network_page.dart';
import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/now_displaying_manager.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
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
      case 'normal':
        return ScreenOrientation.landscape;
      case 'landscapeReverse':
      case 'inverted':
        return ScreenOrientation.landscapeReverse;
      case 'portrait':
      case 'left':
        return ScreenOrientation.portrait;
      case 'portraitReverse':
      case 'right':
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

class ConfigureDeviceState extends State<ConfigureDevice>
    with AfterLayoutMixin<ConfigureDevice> {
  BluetoothDeviceStatus? _deviceStatus;
  bool? _isWifiConnectSuccess = false;
  Timer? _pullingDeviceInfoTimer;

  @override
  void afterFirstLayout(BuildContext context) {
    _pullingDeviceInfo();
    _listenForCanvasCastRequestReply();
  }

  @override
  void dispose() {
    _pullingDeviceInfoTimer?.cancel();
    NowDisplayingManager().updateDisplayingNow();
    super.dispose();
  }

  // listen for response from the device
  void _listenForCanvasCastRequestReply() {
    late NotificationCallback cb;
    cb = (data) {
      log.info(' Received data: $data');
      final success = data['success'] as bool;
      if (mounted) {
        setState(() {
          _isWifiConnectSuccess = success;
        });
      }
      BluetoothNotificationService().unsubscribe(wifiConnectionTopic, cb);
    };
    BluetoothNotificationService().subscribe(wifiConnectionTopic, cb);
  }

  Future<void> _pullingDeviceInfo() async {
    final device = widget.device.toFFBluetoothDevice();
    _pullingDeviceInfoTimer?.cancel();
    _pullingDeviceInfoTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      final deviceStatus = await injector<CanvasClientServiceV2>()
          .getBluetoothDeviceStatus(device);
      if (mounted) {
        setState(() {
          _deviceStatus = deviceStatus;
          _isWifiConnectSuccess = deviceStatus.isConnectedToWifi ||
              (_isWifiConnectSuccess ?? false);
        });
      }
      if (deviceStatus.isConnectedToWifi) {
        timer.cancel();
      }
    });
  }

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
                  // if device not connected to internet, show the device status
                  if (_isWifiConnectSuccess == null) ...[
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
                            'Waiting for Portal to connect to the internet',
                            style: Theme.of(context).textTheme.ppMori400White14,
                          ),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 20,
                      ),
                    ),
                  ] else if (_isWifiConnectSuccess! == false) ...[
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
                            'The Portal is not connected to the internet',
                            style: Theme.of(context).textTheme.ppMori400White14,
                          ),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 20,
                      ),
                    ),
                  ],
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
                    Navigator.of(context).pop();
                    NowDisplayingManager().updateDisplayingNow();
                  },
                  enabled: _isWifiConnectSuccess ?? false,
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
                arguments: ScanWifiNetworkPagePayload(
                    widget.device.toFFBluetoothDevice(), onWifiSelected));
          },
        ),
      ],
    );
  }

  FutureOr<void> onWifiSelected(WifiPoint accessPoint) {
    final blDevice = widget.device;
    log.info('onWifiSelected: $accessPoint');
    final payload = SendWifiCredentialsPagePayload(
        wifiAccessPoint: accessPoint,
        device: blDevice,
        onSubmitted: () {
          injector<NavigationService>().popUntil(AppRouter.configureDevice);
        });
    injector<NavigationService>()
        .navigateTo(AppRouter.sendWifiCredentialPage, arguments: payload);
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
          enabled: _isWifiConnectSuccess ?? false,
          onTap: () async {
            final device = blDevice.toFFBluetoothDevice();
            await injector<CanvasClientServiceV2>().rotateCanvas(device);
            // update orientation
          },
        )
      ],
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
    return ValueListenableBuilder(
        valueListenable: injector<FFBluetoothService>().bluetoothDeviceStatus,
        builder: (context, BluetoothDeviceStatus? status, child) {
          if (status == null) {
            return const SizedBox.shrink();
          }
          final screenRotation = status.screenRotation;
          switch (screenRotation) {
            case ScreenOrientation.landscape:
              return SvgPicture.asset('assets/images/landscape.svg',
                  width: 150);
            case ScreenOrientation.landscapeReverse:
              return RotatedBox(
                quarterTurns: 2,
                child: SvgPicture.asset(
                  'assets/images/landscape.svg',
                  width: 150,
                ),
              );
            case ScreenOrientation.portrait:
              return SvgPicture.asset(
                'assets/images/portrait.svg',
                height: 150,
              );
            case ScreenOrientation.portraitReverse:
              return RotatedBox(
                quarterTurns: 2,
                child: SvgPicture.asset(
                  'assets/images/portrait.svg',
                  height: 150,
                ),
              );
          }
        });
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
        SelectDeviceConfigView(
            selectedIndex: 0,
            isEnable: _isWifiConnectSuccess ?? false,
            items: [
              DeviceConfigItem(
                title: 'fit'.tr(),
                icon: Image.asset('assets/images/fit.png',
                    width: 100, height: 100),
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
      {required this.items,
      required this.selectedIndex,
      super.key,
      this.isEnable = true});

  final List<DeviceConfigItem> items;
  final int selectedIndex;
  final bool isEnable;

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
  void didUpdateWidget(covariant SelectDeviceConfigView oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        final isSelected = _selectedIndex == index && widget.isEnable;
        final activeTitleStyle =
            item.titleStyle ?? Theme.of(context).textTheme.ppMori400White14;
        final deactiveTitleStyle =
            item.titleStyleOnUnselected ?? activeTitleStyle;
        final titleStyle = (isSelected) ? activeTitleStyle : deactiveTitleStyle;
        return GestureDetector(
          onTap: () async {
            if (!(widget.isEnable)) {
              return;
            }
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
