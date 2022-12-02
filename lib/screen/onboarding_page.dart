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
import 'package:autonomy_flutter/screen/claim/claim_token_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/eula_privacy.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:logging/logging.dart';

import '../database/cloud_database.dart';

final logger = Logger('App');

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  bool _processing = false;
  bool fromBranchLink = false;
  bool fromDeeplink = false;

  late AnimationController controller;
  late Animation<double> animation;
  late Tween<double> _topTween;
  static final _opacityTween = Tween<double>(begin: 0, end: 1.0);
  Tween<double> _maxWidthTween = Tween<double>(begin: 0, end: 1.0);

  static const _durationAnimation = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: _durationAnimation, vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeIn);
    controller.forward();
    handleBranchLink();
    handleDeepLink();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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

  void handleBranchLink() async {
    setState(() {
      fromBranchLink = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final data = memoryValues.airdropFFExhibitionId.value;
      final id = "${data?.artworkId ?? ''}${data?.exhibitionId ?? ''}".trim();
      if (id.isEmpty) {
        if (mounted) {
          setState(() {
            fromBranchLink = false;
          });
        }
      }
    });

    String? currentId;

    void _updateDeepLinkState() {
      setState(() {
        fromBranchLink = false;
        currentId = null;
        memoryValues.airdropFFExhibitionId.value = null;
      });
    }

    memoryValues.airdropFFExhibitionId.addListener(() async {
      try {
        final data = memoryValues.airdropFFExhibitionId.value;
        final id = "${data?.exhibitionId}_${data?.artworkId}";
        if (currentId == id) return;
        if (data?.artworkId?.isNotEmpty == true ||
            data?.exhibitionId?.isNotEmpty == true) {
          currentId = id;
          setState(() {
            fromBranchLink = true;
          });

          await _restoreIfNeeded();
          final ffService = injector<FeralFileService>();
          final artwork = data?.artworkId?.isNotEmpty == true
              ? await ffService.getArtwork(data!.artworkId!)
              : await ffService
                  .getAirdropArtworkFromExhibitionId(data!.exhibitionId!);

          if (artwork.airdropInfo?.isAirdropStarted != true) {
            await injector.get<NavigationService>().showAirdropNotStarted();
            _updateDeepLinkState();
            return;
          }

          final endTime = artwork.airdropInfo?.endedAt;

          if (artwork.airdropInfo == null ||
              (endTime != null && endTime.isBefore(DateTime.now()))) {
            await injector.get<NavigationService>().showAirdropExpired();
            _updateDeepLinkState();
            return;
          }

          if (artwork.airdropInfo?.remainAmount == 0) {
            await injector.get<NavigationService>().showNoRemainingToken(
                  artwork: artwork,
                );
            _updateDeepLinkState();
            return;
          }

          final otp = memoryValues.airdropFFExhibitionId.value?.otp;
          if (otp?.isExpired == true) {
            await injector.get<NavigationService>().showOtpExpired();
            _updateDeepLinkState();
            return;
          }

          if (!mounted) return;
          await Navigator.of(context).pushNamed(
            AppRouter.claimFeralfileTokenPage,
            arguments: ClaimTokenPageArgs(
              artwork: artwork,
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

  Future<void> _restoreIfNeeded() async {
    final configurationService = injector<ConfigurationService>();
    if (configurationService.isDoneOnboarding()) return;

    final cloudDB = injector<CloudDatabase>();
    final personas = await cloudDB.personaDao.getPersonas();
    final connections = await cloudDB.connectionDao.getConnections();
    if (personas.isNotEmpty || connections.isNotEmpty) {
      final backupService = injector<BackupService>();
      final accountService = injector<AccountService>();

      final defaultAccount = await accountService.getDefaultAccount();
      final backupVersion =
          await backupService.fetchBackupVersion(defaultAccount);
      if (backupVersion.isNotEmpty) {
        backupService.restoreCloudDatabase(defaultAccount, backupVersion);
        for (var persona in personas) {
          if (persona.name != "") {
            persona.wallet().updateName(persona.name);
          }
        }
        await cloudDB.connectionDao.getUpdatedLinkedAccounts();
        configurationService.setDoneOnboarding(true);
        injector<NavigationService>()
            .navigateTo(AppRouter.homePageNoTransition);
      }
    }
  }

  // @override
  @override
  Widget build(BuildContext context) {
    final centerTop = MediaQuery.of(context).size.height / 2 - 132;
    final heightScreen = MediaQuery.of(context).size.height;
    final widthScreen = MediaQuery.of(context).size.width;
    final widthLogo = widthScreen - 120;
    final maxWidthLogo = widthLogo > 265.0 ? 265.0 : widthLogo;
    var maxTop = MediaQuery.of(context).size.height - (300 + maxWidthLogo);
    maxTop = maxTop < 83 ? 83 : maxTop;

    final fixedTop = maxTop > 200 ? 200.0 : maxTop;
    final spaceLogo = (heightScreen - fixedTop - 430) > 67
        ? 67
        : (heightScreen - fixedTop - 430);

    _topTween = Tween<double>(begin: centerTop, end: fixedTop);
    _maxWidthTween = Tween<double>(begin: 265.0, end: maxWidthLogo);

    final theme = Theme.of(context);
    const edgeInsets = EdgeInsets.only(bottom: 32.0, left: 16.0, right: 16.0);

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
        return Stack(
          children: [
            AnimatedPositioned(
              top: _topTween.evaluate(animation),
              left: (widthScreen - _maxWidthTween.evaluate(animation)) / 2,
              right: (widthScreen - _maxWidthTween.evaluate(animation)) / 2,
              duration: _durationAnimation,
              child: Container(
                child: _logo(maxWidthLogo: _maxWidthTween.evaluate(animation)),
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: fixedTop + maxWidthLogo + spaceLogo,
                  width: widthScreen,
                ),
                AnimatedOpacity(
                  opacity: _opacityTween.evaluate(animation),
                  duration: _durationAnimation,
                  child: Image.asset('assets/images/autonomy_logotype.png'),
                ),
                const Spacer(),
                Container(
                  margin: edgeInsets,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: fromBranchLink ||
                            (state.onboardingStep ==
                                OnboardingStep.undefined) ||
                            fromDeeplink
                        ? [
                            Center(
                                child: Text(
                              tr('loading...').toUpperCase(),
                              style: theme.textTheme.ibmBlackNormal14,
                            ))
                          ]
                        : [
                            privacyView(context),
                            const SizedBox(height: 32.0),
                            _getStartupButton(state),
                          ],
                  ),
                )
              ],
            ),
          ],
        );
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
