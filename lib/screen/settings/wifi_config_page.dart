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

  StreamSubscription? _scanSubscription;
  // Add new controller for logs
  final ScrollController _logScrollController = ScrollController();
  final List<String> _logs = [];

  // Add helper method to add logs
  void _addLog(String message) {
    setState(() {
      _logs.add("[${DateTime.now().toString()}] $message");
      // Scroll to bottom after new log
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    // Check if Bluetooth is supported
    final connectedDevices = await FlutterBluePlus.connectedDevices;
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
    _scanSubscription?.cancel();
    // Updated disconnect method
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: getBackAppBar(
        context,
        title: 'Configure Wi-Fi',
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
                  onScanStarted: () {
                    _addLog('Scanning for devices...');
                    // startScan();
                  },
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
