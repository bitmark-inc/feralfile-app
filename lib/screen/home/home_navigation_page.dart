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
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/accounts/accounts_bloc.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_bloc.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_page.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_state.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/screen/wallet/wallet_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/user_agent_utils.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeNavigationPage extends StatefulWidget {
  final bool fromOnboarding;

  const HomeNavigationPage({Key? key, this.fromOnboarding = false})
      : super(key: key);

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
  late List<BottomNavigationBarItem> _bottomItems;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey();
  final GlobalKey<EditorialPageState> _editorialPageStateKey = GlobalKey();

  StreamSubscription<FGBGType>? _fgbgSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  void _onItemTapped(int index) {
    if (index != _pages.length) {
      final feedService = injector<FeedService>();
      if (_selectedIndex == index) {
        if (index == 1) {
          _homePageKey.currentState?.scrollToTop();
        }
        if (index == 0) {
          _editorialPageStateKey.currentState?.scrollToTop();
        }
      }
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(_selectedIndex);
      if (index == 1) {
        _homePageKey.currentState
            ?.refreshTokens()
            .then((value) => feedService.checkNewFeeds());
      } else if (index == 0) {
        _homePageKey.currentState
            ?.refreshTokens()
            .then((value) => feedService.checkNewFeeds());
        final metricClient = injector<MetricClientService>();
        if (injector<ConfigurationService>().hasFeed()) {
          final feedBloc = context.read<FeedBloc>();
          feedBloc.add(OpenFeedEvent());
          feedBloc.add(GetFeedsEvent());
          metricClient.addEvent(MixpanelEvent.viewDiscovery);
          metricClient.timerEvent(MixpanelEvent.timeViewDiscovery);
        } else {
          metricClient.addEvent(MixpanelEvent.viewEditorial);
          metricClient.timerEvent(MixpanelEvent.timeViewEditorial);
        }
        context.read<EditorialBloc>().add(GetEditorialEvent());
      }
    } else {
      UIHelper.showDrawerAction(
        context,
        options: [
          OptionItem(
            title: 'Scan',
            icon: const Icon(
              AuIcon.scan,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(
                AppRouter.scanQRPage,
                arguments: ScannerItem.GLOBAL,
              );
            },
          ),
          OptionItem(
              title: 'Settings',
              icon: const Icon(
                AuIcon.settings,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRouter.settingsPage);
              }),
          OptionItem(
              title: 'Help',
              icon: ValueListenableBuilder<List<int>?>(
                valueListenable:
                    injector<CustomerSupportService>().numberOfIssuesInfo,
                builder: (BuildContext context, List<int>? numberOfIssuesInfo,
                    Widget? child) {
                  return iconWithRedDot(
                    icon: const Icon(
                      AuIcon.help,
                    ),
                    padding: const EdgeInsets.only(right: 2, top: 2),
                    withReddot: (numberOfIssuesInfo != null &&
                        numberOfIssuesInfo[1] > 0),
                  );
                },
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRouter.supportCustomerPage);
              }),
        ],
      );
    }
  }

  @override
  void initState() {
    injector<CustomerSupportService>().getIssuesAndAnnouncement();
    super.initState();
    if (memoryValues.homePageInitialTab != HomePageTab.DISCOVER) {
      _selectedIndex = HomeNavigatorTab.COLLECTION.index;
    } else {
      _selectedIndex = HomeNavigatorTab.DISCOVER.index;
    }
    _pageController = PageController(initialPage: _selectedIndex);

    final feedService = injector<FeedService>();
    _homePageKey.currentState
        ?.refreshTokens()
        .then((value) => feedService.checkNewFeeds());
    _pages = <Widget>[
      ValueListenableBuilder<bool>(
          valueListenable: injector<FeedService>().hasFeed,
          builder: (BuildContext context, bool isShowDiscover, Widget? child) {
            return EditorialPage(
                key: _editorialPageStateKey, isShowDiscover: isShowDiscover);
          }),
      HomePage(key: _homePageKey),
      MultiBlocProvider(
        providers: [
          BlocProvider.value(
              value: AccountsBloc(injector(), injector<CloudDatabase>(),
                  injector(), injector<AuditService>(), injector())),
        ],
        child: const WalletPage(),
      ),
    ];
    _bottomItems = [
      BottomNavigationBarItem(
        icon: ValueListenableBuilder<int>(
            valueListenable: injector<FeedService>().unviewedCount,
            builder: (BuildContext context, int unreadCount, Widget? child) {
              if (unreadCount > 0) {
                context.read<FeedBloc>().add(GetFeedsEvent());
              }
              return Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: Icon(
                      AuIcon.discover,
                      size: 25,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    Positioned(
                      left: 28,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 3,
                          right: 3,
                        ),
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        constraints: const BoxConstraints(minWidth: 11),
                        child: Center(
                          child: Text(
                            "$unreadCount",
                            style: Theme.of(context)
                                .textTheme
                                .ppMori700White12
                                .copyWith(
                                  fontSize: 8,
                                ),
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              );
            }),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(
          AuIcon.playlists,
          size: 25,
        ),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(
          AuIcon.wallet,
          size: 25,
        ),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: ValueListenableBuilder<List<int>?>(
          valueListenable:
              injector<CustomerSupportService>().numberOfIssuesInfo,
          builder: (BuildContext context, List<int>? numberOfIssuesInfo,
              Widget? child) {
            return iconWithRedDot(
              icon: const Icon(
                AuIcon.drawer,
                size: 25,
              ),
              padding: const EdgeInsets.only(right: 2, top: 2),
              withReddot:
                  (numberOfIssuesInfo != null && numberOfIssuesInfo[1] > 0),
            );
          },
        ),
        label: '',
      ),
    ];

    final configService = injector<ConfigurationService>();
    if (!configService.isReadRemoveSupport()) {
      _showRemoveCustomerSupport();
    }
    OneSignal.shared
        .setNotificationWillShowInForegroundHandler(_shouldShowNotifications);
    injector<AuditService>().auditFirstLog();
    OneSignal.shared.setNotificationOpenedHandler((openedResult) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClicked(openedResult.notification);
      });
    });

    if (!widget.fromOnboarding) {
      injector<TezosBeaconService>().cleanup();
      injector<Wc2Service>().cleanup();
    }
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
  }

  @override
  void didPopNext() async {
    super.didPopNext();
    injector<CustomerSupportService>().getIssuesAndAnnouncement();
  }

  _showRemoveCustomerSupport() async {
    final device = DeviceInfo.instance;
    if (!(await device.isSupportOS())) {
      final dio = Dio(BaseOptions(
        baseUrl: "https://raw.githubusercontent.com",
        connectTimeout: 2000,
      ));
      final data = await dio.get<String>(REMOVE_CUSTOMER_SUPPORT);
      if (data.statusCode == 200) {
        final Uri uri = Uri.parse(AUTONOMY_CLIENT_GITHUB_LINK);
        String? gitHubContent = data.data ?? "";
        Future.delayed(const Duration(seconds: 3), () {
          showInAppNotifications(
              context, "au_has_announcement".tr(), "remove_customer_support",
              notificationOpenedHandler: () {
            UIHelper.showCenterSheet(context,
                content: Markdown(
                  key: const Key("remove_customer_support"),
                  data: gitHubContent,
                  softLineBreak: true,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(0),
                  styleSheet: markDownAnnouncementStyle(context),
                ),
                actionButton: "follow_github".tr(),
                actionButtonOnTap: () =>
                    launchUrl(uri, mode: LaunchMode.externalApplication),
                exitButtonOnTap: () {
                  injector<ConfigurationService>().readRemoveSupport(true);
                  Navigator.of(context).pop();
                },
                exitButton: "i_understand_".tr());
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _fgbgSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        unselectedItemColor: theme.disabledColor,
        selectedItemColor: theme.primaryColor,
        backgroundColor: theme.colorScheme.background.withOpacity(0.95),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: _bottomItems,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
    );
  }

  void _shouldShowNotifications(OSNotificationReceivedEvent event) {
    log.info("Receive notification: ${event.notification}");
    final data = event.notification.additionalData;
    if (data == null) return;
    final configurationService = injector<ConfigurationService>();
    if (configurationService.isNotificationEnabled() != true) {
      injector<ConfigurationService>().showNotifTip.value = true;
    }

    switch (data['notification_type']) {
      case "customer_support_new_message":
      case "customer_support_close_issue":
        final notificationIssueID =
            '${event.notification.additionalData?['issue_id']}';
        injector<CustomerSupportService>().triggerReloadMessages.value += 1;
        injector<CustomerSupportService>().getIssuesAndAnnouncement();
        if (notificationIssueID == memoryValues.viewingSupportThreadIssueID) {
          event.complete(null);
          return;
        }
        break;

      case 'gallery_new_nft':
        _homePageKey.currentState?.refreshTokens();
        break;
      case "artwork_created":
      case "artwork_received":
        injector<FeedService>().checkNewFeeds();
        context.read<FeedBloc>().add(GetFeedsEvent());
        break;
    }
    if (data['notification_type'] == "customer_support_new_announcement") {
      showInfoNotification(
          const Key("Announcement"), "au_has_announcement".tr(),
          addOnTextSpan: [
            TextSpan(
                text: "tap_to_view".tr(),
                style: Theme.of(context).textTheme.ppMori400Green14),
          ], openHandler: () async {
        final announcementID = '${data["id"]}';
        _openAnnouncement(announcementID);
      });
    } else {
      showNotifications(context, event.notification,
          notificationOpenedHandler: _handleNotificationClicked);
    }
    event.complete(null);
  }

  void _handleNotificationClicked(OSNotification notification) async {
    if (notification.additionalData == null) {
      // Skip handling the notification without data
      return;
    }

    log.info(
        "Tap to notification: ${notification.body ?? "empty"} \nAdditional data: ${notification.additionalData!}");

    final notificationType = notification.additionalData!["notification_type"];
    switch (notificationType) {
      case "gallery_new_nft":
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        _pageController.jumpToPage(HomeNavigatorTab.COLLECTION.index);
        break;

      case "customer_support_new_message":
      case "customer_support_close_issue":
        final issueID = '${notification.additionalData!["issue_id"]}';
        final announcement = await injector<CustomerSupportService>()
            .findAnnouncementFromIssueId(issueID);
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.supportThreadPage,
          ((route) =>
              route.settings.name == AppRouter.homePage ||
              route.settings.name == AppRouter.homePageNoTransition),
          arguments: DetailIssuePayload(
              reportIssueType: "",
              issueID: issueID,
              announcement: announcement),
        );
        break;
      case "customer_support_new_announcement":
        final announcementID = '${notification.additionalData!["id"]}';
        _openAnnouncement(announcementID);
        break;

      case "artwork_created":
      case "artwork_received":
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        memoryValues.homePageInitialTab = HomePageTab.DISCOVER;
        _pageController.jumpToPage(HomeNavigatorTab.DISCOVER.index);
        final metricClient = injector<MetricClientService>();
        metricClient.addEvent(MixpanelEvent.tabNotification, data: {
          'type': notificationType,
          'body': notification.body,
        });
        break;
      default:
        log.warning("unhandled notification type: $notificationType");
        break;
    }
  }

  _openAnnouncement(String announcementID) async {
    log.info("Open announcement: id = $announcementID");
    await injector<CustomerSupportService>().fetchAnnouncement();
    final announcement = await injector<CustomerSupportService>()
        .findAnnouncement(announcementID);
    if (announcement != null) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.supportThreadPage,
        ((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition),
        arguments: NewIssuePayload(
          reportIssueType: ReportIssueType.Announcement,
          announcement: announcement,
        ),
      );
    }
  }

  void _handleBackground() {
    _cloudBackup();
  }

  void _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        break;
      case FGBGType.background:
        _handleBackground();
        break;
    }
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _cloudBackup();
  }

  Future<void> _cloudBackup() async {
    final accountService = injector<AccountService>();
    final backup = injector<BackupService>();
    await backup.backupCloudDatabase(await accountService.getDefaultAccount());
  }
}
