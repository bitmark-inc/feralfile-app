//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_bloc.dart';
import 'package:autonomy_flutter/screen/bloc/subscription/subscription_state.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_bloc.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_page.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/screen/home/collection_home_page.dart';
import 'package:autonomy_flutter/screen/home/organize_home_page.dart';
import 'package:autonomy_flutter/screen/playlists/view_playlist/view_playlist.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart' as nc;
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_util.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/notification_type.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/homepage_navigation_bar.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeNavigationPagePayload {
  final bool fromOnboarding;
  final HomeNavigatorTab startedTab;

  const HomeNavigationPagePayload(
      {bool? fromOnboarding, HomeNavigatorTab? startedTab})
      : fromOnboarding = fromOnboarding ?? false,
        startedTab = startedTab ?? HomeNavigatorTab.exhibition;
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
  final GlobalKey<OrganizeHomePageState> _organizeHomePageKey = GlobalKey();
  final GlobalKey<CollectionHomePageState> _collectionHomePageKey = GlobalKey();
  final GlobalKey<ExhibitionsPageState> _exhibitionsPageKey = GlobalKey();
  final GlobalKey<ScanQRPageState> _scanQRPageKey = GlobalKey();
  final _configurationService = injector<ConfigurationService>();
  late Timer? _timer;
  final _clientTokenService = injector<ClientTokenService>();
  final _notificationService = injector<nc.NotificationService>();
  final _playListService = injector<PlaylistService>();
  final _remoteConfig = injector<RemoteConfigService>();
  final _metricClientService = injector<MetricClientService>();
  late HomeNavigatorTab _initialTab;
  final nftBloc = injector<ClientTokenService>().nftBloc;

  StreamSubscription<FGBGType>? _fgbgSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  void sendVisitPageEvent() {
    if (_selectedIndex != HomeNavigatorTab.menu.index) {
      final title = (_selectedIndex == HomeNavigatorTab.scanQr.index)
          ? QRScanTab
              .values[_scanQRPageKey.currentState?.tabController.index ??
                  QRScanTab.scan.index]
              .screenName
          : HomeNavigatorTab.values[_selectedIndex].screenName;
      _metricClientService
        ..addEvent(
          MixpanelEvent.visitPage,
          data: {
            MixpanelProp.title: title,
          },
        )
        ..timerEvent(
          MixpanelEvent.visitPage,
        );
    }
  }

  Future<void> openExhibition(String exhibitionId) async {
    await _onItemTapped(HomeNavigatorTab.exhibition.index);
    // delay to ensure the page is loaded
    Future.delayed(const Duration(milliseconds: 1000), () {
      _exhibitionsPageKey.currentState?.setAutoOpenExhibition(exhibitionId);
    });
  }

  Future<void> _onItemTapped(int index) async {
    if (index < _pages.length) {
      if (_selectedIndex == index) {
        if (index == HomeNavigatorTab.collection.index) {
          _collectionHomePageKey.currentState?.scrollToTop();
        }
        if (index == HomeNavigatorTab.organization.index) {
          _organizeHomePageKey.currentState?.scrollToTop();
        }
        if (index == HomeNavigatorTab.exhibition.index) {
          _exhibitionsPageKey.currentState?.scrollToTop();
        }
      } else {
        if (index == HomeNavigatorTab.scanQr.index) {
          await _scanQRPageKey.currentState?.resumeCamera();
        } else {
          await _scanQRPageKey.currentState?.pauseCamera();
        }
        sendVisitPageEvent();
      }
      setState(() {
        _selectedIndex = index;
      });
      _pageController?.jumpToPage(_selectedIndex);
      if (index == HomeNavigatorTab.collection.index ||
          index == HomeNavigatorTab.organization.index) {
        unawaited(_clientTokenService.refreshTokens());
        unawaited(_playListService.refreshPlayLists());
      }
      if (index == HomeNavigatorTab.exhibition.index) {
        _exhibitionsPageKey.currentState?.refreshExhibitions();
      }
    } else {
      final currentIndex = _selectedIndex;
      _metricClientService.addEvent(
        MixpanelEvent.visitPage,
        data: {
          MixpanelProp.title:
              HomeNavigatorTab.values[_selectedIndex].screenName,
        },
      );
      setState(() {
        _selectedIndex = index;
      });
      await UIHelper.showCenterMenu(
        context,
        options: [
          OptionItem(
            title: 'featured_works'.tr(),
            icon: SvgPicture.asset(
              'assets/images/icon_set.svg',
              colorFilter:
                  const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
            ),
            onTap: () async {
              final artworks =
                  await injector<FeralFileService>().getFeaturedArtworks();
              if (!mounted) {
                return;
              }
              final tokenIds = artworks.map((e) => e.indexerTokenId).toList()
                ..removeWhere((element) => element == null);
              log.info('Featured artworks: '
                  '${tokenIds.length}/${artworks.length} token');
              unawaited(Navigator.popAndPushNamed(
                context,
                AppRouter.viewPlayListPage,
                arguments: ViewPlaylistScreenPayload(
                  playListModel: PlayListModel(
                      name: 'featured'.tr(),
                      tokenIDs: tokenIds.map((e) => e!).toList()),
                  collectionType: CollectionType.featured,
                ),
              ));
            },
          ),
          OptionItem(
            title: 'rnd'.tr(),
            icon: SvgPicture.asset(
              'assets/images/icon_3d.svg',
              colorFilter:
                  const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
            ),
            onTap: () {
              Navigator.of(context).popAndPushNamed(AppRouter.projectsList);
            },
          ),
          OptionItem(
            title: 'addresses'.tr(),
            icon: const Icon(
              AuIcon.wallet,
            ),
            onTap: () {
              Navigator.of(context).popAndPushNamed(AppRouter.walletPage);
            },
          ),
          OptionItem(
            title: 'Settings',
            icon: const Icon(
              AuIcon.settings,
            ),
            onTap: () {
              Navigator.of(context).popAndPushNamed(AppRouter.settingsPage);
            },
          ),
          OptionItem(
              title: 'Help',
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
                Navigator.of(context)
                    .popAndPushNamed(AppRouter.supportCustomerPage);
              }),
        ],
      );
      if (mounted) {
        setState(() {
          _selectedIndex = currentIndex;
        });
        if (_selectedIndex == HomeNavigatorTab.scanQr.index) {
          await _scanQRPageKey.currentState?.resumeCamera();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // since we moved to use bonsoir service,
    // we don't need to wait for canvas service to init
    injector<CanvasDeviceBloc>().add(CanvasDeviceGetDevicesEvent(retry: true));
    unawaited(injector<CustomerSupportService>().getIssuesAndAnnouncement());
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
    unawaited(
        _clientTokenService.refreshTokens(syncAddresses: true).then((value) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
    }));
    unawaited(_clientTokenService.refreshTokens());

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      unawaited(_clientTokenService.refreshTokens());
    });

    _pages = <Widget>[
      CollectionHomePage(key: _collectionHomePageKey),
      OrganizeHomePage(key: _organizeHomePageKey),
      MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: injector<ExhibitionBloc>()..add(GetAllExhibitionsEvent()),
            ),
            BlocProvider.value(
              value: injector<SubscriptionBloc>()..add(GetSubscriptionEvent()),
            ),
          ],
          child: ExhibitionsPage(
            key: _exhibitionsPageKey,
          )),
      ScanQRPage(
        key: _scanQRPageKey,
        onHandleFinished: () async {
          await _onItemTapped(_initialTab.index);
        },
      )
    ];
    if (!_configurationService.isReadRemoveSupport()) {
      unawaited(_showRemoveCustomerSupport());
    }
    OneSignal.shared.setNotificationWillShowInForegroundHandler((event) async {
      await NotificationHandler.instance.shouldShowNotifications(
        context,
        event,
        _pageController,
      );
    });
    injector<AuditService>().auditFirstLog();
    OneSignal.shared.setNotificationOpenedHandler((openedResult) {
      Future.delayed(const Duration(milliseconds: 500), () {
        unawaited(NotificationHandler.instance.handleNotificationClicked(
            context, openedResult.notification, _pageController));
      });
    });

    if (!widget.payload.fromOnboarding) {
      unawaited(injector<TezosBeaconService>().cleanup());
      unawaited(injector<Wc2Service>().cleanup());
    }
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    unawaited(_syncArtist());
  }

  Future<void> _syncArtist() async {
    if (_configurationService.getDidSyncArtists()) {
      return;
    }
    final artists = await injector<AssetTokenDao>().findAllArtists();
    NftCollectionBloc.addEventFollowing(AddArtistsEvent(artists: artists));
    unawaited(_configurationService.setDidSyncArtists(true));
  }

  Future refreshNotification() async {
    await injector<CustomerSupportService>().getIssuesAndAnnouncement();
  }

  @override
  Future<void> didPopNext() async {
    super.didPopNext();
    unawaited(injector<CustomerSupportService>().getIssuesAndAnnouncement());
    if (_selectedIndex == HomeNavigatorTab.scanQr.index) {
      await _scanQRPageKey.currentState?.resumeCamera();
    }
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
    _metricClientService.timerEvent(
      MixpanelEvent.visitPage,
    );
  }

  @override
  Future<void> didPushNext() async {
    super.didPushNext();
    if (_selectedIndex != HomeNavigatorTab.menu.index) {
      _metricClientService.addEvent(
        MixpanelEvent.visitPage,
        data: {
          MixpanelProp.title:
              HomeNavigatorTab.values[_selectedIndex].screenName,
        },
      );
    }
  }

  Future<void> _showRemoveCustomerSupport() async {
    final device = DeviceInfo.instance;
    if (!(await device.isSupportOS())) {
      final dio = baseDio(BaseOptions(
        baseUrl: 'https://raw.githubusercontent.com',
        connectTimeout: const Duration(seconds: 5),
      ));
      final data = await dio.get<String>(REMOVE_CUSTOMER_SUPPORT);
      if (data.statusCode == 200) {
        final Uri uri = Uri.parse(AUTONOMY_CLIENT_GITHUB_LINK);
        String? gitHubContent = data.data ?? '';
        Future.delayed(const Duration(seconds: 3), () {
          showInAppNotifications(
              context, 'au_has_announcement'.tr(), 'remove_customer_support',
              notificationOpenedHandler: () {
            UIHelper.showCenterSheet(context,
                content: Markdown(
                  key: const Key('remove_customer_support'),
                  data: gitHubContent,
                  softLineBreak: true,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(0),
                  styleSheet: markDownAnnouncementStyle(context),
                ),
                actionButton: 'follow_github'.tr(),
                actionButtonOnTap: () =>
                    launchUrl(uri, mode: LaunchMode.externalApplication),
                exitButtonOnTap: () {
                  _configurationService.readRemoveSupport(true);
                  Navigator.of(context).pop();
                },
                exitButton: 'i_understand_'.tr());
          });
        });
      }
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
                } else {
                  setState(() {
                    _initialTab = HomeNavigatorTab.collection;
                  });
                }
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
          'assets/images/icon_collection.svg',
          height: iconSize,
          colorFilter: selectedColorFilter,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/images/icon_collection.svg',
          height: iconSize,
          colorFilter: unselectedColorFilter,
        ),
        label: 'collection',
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
        label: 'organize',
      ),
      FFNavigationBarItem(
        icon: SvgPicture.asset(
          'assets/images/controller_icon.svg',
          height: iconSize,
          colorFilter: selectedColorFilter,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/images/controller_icon.svg',
          height: iconSize,
          colorFilter: unselectedColorFilter,
        ),
        label: 'exhibitions',
      ),
      FFNavigationBarItem(
        icon: SvgPicture.asset(
          'assets/images/icon_scan.svg',
          height: iconSize,
          colorFilter: selectedColorFilter,
        ),
        unselectedIcon: SvgPicture.asset(
          'assets/images/icon_scan.svg',
          height: iconSize,
          colorFilter: unselectedColorFilter,
        ),
        label: 'scan',
      ),
      FFNavigationBarItem(
        icon: ValueListenableBuilder<List<int>?>(
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
        selectedColor: unselectedColor,
        label: 'menu',
      ),
    ];
    return FFNavigationBar(
      items: bottomItems,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      backgroundColor: AppColor.auGreyBackground,
      onSelectTab: _onItemTapped,
      currentIndex: _selectedIndex,
    );
  }

  Future<void> _checkForKeySync(BuildContext context) async {
    final cloudDatabase = injector<CloudDatabase>();
    final defaultAccounts = await cloudDatabase.personaDao.getDefaultPersonas();

    if (defaultAccounts.length >= 2) {
      if (!context.mounted) {
        return;
      }
      unawaited(Navigator.of(context).pushNamed(AppRouter.keySyncPage));
    }
  }

  PageController _getPageController(int initialIndex) =>
      PageController(initialPage: initialIndex);

  void _handleBackground() {
    unawaited(_cloudBackup());
    _metricClientService.onBackground();
  }

  Future<void> _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        unawaited(_handleForeground());
        memoryValues.isForeground = true;
        unawaited(injector<ChatService>().reconnect());
      case FGBGType.background:
        _handleBackground();
        memoryValues.isForeground = false;
    }
  }

  Future<void> _handleForeground() async {
    _metricClientService.onForeground();
    injector<CanvasDeviceBloc>().add(CanvasDeviceGetDevicesEvent(retry: true));
    await injector<CustomerSupportService>().fetchAnnouncement();
    await _remoteConfig.loadConfigs();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    if (widget.payload.startedTab != _initialTab) {
      await _onItemTapped(widget.payload.startedTab.index);
    }
    await _cloudBackup();
    final initialAction = _notificationService.initialAction;
    if (initialAction != null) {
      await nc.NotificationService.onActionReceivedMethod(initialAction);
    }
    if (!context.mounted) {
      return;
    }
    unawaited(_checkForKeySync(context));
  }

  Future<void> _cloudBackup() async {
    final accountService = injector<AccountService>();
    final backup = injector<BackupService>();
    await backup.backupCloudDatabase(await accountService.getDefaultAccount());
  }
}
