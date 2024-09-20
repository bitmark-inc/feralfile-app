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
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final metricClient = injector.get<MetricClientService>();
  final deepLinkService = injector.get<DeeplinkService>();

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
    unawaited(_createAccountOrRestoreIfNeeded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log.info('DefineViewRoutingEvent');
  }

  Future<void> _goToTargetScreen(BuildContext context) async {
    final configService = injector<ConfigurationService>();
    if (!context.mounted) {
      return;
    }

    if (configService.isDoneNewOnboarding()) {
      await Navigator.of(context)
          .pushReplacementNamed(AppRouter.homePageNoTransition);
    } else {
      await Navigator.of(context).pushReplacementNamed(
        AppRouter.newOnboardingPage,
      );
    }
  }

  Future<void> _createAccountOrRestoreIfNeeded() async {
    await injector<AccountService>().restoreIfNeeded();
    if (!mounted) {
      return;
    }
    await metricClient.identity();
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
