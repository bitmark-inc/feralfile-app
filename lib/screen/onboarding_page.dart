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
import 'package:autonomy_flutter/screen/settings/subscription/subscription_page.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:card_swiper/card_swiper.dart';
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

  late SwiperController _swiperController;
  MembershipCardType? _selectedMembershipCardType;

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
    _swiperController = SwiperController();
    unawaited(handleBranchLink());
    handleDeepLink();
    handleIrlLink();
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());
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
            switch (state.onboardingStep) {
              case OnboardingStep.dashboard:
                unawaited(Navigator.of(context)
                    .pushReplacementNamed(AppRouter.homePageNoTransition));
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
            if (state.onboardingStep == OnboardingStep.startScreen) {
              return Container(
                  color: AppColor.primaryBlack, child: _swiper(context));
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

  Widget _onboardingItemWidget(BuildContext context,
      {required String title, required String desc, required Widget subDesc}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
              ),
              Text(
                title,
                style: theme.textTheme.ppMori700White24,
              ),
              Container(
                height: 30,
              ),
              Text(
                desc,
                style: theme.textTheme.ppMori400White14,
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(height: 514, child: subDesc),
      ],
    );
  }

  Widget _onboardingItemImage(BuildContext context,
          {required String title,
          required String desc,
          required String image}) =>
      _onboardingItemWidget(context,
          title: title,
          desc: desc,
          subDesc: SizedBox(
            width: double.infinity,
            child: Image.asset(
              image,
              fit: BoxFit.fitWidth,
            ),
          ));

  Widget _membershipCards(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: BlocConsumer<PersonaBloc, PersonaState>(
            listener: (context, personaState) async {
              switch (personaState.createAccountState) {
                case ActionState.done:
                  switch (_selectedMembershipCardType) {
                    case MembershipCardType.essential:
                      nameContinue(context);
                    case MembershipCardType.premium:
                      await Navigator.of(context)
                          .pushNamed(AppRouter.subscriptionPage,
                              arguments: SubscriptionPagePayload(onBack: () {
                        nameContinue(context);
                      }));
                    default:
                      break;
                  }
                case ActionState.error:
                  setState(() {
                    _selectedMembershipCardType = null;
                  });
                default:
                  break;
              }
            },
            builder: (context, personaState) =>
                BlocBuilder<UpgradesBloc, UpgradeState>(
                    builder: (context, subscriptionState) {
                  final subscriptionDetails =
                      subscriptionState.activeSubscriptionDetails.firstOrNull;
                  return Column(
                    children: [
                      MembershipCard(
                          type: MembershipCardType.essential,
                          price: _getEssentialPrice(subscriptionDetails),
                          isProcessing: personaState.createAccountState ==
                                  ActionState.loading &&
                              _selectedMembershipCardType ==
                                  MembershipCardType.essential,
                          isEnable: personaState.createAccountState ==
                              ActionState.notRequested,
                          onTap: (type) {
                            _selectMembershipType(type, personaState);
                          }),
                      const SizedBox(height: 15),
                      MembershipCard(
                          type: MembershipCardType.premium,
                          price: _getPremiumPrice(subscriptionDetails),
                          isProcessing: personaState.createAccountState ==
                                  ActionState.loading &&
                              _selectedMembershipCardType ==
                                  MembershipCardType.premium,
                          isEnable: personaState.createAccountState ==
                              ActionState.notRequested,
                          onTap: (type) async {
                            _selectMembershipType(type, personaState);
                          }),
                    ],
                  );
                })),
      );

  String _getEssentialPrice(SubscriptionDetails? subscriptionDetails) {
    if (subscriptionDetails == null) {
      return r'$0/year';
    }
    return '${subscriptionDetails.productDetails.currencySymbol}0/${subscriptionDetails.productDetails.period.name}';
  }

  String _getPremiumPrice(SubscriptionDetails? subscriptionDetails) {
    if (subscriptionDetails == null) {
      return r'$200/year';
    }
    return subscriptionDetails.price;
  }

  void _selectMembershipType(
      MembershipCardType type, PersonaState personaState) {
    _selectedMembershipCardType = type;
    context
        .read<PersonaBloc>()
        .add(CreatePersonaAddressesEvent(WalletType.Autonomy));
  }

  Widget _swiper(BuildContext context) {
    final pages = [
      _onboardingItemImage(
        context,
        title: 'live_with_art'.tr(),
        desc: 'live_with_art_desc'.tr(),
        image: 'assets/images/onboarding_1.png',
      ),
      _onboardingItemImage(
        context,
        title: 'new_art_everyday'.tr(),
        desc: 'new_art_everyday_desc'.tr(),
        image: 'assets/images/onboarding_2.png',
      ),
      _onboardingItemWidget(
        context,
        title: 'membership'.tr(),
        desc: 'membership_desc'.tr(),
        subDesc: _membershipCards(context),
      ),
    ];

    return Stack(
      children: [
        Swiper(
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            return page;
          },
          pagination: const SwiperPagination(
            margin: EdgeInsets.only(bottom: 40),
            builder: DotSwiperPaginationBuilder(
              color: Colors.grey,
              activeColor: AppColor.white,
            ),
          ),
          control: const SwiperControl(
              color: Colors.transparent,
              disableColor: Colors.transparent,
              size: 0),
          loop: false,
          controller: _swiperController,
        ),
      ],
    );
  }
}
