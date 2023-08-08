//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:developer';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/account/name_persona_page.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/choose_chain_page.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'bloc/persona/persona_bloc.dart';

final logger = Logger('App');

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  bool fromBranchLink = false;
  bool fromDeeplink = false;
  bool fromIrlLink = false;
  bool creatingAccount = false;

  final metricClient = injector.get<MetricClientService>();

  @override
  void initState() {
    super.initState();
    handleBranchLink();
    handleDeepLink();
    handleIrlLink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log("DefineViewRoutingEvent");
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

  void handleBranchLink() async {
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
        if (data == currentData) return;
        if (data != null) {
          setState(() {
            fromBranchLink = true;
          });

          await injector<AccountService>().restoreIfNeeded();
          final deepLinkService = injector.get<DeeplinkService>();
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

    final height = MediaQuery.of(context).size.height;
    final paddingTop = (height - 640).clamp(0.0, 104).toDouble();

    return Scaffold(
        body: BlocConsumer<RouterBloc, RouterState>(
      listener: (context, state) async {
        switch (state.onboardingStep) {
          case OnboardingStep.dashboard:
            Navigator.of(context)
                .pushReplacementNamed(AppRouter.homePageNoTransition);
            try {
              await injector<SettingsDataService>().restoreSettingsData();
            } catch (_) {
              // just ignore this so that user can go through onboarding
            }
            // await askForNotification();
            await injector<VersionService>().checkForUpdate();
            // hide code show surveys issues/1459
            // await Future.delayed(SHORT_SHOW_DIALOG_DURATION,
            //     () => showSurveysNotification(context));
            break;
          default:
            break;
        }

        if (state.onboardingStep != OnboardingStep.dashboard) {
          await injector<VersionService>().checkForUpdate();
        }
      },
      builder: (context, state) {
        if (creatingAccount) {
          return BlocListener<PersonaBloc, PersonaState>(
            listener: (context, personaState) async {
              switch (personaState.createAccountState) {
                case ActionState.done:
                  final createdPersona = personaState.persona;
                  if (createdPersona != null) {
                    Navigator.of(context).pushNamed(AppRouter.namePersonaPage,
                        arguments:
                            NamePersonaPayload(uuid: createdPersona.uuid));
                  }
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      creatingAccount = false;
                    });
                  });

                  break;
                case ActionState.error:
                  setState(() {
                    creatingAccount = false;
                  });
                  break;
                default:
                  break;
              }
            },
            child: loadingScreen(theme, "generating_wallet".tr()),
          );
        }

        if (state.isLoading) {
          return loadingScreen(theme, "restoring_autonomy".tr());
        }

        return Padding(
          padding: ResponsiveLayout.pageEdgeInsets.copyWith(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _logo(maxWidthLogo: 50),
              SizedBox(height: paddingTop),
              addBoldDivider(),
              Text("collect".tr(), style: theme.textTheme.ppMori700Black36),
              const SizedBox(height: 20),
              addBoldDivider(),
              Text("view".tr(), style: theme.textTheme.ppMori700Black36),
              const SizedBox(height: 20),
              addBoldDivider(),
              Text("discover".tr(), style: theme.textTheme.ppMori700Black36),
              const Spacer(),
              if ((fromBranchLink ||
                      fromDeeplink ||
                      fromIrlLink ||
                      (state.onboardingStep == OnboardingStep.undefined)) &&
                  (state.onboardingStep != OnboardingStep.restore)) ...[
                PrimaryButton(
                  text: "h_loading...".tr(),
                  isProcessing: true,
                )
              ] else if (state.onboardingStep ==
                  OnboardingStep.startScreen) ...[
                Text("create_wallet_description".tr(),
                    style: theme.textTheme.ppMori400Grey14),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: "create_a_new_wallet".tr(),
                  onTap: () {
                    Navigator.of(context).pushNamed(ChooseChainPage.tag);
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text("or".tr().toUpperCase(),
                      style: theme.textTheme.ppMori400Grey14),
                ),
                const SizedBox(height: 20),
                Text("view_existing_address_des".tr(),
                    style: theme.textTheme.ppMori400Grey14),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: "view_existing_address".tr(),
                  onTap: () {
                    Navigator.of(context).pushNamed(ViewExistingAddress.tag,
                        arguments: ViewExistingAddressPayload(true));
                  },
                ),
              ] else if (state.onboardingStep == OnboardingStep.restore) ...[
                PrimaryButton(
                  text: "restoring".tr(),
                  isProcessing: true,
                  enabled: false,
                ),
              ]
            ],
          ),
        );
      },
    ));
  }

  Widget _logo({double? maxWidthLogo}) {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          return SizedBox(
            width: maxWidthLogo,
            child: Image.asset(snapshot.data == true
                ? "assets/images/inhouse_logo.png"
                : "assets/images/moma_logo.png"),
          );
        });
  }
}
