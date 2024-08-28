import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/bloc/persona/persona_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/product_details_ext.dart';
import 'package:autonomy_flutter/util/subscription_detail_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/util/wallet_utils.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/membership_card.dart';
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
  late final UpgradesBloc _upgradeBloc;

  late SwiperController _swiperController;
  MembershipCardType? _selectedMembershipCardType;
  late final bool _isDoneOnboarding;

  final VideoPlayerController _controller1 =
      VideoPlayerController.asset('assets/videos/onboarding_1.mov');
  final VideoPlayerController _controller2 =
      VideoPlayerController.asset('assets/videos/onboarding_2.mov');

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
    _upgradeBloc = context.read<UpgradesBloc>();
    _upgradeBloc.add(UpgradeQueryInfoEvent());
    _isDoneOnboarding = injector<ConfigurationService>().isDoneOnboarding();
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

  Widget _membershipCards(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: BlocConsumer<UpgradesBloc, UpgradeState>(
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
                  nameContinue(context);
                  Future.delayed(const Duration(seconds: 2), () {
                    UIHelper.showUpgradedNotification();
                  });
                default:
                  break;
              }
            },
            builder: (context, subscriptionState) {
              final subscriptionDetails =
                  subscriptionState.activeSubscriptionDetails.firstOrNull;
              final isSubscribed =
                  subscriptionDetails?.status == IAPProductStatus.completed;
              return BlocConsumer<PersonaBloc, PersonaState>(
                  listener: (context, personaState) async {
                    switch (personaState.createAccountState) {
                      case ActionState.done:
                        switch (_selectedMembershipCardType) {
                          case MembershipCardType.essential:
                            nameContinue(context);
                          case MembershipCardType.premium:
                            _upgradePurchase(subscriptionDetails);
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
                  builder: (context, personaState) => Column(
                        children: [
                          if (!isSubscribed)
                            MembershipCard(
                              type: MembershipCardType.essential,
                              price: _getEssentialPrice(subscriptionDetails),
                              isProcessing: personaState.createAccountState ==
                                      ActionState.loading &&
                                  _selectedMembershipCardType ==
                                      MembershipCardType.essential,
                              isEnable: personaState.createAccountState !=
                                  ActionState.loading,
                              onTap: (type) {
                                _selectMembershipType(type);
                                if (_isDoneCreateAccount(personaState)) {
                                  _createAccount();
                                } else {
                                  nameContinue(context);
                                }
                              },
                            ),
                          const SizedBox(height: 15),
                          MembershipCard(
                              type: MembershipCardType.premium,
                              price: _getPremiumPrice(subscriptionDetails),
                              isProcessing: personaState.createAccountState ==
                                      ActionState.loading &&
                                  _selectedMembershipCardType ==
                                      MembershipCardType.premium,
                              isEnable: personaState.createAccountState !=
                                  ActionState.loading,
                              onTap: (type) async {
                                _selectMembershipType(type);
                                if (!_isDoneCreateAccount(personaState)) {
                                  _createAccount();
                                } else {
                                  _upgradePurchase(subscriptionDetails);
                                }
                              }),
                        ],
                      ));
            }),
      );

  bool _isDoneCreateAccount(PersonaState personaState) =>
      _isDoneOnboarding || personaState.createAccountState == ActionState.done;

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

  void _selectMembershipType(MembershipCardType type) {
    _selectedMembershipCardType = type;
  }

  void _createAccount() {
    context
        .read<PersonaBloc>()
        .add(CreatePersonaAddressesEvent(WalletType.Autonomy));
  }

  void _upgradePurchase(SubscriptionDetails? subscriptionDetails) {
    if (subscriptionDetails == null) {
      return;
    }
    if (subscriptionDetails.status == IAPProductStatus.completed) {
      nameContinue(context);
      return;
    }
    final ids = [subscriptionDetails.productDetails.id];
    log.info('Cast button: upgrade purchase: ${ids.first}');
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
          onIndexChanged: (index) {
            if (index == 0) {
              _controller1.play();
              _controller2.pause();
            } else if (index == 1) {
              _controller1.pause();
              _controller2.play();
            } else {
              _controller1.pause();
              _controller2.pause();
            }
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
