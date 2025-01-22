import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/gesture_constrain_widget.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/send_wifi_crendential_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/svg.dart';

class BluetoothConnectWidget extends StatefulWidget {
  const BluetoothConnectWidget({
    super.key,
    this.onDeviceSelected,
    this.onDeviceDisconnected,
    this.onScanStarted,
    this.onScanStopped,
  });

  // function to call when a device is selected
  final FutureOr<void> Function(BluetoothDevice device)? onDeviceSelected;

  // function to call when a device is disconnected
  final FutureOr<void> Function(BluetoothDevice device)? onDeviceDisconnected;

  // function to call when starting a scan
  final FutureOr<void> Function()? onScanStarted;

  // function to call when stopping a scan
  final FutureOr<void> Function()? onScanStopped;

  @override
  State<BluetoothConnectWidget> createState() => _BluetoothConnectWidgetState();
}

class _BluetoothConnectWidgetState extends State<BluetoothConnectWidget>
    with AfterLayoutMixin<BluetoothConnectWidget> {
  late BluetoothConnectBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = injector<BluetoothConnectBloc>();
    _bloc.add(BluetoothConnectEventScan());
  }

  @override
  void afterFirstLayout(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BluetoothConnectBloc, BluetoothConnectState>(
      bloc: _bloc,
      listener: (context, state) {},
      builder: (context, state) {
        final bluetoothState = state.bluetoothAdapterState;
        if (bluetoothState != BluetoothAdapterState.on) {
          return bluetoothNotAvailable(context);
        }
        final isScanning = state.isScanning;
        final scannedDevices = state.scanResults;
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _instruction(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: PrimaryAsyncButton(
                onTap: state.isScanning
                    ? null
                    : () => _bloc.add(BluetoothConnectEventScan()),
                text: !isScanning ? 'Start Scan' : 'Scanning...',
                processingText: 'Scanning...',
                enabled: !isScanning,
                color: AppColor.feralFileLightBlue,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (scannedDevices.isNotEmpty) ...[
              SliverList.builder(
                itemCount: scannedDevices.length,
                itemBuilder: (context, index) {
                  final result = scannedDevices[index];
                  final device = result.device;
                  return Column(
                    children: [
                      bluetoothItem(context, device),
                      const Divider(
                        color: AppColor.auLightGrey,
                        height: 1,
                      ),
                    ],
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }

  Widget _instruction(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'welcome_to_FF_X1'.tr(),
          style: Theme.of(context).textTheme.ppMori400Black16,
        ),
        const SizedBox(height: 16),
        Text(
          'welcome_to_FF_X1_desc'.tr(),
          style: Theme.of(context).textTheme.ppMori400Black14,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
        Text(
          'how_you_can_help'.tr(),
          style: theme.textTheme.ppMori700Black16,
        ),
        for (final index in [1, 2, 3])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8).copyWith(left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index.',
                  style: theme.textTheme.ppMori400Black14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'how_you_can_help_$index'.tr(),
                    style: theme.textTheme.ppMori400Black14,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget bluetoothItem(BuildContext context, BluetoothDevice device) {
    final theme = Theme.of(context);

    return BlocBuilder<BluetoothConnectBloc, BluetoothConnectState>(
      bloc: _bloc,
      builder: (context, state) {
        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () async {
            // _onMoreTap(context, device);
          },
          child: Stack(
            children: [
              ColoredBox(
                color: Colors.transparent,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.platformName.isNotEmpty
                                  ? device.platformName
                                  : 'Unknown Device',
                              style: theme.textTheme.ppMori700Black16,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          GestureDetector(
                            onTap: () {
                              onRotateDisplaySelected(context, device);
                            },
                            child: GestureConstrainWidget(
                              child: SvgPicture.asset(
                                'assets/images/icon_rotate.svg',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          GestureDetector(
                            onTap: () {
                              _onMoreTap(context, device);
                            },
                            child: GestureConstrainWidget(
                              child: SvgPicture.asset(
                                'assets/images/more_circle.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  AppColor.primaryBlack,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        device.remoteId.str,
                        style: theme.textTheme.ppMori400Grey14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onMoreTap(BuildContext context, BluetoothDevice device) async {
    Theme.of(context);
    await UIHelper.showDrawerAction(
      context,
      options: [
        OptionItem(
          title: 'configure_wifi'.tr(),
          icon: SvgPicture.asset(
            'assets/images/wifi.svg',
            width: 24,
            colorFilter: const ColorFilter.mode(
              AppColor.white,
              BlendMode.srcIn,
            ),
          ),
          onTap: () {
            onSendWifiSelected(context, device);
          },
        ),
        OptionItem(
          title: 'rotate_display'.tr(),
          icon: SvgPicture.asset(
            'assets/images/icon_rotate.svg',
            width: 24,
            colorFilter: const ColorFilter.mode(
              AppColor.white,
              BlendMode.srcIn,
            ),
          ),
          onTap: () {
            onRotateDisplaySelected(context, device);
          },
        ),
        OptionItem(
          title: 'get_support'.tr(),
          icon: const Icon(
            AuIcon.help,
          ),
          iconOnDisable: const Icon(
            AuIcon.help,
            color: AppColor.disabledColor,
          ),
          isEnable: false,
        ),
        OptionItem(),
      ],
    );
  }

  FutureOr<void> onSendWifiSelected(
    BuildContext context,
    BluetoothDevice device,
  ) {
    _bloc.add(
      BluetoothConnectEventConnect(
        device: device,
        onConnectSuccess: (device) async {
          await injector<FFBluetoothService>().findCharacteristics(device);
          Navigator.of(context).pop();
          _showWifiCredentialsDialog();
          // widget.onDeviceSelected?.call(device);

          // show connect to wifi dialog
        },
      ),
    );
  }

  FutureOr<void> onRotateDisplaySelected(
    BuildContext context,
    BluetoothDevice device,
  ) {
    final ffDevice = FFBluetoothDevice.fromBluetoothDevice(device);
    injector<CanvasDeviceBloc>().add(CanvasDeviceRotateEvent(ffDevice));
  }

  void _showWifiCredentialsDialog() {
    UIHelper.showDialog(
      context,
      'Send Wifi Credential',
      KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: SendWifiCredentialView(
              onSend: (ssid, password) async {
                await injector<FFBluetoothService>()
                    .sendWifiCredentials(ssid: ssid, password: password);
              },
            ),
          );
        },
      ),
      isDismissible: true,
    );
  }

  Widget bluetoothNotAvailable(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.bluetooth_disabled,
            size: 48,
            color: AppColor.feralFileLightBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Bluetooth is not available',
            style: Theme.of(context).textTheme.ppMori400Black16,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Go to Bluetooth Settings',
            onTap: () {
              injector<NavigationService>().openBluetoothSettings();
            },
          ),
        ],
      ),
    );
  }
}
