import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/jwt.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class NewOnboardingPage extends StatefulWidget {
  const NewOnboardingPage({super.key});

  @override
  State<NewOnboardingPage> createState() => _NewOnboardingPageState();
}

class _NewOnboardingPageState extends State<NewOnboardingPage> {
  final UpgradesBloc _upgradeBloc = injector<UpgradesBloc>();

  late SwiperController _swiperController;
  MembershipCardType? _selectedMembershipCardType;

  final VideoPlayerController _controller1 =
      VideoPlayerController.asset('assets/videos/onboarding_1.mov');
  final VideoPlayerController _controller2 =
      VideoPlayerController.asset('assets/videos/onboarding_2.mov');

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
    _upgradeBloc.add(UpgradeQueryInfoEvent());
    unawaited(_initPlayer(_controller1, shouldPlay: true));
    unawaited(_initPlayer(_controller2, shouldPlay: false));
  }

  @override
  void dispose() {
    unawaited(_controller1.dispose());
    unawaited(_controller2.dispose());
    super.dispose();
  }

  Future<void> _initPlayer(VideoPlayerController controller,
      {required bool shouldPlay}) async {
    if (controller.value.isInitialized) {
      if (shouldPlay) {
        await controller.play();
      }
      return;
    }
    await controller.initialize().then((_) {
      controller.setLooping(true);
      setState(() {});
      if (shouldPlay) {
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getDarkEmptyAppBar(Colors.transparent),
        backgroundColor: AppColor.primaryBlack,
        body: Container(color: AppColor.primaryBlack, child: _swiper(context)),
      );

  Widget _onboardingItemWidget(
    BuildContext context, {
    required String title,
    required String desc,
    required Widget subDesc,
    bool subDescFixedSized = true,
  }) {
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
                height: 59,
              ),
              Text(
                title,
                style: theme.textTheme.ppMori700Black36.copyWith(
                  color: AppColor.white,
                ),
              ),
              Container(
                height: 30,
              ),
              Text(
                desc,
                style: theme.textTheme.ppMori700White18.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (subDescFixedSized) ...[
          const Spacer(),
          SizedBox(
            height: 514,
            child: subDesc,
          )
        ] else ...[
          Expanded(
            child: subDesc,
          )
        ],
      ],
    );
  }

  Widget _onboardingItemVideo(BuildContext context,
          {required String title,
          required String desc,
          required VideoPlayerController controller}) =>
      _onboardingItemWidget(context,
          title: title,
          desc: desc,
          subDesc: SizedBox(
            width: double.infinity,
            child: controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller))
                : Container(),
          ));

  Widget _membershipCards(BuildContext context) =>
      ValueListenableBuilder<bool?>(
        builder: (context, value, child) {
          final didOpenWithGiftMembership = value;
          return BlocConsumer<UpgradesBloc, UpgradeState>(
              bloc: _upgradeBloc,
              listenWhen: (previous, current) =>
                  previous.activeSubscriptionDetails.firstOrNull?.status !=
                  current.activeSubscriptionDetails.firstOrNull?.status,
              listener: (context, subscriptionState) async {
                final subscriptionDetail =
                    subscriptionState.activeSubscriptionDetails.firstOrNull;
                final status = subscriptionDetail?.status;
                log.info('Onboarding: upgradeState: $status');
                switch (status) {
                  case IAPProductStatus.completed:
                    // this is for the case when user buy membership
                    // on onboarding screen
                    if (_selectedMembershipCardType != null) {
                      _goToHomePage(context);
                    }
                  default:
                    break;
                }
              },
              builder: (context, subscriptionState) {
                final subscriptionDetails =
                    subscriptionState.activeSubscriptionDetails.firstOrNull;
                final isSubscribed =
                    subscriptionDetails?.status == IAPProductStatus.completed;
                final renewDate = subscriptionDetails?.renewDate;

                final shouldShowReceivedPremium =
                    (didOpenWithGiftMembership == true) ||
                        (isSubscribed && _selectedMembershipCardType == null);
                log.info('Onboarding: isSubscribed: $isSubscribed, '
                    'renewDate: $renewDate,'
                    'shouldShowReceivedPremium: $shouldShowReceivedPremium'
                    'source: ${subscriptionState.membershipSource}');

                final didUserBuy = (subscriptionState.membershipSource ==
                        MembershipSource.purchase) ||
                    (subscriptionState.membershipSource ==
                        MembershipSource.preset);
                if (shouldShowReceivedPremium) {
                  return _receivedPremiumCard(
                      context, subscriptionDetails, didUserBuy);
                }

                return _onboardingItemWidget(
                  context,
                  title: 'membership'.tr(),
                  desc: 'membership_desc'.tr(),
                  subDesc: Column(
                    children: [
                      if (!isSubscribed)
                        MembershipCard(
                          type: MembershipCardType.essential,
                          price: _getEssentialPrice(subscriptionDetails),
                          isProcessing: _selectedMembershipCardType ==
                                  MembershipCardType.essential &&
                              (subscriptionDetails?.status ==
                                      IAPProductStatus.pending ||
                                  subscriptionState.isProcessing),
                          isEnable: true,
                          onTap: (type) {
                            _selectMembershipType(type);
                            _goToHomePage(context);
                          },
                        ),
                      const SizedBox(height: 15),
                      MembershipCard(
                        type: MembershipCardType.premium,
                        price: _getPremiumPrice(subscriptionDetails),
                        isProcessing: _selectedMembershipCardType ==
                                MembershipCardType.premium &&
                            (subscriptionDetails?.status ==
                                    IAPProductStatus.pending ||
                                subscriptionState.isProcessing),
                        isEnable: true,
                        onTap: (type) async {
                          _selectMembershipType(type);
                          _upgradePurchase(subscriptionDetails);
                        },
                      ),
                    ],
                  ),
                );
              });
        },
        valueListenable: injector<DeeplinkService>().didOpenWithGiftMembership,
      );

  Widget _receivedPremiumCard(
    BuildContext context,
    SubscriptionDetails? subscriptionDetails,
    bool didUserBuy,
  ) =>
      _onboardingItemWidget(context,
          title: didUserBuy
              ? 'thank_for_being_pro'.tr()
              : 'you_received_premium'.tr(),
          desc: didUserBuy
              ? 'thank_for_being_pro_desc'.tr()
              : 'you_received_premium_desc'.tr(),
          subDescFixedSized: false,
          subDesc: Padding(
            padding: const EdgeInsets.only(top: 30, right: 15, left: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MembershipCard(
                  type: MembershipCardType.premium,
                  price: _getPremiumPrice(subscriptionDetails),
                  isProcessing: false,
                  isEnable: false,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: PrimaryButton(
                    text: 'continue'.tr(),
                    onTap: () {
                      _goToHomePage(context);
                    },
                  ),
                ),
              ],
            ),
          ));

  String _getEssentialPrice(SubscriptionDetails? subscriptionDetails) {
    if (subscriptionDetails == null) {
      return r'$0/year';
    }
    return '${subscriptionDetails.productDetails.currencySymbol}0/${subscriptionDetails.productDetails.period.name}';
  }

  String _getPremiumPrice(SubscriptionDetails? subscriptionDetails) {
    if (subscriptionDetails == null) {
      return r'$230/year';
    }
    return subscriptionDetails.price;
  }

  void _selectMembershipType(MembershipCardType type) {
    _selectedMembershipCardType = type;
  }

  void _upgradePurchase(SubscriptionDetails? subscriptionDetails) {
    if (subscriptionDetails == null) {
      log.info('Onboarding: upgrade purchase subscriptionDetails is null');
      return;
    }
    if (subscriptionDetails.status == IAPProductStatus.completed) {
      _goToHomePage(context);
      return;
    }
    final ids = [subscriptionDetails.productDetails.id];
    log.info('Onboarding: upgrade purchase: ${ids.first}');
    _upgradeBloc.add(UpgradePurchaseEvent(ids));
  }

  Widget _swiper(BuildContext context) {
    final pages = [
      _onboardingItemVideo(
        context,
        title: 'live_with_art'.tr(),
        desc: 'live_with_art_desc'.tr(),
        controller: _controller1,
      ),
      _onboardingItemVideo(
        context,
        title: 'new_art_everyday'.tr(),
        desc: 'new_art_everyday_desc'.tr(),
        controller: _controller2,
      ),
      _membershipCards(context),
    ];

    return Stack(
      children: [
        Swiper(
          itemCount: pages.length,
          itemBuilder: (context, index) {
            final page = pages[index];
            return page;
          },
          onIndexChanged: (index) {
            if (index == 0) {
              unawaited(_controller1.play());
              unawaited(_controller2.pause());
            } else if (index == 1) {
              unawaited(_controller1.pause());
              unawaited(_controller2.play());
            } else {
              unawaited(_controller1.pause());
              unawaited(_controller2.pause());
            }
          },
          pagination: const SwiperPagination(
            margin: EdgeInsets.only(bottom: 20),
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

  void _goToHomePage(BuildContext context) {
    unawaited(injector<ConfigurationService>().setDoneNewOnboarding(true));
    unawaited(Navigator.of(context)
        .pushReplacementNamed(AppRouter.homePageNoTransition));
  }
}
