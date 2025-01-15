import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/send_wifi_crendential_view.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

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

  Map<String, Stream<BluetoothConnectionState>> _connectionStateMap = {};

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
        final isScanning = state.isScanning;
        final scannedDevices = state.scanResults;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            PrimaryAsyncButton(
              onTap: state.isScanning
                  ? null
                  : () => _bloc.add(BluetoothConnectEventScan()),
              text: !isScanning ? 'Start Scan' : 'Scanning...',
              processingText: 'Scanning...',
              enabled: !isScanning,
              color: AppColor.feralFileLightBlue,
            ),
            const SizedBox(height: 16),
            if (scannedDevices.isNotEmpty)
              Expanded(
                child: ListView.builder(
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
              ),
          ],
        );
      },
    );
  }

  Widget bluetoothItem(BuildContext context, BluetoothDevice device) {
    final theme = Theme.of(context);

    return BlocBuilder<BluetoothConnectBloc, BluetoothConnectState>(
      bloc: _bloc,
      builder: (context, state) {
        final connectedDevice = state.connectedDevice;
        final isConnected = connectedDevice?.remoteId == device.remoteId;
        final isConnecting =
            state.connectingDevice?.remoteId == device.remoteId;
        final subTitle = (device.isConnected)
            ? 'Connected'
            : isConnecting
                ? 'Connecting..'
                : 'Not Connected';
        return GestureDetector(
          onTap: () async {
            _bloc.add(
              BluetoothConnectEventConnect(
                device: device,
                onConnectSuccess: (device) async {
                  await injector<FFBluetoothService>()
                      .findCharacteristics(device);
                  _showWifiCredentialsDialog();
                  // widget.onDeviceSelected?.call(device);

                  // show connect to wifi dialog
                },
              ),
            );
          },
          child: Stack(
            children: [
              Padding(
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
                            style: isConnected
                                ? theme.textTheme.ppMori700Black16
                                : theme.textTheme.ppMori400Black16,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Text(
                          subTitle,
                          style: theme.textTheme.ppMori400Grey14,
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
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        );
      },
    );
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
                    .sendWifiCredentials(ssid, password);
              },
            ),
          );
        },
      ),
      isDismissible: true,
    );
  }
}
