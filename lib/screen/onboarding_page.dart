//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/new_onboarding_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  bool fromBranchLink = false;
  bool fromDeeplink = false;
  bool fromIrlLink = false;

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
    unawaited(handleBranchLink());
    handleDeepLink();
    handleIrlLink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log.info('DefineViewRoutingEvent');
    context.read<RouterBloc>().add(DefineViewRoutingEvent());
  }

  void handleDeepLink() {
    setState(() {
      fromDeeplink = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      final link = memoryValues.deepLink.value;
      if (link == null || link.isEmpty) {
        if (mounted) {
          setState(() {
            fromDeeplink = false;
          });
        }
      }
    });
    memoryValues.deepLink.addListener(() async {
      if (memoryValues.deepLink.value != null) {
        setState(() {
          fromDeeplink = true;
        });
        Future.delayed(const Duration(seconds: 30), () {
          setState(() {
            fromDeeplink = false;
          });
        });
      } else {
        setState(() {
          fromDeeplink = false;
        });
      }
    });
  }

  // make a function to handle irlLink like deepLink
  void handleIrlLink() {
    setState(() {
      fromIrlLink = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      final link = memoryValues.irlLink.value;
      if (link == null || link.isEmpty) {
        if (mounted) {
          setState(() {
            fromIrlLink = false;
          });
        }
      }
    });
    memoryValues.irlLink.addListener(() async {
      if (memoryValues.irlLink.value != null) {
        if (mounted) {
          setState(() {
            fromIrlLink = true;
          });
        }
        Future.delayed(const Duration(seconds: 30), () {
          setState(() {
            fromIrlLink = false;
          });
        });
      } else {
        setState(() {
          fromIrlLink = false;
        });
      }
    });
  }

  Future<void> handleBranchLink() async {
    setState(() {
      fromBranchLink = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final data = memoryValues.branchDeeplinkData.value;
      if (data == null || data.isEmpty) {
        if (mounted) {
          setState(() {
            fromBranchLink = false;
          });
        }
      }
    });

    Map<dynamic, dynamic>? currentData;

    void updateDeepLinkState() {
      setState(() {
        fromBranchLink = false;
        currentData = null;
        memoryValues.branchDeeplinkData.value = null;
      });
    }

    memoryValues.branchDeeplinkData.addListener(() async {
      try {
        final data = memoryValues.branchDeeplinkData.value;
        if (data == currentData) {
          return;
        }
        if (data != null) {
          setState(() {
            fromBranchLink = true;
          });

          await injector<AccountService>().restoreIfNeeded();
          deepLinkService.handleBranchDeeplinkData(data);
          updateDeepLinkState();
        }
      } catch (e) {
        setState(() {
          fromBranchLink = false;
        });
      }
    });
  }

  // @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: getDarkEmptyAppBar(Colors.transparent),
        backgroundColor: AppColor.primaryBlack,
        body: BlocConsumer<RouterBloc, RouterState>(
          listener: (context, state) async {
            final isSubscribed = await injector<IAPService>()
                .isSubscribed(includeInhouse: false);
            switch (state.onboardingStep) {
              case OnboardingStep.dashboard:
                /// skip membership screen if user is already subscribed
              /// or done new onboarding
                if (injector<ConfigurationService>().isDoneNewOnboarding() ||
                    isSubscribed) {
                  if (context.mounted) {
                    unawaited(Navigator.of(context)
                        .pushReplacementNamed(AppRouter.homePageNoTransition));
                  }
                }
                try {
                  await injector<SettingsDataService>().restoreSettingsData();
                } catch (_) {}
                await injector<VersionService>().checkForUpdate();
              case OnboardingStep.startScreen:
              default:
                break;
            }

            if (state.onboardingStep != OnboardingStep.dashboard) {
              await injector<VersionService>().checkForUpdate();
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return loadingScreen(theme, 'restoring_autonomy'.tr());
            }
            if (state.onboardingStep == OnboardingStep.startScreen ||
                state.onboardingStep == OnboardingStep.dashboard) {
              return MultiBlocProvider(providers: [
                BlocProvider<PersonaBloc>.value(
                    value: PersonaBloc(injector(), injector())),
                BlocProvider<UpgradesBloc>.value(
                    value: UpgradesBloc(injector(), injector())),
              ], child: const NewOnboardingPage());
            }

            final button = ((fromBranchLink ||
                        fromDeeplink ||
                        fromIrlLink ||
                        (state.onboardingStep == OnboardingStep.undefined)) &&
                    (state.onboardingStep != OnboardingStep.restore))
                ? PrimaryButton(
                    text: 'h_loading...'.tr(),
                    isProcessing: true,
                    enabled: false,
                    disabledColor: AppColor.auGreyBackground,
                    textColor: AppColor.white,
                    indicatorColor: AppColor.white,
                  )
                : (state.onboardingStep == OnboardingStep.restore)
                    ? PrimaryButton(
                        text: 'restoring'.tr(),
                        isProcessing: true,
                        enabled: false,
                        disabledColor: AppColor.auGreyBackground,
                        textColor: AppColor.white,
                        indicatorColor: AppColor.white,
                      )
                    : null;

            return Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets
                  .copyWith(bottom: 40),
              child: Stack(
                children: [
                  _onboardingLogo,
                  Positioned.fill(
                    child: Column(
                      children: [
                        const Spacer(),
                        button ?? const SizedBox(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }
}
