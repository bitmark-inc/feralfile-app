//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/device_info_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/dailies_helper.dart';
import 'package:autonomy_flutter/util/john_gerrard_helper.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/metric_helper.dart';
import 'package:autonomy_flutter/util/style.dart';
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

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final metricClient = injector.get<MetricClientService>();
  final deepLinkService = injector.get<DeeplinkService>();
  Timer? _timer;

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
    _timer = Timer(const Duration(seconds: 10), () {
      log.info('OnboardingPage loading more than 10s');
      unawaited(Sentry.captureMessage('OnboardingPage loading more than 10s'));
      unawaited(injector<NavigationService>().showAppLoadError());
    });
    unawaited(setup(context).then((_) => _fetchRuntimeCache()));
  }

  Future<void> setup(BuildContext context) async {
    // can ignore if error
    // if something goes wrong, we will catch it in the try catch block,
    // those issue can be ignored, let user continue to use the app
    log.info('[OnboardingPage] setup start');
    try {
      final didRunSetup = injector<ConfigurationService>().didRunSetup();
      if (didRunSetup) {
        log.info('Setup already run');
        return;
      }
      unawaited(DeviceInfo.instance.init());
      unawaited(injector<DeviceInfoService>().init().then((_) {
        injector<MetricClientService>().initService();
      }));
      await injector<RemoteConfigService>().loadConfigs();
      final countOpenApp = injector<ConfigurationService>().countOpenApp() ?? 0;
      unawaited(
          injector<ConfigurationService>().setCountOpenApp(countOpenApp + 1));

      // set version info for user agent
      unawaited(PackageInfo.fromPlatform().then((packageInfo) =>
          injector<ConfigurationService>()
              .setVersionInfo(packageInfo.version)));

      final notificationService = injector<NotificationService>();
      unawaited(notificationService.initNotification().then((_) {
        notificationService.startListeningNotificationEvents();
      }));
      unawaited(disableLandscapeMode());
      unawaited(JohnGerrardHelper.updateJohnGerrardLatestRevealIndex());
      DailiesHelper.updateDailies([]);
      unawaited(injector<DeeplinkService>().setup());
      unawaited(injector<ConfigurationService>().setDidRunSetup(true));
    } catch (e, s) {
      log.info('Setup error: $e');
      unawaited(Sentry.captureException('Setup error: $e', stackTrace: s));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log.info('DefineViewRoutingEvent');
  }

  Future<void> _goToTargetScreen(BuildContext context) async {
    log.info('[_goToTargetScreen] start');
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
    }
    unawaited(Navigator.of(context)
        .pushReplacementNamed(AppRouter.homePageNoTransition));
    await injector<ConfigurationService>().setDoneOnboarding(true);
  }

  Future<void> _fetchRuntimeCache() async {
    final timer = Timer(const Duration(seconds: 10), () {
      log.info('[_createAccountOrRestoreIfNeeded] Loading more than 10s');
      unawaited(Sentry.captureMessage(
          '[_createAccountOrRestoreIfNeeded] Loading more than 10s'));
    });
    log.info('[_fetchRuntimeCache] start');
    await injector<AccountService>().migrateAccount();
    log.info('[_fetchRuntimeCache] end');
    if (timer.isActive) {
      timer.cancel();
    }
    unawaited(metricClient.identity());
    // count open app
    unawaited(metricClient.addEvent(MetricEventName.openApp.name));
    if (!mounted) {
      return;
    }
    await _goToTargetScreen(context);
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
                    PrimaryButton(
                      text: 'h_loading...'.tr(),
                      isProcessing: true,
                      enabled: false,
                      disabledColor: AppColor.auGreyBackground,
                      textColor: AppColor.white,
                      indicatorColor: AppColor.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
