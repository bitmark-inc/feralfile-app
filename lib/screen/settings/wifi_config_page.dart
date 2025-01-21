import 'dart:async';
import 'dart:io' show Platform;

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/bluetooth_connect_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WifiConfigPage extends StatefulWidget {
  const WifiConfigPage({super.key});

  @override
  State<WifiConfigPage> createState() => _WifiConfigPageState();
}

class _WifiConfigPageState extends State<WifiConfigPage> {
  final flutterBlue = FlutterBluePlus.instance;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bluetooth not supported by this device')),
        );
      }
      return;
    }

    // Listen to Bluetooth state changes
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (mounted) {
        setState(() {
          if (state == BluetoothAdapterState.on) {
            // Bluetooth is on - you can start scanning or other operations
            // startScan();
          } else {
            // Show error/warning to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Please enable Bluetooth. Current state: $state')),
            );
          }
        });
      }
    });

    // Auto-enable Bluetooth on Android
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to enable Bluetooth')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'Configure FF-X1 Pilot',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            addTitleSpace(),
            Expanded(
              child: Padding(
                padding: ResponsiveLayout.pageEdgeInsets,
                child: BluetoothConnectWidget(
                  onScanStarted: () {},
                  onDeviceSelected: (device) {},
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
