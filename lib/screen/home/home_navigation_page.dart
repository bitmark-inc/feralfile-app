//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/graphql/account_settings/cloud_manager.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/additional_data/additional_data.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_bloc.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home.dart';
import 'package:autonomy_flutter/screen/feralfile_home/feralfile_home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/home/list_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/home/organize_home_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/announcement/announcement_service.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/deeplink_service.dart';
import 'package:autonomy_flutter/service/home_widget_service.dart';
import 'package:autonomy_flutter/service/locale_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart' as nc;
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/shared.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_type.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/homepage_navigation_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class HomeNavigationPagePayload {
  final bool fromOnboarding;
  final HomeNavigatorTab startedTab;

  const HomeNavigationPagePayload(
      {bool? fromOnboarding, HomeNavigatorTab? startedTab})
      : fromOnboarding = fromOnboarding ?? false,
        startedTab = startedTab ?? HomeNavigatorTab.daily;
}

class HomeNavigationPage extends StatefulWidget {
  final HomeNavigationPagePayload payload;

  const HomeNavigationPage({
    super.key,
    this.payload = const HomeNavigationPagePayload(),
  });

  @override
  State<HomeNavigationPage> createState() => HomeNavigationPageState();
}

class HomeNavigationPageState extends State<HomeNavigationPage>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<HomeNavigationPage> {
  late int _selectedIndex;
  PageController? _pageController;
  late List<Widget> _pages;
  final GlobalKey<DailyWorkPageState> _dailyWorkKey = GlobalKey();
  final GlobalKey<OrganizeHomePageState> _organizeHomeKey = GlobalKey();
  final _configurationService = injector<ConfigurationService>();
  late Timer? _timer;
  final _clientTokenService = injector<ClientTokenService>();
  final _notificationService = injector<nc.NotificationService>();
  final _remoteConfig = injector<RemoteConfigService>();
  final _announcementService = injector<AnnouncementService>();
  late HomeNavigatorTab _initialTab;
  final nftBloc = injector<ClientTokenService>().nftBloc;
  final _subscriptionBloc = injector<SubscriptionBloc>();

  StreamSubscription<FGBGType>? _fgbgSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  Future<void> openExhibition(String exhibitionId) async {
    await onItemTapped(HomeNavigatorTab.explore.index);
  }

  Future<void> onItemTapped(int index) async {
    if (index < _pages.length) {
      // handle scroll to top when tap on the same tab
      if (_selectedIndex == index) {
        if (index == HomeNavigatorTab.explore.index) {
          feralFileHomeKey.currentState?.scrollToTop();
        } else if (index == HomeNavigatorTab.daily.index) {
          _dailyWorkKey.currentState?.scrollToTop();
        } else if (index == HomeNavigatorTab.collection.index) {
          _organizeHomeKey.currentState?.scrollToTop();
        }
      }
      // when user change tap
      else {
        // if tap on daily, resume daily work,
        // otherwise pause daily work
        if (index == HomeNavigatorTab.daily.index) {
          _dailyWorkKey.currentState?.resumeDailyWork();
        } else {
          _dailyWorkKey.currentState?.pauseDailyWork();
        }
      }
      setState(() {
        _selectedIndex = index;
      });
      _pageController?.jumpToPage(_selectedIndex);
    }
    // handle hamburger menu
    else {
      final currentIndex = _selectedIndex;
      setState(() {
        _selectedIndex = index;
      });
      await UIHelper.showCenterMenu(
        context,
        options: [
          OptionItem(
            title: 'scan'.tr(),
            icon: const Icon(
              AuIcon.scan,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.scanQRPage,
                  arguments:
                      const ScanQRPagePayload(scannerItem: ScannerItem.GLOBAL));
            },
          ),
          OptionItem(
            title: 'wallet'.tr(),
            icon: const Icon(
              AuIcon.wallet,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.walletPage);
            },
          ),
          OptionItem(
            title: 'settings'.tr(),
            icon: const Icon(
              AuIcon.settings,
            ),
            onTap: () {
              Navigator.of(context).pushNamed(AppRouter.settingsPage);
            },
          ),
          OptionItem(
              title: 'help'.tr(),
              icon: ValueListenableBuilder<List<int>?>(
                valueListenable:
                    injector<CustomerSupportService>().numberOfIssuesInfo,
                builder: (BuildContext context, List<int>? numberOfIssuesInfo,
                        Widget? child) =>
                    iconWithRedDot(
                  icon: const Icon(
                    AuIcon.help,
                  ),
                  padding: const EdgeInsets.only(right: 2, top: 2),
                  withReddot:
                      numberOfIssuesInfo != null && numberOfIssuesInfo[1] > 0,
                ),
              ),
              onTap: () {
                Navigator.of(context).pushNamed(AppRouter.supportCustomerPage);
              }),
        ],
      );
      if (mounted) {
        setState(() {
          _selectedIndex = currentIndex;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // since we moved to use bonsoir service,
    // we don't need to wait for canvas service to init

    Future.delayed(const Duration(seconds: 1), () {
      if (!_configurationService.didShowLiveWithArt()) {
        if (!mounted) {
          return;
        }
        unawaited(UIHelper.showLiveWithArtIntro(context));
      }
    });
    injector<CanvasDeviceBloc>().add(CanvasDeviceGetDevicesEvent(retry: true));
    unawaited(injector<CustomerSupportService>().getChatThreads());
    _initialTab = widget.payload.startedTab;
    _selectedIndex = _initialTab.index;
    NftCollectionBloc.eventController.stream.listen((event) async {
      switch (event.runtimeType) {
        case const (ReloadEvent):
        case const (GetTokensByOwnerEvent):
        case const (UpdateTokensEvent):
        case const (GetTokensBeforeByOwnerEvent):
          nftBloc.add(event);
        default:
      }
    });
    unawaited(injector<VersionService>().checkForUpdate());
    unawaited(_clientTokenService.refreshTokens(syncAddresses: true).then(
      (_) {
        nftBloc.add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
      },
    ));
    context.read<HomeBloc>().add(CheckReviewAppEvent());
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      unawaited(_clientTokenService.refreshTokens());
    });

    _pages = <Widget>[
      MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => DailyWorkBloc(injector(), injector()),
            ),
            BlocProvider.value(value: injector<CanvasDeviceBloc>()),
          ],
          child: DailyWorkPage(
            key: _dailyWorkKey,
          )),
      MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: FeralfileHomeBloc(injector()),
            ),
            BlocProvider.value(
              value: _subscriptionBloc..add(GetSubscriptionEvent()),
            ),
          ],
          child: FeralfileHomePage(
            key: feralFileHomeKey,
          )),
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _subscriptionBloc),
        ],
        child: OrganizeHomePage(
          key: _organizeHomeKey,
        ),
      )
    ];

    _triggerShowAnnouncement();

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      log.info('Receive notification: ${event.notification.additionalData}');
      if (event.notification.additionalData == null) {
        return;
      }
      event.preventDefault();
      final additionalData =
          AdditionalData.fromJson(event.notification.additionalData!);
      final id = additionalData.announcementContentId ??
          event.notification.notificationId;
      final body = event.notification.body;

      /// should complete event after getting all data needed
      /// and before calling async function
      Future.delayed(const Duration(milliseconds: 500), () async {
        await injector<AnnouncementService>().fetchAnnouncements();
        if (!mounted) {
          return;
        }
        await NotificationHandler.instance.shouldShowNotifications(
          context,
          additionalData,
          id,
          body ?? '',
          _pageController,
        );
      });
    });
    OneSignal.Notifications.addClickListener((openedResult) async {
      log.info('Tapped push notification: '
          '${openedResult.notification.additionalData}');
      final additionalData =
          AdditionalData.fromJson(openedResult.notification.additionalData!);
      final id = additionalData.announcementContentId ??
          openedResult.notification.notificationId;
      final body = openedResult.notification.body;
      await _announcementService.fetchAnnouncements();
      if (!mounted) {
        return;
      }
      unawaited(NotificationHandler.instance
          .handleNotificationClicked(context, additionalData, id, body ?? ''));
    });

    if (!widget.payload.fromOnboarding) {
      unawaited(injector<TezosBeaconService>().cleanup());
      unawaited(injector<Wc2Service>().cleanup());
    }
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);

    /// precache playlist
    injector<ListPlaylistBloc>().add(ListPlaylistLoadPlaylist());
  }

  Future refreshNotification() async {
    await injector<CustomerSupportService>().getChatThreads();
    await injector<CustomerSupportService>().processMessages();
  }

  @override
  Future<void> didPopNext() async {
    super.didPopNext();
    unawaited(_clientTokenService.refreshTokens());
    unawaited(refreshNotification());
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!mounted) {
          return;
        }
        nftBloc
            .add(RequestIndexEvent(await _clientTokenService.getAddresses()));
      });
    }
    // refresh playlist token here
    injector<ListPlaylistBloc>()
        .add(ListPlaylistLoadPlaylist(refreshDefaultPlaylist: true));
    if (_selectedIndex == HomeNavigatorTab.daily.index) {
      _dailyWorkKey.currentState?.resumeDailyWork();
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_fgbgSubscription?.cancel());
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColor.primaryBlack,
        body: SafeArea(
          top: false,
          bottom: false,
          child: BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
              bloc: nftBloc,
              listenWhen: (previous, current) =>
                  _pageController == null ||
                  previous.tokens.isEmpty && current.tokens.isNotEmpty ||
                  previous.tokens.isNotEmpty && current.tokens.isEmpty,
              listener: (context, state) {
                if (state.tokens.isEmpty) {
                  setState(() {
                    _initialTab = widget.payload.startedTab;
                  });
                } else {}
              },
              buildWhen: (previous, current) {
                final shouldRebuild = _pageController == null;
                if (shouldRebuild) {
                  _selectedIndex = _initialTab.index;
                  _pageController?.dispose();
                  _pageController = _getPageController(_selectedIndex);
                }
                return shouldRebuild;
              },
              builder: (context, state) {
                if (state.tokens.isEmpty) {
                  if ([NftLoadingState.notRequested, NftLoadingState.loading]
                      .contains(state.state)) {
                    return Center(
                        child: loadingIndicator(valueColor: AppColor.white));
                  }
                }
                return Stack(
                  children: [
                    PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: _pages,
                    ),
                    KeyboardVisibilityBuilder(
                      builder: (context, isKeyboardVisible) => isKeyboardVisible
                          ? const SizedBox()
                          : Positioned.fill(
                              bottom: 40,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _buildBottomNavigationBar(context),
                              ),
                            ),
                    ),
                  ],
                );
              }),
        ),
      );

  Widget _buildBottomNavigationBar(BuildContext context) {
    const selectedColor = AppColor.white;
    const unselectedColor = AppColor.disabledColor;
    const selectedColorFilter =
        ColorFilter.mode(selectedColor, BlendMode.srcIn);
    const unselectedColorFilter =
        ColorFilter.mode(unselectedColor, BlendMode.srcIn);
    const iconSize = 25.0;
    final bottomItems = [
      FFNavigationBarItem(
        icon: SvgPicture.asset(
          'assets/images/discover.svg',
          height: iconSize,
          colorFilter: selectedColorFilter,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/images/discover.svg',
          height: iconSize,
          colorFilter: unselectedColorFilter,
        ),
        label: 'dailies',
      ),
      FFNavigationBarItem(
        icon: SvgPicture.asset(
          'assets/images/set_icon.svg',
          height: iconSize,
          colorFilter: selectedColorFilter,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/images/set_icon.svg',
          height: iconSize,
          colorFilter: unselectedColorFilter,
        ),
        label: 'explore',
      ),
      const FFNavigationBarItem(
        icon: Icon(
          AuIcon.playlists,
          size: iconSize,
        ),
        unselectedIcon: Icon(
          AuIcon.playlists,
          size: iconSize,
        ),
        selectedColor: selectedColor,
        unselectedColor: unselectedColor,
        label: 'collection',
      ),
      FFNavigationBarItem(
        unselectedIcon: ValueListenableBuilder<List<int>?>(
          valueListenable:
              injector<CustomerSupportService>().numberOfIssuesInfo,
          builder: (BuildContext context, List<int>? numberOfIssuesInfo,
                  Widget? child) =>
              iconWithRedDot(
            icon: SvgPicture.asset(
              'assets/images/icon_drawer.svg',
              height: iconSize,
              colorFilter: unselectedColorFilter,
            ),
            padding: const EdgeInsets.only(right: 2, top: 2),
            withReddot: numberOfIssuesInfo != null && numberOfIssuesInfo[1] > 0,
          ),
        ),
        icon: SvgPicture.asset(
          'assets/images/close.svg',
          colorFilter: const ColorFilter.mode(selectedColor, BlendMode.srcIn),
          height: iconSize,
          width: iconSize,
        ),
        selectedColor: unselectedColor,
        label: 'menu',
      ),
    ];
    return FFNavigationBar(
      items: bottomItems,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: AppColor.auGreyBackground,
      onSelectTab: onItemTapped,
      currentIndex: _selectedIndex,
    );
  }

  PageController _getPageController(int initialIndex) {
    final pageController = PageController(initialPage: initialIndex);
    injector<NavigationService>().setGlobalHomeTabController(pageController);
    return pageController;
  }

  void _handleBackground() {
    unawaited(_checkForReferralCode());
  }

  Future<void> _checkForReferralCode() async {
    final referralCode = injector<ConfigurationService>().getReferralCode();
    if (referralCode != null && referralCode.isNotEmpty) {
      await injector<DeeplinkService>().handleReferralCode(referralCode);
    }
  }

  void _triggerShowAnnouncement() {
    unawaited(Future.delayed(const Duration(milliseconds: 1000), () {
      _announcementService.fetchAnnouncements().then(
        (_) async {
          await _announcementService.showOldestAnnouncement();
        },
      );
    }));
  }

  Future<void> _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        unawaited(_handleForeground());
        memoryValues.isForeground = true;
        unawaited(injector<ChatService>().reconnect());
      case FGBGType.background:
        memoryValues.isForeground = false;
        _handleBackground();
    }
  }

  Future<void> _handleForeground() async {
    final locale = Localizations.localeOf(context);
    unawaited(LocaleService.refresh(locale));
    memoryValues.inForegroundAt = DateTime.now();
    await injector<ConfigurationService>().reload();
    await injector<CloudManager>().downloadAll(includePlaylists: true);
    unawaited(injector<VersionService>().checkForUpdate());
    injector<CanvasDeviceBloc>().add(CanvasDeviceGetDevicesEvent(retry: true));
    await _remoteConfig.loadConfigs(forceRefresh: true);

    unawaited(injector<HomeWidgetService>().updateDailyTokensToHomeWidget());
    _triggerShowAnnouncement();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    if (widget.payload.startedTab != _initialTab) {
      await onItemTapped(widget.payload.startedTab.index);
    }
    final initialAction = _notificationService.initialAction;
    if (initialAction != null) {
      await nc.NotificationService.onActionReceivedMethod(initialAction);
    }
  }
}
