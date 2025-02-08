import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
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

class SendWifiCredentialsPagePayload {
  final WifiPoint wifiAccessPoint;
  final BluetoothDevice device;

  SendWifiCredentialsPagePayload({
    required this.wifiAccessPoint,
    required this.device,
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
  final TextEditingController passwordController =
      TextEditingController(text: kDebugMode ? r'btmrkrckt@)@$' : '');

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
                        TextField(
                          controller: passwordController,
                          style: Theme.of(context).textTheme.ppMori400White14,
                          decoration: InputDecoration(
                            labelText: 'Wi-Fi Password',
                            labelStyle:
                                Theme.of(context).textTheme.ppMori400Grey14,
                            border: const OutlineInputBorder(),
                            fillColor: AppColor.auGreyBackground,
                          ),
                          obscureText: true,
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
                  onTap: () async {
                    final ssid = widget.payload.wifiAccessPoint.ssid;
                    final password = passwordController.text.trim();
                    try {
                      await injector<FFBluetoothService>().sendWifiCredentials(
                        device: widget.payload.device,
                        ssid: ssid,
                        password: password,
                      );
                      Navigator.of(context).pushNamed(
                        AppRouter.configureDevice,
                        arguments: widget.payload.device,
                      );
                    } catch (e) {
                      log.info('Failed to send wifi credentials: $e');
                      UIHelper.showInfoDialog(
                          context, 'Send wifi credentials failed', 'Reson: $e');
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
