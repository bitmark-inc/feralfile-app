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
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/choose_chain_page.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../database/cloud_database.dart';
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
        setState(() {
          fromIrlLink = true;
        });
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
      final data = memoryValues.airdropFFExhibitionId.value;
      final id = "${data?.seriesId ?? ''}${data?.exhibitionId ?? ''}".trim();
      if (id.isEmpty) {
        if (mounted) {
          setState(() {
            fromBranchLink = false;
          });
        }
      }
    });

    String? currentId;

    void updateDeepLinkState() {
      setState(() {
        fromBranchLink = false;
        currentId = null;
        memoryValues.airdropFFExhibitionId.value = null;
      });
    }

    memoryValues.airdropFFExhibitionId.addListener(() async {
      try {
        final data = memoryValues.airdropFFExhibitionId.value;
        final id = "${data?.exhibitionId}_${data?.seriesId}";
        if (currentId == id) return;
        if (data?.seriesId?.isNotEmpty == true ||
            data?.exhibitionId?.isNotEmpty == true) {
          currentId = id;
          setState(() {
            fromBranchLink = true;
          });

          await _createAddressIfNeeded();
          final ffService = injector<FeralFileService>();
          final artwork = data?.seriesId?.isNotEmpty == true
              ? await ffService.getSeries(data!.seriesId!)
              : await ffService
                  .getAirdropSeriesFromExhibitionId(data!.exhibitionId!);

          if (artwork.airdropInfo?.isAirdropStarted != true) {
            await injector
                .get<NavigationService>()
                .showAirdropNotStarted(artwork.id);
            updateDeepLinkState();
            return;
          }

          final endTime = artwork.airdropInfo?.endedAt;

          if (artwork.airdropInfo == null ||
              (endTime != null && endTime.isBefore(DateTime.now()))) {
            await injector
                .get<NavigationService>()
                .showAirdropExpired(artwork.id);
            updateDeepLinkState();
            return;
          }

          if (artwork.airdropInfo?.remainAmount == 0) {
            await injector.get<NavigationService>().showNoRemainingToken(
                  series: artwork,
                );
            updateDeepLinkState();
            return;
          }

          final otp = memoryValues.airdropFFExhibitionId.value?.otp;
          if (otp?.isExpired == true) {
            await injector.get<NavigationService>().showOtpExpired(artwork.id);
            updateDeepLinkState();
            return;
          }

          if (!mounted) return;
          await Navigator.of(context).pushNamed(
            AppRouter.claimFeralfileTokenPage,
            arguments: ClaimTokenPageArgs(
              series: artwork,
              otp: otp,
            ),
          );
          currentId = null;

          setState(() {
            fromBranchLink = false;
          });
        }
      } catch (e) {
        setState(() {
          fromBranchLink = false;
        });
      }
    });
  }

  Future<void> _createAddressIfNeeded() async {
    final configurationService = injector<ConfigurationService>();
    if (configurationService.isDoneOnboarding()) return;

    final cloudDB = injector<CloudDatabase>();
    final accountService = injector<AccountService>();
    final personas = await cloudDB.personaDao.getPersonas();
    if (personas.isEmpty) {
      logger.info("Onboarding: create new addresses");
      configurationService.setDoneOnboarding(true);
      final persona = await accountService.createPersona();
      await persona.insertAddress(WalletType.Autonomy);
      injector<MetricClientService>().mixPanelClient.initIfDefaultAccount();
      injector<NavigationService>().navigateTo(AppRouter.homePageNoTransition);
    }
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
        injector<WalletConnectService>().initSessions(forced: true);
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
