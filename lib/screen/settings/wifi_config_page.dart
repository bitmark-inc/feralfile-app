import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiConfigPage extends StatefulWidget {
  const WifiConfigPage({super.key});

  @override
  State<WifiConfigPage> createState() => _WifiConfigPageState();
}

class _WifiConfigPageState extends State<WifiConfigPage> {
  bool _scanning = false;
  BluetoothDevice? _targetDevice;
  BluetoothConnection? _connection;
  String _status = "Idle";
  String _receivedData = "";

  // Replace these with your stored credentials
  String ssid = "Your_SSID";
  String password = "Your_Password";

  @override
  void initState() {
    super.initState();
    // If needed, ensure Bluetooth is enabled
    _ensureBluetoothIsEnabled();
  }

  Future<void> _ensureBluetoothIsEnabled() async {
    final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (isEnabled == false) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _status = "Scanning for devices...";
      _scanning = true;
    });

    final permissions = await Permission.bluetooth.request();

    List<BluetoothDiscoveryResult> results = [];

    StreamSubscription<BluetoothDiscoveryResult>? scanSubscription;
    scanSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
      // Store discovered devices in a local list
      results.add(result);

      // Check if this is the target device
      if (result.device.name == "FeralFile-WiFi") {
        scanSubscription?.cancel();
        setState(() {
          _scanning = false;
          _targetDevice = result.device;
          _status = "Found target device: ${result.device.name}";
        });
      }
    });

    // Wait until the scanning completes (or is canceled)
    await Future.delayed(const Duration(seconds: 10));
    if (_scanning) {
      // If still scanning after 10 seconds and no device found
      scanSubscription?.cancel();
      setState(() {
        _scanning = false;
        _status = "Device not found";
      });
    }
  }

  Future<void> _connectToDevice() async {
    if (_targetDevice == null) return;

    setState(() {
      _status = "Connecting to ${_targetDevice!.name}...";
    });

    try {
      final connection =
          await BluetoothConnection.toAddress(_targetDevice!.address);
      setState(() {
        _connection = connection;
        _status = "Connected to ${_targetDevice!.name}";
      });

      // Listen for data from the Pi
      _connection!.input?.listen((Uint8List data) {
        final receivedText = utf8.decode(data);
        setState(() {
          _receivedData += receivedText;
        });
      }).onDone(() {
        setState(() {
          _status = "Disconnected";
        });
      });
    } catch (e) {
      setState(() {
        _status = "Connection failed: $e";
      });
    }
  }

  Future<void> _sendWifiCredentials() async {
    if (_connection == null || !_connection!.isConnected) {
      setState(() {
        _status = "Not connected to any device.";
      });
      return;
    }

    // Prepare JSON
    final credentialsJson = jsonEncode({"ssid": ssid, "password": password});

    setState(() {
      _status = "Sending Wi-Fi credentials...";
    });

    // Send data
    _connection!.output.add(utf8.encode(credentialsJson));
    await _connection!.output.allSent;

    setState(() {
      _status = "Credentials sent. Waiting for response...";
    });
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Wi-Fi via Bluetooth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Status: $_status"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scanning ? null : _startScan,
              child: const Text("Start Scan"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _targetDevice == null || _connection != null
                  ? null
                  : _connectToDevice,
              child: const Text("Connect to Device"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _connection == null || !_connection!.isConnected
                  ? null
                  : _sendWifiCredentials,
              child: const Text("Send Wi-Fi Credentials"),
            ),
            const SizedBox(height: 20),
            Text("Received Data: $_receivedData"),
          ],
        ),
      ),
    );
  }
}
