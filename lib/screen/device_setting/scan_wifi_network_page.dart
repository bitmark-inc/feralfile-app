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
  List<WifiPoint>? _accessPoints;
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
              if (_isScanning) ...[
                SliverToBoxAdapter(
                  child: Text(
                    'Getting WiFi networks from Portal. Please wait a moment...',
                    style: Theme.of(context).textTheme.ppMori400White14,
                  ),
                ),
                SliverToBoxAdapter(child: const SizedBox(height: 24))
              ],
              if (!_isScanning) ...[
                if (_accessPoints == null)
                  SliverToBoxAdapter(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.payload.device.isConnected)
                        Text(
                          'Cannot get available networks from Portal',
                          style: Theme.of(context).textTheme.ppMori400White14,
                        )
                      else ...[
                        Text(
                          'Cannot connect to Portal',
                          style: Theme.of(context).textTheme.ppMori400White14,
                        ),
                      ],
                    ],
                  ))
                else if (_accessPoints!.isEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No wifi networks found by Portal',
                          style: Theme.of(context).textTheme.ppMori400White14,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'There might be an issue with the WiFi module on your Portal. Please try restarting your Portal and scan again.',
                          style: Theme.of(context).textTheme.ppMori400White14,
                        ),
                      ],
                    ),
                  ),
                if (_accessPoints == null || _accessPoints!.isEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        PrimaryButton(
                          onTap: () async {
                            await _startScan();
                          },
                          text: 'retry'.tr(),
                        ),
                      ],
                    ),
                  ),
              ],
              ...[
                ..._accessPoints?.map(
                      (e) => SliverToBoxAdapter(child: itemBuilder(context, e)),
                    ) ??
                    [],
              ],
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
