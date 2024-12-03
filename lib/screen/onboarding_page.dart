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
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/passkey_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/dailies_helper.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/metric_helper.dart';
import 'package:autonomy_flutter/util/notification_util.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
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
  bool? _isLoginSuccess;
  late StreamSubscription<FGBGType> _fgbgSubscription;

  final _onboardingLogo = Semantics(
    label: 'onboarding_logo',
    child: Center(
      child: SvgPicture.asset(
        'assets/images/feral_file_onboarding.svg',
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    log.info('OnboardingPage initState');
    // on foreground listener
    _fgbgSubscription =
        FGBGEvents.instance.stream.listen(_handleForeBackground);
  }

  void _handleForeBackground(FGBGType event) {
    if (event == FGBGType.foreground) {
      if (didRunSetup && _isLoginSuccess == false) {
        // if setup is done and login is failed, try to login again
        injector<NavigationService>().goBack(result: false);
        unawaited(_fetchRuntimeCache());
      }
    } else {
      log.info('App is in background');
    }
  }

  @override
  void dispose() {
    unawaited(_fgbgSubscription.cancel());
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _timer = Timer(const Duration(seconds: 10), () {
      log.info('OnboardingPage loading more than 10s');
      unawaited(Sentry.captureMessage('OnboardingPage loading more than 10s'));
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
      await injector<PasskeyService>().init();
      await injector<MetricClientService>().initService();

      unawaited(injector<RemoteConfigService>().loadConfigs());
      final countOpenApp = injector<ConfigurationService>().countOpenApp() ?? 0;

      await injector<ConfigurationService>().setCountOpenApp(countOpenApp + 1);

      // set version info for user agent
      final packageInfo = await PackageInfo.fromPlatform();
      await injector<ConfigurationService>()
          .setVersionInfo(packageInfo.version);

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
      await registerPushNotifications();
    } catch (e, s) {
      log.info('registerPushNotifications error: $e');
      unawaited(
        Sentry.captureException(
          'registerPushNotifications error: $e',
          stackTrace: s,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log.info('DefineViewRoutingEvent');
  }

  Future<void> _goToTargetScreen(BuildContext context) async {
    log.info('[_goToTargetScreen] start');
    unawaited(
      Navigator.of(context)
          .pushReplacementNamed(AppRouter.homePageNoTransition),
    );
    await injector<ConfigurationService>().setDoneOnboarding(true);
  }

  Future<void> _fetchRuntimeCache() async {
    log.info('[_fetchRuntimeCache] start');
    var isSuccess = false;
    try {
      isSuccess = await _loginProcess();
    } catch (e) {
      log.info('Failed to login process: $e');
    }
    _isLoginSuccess = isSuccess;
    if (!isSuccess) {
      log.info('Login process failed');
      unawaited(Sentry.captureMessage('Login process failed'));
      return;
    }
    // download user data
    await injector<CloudManager>().downloadAll(includePlaylists: true);
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

  Future<void> _showBackupRecoveryPhraseDialog() async {
    await injector<NavigationService>().showBackupRecoveryPhraseDialog();
  }

  Future<void> _showAuthenticationUpdateRequired() async {
    await injector<NavigationService>().showAuthenticationUpdateRequired();
  }

  Future<bool> _loginProcess() async {
    final doesOSSupport = await _passkeyService.doesOSSupport();
    final canAuthenticate = await _passkeyService.canAuthenticate();
    if (!doesOSSupport || !canAuthenticate) {
      if (!doesOSSupport) {
        log.info('OS does not support passkey');
        _passkeyService.isShowingLoginDialog.value = true;
        unawaited(
          _showBackupRecoveryPhraseDialog().then((_) {
            _passkeyService.isShowingLoginDialog.value = false;
          }),
        );
        return false;
      }
      if (!canAuthenticate) {
        log.info('OS supports passkey but cannot authenticate');
        _passkeyService.isShowingLoginDialog.value = true;
        unawaited(
          _showAuthenticationUpdateRequired().then((_) {
            _passkeyService.isShowingLoginDialog.value = false;
          }),
        );
        return false;
      }
      return false;
    } else {
      log.info('Passkey is supported. Authenticate with passkey');
      final userId = _passkeyService.getUserId();
      log.info('Passkey userId: $userId');
      final didLoginSuccess =
          userId != null ? await _loginWithPasskey() : await _registerPasskey();
      if (didLoginSuccess != true) {
        throw Exception('Failed to login with passkey');
      }
      return true;
    }
  }

  Future<dynamic> _loginWithPasskey() async {
    try {
      log.info('Login with passkey');
      await _loginAndMigrate();
      log.info('Login with passkey done');
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
    log.info('Login and migrate');
    _isLoginSuccess = null;
    try {
      try {
        log.info('[_loginAndMigrate] create JWT token');
        final localResponse = await _passkeyService.logInInitiate();
        await _passkeyService.logInFinalize(localResponse);
        log.info('[_loginAndMigrate] create JWT token done');
      } catch (e, s) {
        log.info('Failed to create login JWT: $e');
        unawaited(Sentry.captureException(e, stackTrace: s));
        rethrow;
      }
      _isLoginSuccess = true;
    } catch (e, s) {
      _isLoginSuccess = false;
      log.info('Failed to migrate account: $e');
      unawaited(Sentry.captureException(e, stackTrace: s));
      rethrow;
    }
    log.info('Login and migrate done');
  }

  Future<dynamic> _registerPasskey() async {
    log.info('Register passkey');
    _passkeyService.isShowingLoginDialog.value = true;
    final result = await UIHelper.showPasskeyRegisterDialog(context);
    _passkeyService.isShowingLoginDialog.value = false;
    log.info('Register passkey done, result: $result');
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
