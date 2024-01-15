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
import 'package:autonomy_flutter/screen/bloc/router/router_bloc.dart';
import 'package:autonomy_flutter/screen/onboarding/new_address/address_alias.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
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
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
    _currentIndex = 0;
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
        appBar: getDarkEmptyAppBar(),
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
                break;
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
                  padding: const EdgeInsets.only(bottom: 40),
                  color: AppColor.primaryBlack,
                  child: _swiper(context));
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
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/feral_file_onboarding.svg',
                      ),
                    ),
                  ),
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

  Widget _onboardingItem(BuildContext context,
      {required String title,
      required String desc,
      required String image,
      Widget? subDesc}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 100),
        Text(
          title,
          style: theme.textTheme.ppMori700White24
              .copyWith(fontSize: 36, height: 1),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: Image.asset(
            image,
            fit: BoxFit.fitWidth,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          desc,
          style: theme.textTheme.ppMori400White14
              .copyWith(fontSize: 24, height: 1),
        ),
        const SizedBox(height: 10),
        subDesc ?? const SizedBox(),
      ],
    );
  }

  Widget _swiper(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, String>> exploreArtworks = [
      {'Licia He': 'Fictional Lullaby'},
    ];
    final List<Map<String, String>> streamArtworks = [
      {'Refik Anadol': 'Unsupervised'},
      {'Nancy Baker Cahill': 'Slipstream 001'},
      {'Refik Anadol': 'Unsupervised'}
    ];
    final pages = [
      Center(
        child: SvgPicture.asset('assets/images/feral_file_onboarding.svg'),
      ),
      _onboardingItem(
        context,
        title: 'explore_exhibitions'.tr(),
        desc: 'explore_exhibitions_desc'.tr(),
        image: 'assets/images/feral_file_onboarding_exhibition.png',
        subDesc: RichText(
          text: TextSpan(
              text: 'artwork_'.tr(),
              style: theme.textTheme.ppMori400Grey12,
              children: exploreArtworks
                  .mapIndexed((index, e) => [
                        TextSpan(
                          text: e.keys.first,
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: e.values.first,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (index != exploreArtworks.length - 1)
                          const TextSpan(text: '; ')
                      ])
                  .flattened
                  .toList()),
        ),
      ),
      _onboardingItem(context,
          title: 'manage_your_collection'.tr(),
          desc: 'manage_your_collection_desc'.tr(),
          image: 'assets/images/feral_file_onboarding_organize.png'),
      _onboardingItem(
        context,
        title: 'view_everywhere'.tr(),
        desc: 'view_everywhere_desc'.tr(),
        image: 'assets/images/feral_file_onboarding_stream.png',
        subDesc: RichText(
          text: TextSpan(
              text: 'artwork_'.tr(),
              style: theme.textTheme.ppMori400Grey12,
              children: streamArtworks
                  .mapIndexed((index, e) => [
                        TextSpan(
                          text: e.keys.first,
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: e.values.first,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (index != streamArtworks.length - 1)
                          const TextSpan(text: '; ')
                      ])
                  .flattened
                  .toList()),
        ),
      ),
    ];
    final isLastPage = _currentIndex == pages.length - 1;
    final padding = ResponsiveLayout.pageHorizontalEdgeInsets;

    return Stack(
      children: [
        Swiper(
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            return Padding(
              padding: ResponsiveLayout.pageEdgeInsets,
              child: page,
            );
          },
          onIndexChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          pagination: const SwiperPagination(
            builder: DotSwiperPaginationBuilder(
              color: Colors.grey,
              activeColor: AppColor.feralFileHighlight,
            ),
          ),
          control: const SwiperControl(
              color: Colors.transparent,
              disableColor: Colors.transparent,
              size: 0),
          loop: false,
          controller: _swiperController,
        ),
        Visibility(
          visible: isLastPage,
          child: Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColor.primaryBlack,
              padding: padding,
              child: Column(
                children: [
                  PrimaryButton(
                    text: 'get_started'.tr(),
                    onTap: () async {
                      await Navigator.of(context).pushNamed(AddressAlias.tag,
                          arguments: AddressAliasPayload(WalletType.Autonomy));
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                          ViewExistingAddress.tag,
                          arguments: ViewExistingAddressPayload(true));
                    },
                    child: Text(
                      'already_have_an_address'.tr(),
                      style: theme.textTheme.ppMori400Grey14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
