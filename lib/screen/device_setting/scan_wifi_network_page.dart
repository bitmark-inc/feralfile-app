import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/wifi_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiPoint {
  WifiPoint(this.ssid);

  final String ssid;
}

class ScanWifiNetworkPagePayload {
  ScanWifiNetworkPagePayload(this.device, this.onNetworkSelected);

  final FutureOr<void> Function(WifiPoint wifiAccessPoint) onNetworkSelected;
  final BluetoothDevice device;
}

class ScanWifiNetworkPage extends StatefulWidget {
  const ScanWifiNetworkPage({required this.payload, super.key});

  final ScanWifiNetworkPagePayload payload;

  @override
  State<ScanWifiNetworkPage> createState() => ScanWifiNetworkPageState();
}

class ScanWifiNetworkPageState extends State<ScanWifiNetworkPage> {
  List<WifiPoint> _accessPoints = [];
  final bool _isLocationPermissionGranted = true;
  StreamSubscription<List<WiFiAccessPoint>>? _subscription;

  final TextEditingController _ssidController = TextEditingController();
  bool _shouldEnableConnectButton = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final device = widget.payload.device;
    setState(() {
      _isScanning = true;
    });
    try {
      await injector<FFBluetoothService>()
          .connectToDevice(device, shouldChangeNowDisplayingStatus: true);
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      return;
    }
    const timeout = Duration(seconds: 15);

    // check platform support and necessary requirements
    await WifiHelper.scanWifiNetwork(
      device: device.toFFBluetoothDevice(),
      timeout: timeout,
      onResultScan: (result) {
        final accessPoints = result.keys.map(WifiPoint.new).toList();
        if (mounted) {
          setState(() {
            _accessPoints = _filterUniqueSSIDs(accessPoints);
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  List<WifiPoint> _filterUniqueSSIDs(List<WifiPoint> scanResults) {
    final uniqueNetworks = <String, WifiPoint>{};
    for (final scanResult in scanResults) {
      uniqueNetworks[scanResult.ssid] = scanResult;
    }
    uniqueNetworks.removeWhere((key, value) => key.isEmpty);
    return uniqueNetworks.values.toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
        title: 'select_network'.tr(),
        isWhite: false,
      ),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pageEdgeInsets,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                ),
              ),
              if (!_isLocationPermissionGranted) ...[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location permission is required to scan for wifi networks, please enable it in settings',
                        style: Theme.of(context).textTheme.ppMori400White14,
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        onTap: () async {
                          await _startScan();
                        },
                        text: 'retry'.tr(),
                      ),
                    ],
                  ),
                ),
              ] else if (_accessPoints.isEmpty && !_isScanning)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.payload.device.isConnected)
                        Text(
                          'No wifi networks found',
                          style: Theme.of(context).textTheme.ppMori400White14,
                        )
                      else ...[
                        Text(
                          'Cannot connect to device',
                          style: Theme.of(context).textTheme.ppMori400White14,
                        ),
                      ],
                      const SizedBox(height: 10),
                      PrimaryButton(
                        onTap: () async {
                          await _startScan();
                        },
                        text: 'retry'.tr(),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        'or connect to a wifi network manually',
                        style: Theme.of(context).textTheme.ppMori400White14,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ssidController,
                        decoration: InputDecoration(
                          // border radius 10
                          hintText: 'Enter wifi network',
                          hintStyle:
                              Theme.of(context).textTheme.ppMori400White14,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: AppColor.auGreyBackground,
                          focusColor: AppColor.auGreyBackground,
                          filled: true,
                          constraints: const BoxConstraints(minHeight: 60),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                        ),
                        style: Theme.of(context).textTheme.ppMori400White14,
                        onChanged: (value) {
                          setState(() {
                            _shouldEnableConnectButton =
                                value.trim().isNotEmpty;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        enabled: _shouldEnableConnectButton,
                        onTap: () async {
                          final ssid = _ssidController.text.trim();
                          if (ssid.isEmpty) {
                            return;
                          }
                          await widget.payload
                              .onNetworkSelected(WifiPoint(ssid));
                        },
                        text: 'Connect',
                      ),
                    ],
                  ),
                )
              else ...[
                if (_isScanning) ...[
                  SliverToBoxAdapter(
                    child: Text(
                      'Scanning for wifi networks...',
                      style: Theme.of(context).textTheme.ppMori400White14,
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 24))
                ],
                ..._accessPoints.map(
                  (e) => SliverToBoxAdapter(child: itemBuilder(context, e)),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget itemBuilder(BuildContext context, WifiPoint wifiAccessPoint) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            await widget.payload.onNetworkSelected(wifiAccessPoint);
          },
          child: SizedBox(
            width: double.infinity,
            child: ColoredBox(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  wifiAccessPoint.ssid,
                  style: theme.textTheme.ppMori400White14,
                ),
              ),
            ),
          ),
        ),
        const Divider(
          color: AppColor.auGreyBackground,
        ),
      ],
    );
  }
}
