//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_bloc.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_page.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_state.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class HomeNavigationPage extends StatefulWidget {
  const HomeNavigationPage({Key? key}) : super(key: key);

  @override
  State<HomeNavigationPage> createState() => _HomeNavigationPageState();
}

class _HomeNavigationPageState extends State<HomeNavigationPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<Widget> _pages;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey();

  void _onItemTapped(int index) {
    if (index != 2) {
      if (_selectedIndex == index && index == 0) {
        _homePageKey.currentState?.scrollToTop();
      }
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(_selectedIndex);
      if (index == 0) {
        final feedService = injector<FeedService>();
        _homePageKey.currentState
            ?.refreshTokens()
            .then((value) => feedService.checkNewFeeds());
      } else {
        final metricClient = injector<MetricClientService>();
        if (injector<ConfigurationService>().hasFeed()) {
          final feedBloc = context.read<FeedBloc>();
          feedBloc.add(OpenFeedEvent());
          feedBloc.add(GetFeedsEvent());
          metricClient.addEvent(MixpanelEvent.viewDiscovery);
        } else {
          metricClient.addEvent(MixpanelEvent.viewEditorial);
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
              icon: const Icon(
                AuIcon.help,
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
    super.initState();
    if (memoryValues.homePageInitialTab != HomePageTab.HOME) {
      _selectedIndex = 1;
    } else {
      _selectedIndex = 0;
    }
    _pageController = PageController(initialPage: _selectedIndex);
    _pages = <Widget>[
      HomePage(key: _homePageKey),
      ValueListenableBuilder<bool>(
          valueListenable: injector<FeedService>().hasFeed,
          builder: (BuildContext context, bool isShowDiscover, Widget? child) {
            return EditorialPage(isShowDiscover: isShowDiscover);
          }),
    ];

    OneSignal.shared
        .setNotificationWillShowInForegroundHandler(_shouldShowNotifications);
    injector<AuditService>().auditFirstLog();
    OneSignal.shared.setNotificationOpenedHandler((openedResult) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClicked(openedResult.notification);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        backgroundColor: theme.backgroundColor.withOpacity(0.95),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(
              AuIcon.collection,
              size: 25,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<int>(
                valueListenable: injector<FeedService>().unviewedCount,
                builder:
                    (BuildContext context, int unreadCount, Widget? child) {
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
                                style:
                                    theme.textTheme.ppMori700White12.copyWith(
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
              AuIcon.drawer,
              size: 25,
            ),
            label: '',
          ),
        ],
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

    switch (data['notification_type']) {
      case "customer_support_new_message":
      case "customer_support_close_issue":
        final notificationIssueID =
            '${event.notification.additionalData?['issue_id']}';
        injector<CustomerSupportService>().triggerReloadMessages.value += 1;
        injector<CustomerSupportService>().getIssues();
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

    showNotifications(context, event.notification,
        notificationOpenedHandler: _handleNotificationClicked);
    event.complete(null);
  }

  void _handleNotificationClicked(OSNotification notification) {
    if (notification.additionalData == null) {
      // Skip handling the notification without data
      return;
    }

    log.info(
        "Tap to notification: ${notification.body ?? "empty"} \nAddtional data: ${notification.additionalData!}");

    final notificationType = notification.additionalData!["notification_type"];
    switch (notificationType) {
      case "gallery_new_nft":
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        _pageController.jumpToPage(0);
        break;

      case "customer_support_new_message":
      case "customer_support_close_issue":
        final issueID = '${notification.additionalData!["issue_id"]}';
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.supportThreadPage,
          ((route) =>
              route.settings.name == AppRouter.homePage ||
              route.settings.name == AppRouter.homePageNoTransition),
          arguments: DetailIssuePayload(reportIssueType: "", issueID: issueID),
        );
        break;

      case "artwork_created":
      case "artwork_received":
        Navigator.of(context).popUntil((route) =>
            route.settings.name == AppRouter.homePage ||
            route.settings.name == AppRouter.homePageNoTransition);
        _onItemTapped(1);
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
}
