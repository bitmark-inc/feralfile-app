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
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/eula_privacy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _processing = false;
  bool fromBranchLink = false;

  @override
  void initState() {
    super.initState();
    handleBranchLink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log("DefineViewRoutingEvent");
    context.read<RouterBloc>().add(DefineViewRoutingEvent());
  }

  void handleBranchLink() async {
    setState(() {
      fromBranchLink = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final id = memoryValues.airdropFFExhibitionId.value;
      if (id == null || id.isEmpty) {
        if (mounted) {
          setState(() {
            fromBranchLink = false;
          });
        }
      }
    });

    String? currentExhibitionId;
    memoryValues.airdropFFExhibitionId.addListener(() async {
      try {
        final exhibitionId = memoryValues.airdropFFExhibitionId.value;
        if (currentExhibitionId == exhibitionId) return;
        if (exhibitionId != null && exhibitionId.isNotEmpty) {
          currentExhibitionId = exhibitionId;
          setState(() {
            fromBranchLink = true;
          });
          final exhibition =
              await injector<FeralFileService>().getExhibition(exhibitionId);

          if (exhibition.exhibitionStartAt.isAfter(DateTime.now())) {
            await injector.get<NavigationService>().showExhibitionNotStarted(
                  startTime: exhibition.exhibitionStartAt,
                );
            setState(() {
              fromBranchLink = false;
              currentExhibitionId = null;
              memoryValues.airdropFFExhibitionId.value = null;
            });
            return;
          }

          final endTime = exhibition.airdropInfo?.endedAt;

          if (exhibition.airdropInfo == null ||
              (endTime != null && endTime.isBefore(DateTime.now()))) {
            await injector.get<NavigationService>().showAirdropExpired();
            setState(() {
              fromBranchLink = false;
              currentExhibitionId = null;
              memoryValues.airdropFFExhibitionId.value = null;
            });
            return;
          }

          if (exhibition.airdropInfo?.remainAmount == 0) {
            await injector.get<NavigationService>().showNoRemainingToken(
                  exhibition: exhibition,
                );
            setState(() {
              fromBranchLink = false;
              currentExhibitionId = null;
              memoryValues.airdropFFExhibitionId.value = null;
            });
            return;
          }

          if (!mounted) return;
          await Navigator.of(context).pushNamed(
            AppRouter.claimFeralfileTokenPage,
            arguments: exhibition,
          );
          currentExhibitionId = null;

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

  // @override
  @override
  Widget build(BuildContext context) {
    var penroseWidth = MediaQuery.of(context).size.width;
    // maxWidth for Penrose
    if (penroseWidth > 380 || penroseWidth < 0) {
      penroseWidth = 380;
    }
    final theme = Theme.of(context);
    const edgeInsets =
        EdgeInsets.only(top: 120.0, bottom: 32.0, left: 16.0, right: 16.0);

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
        return Stack(children: [
          state.onboardingStep != OnboardingStep.undefined
              ? Container(
                  margin: edgeInsets,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FittedBox(
                        child: Text(
                          "autonomy".tr(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.largeTitle,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(),
          SafeArea(
            child: Center(
                child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: _logo())),
          ),
          Container(
            margin: edgeInsets,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: fromBranchLink
                  ? [
                      Center(
                          child: Text(
                        tr('loading...').toUpperCase(),
                        style: theme.textTheme.ibmBlackNormal14,
                      ))
                    ]
                  : [
                      state.onboardingStep != OnboardingStep.undefined
                          ? privacyView(context)
                          : const SizedBox(),
                      const SizedBox(height: 32.0),
                      _getStartupButton(state),
                    ],
            ),
          )
        ]);
      },
    ));
  }

  Future _gotoOwnGalleryPage() async {
    if (!mounted) return;
    return Navigator.of(context).pushNamed(AppRouter.beOwnGalleryPage);
  }

  Widget _getStartupButton(RouterState state) {
    switch (state.onboardingStep) {
      case OnboardingStep.startScreen:
        return Row(
          children: [
            Expanded(
              child: AuFilledButton(
                isProcessing: _processing,
                enabled: !_processing,
                text: "start".tr().toUpperCase(),
                key: const Key("start_button"),
                onPress: () async {
                  _gotoOwnGalleryPage();
                },
              ),
            )
          ],
        );
      case OnboardingStep.restore:
        return Row(
          children: [
            Expanded(
              child: AuFilledButton(
                text: "restore".tr().toUpperCase(),
                key: const Key("restore_button"),
                onPress: !state.isLoading
                    ? () {
                        context.read<RouterBloc>().add(
                            RestoreCloudDatabaseRoutingEvent(
                                state.backupVersion));
                      }
                    : null,
              ),
            )
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _logo() {
    return FutureBuilder<bool>(
        future: isAppCenterBuild(),
        builder: (context, snapshot) {
          return Image.asset(snapshot.data == true
              ? "assets/images/penrose_onboarding_appcenter.png"
              : "assets/images/penrose_onboarding.png");
        });
  }
}
