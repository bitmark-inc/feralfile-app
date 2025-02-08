import 'dart:async';

import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiPoint {
  WifiPoint(this.ssid);

  final String ssid;
}

class ScanWifiNetworkPage extends StatefulWidget {
  const ScanWifiNetworkPage({super.key, required this.onNetworkSelected});

  final FutureOr<void> Function(WifiPoint wifiAccessPoint) onNetworkSelected;

  @override
  State<ScanWifiNetworkPage> createState() => ScanWifiNetworkPageState();
}

class ScanWifiNetworkPageState extends State<ScanWifiNetworkPage> {
  List<WifiPoint> _accessPoints = [];
  StreamSubscription<List<WiFiAccessPoint>>? _subscription;

  @override
  void initState() {
    super.initState();
    _startScan();
    _startListeningToScannedResults();
  }

  Future<void> _startScan() async {
    // check platform support and necessary requirements
    final can = await WiFiScan.instance.canStartScan(askPermissions: true);
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
    final can =
        await WiFiScan.instance.canGetScannedResults(askPermissions: true);
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
        setState(() {
          _accessPoints = [connectedWifi];
        });
      // ... handle other cases of CanGetScannedResults values
    }
  }

  Future<WifiPoint> _getConnectedWifiSSID() async {
    final isLocationPermissionGranted =
        await Permission.locationWhenInUse.request().isGranted;
    log.info('Location permission granted: $isLocationPermissionGranted');
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    final point = WifiPoint(wifiName ?? '');
    log.info('Connected wifi: ${point.ssid}');
    return point;
  }

  List<WifiPoint> _filterUniqueSSIDs(List<WiFiAccessPoint> scanResults) {
    Map<String, WiFiAccessPoint> uniqueNetworks = {};

    for (var wifi in scanResults) {
      if (!uniqueNetworks.containsKey(wifi.ssid) ||
          wifi.level > uniqueNetworks[wifi.ssid]!.level) {
        uniqueNetworks[wifi.ssid] = wifi; // Keep the strongest signal
      }
    }

    // Convert to list and sort by signal strength (RSSI), strongest first
    List<WiFiAccessPoint> sortedNetworks = uniqueNetworks.values.toList()
      ..removeWhere((element) => element.ssid.isEmpty)
      ..sort((a, b) =>
          b.level.compareTo(a.level)); // Higher RSSI (closer to 0) is stronger

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
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                ),
              ),
              ..._accessPoints
                  .map(
                      (e) => SliverToBoxAdapter(child: itemBuilder(context, e)))
                  .toList(),
            ],
          ),
        )));
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
        Divider(
          color: AppColor.auGreyBackground,
        )
      ],
    );
  }
}
