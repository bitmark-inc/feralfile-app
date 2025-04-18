import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/device_setting/enter_wifi_password.dart';
import 'package:autonomy_flutter/screen/device_setting/scan_wifi_network_page.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service_v2.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BluetoothDevicePortalPage extends StatefulWidget {
  const BluetoothDevicePortalPage({required this.device, super.key});

  final FFBluetoothDevice device;

  @override
  State<BluetoothDevicePortalPage> createState() =>
      BluetoothDevicePortalPageState();
}

class BluetoothDevicePortalPageState extends State<BluetoothDevicePortalPage>
    with RouteAware, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pageEdgeInsets,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Expanded(
                          child: SizedBox(
                            height: 120,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Icon(
                            AuIcon.close,
                            color: AppColor.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SvgPicture.asset(
                      'assets/images/portal.svg',
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _instruction(context),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80,
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
                    final device = widget.device;

                    await injector<FFBluetoothService>()
                        .connectToDevice(device);

                    final deviceStatus = await injector<CanvasClientServiceV2>()
                        .getBluetoothDeviceStatus(device);

                    if (deviceStatus.isConnectedToWifi) {
                      unawaited(UIHelper.showDialog(
                        context,
                        'The Portal is All Set',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your device is already set up and connected. You can head to settings to make changes or check the status.',
                              style:
                                  Theme.of(context).textTheme.ppMori400White14,
                            ),
                            const SizedBox(height: 16),
                            PrimaryButton(
                              onTap: () {
                                injector<NavigationService>().popUntil(
                                    AppRouter.bluetoothDevicePortalPage);
                                injector<NavigationService>()
                                    .goBack(result: false);
                              },
                              text: 'Go to Settings',
                            ),
                          ],
                        ),
                      ));
                    } else
                      unawaited(Navigator.of(context).pushNamed(
                        AppRouter.scanWifiNetworkPage,
                        arguments: ScanWifiNetworkPagePayload(
                          widget.device.toFFBluetoothDevice(),
                          onWifiSelected,
                        ),
                      ));
                  },
                  color: AppColor.white,
                  text: 'start_device_setup'.tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FutureOr<void> onWifiSelected(WifiPoint accessPoint) {
    log.info('onWifiSelected: $accessPoint');
    final payload = SendWifiCredentialsPagePayload(
      wifiAccessPoint: accessPoint,
      device: widget.device,
      onSubmitted: () {
        injector<NavigationService>()
            .popUntil(AppRouter.bluetoothDevicePortalPage);
        injector<NavigationService>().goBack(result: true);
      },
    );
    injector<NavigationService>()
        .navigateTo(AppRouter.sendWifiCredentialPage, arguments: payload);
  }

  Widget _instruction(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'welcome_to_FF_X1'.tr(),
          style: Theme.of(context).textTheme.ppMori400White16,
        ),
        const SizedBox(height: 16),
        Text(
          'welcome_to_FF_X1_desc'.tr(),
          style: Theme.of(context).textTheme.ppMori400White14,
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
        const Divider(
          color: AppColor.white,
          thickness: 1,
        ),
        const SizedBox(height: 16),
        Text(
          'how_you_can_help'.tr(),
          style: theme.textTheme.ppMori700White16,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8).copyWith(left: 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1.',
                    style: theme.textTheme.ppMori400White14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.ppMori400White14,
                        children: [
                          TextSpan(
                            text: '${'experiment_freely'.tr()} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'experiment_freely_desc'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2.',
                    style: theme.textTheme.ppMori400White14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.ppMori400White14,
                        children: [
                          TextSpan(
                            text: '${'share_your_experience'.tr()} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '${'join_our'.tr()} ',
                          ),
                          TextSpan(
                            text: 'google_chat_space'.tr(),
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                injector<NavigationService>()
                                    .openGoogleChatSpace();
                              },
                          ),
                          TextSpan(
                            text: ' ${'to_provide_feedback'.tr()}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
