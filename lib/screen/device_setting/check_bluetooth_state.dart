import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/nft_collection/utils/list_extentions.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/bluetooth_connect/bluetooth_connect_state.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_connected_device_config.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_helper.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:collection/collection.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class HandleBluetoothDeviceScanDeeplinkScreenPayload {
  HandleBluetoothDeviceScanDeeplinkScreenPayload({
    required this.deeplink,
    this.onFinish,
  });

  final String deeplink;
  final Function? onFinish;
}

class HandleBluetoothDeviceScanDeeplinkScreen extends StatefulWidget {
  const HandleBluetoothDeviceScanDeeplinkScreen({
    required this.payload,
    super.key,
  });

  final HandleBluetoothDeviceScanDeeplinkScreenPayload payload;

  @override
  State<HandleBluetoothDeviceScanDeeplinkScreen> createState() =>
      HandleBluetoothDeviceScanDeeplinkScreenState();
}

class HandleBluetoothDeviceScanDeeplinkScreenState
    extends State<HandleBluetoothDeviceScanDeeplinkScreen>
    with WidgetsBindingObserver {
  late String _deeplink;
  bool _isScanning = false;
  BluetoothDevice? _resultDevice;
  final bloc = injector<BluetoothConnectBloc>();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _deeplink = widget.payload.deeplink;
    if (bloc.state.bluetoothAdapterState == BluetoothAdapterState.on) {
      _handleBluetoothConnectDeeplink(
        context,
        _deeplink,
        onFinish: widget.payload.onFinish,
      );
    }
    injector<FFBluetoothService>().listenForAdapterState();
  }

  List<String> getDataFromLink(String link) {
    final prefix = Constants.bluetoothConnectDeepLinks
        .firstWhereOrNull((prefix) => link.startsWith(prefix));
    if (prefix == null) {
      return [];
    }
    final data = link.replaceFirst(prefix, '').substring(1).split('|')
      ..removeWhere(
        (element) => element.isEmpty,
      );
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: AppColor.primaryBlack,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<BluetoothConnectBloc, BluetoothConnectState>(
          bloc: injector<BluetoothConnectBloc>(),
          builder: (context, state) {
            final isBluetoothEnabled =
                state.bluetoothAdapterState == BluetoothAdapterState.on;
            if (!isBluetoothEnabled) {
              return bluetoothNotAvailable(context);
            }

            if (_isScanning) {
              return scanning(context);
            }

            if (_resultDevice == null) {
              return deviceNotFound(context);
            }

            return Container();
          },
          listener: (context, state) {
            if (state.bluetoothAdapterState == BluetoothAdapterState.on) {
              _handleBluetoothConnectDeeplink(
                context,
                _deeplink,
                onFinish: widget.payload.onFinish,
              );
            }
          },
        ),
      ),
    );
  }

  Widget bluetoothNotAvailable(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                'Bluetooth is required for setup. Please turn it on to continue.',
                style: Theme.of(context)
                    .textTheme
                    .ppMori700White24
                    .copyWith(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Open Bluetooth Settings',
            onTap: () {
              injector<NavigationService>().openBluetoothSettings();
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget scanning(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            'Scanning for device...',
            style: Theme.of(context).textTheme.ppMori700White16,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget deviceNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 48,
            color: AppColor.feralFileLightBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Device not found',
            style: Theme.of(context).textTheme.ppMori700White16,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Try again',
            onTap: () {
              _handleBluetoothConnectDeeplink(
                context,
                _deeplink,
                onFinish: widget.payload.onFinish,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleBluetoothConnectDeeplink(
    BuildContext context,
    String link, {
    Function? onFinish,
  }) async {
    final data = getDataFromLink(link);
    final deviceName = data.firstOrNull;

    final locationId = data.atIndexOrNull(1);
    final topicId = data.atIndexOrNull(2);
    BluetoothDevice? resultDevice;
    if (_isScanning) {
      return;
    }
    setState(() {
      _isScanning = true;
    });
    await injector<FFBluetoothService>().startScan(
      timeout: const Duration(seconds: 10),
      forceScan: true,
      onData: (results) {
        final devices = results.map((e) => e.device).toList();
        final device = devices
            .firstWhereOrNull((element) => element.advName == deviceName);
        if (device != null) {
          resultDevice = device;
          return true;
        }
        return false;
      },
      onError: (error) {
        log.info('Failed to scan for device: $error');
        setState(() {
          _isScanning = false;
        });
      },
    );
    if (context.mounted) {
      setState(() {
        _isScanning = false;
        _resultDevice = resultDevice;
      });
    }
    if (resultDevice != null) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      unawaited(injector<ConfigurationService>().setBetaTester(true));
      injector<SubscriptionBloc>().add(GetSubscriptionEvent());
      // go to setting wifi page

      Pair<FFBluetoothDevice, bool>? res;
      if (locationId != null && topicId != null) {
        res = Pair(
          resultDevice!.toFFBluetoothDevice(
            locationId: locationId,
            topicId: topicId,
          ),
          true,
        );
        // Hide QR code on device
        unawaited(injector<CanvasClientServiceV2>()
            .showPairingQRCode(res.first, false));
      } else {
        final r = await injector<NavigationService>().navigateTo(
          AppRouter.bluetoothDevicePortalPage,
          arguments: resultDevice,
        );
        res = r == null ? null : r as Pair<FFBluetoothDevice, bool>;
      }

      // after setting wifi, go to device setting page
      if (res is Pair<FFBluetoothDevice, bool>) {
        unawaited(injector<NavigationService>().navigateTo(
          AppRouter.bluetoothConnectedDeviceConfig,
          arguments: BluetoothConnectedDeviceConfigPayload(
            device: res.first,
            isFromOnboarding: res.second,
          ),
        ));

        // add device to canvas
        await BluetoothDeviceManager.addDevice(
          res.first,
        );
      }
      try {
        await onFinish?.call();
      } catch (e) {
        log.info('Failed to call onFinish: $e');
      }
    }
  }
}
