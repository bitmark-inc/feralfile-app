import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/gesture_constrain_widget.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8).copyWith(left: 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1.',
                    style: theme.textTheme.ppMori400Black14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.ppMori400Black14,
                        children: [
                          TextSpan(
                            text: '${'experiment_freely'.tr()} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'experiment_freely_desc'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2.',
                    style: theme.textTheme.ppMori400Black14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.ppMori400Black14,
                        children: [
                          TextSpan(
                            text: '${'share_your_experience'.tr()} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '${'join_our'.tr()} ',
                          ),
                          TextSpan(
                            text: '${'google_chat_space'.tr()}',
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                injector<NavigationService>()
                                    .openGoogleChatSpace();
                              },
                          ),
                          TextSpan(
                            text: ' ${'to_provide_feedback'.tr()}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

            Navigator.of(context).pushNamed(AppRouter.bluetoothDevicePortalPage,
                arguments: device);
          },
          child: ColoredBox(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            injector<NavigationService>().navigateTo(
                              AppRouter.bluetoothConnectedDeviceConfig,
                              arguments: device,
                            );
                          },
                          child: Text(
                            device.advName.isNotEmpty
                                ? device.advName
                                : 'Unknown Device',
                            style: theme.textTheme.ppMori700Black16,
                          ),
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
                  FutureBuilder(
                      future: injector<CanvasClientServiceV2>()
                          .getVersion(device.toFFBluetoothDevice()),
                      builder: (context, snapshot) {
                        final theme = Theme.of(context);
                        final style = theme.textTheme.ppMori400Grey14;
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text('Loading...', style: style);
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}', style: style);
                        }
                        if (snapshot.hasData) {
                          return Text('Version: ${snapshot.data}',
                              style: style);
                        }
                        return Text('Unknown version', style: style);
                      }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onMoreTap(BuildContext context, BluetoothDevice device) async {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.ppMori400White14;
    final disabledTitleStyle = theme.textTheme.ppMori400Grey14;
    final processingTitleStyle = theme.textTheme.ppMori400FFYellow14;
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
          titleStyle: titleStyle,
          titleStyleOnPrecessing: processingTitleStyle,
          titleStyleOnDisable: disabledTitleStyle,
          onTap: () async {
            await onSendWifiSelected(context, device);
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
          titleStyle: titleStyle,
          titleStyleOnPrecessing: processingTitleStyle,
          titleStyleOnDisable: disabledTitleStyle,
          onTap: () async {
            await onRotateDisplaySelected(context, device);
          },
        ),
        OptionItem(
          title: 'get_support'.tr(),
          icon: const Icon(
            AuIcon.help,
            color: AppColor.white,
          ),
          iconOnDisable: const Icon(
            AuIcon.help,
            color: AppColor.disabledColor,
          ),
          titleStyle: titleStyle,
          titleStyleOnPrecessing: processingTitleStyle,
          titleStyleOnDisable: disabledTitleStyle,
          onTap: () async {
            await onGetSupportSelected(context, device);
          },
        ),
        if (kDebugMode) ...[
          OptionItem(
            title: 'delete'.tr(),
            icon: const Icon(
              Icons.delete,
              color: AppColor.white,
            ),
            titleStyle: titleStyle,
            titleStyleOnPrecessing: processingTitleStyle,
            titleStyleOnDisable: disabledTitleStyle,
            onTap: () async {
              await BluetoothDeviceHelper.removeDevice(device.remoteId.str);
            },
          ),
        ],
        OptionItem(),
      ],
    );
  }

  FutureOr<void> onSendWifiSelected(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    final completer = Completer<void>();
    _bloc.add(
      BluetoothConnectEventConnect(
        device: device,
        onConnectSuccess: (device) async {
          await injector<FFBluetoothService>().findCharacteristics(device);
          Navigator.of(context).pop();
          await UIHelper.showWifiCredentialsDialog(device: device);
          completer.complete();
          // widget.onDeviceSelected?.call(device);

          // show connect to wifi dialog
        },
      ),
    );
    await completer.future;
  }

  FutureOr<void> onRotateDisplaySelected(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    final ffDevice = FFBluetoothDevice.fromBluetoothDevice(device);
    final completer = Completer<void>();
    injector<CanvasDeviceBloc>().add(
      CanvasDeviceRotateEvent(
        ffDevice,
        onDoneCallback: () {
          completer.complete();
        },
      ),
    );
    await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        UIHelper.showDialog(
          context,
          'Failed to rotate display',
          const Text('Failed to rotate display: timeout'),
          isDismissible: true,
        );
      },
    );
  }

  FutureOr<void> onGetSupportSelected(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    try {
      final ffDevice = FFBluetoothDevice.fromBluetoothDevice(device);
      bool isSuceess = false;
      await injector<CanvasClientServiceV2>()
          .sendLog(ffDevice, null)
          .then((value) {
        isSuceess = true;
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          UIHelper.showDialog(
            context,
            'Failed to get support',
            const Text('Failed to get support: timeout'),
            isDismissible: true,
          );
        },
      );
      if (isSuceess) {
        UIHelper.showDialog(
          context,
          'Get support',
          const Text('Get support: success'),
          isDismissible: true,
        );
      }
    } catch (e) {
      UIHelper.showDialog(
        context,
        'Failed to get support',
        Text('Failed to get support: $e'),
        isDismissible: true,
      );
    }
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
