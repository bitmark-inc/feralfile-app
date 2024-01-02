//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/announcement_local.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_bloc.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_page.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/screen/home/collection_home_page.dart';
import 'package:autonomy_flutter/screen/home/organize_home_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/airdrop_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/canvas_client_service.dart';
import 'package:autonomy_flutter/service/chat_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/notification_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/announcement_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_util.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/homepage_navigation_bar.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nft_collection/database/dao/asset_token_dao.dart';
import 'package:nft_collection/database/nft_collection_database.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeNavigationPage extends StatefulWidget {
  final bool fromOnboarding;

  const HomeNavigationPage({super.key, this.fromOnboarding = false});

  @override
  State<HomeNavigationPage> createState() => _HomeNavigationPageState();
}

class _HomeNavigationPageState extends State<HomeNavigationPage>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<HomeNavigationPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<Widget> _pages;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey();
  final GlobalKey<CollectionHomePageState> _collectionHomePageKey = GlobalKey();
  final _configurationService = injector<ConfigurationService>();
  late Timer? _timer;
  final _clientTokenService = injector<ClientTokenService>();
  final _metricClientService = injector<MetricClientService>();
  final _notificationService = injector<NotificationService>();
  final _playListService = injector<PlaylistService>();
  final _remoteConfig = injector<RemoteConfigService>();

  StreamSubscription<FGBGType>? _fgbgSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  Future<void> _onItemTapped(int index) async {
    if (index < _pages.length) {
      if (_selectedIndex == index) {
        if (index == 0) {
          _homePageKey.currentState?.scrollToTop();
        }
      }
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(_selectedIndex);
      if (index == 0) {
        unawaited(_clientTokenService.refreshTokens());
        unawaited(_playListService.refreshPlayLists());
      }
    } else {
      final currentIndex = _selectedIndex;
      setState(() {
        _selectedIndex = index;
      });
      await UIHelper.showCenterMenu(
        context,
        options: [
          OptionItem(
            title: 'moma_postcard'.tr(),
            icon: const Icon(
              AuIcon.settings,
            ),
            onTap: () {
              Navigator.of(context)
                  .pushReplacementNamed(AppRouter.momaPostcardPage);
            },
          ),
          OptionItem(
            title: 'wallet'.tr(),
            icon: const Icon(
              AuIcon.wallet,
            ),
            onTap: () {
              Navigator.of(context).pushReplacementNamed(AppRouter.walletPage);
            },
          ),
          OptionItem(
            title: 'Settings',
            icon: const Icon(
              AuIcon.settings,
            ),
            onTap: () {
              Navigator.of(context)
                  .pushReplacementNamed(AppRouter.settingsPage);
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
                    .pushReplacementNamed(AppRouter.supportCustomerPage);
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
    unawaited(injector<CustomerSupportService>().getIssuesAndAnnouncement());
    super.initState();
    _selectedIndex = HomeNavigatorTab.COLLECTION.index;
    _pageController = PageController(initialPage: _selectedIndex);

    unawaited(_clientTokenService.refreshTokens());

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      unawaited(_clientTokenService.refreshTokens());
    });

    _pages = <Widget>[
      CollectionHomePage(key: _collectionHomePageKey),
      HomePage(key: _homePageKey),
      MultiBlocProvider(providers: [
        BlocProvider.value(
            value: ExhibitionBloc(injector())..add(GetAllExhibitionsEvent())),
      ], child: const ExhibitionsPage()),
      const ScanQRPage()
    ];

    if (!_configurationService.isReadRemoveSupport()) {
      unawaited(_showRemoveCustomerSupport());
    }
    OneSignal.shared
        .setNotificationWillShowInForegroundHandler(_shouldShowNotifications);
    injector<AuditService>().auditFirstLog();
    OneSignal.shared.setNotificationOpenedHandler((openedResult) {
      Future.delayed(const Duration(milliseconds: 500), () {
        unawaited(_handleNotificationClicked(openedResult.notification));
      });
    });

    if (!widget.fromOnboarding) {
      unawaited(injector<TezosBeaconService>().cleanup());
      unawaited(injector<Wc2Service>().cleanup());
    }
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);

    unawaited(injector<CanvasClientService>().init());
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

  @override
  Future<void> didPopNext() async {
    super.didPopNext();
    unawaited(injector<CustomerSupportService>().getIssuesAndAnnouncement());
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
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_fgbgSubscription?.cancel());
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
            Positioned.fill(
              bottom: 40,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomNavigationBar(context),
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomNavigationBar(BuildContext context) {
    final bottomItems = [
      const FFNavigationBarItem(
        icon: Icon(
          AuIcon.playlists,
          size: 25,
        ),
        label: '',
      ),
      const FFNavigationBarItem(
        icon: Icon(
          AuIcon.set,
          size: 25,
        ),
        label: '',
      ),
      const FFNavigationBarItem(
        icon: Icon(
          AuIcon.controller,
          size: 25,
        ),
        label: '',
      ),
      const FFNavigationBarItem(
        icon: Icon(
          AuIcon.scan,
          size: 25,
        ),
        label: '',
      ),
      FFNavigationBarItem(
        icon: ValueListenableBuilder<List<int>?>(
          valueListenable:
              injector<CustomerSupportService>().numberOfIssuesInfo,
          builder: (BuildContext context, List<int>? numberOfIssuesInfo,
                  Widget? child) =>
              iconWithRedDot(
            icon: const Icon(
              AuIcon.drawer,
              size: 25,
            ),
            padding: const EdgeInsets.only(right: 2, top: 2),
            withReddot: numberOfIssuesInfo != null && numberOfIssuesInfo[1] > 0,
          ),
        ),
        selectedColor: AppColor.disabledColor,
        label: '',
      ),
    ];
    return FFNavigationBar(
      items: bottomItems,
      selectedItemColor: AppColor.white,
      unselectedItemColor: AppColor.disabledColor,
      backgroundColor: AppColor.auGreyBackground,
      onSelectTab: _onItemTapped,
      currentIndex: _selectedIndex,
    );
  }

  Future<void> _shouldShowNotifications(
      OSNotificationReceivedEvent event) async {
    log.info('Receive notification: ${event.notification}');
    final data = event.notification.additionalData;
    if (data == null) {
      return;
    }
    if (_configurationService.isNotificationEnabled() != true) {
      _configurationService.showNotifTip.value = true;
    }

    switch (data['notification_type']) {
      case 'customer_support_new_message':
      case 'customer_support_close_issue':
        final notificationIssueID =
            '${event.notification.additionalData?['issue_id']}';
        injector<CustomerSupportService>().triggerReloadMessages.value += 1;
        unawaited(
            injector<CustomerSupportService>().getIssuesAndAnnouncement());
        if (notificationIssueID == memoryValues.viewingSupportThreadIssueID) {
          event.complete(null);
          return;
        }
        break;

      case 'gallery_new_nft':
      case 'new_postcard_trip':
        unawaited(_clientTokenService.refreshTokens());
        break;
      case 'artwork_created':
      case 'artwork_received':
        break;
    }
    switch (data['notification_type']) {
      case 'customer_support_new_announcement':
        showInfoNotification(
            const Key('Announcement'), 'au_has_announcement'.tr(),
            addOnTextSpan: [
              TextSpan(
                  text: 'tap_to_view'.tr(),
                  style: Theme.of(context).textTheme.ppMori400Green14),
            ], openHandler: () async {
          final announcementID = '${data["id"]}';
          unawaited(_openAnnouncement(announcementID));
        });
        break;
      case 'new_message':
        final groupId = data['group_id'];

        if (!_remoteConfig.getBool(ConfigGroup.viewDetail, ConfigKey.chat)) {
          return;
        }

        final currentGroupId = memoryValues.currentGroupChatId;
        if (groupId != currentGroupId) {
          showNotifications(context, event.notification,
              notificationOpenedHandler: _handleNotificationClicked);
        }
        break;
      default:
        showNotifications(context, event.notification,
            notificationOpenedHandler: _handleNotificationClicked);
    }
    event.complete(null);
  }

  Future<void> _handleNotificationClicked(OSNotification notification) async {
    if (notification.additionalData == null) {
      // Skip handling the notification without data
      return;
    }

    log.info("Tap to notification: ${notification.body ?? "empty"} "
        '\nAdditional data: ${notification.additionalData!}');
    final notificationType = notification.additionalData!['notification_type'];
    unawaited(
        _metricClientService.addEvent(MixpanelEvent.tabNotification, data: {
      'type': notificationType,
    }));
    switch (notificationType) {
      case 'gallery_new_nft':
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        _pageController.jumpToPage(HomeNavigatorTab.COLLECTION.index);
        break;

      case 'customer_support_new_message':
      case 'customer_support_close_issue':
        final issueID = '${notification.additionalData!["issue_id"]}';
        final announcement = await injector<CustomerSupportService>()
            .findAnnouncementFromIssueId(issueID);
        if (!mounted) {
          return;
        }
        unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.supportThreadPage,
          (route) =>
              route.settings.name == AppRouter.homePage ||
              route.settings.name == AppRouter.homePageNoTransition,
          arguments: DetailIssuePayload(
              reportIssueType: '',
              issueID: issueID,
              announcement: announcement),
        ));
        break;
      case 'customer_support_new_announcement':
        final announcementID = '${notification.additionalData!["id"]}';
        unawaited(_openAnnouncement(announcementID));
        break;

      case 'artwork_created':
      case 'artwork_received':
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        _pageController.jumpToPage(HomeNavigatorTab.COLLECTION.index);
        break;
      case 'new_message':
        if (!_remoteConfig.getBool(ConfigGroup.viewDetail, ConfigKey.chat)) {
          return;
        }
        final data = notification.additionalData;
        if (data == null) {
          return;
        }
        final tokenId = data['group_id'];
        final tokens = await injector<NftCollectionDatabase>()
            .assetTokenDao
            .findAllAssetTokensByTokenIDs([tokenId]);
        final owner = tokens.first.owner;
        final isSkip =
            injector<ChatService>().isConnecting(address: owner, id: tokenId);
        if (isSkip) {
          return;
        }
        final GlobalKey<ClaimedPostcardDetailPageState> key = GlobalKey();
        final postcardDetailPayload = PostcardDetailPagePayload(
            [ArtworkIdentity(tokenId, owner)], 0,
            key: key);
        if (!mounted) {
          return;
        }
        unawaited(Navigator.of(context).pushNamed(
            AppRouter.claimedPostcardDetailsPage,
            arguments: postcardDetailPayload));
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
          final state = key.currentState;
          final assetToken =
              key.currentContext?.read<PostcardDetailBloc>().state.assetToken;
          if (state != null && assetToken != null) {
            unawaited(state.gotoChatThread(key.currentContext!));
            timer.cancel();
          }
        });

        break;
      case 'new_postcard_trip':
      case 'postcard_share_expired':
        final data = notification.additionalData;
        if (data == null) {
          return;
        }
        final indexID = data['indexID'];
        final tokens = await injector<NftCollectionDatabase>()
            .assetTokenDao
            .findAllAssetTokensByTokenIDs([indexID]);
        if (tokens.isEmpty) {
          return;
        }
        final owner = tokens.first.owner;
        final postcardDetailPayload = PostcardDetailPagePayload(
          [ArtworkIdentity(indexID, owner)],
          0,
          useIndexer: true,
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        unawaited(Navigator.of(context).pushNamed(
            AppRouter.claimedPostcardDetailsPage,
            arguments: postcardDetailPayload));
        break;

      default:
        log.warning('unhandled notification type: $notificationType');
        break;
    }
  }

  Future<void> _openAnnouncement(String announcementID) async {
    log.info('Open announcement: id = $announcementID');
    await injector<CustomerSupportService>().fetchAnnouncement();
    final announcement = await injector<CustomerSupportService>()
        .findAnnouncement(announcementID);
    if (announcement != null) {
      if (!mounted) {
        return;
      }
      unawaited(Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.supportThreadPage,
        (route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition,
        arguments: NewIssuePayload(
          reportIssueType: ReportIssueType.Announcement,
          announcement: announcement,
        ),
      ));
    }
  }

  void _handleBackground() {
    unawaited(_cloudBackup());
    _metricClientService.useAppTimer?.cancel();
  }

  Future<void> _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        unawaited(_handleForeground());
        memoryValues.isForeground = true;
        unawaited(injector<ChatService>().reconnect());
        break;
      case FGBGType.background:
        _handleBackground();
        memoryValues.isForeground = false;
        break;
    }
  }

  Future<void> showAnnouncementNotification(
      AnnouncementLocal announcement) async {
    showInfoNotification(
        const Key('Announcement'), announcement.notificationTitle,
        addOnTextSpan: [
          TextSpan(
              text: 'tap_to_view'.tr(),
              style: Theme.of(context).textTheme.ppMori400Green14),
        ], openHandler: () async {
      final announcementID = announcement.announcementContextId;
      unawaited(_openAnnouncement(announcementID));
    });
  }

  Future<void> announcementNotificationIfNeed() async {
    final announcements =
        (await injector<CustomerSupportService>().getIssuesAndAnnouncement())
            .whereType<AnnouncementLocal>()
            .toList();

    final showAnnouncementInfo =
        _configurationService.getShowAnnouncementNotificationInfo();
    final shouldShowAnnouncements = announcements.where((element) =>
        (element.isMemento6 &&
            !_configurationService
                .getAlreadyClaimedAirdrop(AirdropType.Memento6.seriesId)) &&
        showAnnouncementInfo.shouldShowAnnouncementNotification(element));
    if (shouldShowAnnouncements.isEmpty) {
      return;
    }
    unawaited(Future.forEach<AnnouncementLocal>(shouldShowAnnouncements,
        (announcement) async {
      await showAnnouncementNotification(announcement);
      await _configurationService
          .updateShowAnnouncementNotificationInfo(announcement);
    }));
  }

  Future<void> _handleForeground() async {
    await injector<CustomerSupportService>().fetchAnnouncement();
    unawaited(announcementNotificationIfNeed());
    Timer? useAppTimer = _metricClientService.useAppTimer;
    useAppTimer?.cancel();
    useAppTimer = Timer(USE_APP_MIN_DURATION, () async {
      await _metricClientService.onUseAppInForeground();
    });
    await _remoteConfig.loadConfigs();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _cloudBackup();
    final initialAction = _notificationService.initialAction;
    if (initialAction != null) {
      NotificationService.onActionReceivedMethod(initialAction);
    }
  }

  Future<void> _cloudBackup() async {
    final accountService = injector<AccountService>();
    final backup = injector<BackupService>();
    await backup.backupCloudDatabase(await accountService.getDefaultAccount());
  }
}
