import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WifiConfigPage extends StatefulWidget {
  const WifiConfigPage({super.key});

  @override
  State<WifiConfigPage> createState() => _WifiConfigPageState();
}

class _WifiConfigPageState extends State<WifiConfigPage> {
  final flutterBlue = FlutterBluePlus;
  BluetoothDevice? targetDevice;

  // characteristic to send Wi-Fi credentials to Peripheral
  BluetoothCharacteristic? targetCharacteristic;

  bool scanning = false;
  String status = 'Idle';
  String receivedData = '';

  final String advertisingUuid =
      'f7826da6-4fa2-4e98-8024-bc5b71e0893e'; // For scanning
  final String serviceUuid =
      'f7826da6-4fa2-4e98-8024-bc5b71e0893e'; // For connection
  final String charUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // Target characteristic

  // Wi-Fi credentials to send:
  String ssid = "Your_SSID";
  String password = "Your_Password";

  StreamSubscription? _scanSubscription;

  // Add these new state variables
  List<ScanResult> scanResults = [];
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Add timer related variables
  int _scanTimeRemaining = 60;
  Timer? _scanTimer;

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
            startScan();
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

  void startScan() {
    _addLog("Starting BLE scan...");
    setState(() {
      scanning = true;
      scanResults.clear();
      _scanTimeRemaining = 60;
    });

    // Set up countdown timer
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_scanTimeRemaining > 0) {
          _scanTimeRemaining--;
        } else {
          timer.cancel();
          scanning = false;
        }
      });
    });

    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (ScanResult r in results) {
          _addLog('Device found: ${r.device.name} (${r.device.id.id})');
          _addLog('  Service UUIDs: ${r.advertisementData.serviceUuids}');
          log.info('Found device: ${r.device.name}, ID: ${r.device.id.id}');
        }

        // Filter results to only include devices advertising our service UUID
        final filteredResults = results.where((result) {
          return result.advertisementData.serviceUuids
              .map((uuid) => uuid.toString().toLowerCase())
              .contains(advertisingUuid.toLowerCase());
        }).toList();

        setState(() {
          scanResults = filteredResults;
        });
      },
      onError: (error) {
        _addLog('Scan error: $error');
        setState(() {
          scanning = false;
          status = 'Scan error: $error';
        });
      },
    );

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 60), // Updated to 60 seconds
      androidUsesFineLocation: true,
    );
  }

  Future<void> connectToDevice() async {
    if (targetDevice == null) return;

    _addLog(
        'Attempting to connect to ${targetDevice!.name} (${targetDevice!.id.id})');

    try {
      await targetDevice!.connect(autoConnect: false);
      _addLog('Successfully connected to device');

      _addLog('Discovering services...');
      final services = await targetDevice!.discoverServices();
      _addLog('Found ${services.length} services');

      for (var service in services) {
        _addLog('Service: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          _addLog('  Characteristic: ${characteristic.uuid}');
          _addLog(
              '  Properties: ${_getCharacteristicProperties(characteristic)}');
        }
      }
    } catch (e) {
      _addLog('Connection error: $e');
      return;
    }

    // After connection, show the WiFi credentials dialog
    if (mounted) {
      _showWifiCredentialsDialog();
    }

    // Discover services
    final List<BluetoothService> services =
        await targetDevice!.discoverServices();
    for (var service in services) {
      log.info(
          'Discovered service UUID: ${service.uuid.toString().toLowerCase()}');

      // if the service UUID matches the target service UUID
      if (service.uuid.toString().toLowerCase() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          log.info(
            'Found characteristic UUID: ${characteristic.uuid.toString().toLowerCase()}',
          );
          // if the characteristic UUID matches the target characteristic UUID
          if (characteristic.uuid.toString().toLowerCase() == charUuid) {
            targetCharacteristic = characteristic;
            setState(() {
              status = 'Found target characteristic';
            });

            // Set up notifications
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.value.listen((value) {
                final receivedText = utf8.decode(value);
                setState(() {
                  receivedData = receivedText;
                  status = 'Received response from device';
                });
              });
            }

            return; // Found what we need
          }
        }
      }
    }

    setState(() {
      status = 'Target characteristic not found';
    });
  }

  // Helper to format characteristic properties
  String _getCharacteristicProperties(BluetoothCharacteristic char) {
    final props = [];
    if (char.properties.read) props.add('Read');
    if (char.properties.write) props.add('Write');
    if (char.properties.notify) props.add('Notify');
    if (char.properties.indicate) props.add('Indicate');
    if (char.properties.writeWithoutResponse)
      props.add('Write Without Response');
    return props.join(', ');
  }

  void _showWifiCredentialsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Enter Wi-Fi Credentials',
            style: Theme.of(context).textTheme.ppMori400Black16,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter the Wi-Fi credentials that you want the Feral File device to connect to.',
                style: Theme.of(context).textTheme.ppMori400Grey14,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ssidController,
                style: Theme.of(context).textTheme.ppMori400Black14,
                decoration: InputDecoration(
                  labelText: 'Wi-Fi Name (SSID)',
                  labelStyle: Theme.of(context).textTheme.ppMori400Grey14,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                style: Theme.of(context).textTheme.ppMori400Black14,
                decoration: InputDecoration(
                  labelText: 'Wi-Fi Password',
                  labelStyle: Theme.of(context).textTheme.ppMori400Grey14,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.ppMori400Grey14,
              ),
            ),
            TextButton(
              onPressed: () {
                ssid = ssidController.text;
                password = passwordController.text;
                Navigator.of(context).pop();
                sendWifiCredentials();
              },
              child: Text(
                'Connect',
                style: Theme.of(context).textTheme.ppMori400Black14,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendWifiCredentials() async {
    if (targetCharacteristic == null) {
      setState(() {
        status = 'Target characteristic not set';
      });
      return;
    }

    setState(() {
      status = 'Sending Wi-Fi credentials...';
    });

    // Convert credentials to ASCII bytes
    final ssidBytes = ascii.encode(ssid);
    final passwordBytes = ascii.encode(password);

    // Create a BytesBuilder to construct the message
    final builder = BytesBuilder();

    // Write SSID length as varint
    _writeVarint(builder, ssidBytes.length);
    // Write SSID bytes
    builder.add(ssidBytes);

    // Write password length as varint
    _writeVarint(builder, passwordBytes.length);
    // Write password bytes
    builder.add(passwordBytes);

    // Write the data to the characteristic
    await targetCharacteristic!
        .write(builder.takeBytes(), withoutResponse: false);

    setState(() {
      status = 'Credentials sent, waiting for response (if any)';
    });
  }

  // Helper method to write varint
  void _writeVarint(BytesBuilder builder, int value) {
    while (value >= 0x80) {
      builder.addByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    builder.addByte(value & 0x7F);
  }

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    // Updated disconnect method
    if (targetDevice != null) {
      targetDevice!.disconnect().then((_) {
        // Handle disconnect completion if needed
      }).catchError((error) {
        // Handle any errors
      });
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $status',
                      style: theme.textTheme.ppMori400Black14,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: scanning ? null : startScan,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColor.primaryBlack),
                        backgroundColor: AppColor.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        scanning
                            ? 'Scanning... ${_scanTimeRemaining}s'
                            : 'Start Scan',
                        style: theme.textTheme.ppMori400Black14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (scanResults.isNotEmpty)
                      Expanded(
                        child: ListView.separated(
                          itemCount: scanResults.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: AppColor.auLightGrey,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final result = scanResults[index];
                            return ListTile(
                              title: Text(
                                result.device.name.isNotEmpty
                                    ? result.device.name
                                    : "Unknown Device",
                                style: theme.textTheme.ppMori400Black16,
                              ),
                              subtitle: Text(
                                result.device.id.id,
                                style: theme.textTheme.ppMori400Grey14,
                              ),
                              onTap: () async {
                                setState(() {
                                  targetDevice = result.device;
                                  status = 'Selected: ${result.device.name}';
                                  FFBluetoothService.connectedDevice =
                                      result.device;
                                });
                                await connectToDevice();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: ResponsiveLayout.pageEdgeInsets,
              child: Text(
                'Received Data: $receivedData',
                style: theme.textTheme.ppMori400Grey14,
              ),
            ),
            // Add log display area
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.auLightGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColor.auLightGrey),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Debug Logs',
                          style: theme.textTheme.ppMori400Black14,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                final logText = _logs.join('\n');
                                Clipboard.setData(ClipboardData(text: logText))
                                    .then((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Logs copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => setState(() => _logs.clear()),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _logScrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _logs[index],
                          style: theme.textTheme.ppMori400Grey14,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
