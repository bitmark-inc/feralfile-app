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
import 'package:autonomy_flutter/screen/onboarding/new_address/choose_chain_page.dart';
import 'package:autonomy_flutter/screen/onboarding/view_address/view_existing_address.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
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
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  bool fromBranchLink = false;
  bool fromDeeplink = false;
  bool fromIrlLink = false;

  final metricClient = injector.get<MetricClientService>();

  late SwiperController _swiperController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
    _currentIndex = 0;
    handleBranchLink();
    handleDeepLink();
    handleIrlLink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    log.info("DefineViewRoutingEvent");
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
        appBar: getDarkEmptyAppBar(),
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
            if (state.isLoading) {
              return loadingScreen(theme, "restoring_autonomy".tr());
            }
            if (state.onboardingStep == OnboardingStep.startScreen) {
              return Container(
                  padding: EdgeInsets.only(bottom: 40),
                  color: AppColor.primaryBlack,
                  child: _swipper(context));
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
                  Text("discover".tr(),
                      style: theme.textTheme.ppMori700Black36),
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
                  ] else if (state.onboardingStep ==
                      OnboardingStep.restore) ...[
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

  Widget _onboardingItem(BuildContext context,
      {required String title,
      required String desc,
      required String image,
      Widget? subDesc}) {
    final theme = Theme.of(context);
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          Text(
            title,
            style: theme.textTheme.ppMori700White24
                .copyWith(fontSize: 36, height: 1.0),
          ),
          const SizedBox(height: 40),
          Image.asset(image),
          const SizedBox(height: 40),
          Text(
            desc,
            style: theme.textTheme.ppMori400White14
                .copyWith(fontSize: 24, height: 1.0),
          ),
          const SizedBox(height: 10),
          subDesc ?? const SizedBox(),
        ],
      ),
    );
  }

  Widget _swipper(BuildContext context) {
    final theme = Theme.of(context);
    final explore_artworks = [
      'Licia He, Fictional Lullaby',
    ];
    final stream_artworks = [
      'Refik Anadol, Unsupervised',
      'Nancy Baker Cahill, Slipstream 001',
      'Refik Anadol, Unsupervised'
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
              children: explore_artworks
                  .map((e) => TextSpan(
                        text: e,
                      ))
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
              children: stream_artworks
                  .mapIndexed((index, e) => [
                        TextSpan(
                          text: e,
                        ),
                        if (index != stream_artworks.length - 1)
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
          pagination: SwiperPagination(
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
                      await Navigator.of(context)
                          .pushNamed(ChooseChainPage.tag);
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
