import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/device_setting/bluetooth_exception.dart';
import 'package:autonomy_flutter/screen/device_setting/scan_wifi_network_page.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sentry/sentry.dart';

class SendWifiCredentialsPagePayload {
  final WifiPoint wifiAccessPoint;
  final BluetoothDevice device;
  final Function(FFBluetoothDevice)? onSubmitted;

  SendWifiCredentialsPagePayload({
    required this.wifiAccessPoint,
    required this.device,
    this.onSubmitted,
  });
}

class SendWifiCredentialsPage extends StatefulWidget {
  const SendWifiCredentialsPage({
    super.key,
    required this.payload,
  });

  final SendWifiCredentialsPagePayload payload;

  @override
  State<SendWifiCredentialsPage> createState() =>
      SendWifiCredentialsPageState();
}

class SendWifiCredentialsPageState extends State<SendWifiCredentialsPage> {
  late String _password;

  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    _password = kDebugMode ? r'btmrkrckt@)@$' : '';
    passwordController = TextEditingController(text: _password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.payload.wifiAccessPoint.ssid,
                          style: theme.textTheme.ppMori400White14,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        PasswordTextField(
                          controller: passwordController,
                          style: Theme.of(context).textTheme.ppMori400White14,
                          hintText: 'password'.tr(),
                          defaultObscure: false,
                          onChanged: (value) {
                            setState(() {
                              _password = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: PrimaryAsyncButton(
                  enabled: _password.isNotEmpty,
                  onTap: () async {
                    final ssid = widget.payload.wifiAccessPoint.ssid;
                    final password = passwordController.text.trim();
                    final device = widget.payload.device.toFFBluetoothDevice();
                    try {
                      // Check if the device is connected
                      if (!device.isConnected) {
                        await injector<FFBluetoothService>()
                            .connectToDevice(device);
                      }
                      final ffBluetoothDevice =
                          await injector<FFBluetoothService>()
                              .sendWifiCredentials(
                        device: device,
                        ssid: ssid,
                        password: password,
                      );
                      if (ffBluetoothDevice == null) {
                        throw FailedToConnectToWifiException(ssid, device);
                      }
                      widget.payload.onSubmitted?.call(ffBluetoothDevice);
                    } on FailedToConnectToWifiException catch (e) {
                      log.info('Failed to connect to wifi: $e');
                      unawaited(Sentry.captureException(
                        e,
                      ));
                      unawaited(UIHelper.showInfoDialog(
                        context,
                        'Failed to connect to wifi',
                        'The Portal failed to connect to ${e.ssid}',
                      ));
                    } catch (e) {
                      log.info('Failed to send wifi credentials: $e');
                      unawaited(
                        Sentry.captureException(
                          'Failed to send wifi credentials: $e',
                        ),
                      );
                      unawaited(UIHelper.showInfoDialog(
                        context,
                        'Send wifi credentials failed',
                        'Reason: $e',
                      ));
                    }
                  },
                  color: AppColor.white,
                  text: 'submit'.tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class PasswordTextField, to enter password, with button to change the visibility of the password

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    this.defaultObscure = true,
    this.style,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onVisibilityChanged,
  });

  final TextEditingController controller;
  final TextStyle? style;
  final bool defaultObscure;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.defaultObscure;
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = AppColor.auGreyBackground;
    return TextField(
      autocorrect: false,
      enableSuggestions: false,
      controller: widget.controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      obscureText: _isObscure,
      style: widget.style,
      decoration: InputDecoration(
        // border radius 10
        hintText: widget.hintText,
        hintStyle: widget.style,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        fillColor: backgroundColor,
        focusColor: backgroundColor,
        filled: true,
        constraints: const BoxConstraints(minHeight: 60),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility : Icons.visibility_off,
            color: AppColor.greyMedium,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
              widget.onVisibilityChanged?.call(_isObscure);
            });
          },
        ),
      ),
    );
  }
}
