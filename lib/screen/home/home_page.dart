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
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tokens_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/au_cached_manager.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sentry_flutter/sentry_flutter.dart';

class HomePage extends StatefulWidget {
  static const tag = "home";

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver, AfterLayoutMixin<HomePage> {
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  int _cachedImageSize = 0;

  @override
  void initState() {
    super.initState();
    _checkForKeySync();
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController();
    context.read<HomeBloc>().add(RefreshTokensEvent());
    context.read<HomeBloc>().add(ReindexIndexerEvent());
    OneSignal.shared
        .setNotificationWillShowInForegroundHandler(_shouldShowNotifications);
    injector<AuditService>().auditFirstLog();
    OneSignal.shared.setNotificationOpenedHandler((openedResult) {
      Future.delayed(Duration(milliseconds: 500), () {
        _handleNotificationClicked(openedResult.notification);
      });
    });
    memoryValues.inGalleryView = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    injector<FeralFileService>().completeDelayedFFConnections();
    _cloudBackup();
    _handleForeground();
    injector<AutonomyService>().postLinkedAddresses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _fgbgSubscription?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() async {
    super.didPopNext();
    final connectivityResult = await (Connectivity().checkConnectivity());

    context.read<HomeBloc>().add(RefreshTokensEvent());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        context.read<HomeBloc>().add(ReindexIndexerEvent());
      });
    }
    memoryValues.inGalleryView = true;
  }

  @override
  void didPushNext() {
    memoryValues.inGalleryView = false;
    super.didPushNext();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeBloc>().state;
    final tokens = state.tokens;

    final shouldShowMainView = tokens != null && tokens.isNotEmpty;

    final Widget assetsWidget =
        shouldShowMainView ? _assetsWidget(tokens!) : _emptyGallery();

    return PrimaryScrollController(
      controller: _controller,
      child: Scaffold(
        body: Stack(
          fit: StackFit.loose,
          children: [
            assetsWidget,
            if (injector<ConfigurationService>().getUXGuideStep() != null) ...[
              PenroseTopBarView(true, _controller),
            ],
            if (state.fetchTokenState == ActionState.loading) ...[
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).padding.top + 120, 20, 0),
                  child: CupertinoActivityIndicator(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyGallery() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        SizedBox(height: 160),
        Text(
          "Gallery",
          style: appTextTheme.headline1,
        ),
        SizedBox(height: 24.0),
        Text(
          "Your gallery is empty for now.",
          style: appTextTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _assetsWidget(List<AssetToken> tokens) {
    final tokenIDs = tokens.map((element) => element.id).toList();

    const int cellPerRow = 3;
    const double cellSpacing = 3.0;

    if (_cachedImageSize == 0) {
      final estimatedCellWidth =
          MediaQuery.of(context).size.width / cellPerRow -
              cellSpacing * (cellPerRow - 1);
      _cachedImageSize = (estimatedCellWidth * 3).ceil();
    }
    List<Widget> sources;
    sources = [
      SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cellPerRow,
          crossAxisSpacing: cellSpacing,
          mainAxisSpacing: cellSpacing,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final asset = tokens[index];
            final ext = p.extension(asset.galleryThumbnailURL!);

            return GestureDetector(
              child: Hero(
                tag: asset.id,
                child: ext == ".svg"
                    ? SvgPicture.network(asset.galleryThumbnailURL!,
                        placeholderBuilder: (context) =>
                            Container(color: Color.fromRGBO(227, 227, 227, 1)))
                    : CachedNetworkImage(
                        imageUrl: asset.galleryThumbnailURL!,
                        fit: BoxFit.cover,
                        memCacheHeight: _cachedImageSize,
                        memCacheWidth: _cachedImageSize,
                        cacheManager: injector<AUCacheManager>(),
                        placeholder: (context, index) =>
                            Container(color: Color.fromRGBO(227, 227, 227, 1)),
                        placeholderFadeInDuration: Duration(milliseconds: 300),
                        errorWidget: (context, url, error) => Container(
                            color: Color.fromRGBO(227, 227, 227, 1),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/images/image_error.svg',
                                width: 75,
                                height: 75,
                              ),
                            )),
                      ),
              ),
              onTap: () {
                final index = tokens.indexOf(asset);
                final payload = ArtworkDetailPayload(tokenIDs, index);

                if (injector<ConfigurationService>()
                    .isImmediatePlaybackEnabled()) {
                  Navigator.of(context).pushNamed(AppRouter.artworkPreviewPage,
                      arguments: payload);
                } else {
                  Navigator.of(context).push(
                    AppRouter.onGenerateRoute(RouteSettings(
                        name: AppRouter.artworkDetailsPage,
                        arguments: payload)),
                  );
                }
              },
            );
          },
          childCount: tokens.length,
        ),
      ),
    ];

    sources.insert(
      0,
      SliverToBoxAdapter(
        child: Container(
          height: 168.0,
        ),
      ),
    );

    return CustomScrollView(
      slivers: sources,
      controller: _controller,
    );
  }

  Future<void> _cloudBackup() async {
    final backup = injector<BackupService>();
    await backup.backupCloudDatabase();
  }

  Future<void> _checkForKeySync() async {
    final cloudDatabase = injector<CloudDatabase>();
    final defaultAccounts = await cloudDatabase.personaDao.getDefaultPersonas();

    if (defaultAccounts.length >= 2) {
      Navigator.of(context).pushNamed(AppRouter.keySyncPage);
    }
  }

  void _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        _handleForeground();
        break;
      case FGBGType.background:
        _handleBackground();
        break;
    }
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
        if (notificationIssueID == memoryValues.viewingSupportThreadIssueID) {
          injector<CustomerSupportService>().triggerReloadMessages.value += 1;
          injector<CustomerSupportService>().getIssues();
          event.complete(null);
          return;
        }
        break;

      case 'gallery_new_nft':
        context.read<HomeBloc>().add(RefreshTokensEvent());
        break;
    }

    showNotifications(event.notification,
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
        break;

      case "customer_support_new_message":
      case "customer_support_close_issue":
        final issueID = '${notification.additionalData!["issue_id"]}';
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.supportThreadPage,
            ((route) =>
                route.settings.name == AppRouter.homePage ||
                route.settings.name == AppRouter.homePageNoTransition),
            arguments:
                DetailIssuePayload(reportIssueType: "", issueID: '$issueID'));
        break;
      default:
        log.warning("unhandled notification type: $notificationType");
        break;
    }
  }

  void _handleForeground() async {
    memoryValues.inForegroundAt = DateTime.now();
    await injector<ConfigurationService>().reload();
    try {
      await injector<SettingsDataService>().restoreSettingsData();
    } catch (exception) {
      if (exception is DioError && exception.response?.statusCode == 404) {
        // if there is no backup, upload one.
        await injector<SettingsDataService>().backup();
      } else {
        Sentry.captureException(exception);
      }
    }
    Future.delayed(const Duration(milliseconds: 3500), () async {
      context.read<HomeBloc>().add(RefreshTokensEvent());
      context.read<HomeBloc>().add(ReindexIndexerEvent());
      await injector<AWSService>()
          .storeEventWithDeviceData("device_foreground");
    });

    injector<VersionService>().checkForUpdate(true);
    injector<CustomerSupportService>().getIssues();
    injector<CustomerSupportService>().processMessages();
  }

  void _handleBackground() {
    injector<AWSService>().storeEventWithDeviceData("device_background");
    injector<TokensService>().disposeIsolate();
    _cloudBackup();
    FileLogger.shrinkLogFileIfNeeded();
  }
}
