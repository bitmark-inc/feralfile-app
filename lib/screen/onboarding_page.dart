//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart';
import 'package:autonomy_flutter/service/passkey_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/dailies_helper.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/metric_helper.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/user_account_channel.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry/sentry.dart';

bool didRunSetup = false;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin, AfterLayoutMixin<OnboardingPage> {
  final metricClient = injector.get<MetricClientService>();
  final deepLinkService = injector.get<DeeplinkService>();
  Timer? _timer;

  final _passkeyService = injector.get<PasskeyService>();
  final _userAccountChannel = injector.get<UserAccountChannel>();
  final _authService = injector.get<AuthService>();

  final _onboardingLogo = Semantics(
    label: 'onboarding_logo',
    child: Center(
      child: SvgPicture.asset(
        'assets/images/feral_file_onboarding.svg',
      ),
    ),
  );

  @override
  void afterFirstLayout(BuildContext context) {
    _timer = Timer(const Duration(seconds: 10), () {
      log.info('OnboardingPage loading more than 10s');
      unawaited(Sentry.captureMessage('OnboardingPage loading more than 10s'));
      // unawaited(injector<NavigationService>().showAppLoadError());
    });

    unawaited(setup(context).then((_) => _fetchRuntimeCache()));
  }

  Future<void> setup(BuildContext context) async {
    // can ignore if error
    // if something goes wrong, we will catch it in the try catch block,
    // those issue can be ignored, let user continue to use the app
    log.info('[OnboardingPage] setup start');
    try {
      if (didRunSetup) {
        log.info('Setup already run');
        return;
      }
      Environment.checkAllKeys();
      await DeviceInfo.instance.init();
      await injector<DeviceInfoService>().init();
      await injector<MetricClientService>().initService();

      unawaited(injector<RemoteConfigService>().loadConfigs());
      final countOpenApp = injector<ConfigurationService>().countOpenApp() ?? 0;

      await injector<ConfigurationService>().setCountOpenApp(countOpenApp + 1);

      // set version info for user agent
      final packageInfo = await PackageInfo.fromPlatform();
      await injector<ConfigurationService>()
          .setVersionInfo(packageInfo.version);

      final notificationService = injector<NotificationService>();
      unawaited(
        notificationService.initNotification().then(
          (_) {
            notificationService.startListeningNotificationEvents();
          },
        ),
      );
      await disableLandscapeMode();
      unawaited(JohnGerrardHelper.updateJohnGerrardLatestRevealIndex());
      DailiesHelper.updateDailies([]);
      didRunSetup = true;
    } catch (e, s) {
      log.info('Setup error: $e');
      unawaited(Sentry.captureException('Setup error: $e', stackTrace: s));
    }
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
  }

  Future<void> _registerPushNotifications() async {
    try {
      final isNotificationEnabled =
          injector<ConfigurationService>().isNotificationEnabled();
      if (isNotificationEnabled) {
        await registerPushNotifications();
      }
    } catch (e, s) {
      log.info('registerPushNotifications error: $e');
      unawaited(Sentry.captureException('registerPushNotifications error: $e',
          stackTrace: s));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log.info('DefineViewRoutingEvent');
  }

  Future<void> _goToTargetScreen(BuildContext context) async {
    log.info('[_goToTargetScreen] start');
    unawaited(Navigator.of(context)
        .pushReplacementNamed(AppRouter.homePageNoTransition));
    await injector<ConfigurationService>().setDoneOnboarding(true);
  }

  Future<void> _fetchRuntimeCache() async {
    log.info('[_fetchRuntimeCache] start');
    await _loginProcess();
    unawaited(_registerPushNotifications());
    unawaited(injector<DeeplinkService>().setup());
    log.info('[_fetchRuntimeCache] end');
    unawaited(metricClient.identity());
    // count open app
    unawaited(metricClient.addEvent(MetricEventName.openApp));
    if (!mounted) {
      return;
    }
    await _goToTargetScreen(context);
  }

  Future<void> _loginProcess() async {
    final isSupportPasskey = await _passkeyService.isPassKeyAvailable();
    if (!isSupportPasskey) {
      log.info('Passkey is not supported. Login with address');
      await injector<AccountService>().migrateAccount(() async {
        await _authService.authenticateAddress();
      });
    } else {
      log.info('Passkey is supported. Authenticate with passkey');
      final didRegisterPasskey = await _userAccountChannel.didRegisterPasskey();
      log.info('Passkey registered: $didRegisterPasskey');
      final didLoginSuccess = didRegisterPasskey
          ? await _loginWithPasskey()
          : await _registerPasskey();
      if (didLoginSuccess != true) {
        throw Exception('Failed to login with passkey');
      }
    }
  }

  Future<dynamic> _loginWithPasskey() async {
    try {
      await _loginAndMigrate();
      return true;
    } catch (e, s) {
      log.info('Failed to login with passkey: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
      if (!mounted) {
        return false;
      }
      final result =
          await UIHelper.showPasskeyLoginDialog(context, _loginAndMigrate);
      _passkeyService.isShowingLoginDialog.value = false;
      return result;
    }
  }

  Future<void> _loginAndMigrate() async {
    await injector<AccountService>().migrateAccount(() async {
      final localResponse = await _passkeyService.logInInitiate();
      await _passkeyService.logInFinalize(localResponse);
    });
  }

  Future<dynamic> _registerPasskey() async {
    _passkeyService.isShowingLoginDialog.value = true;
    final result = await UIHelper.showPasskeyRegisterDialog(context);
    _passkeyService.isShowingLoginDialog.value = false;
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getDarkEmptyAppBar(Colors.transparent),
        backgroundColor: AppColor.primaryBlack,
        body: Padding(
          padding:
              ResponsiveLayout.pageHorizontalEdgeInsets.copyWith(bottom: 40),
          child: Stack(
            children: [
              _onboardingLogo,
              Positioned.fill(
                child: Column(
                  children: [
                    const Spacer(),
                    ValueListenableBuilder(
                      valueListenable: _passkeyService.isShowingLoginDialog,
                      builder: (context, value, child) {
                        if (value) {
                          return const SizedBox();
                        }
                        return PrimaryButton(
                          text: 'h_loading...'.tr(),
                          isProcessing: true,
                          enabled: false,
                          disabledColor: AppColor.auGreyBackground,
                          textColor: AppColor.white,
                          indicatorColor: AppColor.white,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
