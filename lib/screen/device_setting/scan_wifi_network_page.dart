import 'dart:async';

import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiPoint {
  WifiPoint(this.ssid);

  final String ssid;
}

class ScanWifiNetworkPage extends StatefulWidget {
  const ScanWifiNetworkPage({required this.onNetworkSelected, super.key});

  final FutureOr<void> Function(WifiPoint wifiAccessPoint) onNetworkSelected;

  @override
  State<ScanWifiNetworkPage> createState() => ScanWifiNetworkPageState();
}

class ScanWifiNetworkPageState extends State<ScanWifiNetworkPage> {
  List<WifiPoint> _accessPoints = [];
  bool _isLocationPermissionGranted = false;
  StreamSubscription<List<WiFiAccessPoint>>? _subscription;

  TextEditingController _ssidController = TextEditingController();
  bool _shouldEnableConnectButton = false;

  @override
  void initState() {
    super.initState();
    _startScan();
    _startListeningToScannedResults();
  }

  Future<void> _startScan() async {
    // check platform support and necessary requirements
    final can = await WiFiScan.instance.canStartScan();
    switch (can) {
      case CanStartScan.yes:
        // start full scan async-ly
        final isScanning = await WiFiScan.instance.startScan();
        log.info('Scan started: $isScanning');
      default:
        log.info('Cannot start scan: $can');
      // ... handle other cases of CanStartScan values
    }
  }

  Future<void> _startListeningToScannedResults() async {
    // check platform support and necessary requirements
    final can = await WiFiScan.instance.canGetScannedResults();
    switch (can) {
      case CanGetScannedResults.yes:
        // listen to onScannedResultsAvailable stream
        _subscription =
            WiFiScan.instance.onScannedResultsAvailable.listen((results) {
          // update accessPoints
          setState(() {
            _accessPoints = _filterUniqueSSIDs(results);
          });
        });
      default:
        log.info('Cannot get scanned results: $can');
        final connectedWifi = await _getConnectedWifiSSID();
        if (connectedWifi != null)
          setState(() {
            _accessPoints = [connectedWifi];
          });
      // ... handle other cases of CanGetScannedResults values
    }
  }

  Future<WifiPoint?> _getConnectedWifiSSID() async {
    _isLocationPermissionGranted =
        await Permission.locationWhenInUse.request().isGranted;
    log.info('Location permission granted: $_isLocationPermissionGranted');
    if (!_isLocationPermissionGranted) {
      Sentry.captureException('Location permission not granted');
      return null;
    }
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    if (wifiName == null) {
      log.info('No wifi connected');
      Sentry.captureException('No wifi connected');
      return null;
    }
    final point = WifiPoint(wifiName);
    log.info('Connected wifi: ${point.ssid}');
    return point;
  }

  List<WifiPoint> _filterUniqueSSIDs(List<WiFiAccessPoint> scanResults) {
    final uniqueNetworks = <String, WiFiAccessPoint>{};

    for (final wifi in scanResults) {
      if (!uniqueNetworks.containsKey(wifi.ssid) ||
          wifi.level > uniqueNetworks[wifi.ssid]!.level) {
        uniqueNetworks[wifi.ssid] = wifi; // Keep the strongest signal
      }
    }

    // Convert to list and sort by signal strength (RSSI), strongest first
    final sortedNetworks = uniqueNetworks.values.toList()
      ..removeWhere((element) => element.ssid.isEmpty)
      ..sort(
        (a, b) => b.level.compareTo(a.level),
      ); // Higher RSSI (closer to 0) is stronger

    return sortedNetworks.map((e) => WifiPoint(e.ssid)).toList();
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
                          await _startListeningToScannedResults();
                        },
                        text: 'retry'.tr(),
                      )
                    ],
                  ),
                )
              ] else if (_accessPoints.isEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No wifi networks found',
                        style: Theme.of(context).textTheme.ppMori400White14,
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        onTap: () async {
                          await _startScan();
                          await _startListeningToScannedResults();
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
                              vertical: 24, horizontal: 16),
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
                          await widget.onNetworkSelected(WifiPoint(ssid));
                        },
                        text: 'Connect',
                      ),
                    ],
                  ),
                )
              else
                ..._accessPoints.map(
                  (e) => SliverToBoxAdapter(child: itemBuilder(context, e)),
                ),
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
            await widget.onNetworkSelected(wifiAccessPoint);
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
