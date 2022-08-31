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
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class HomePage extends StatefulWidget {
  static const tag = "home";

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver, AfterLayoutMixin<HomePage> {
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  int _cachedImageSize = 0;

  Future<List<String>> getAddresses() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddresses();
  }

  Future<List<String>> getManualTokenIds() async {
    final cloudDb = injector<CloudDatabase>();
    final tokenIndexerIDs = (await cloudDb.connectionDao.getConnectionsByType(
            ConnectionType.manuallyIndexerTokenID.rawValue))
        .map((e) => e.key)
        .toList();
    return tokenIndexerIDs;
  }

  @override
  void initState() {
    super.initState();
    _checkForKeySync();
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController();
    final accountService = injector<AccountService>();
    Future.wait([
      getAddresses(),
      getManualTokenIds(),
      accountService.getHiddenAddresses()
    ]).then((value) {
      final addresses = value[0];
      final indexerIds = value[1];
      final hiddenAddresses = value[2];
      final nftBloc = context.read<NftCollectionBloc>();
      nftBloc.add(UpdateHiddenTokens(ownerAddresses: hiddenAddresses));
      nftBloc.add(
          RefreshTokenEvent(addresses: addresses, debugTokens: indexerIds));
      nftBloc.add(RequestIndexEvent(addresses));
      context.read<HomeBloc>().add(CheckReviewAppEvent());
    });
    OneSignal.shared
        .setNotificationWillShowInForegroundHandler(_shouldShowNotifications);
    injector<AuditService>().auditFirstLog();
    OneSignal.shared.setNotificationOpenedHandler((openedResult) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClicked(openedResult.notification);
      });
    });
    injector<IAPService>().setup();
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

    if (!mounted) return;

    Future.wait([getAddresses(), getManualTokenIds()]).then((value) {
      final addresses = value[0];
      final indexerIds = value[1];
      context.read<NftCollectionBloc>().add(
          RefreshTokenEvent(addresses: addresses, debugTokens: indexerIds));
    });
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Future.delayed(const Duration(milliseconds: 1000), () async {
        context
            .read<NftCollectionBloc>()
            .add(RequestIndexEvent(await getAddresses()));
      });
    }
    memoryValues.inGalleryView = true;
  }

  @override
  void didPushNext() {
    memoryValues.inGalleryView = false;
    super.didPushNext();
  }

  void _onTokensUpdate(List<AssetToken> tokens) async {
    final artistIds = tokens
        .map((e) => e.artistID)
        .where((value) => value?.isNotEmpty == true)
        .map((e) => e as String)
        .toList();
    injector<FeedService>().refreshFollowings(artistIds);

    // Check if there is any Tezos token in the list
    List<String> allAccountNumbers =
        await injector<AccountService>().getAllAddresses();
    final hashedAddresses = allAccountNumbers.fold(
        0, (int previousValue, element) => previousValue + element.hashCode);

    if (injector<ConfigurationService>().sentTezosArtworkMetricValue() !=
            hashedAddresses &&
        tokens.any((asset) =>
            asset.blockchain == Blockchain.TEZOS.name.toLowerCase())) {
      await injector<AWSService>()
          .storeEventWithDeviceData("collection_has_tezos");
      injector<ConfigurationService>()
          .setSentTezosArtworkMetric(hashedAddresses);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentWidget =
        BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
            builder: (context, state) {
      final hiddenTokens =
          injector<ConfigurationService>().getTempStorageHiddenTokenIDs();
      return NftCollectionGrid(
        state: state.state,
        tokens: state.tokens
            .where((element) => !hiddenTokens.contains(element.id))
            .toList(),
        loadingIndicatorBuilder: _loadingView,
        emptyGalleryViewBuilder: _emptyGallery,
        customGalleryViewBuilder: (context, tokens) =>
            _assetsWidget(context, tokens),
      );
    }, listener: (context, state) async {
      log.info("[NftCollectionBloc] State update $state");
      if (state.state == NftLoadingState.done) {
        _onTokensUpdate(state.tokens);
      }
    });

    return PrimaryScrollController(
      controller: _controller,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              contentWidget,
              PenroseTopBarView(
                _controller,
                PenroseTopBarViewStyle.main,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingView(BuildContext context) {
    return Center(
        child: Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(0, 32, 0, 48),
          child: autonomyLogo,
        ),
        loadingIndicator(),
      ],
    ));
  }

  Widget _emptyGallery(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: ResponsiveLayout.getPadding,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(0, 32, 0, 48),
          child: autonomyLogo,
        ),
        Text(
          "collection".tr(),
          style: theme.textTheme.headline1,
        ),
        const SizedBox(height: 24.0),
        Text(
          "collection_empty_now".tr(),
          //"Your collection is empty for now.",
          style: theme.textTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _assetsWidget(BuildContext context, List<AssetToken> tokens) {
    tokens.sort((a, b) {
      final aSource = a.source?.toLowerCase() ?? INDEXER_UNKNOWN_SOURCE;
      final bSource = b.source?.toLowerCase() ?? INDEXER_UNKNOWN_SOURCE;

      if (aSource == INDEXER_UNKNOWN_SOURCE &&
          bSource == INDEXER_UNKNOWN_SOURCE) {
        return b.lastActivityTime.compareTo(a.lastActivityTime);
      }

      if (aSource == INDEXER_UNKNOWN_SOURCE) return 1;
      if (bSource == INDEXER_UNKNOWN_SOURCE) return -1;

      return b.lastActivityTime.compareTo(a.lastActivityTime);
    });

    final tokenIDs = tokens.map((element) => element.id).toList();

    const int cellPerRowPhone = 3;
    const int cellPerRowTablet = 6;
    const double cellSpacing = 3.0;
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    if (_cachedImageSize == 0) {
      final estimatedCellWidth =
          MediaQuery.of(context).size.width / cellPerRow -
              cellSpacing * (cellPerRow - 1);
      _cachedImageSize = (estimatedCellWidth * 3).ceil();
    }
    List<Widget> sources;
    sources = [
      SliverToBoxAdapter(
          child: Container(
        padding: const EdgeInsets.fromLTRB(0, 32, 0, 48),
        child: autonomyLogo,
      )),
      SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cellPerRow,
          crossAxisSpacing: cellSpacing,
          mainAxisSpacing: cellSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final asset = tokens[index];

            return GestureDetector(
              child:
                  tokenGalleryThumbnailWidget(context, asset, _cachedImageSize),
              onTap: () {
                final index = tokens.indexOf(asset);
                final payload = ArtworkDetailPayload(tokenIDs, index);

                if (injector<ConfigurationService>()
                    .isImmediateInfoViewEnabled()) {
                  Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
                      arguments: payload);
                } else {
                  Navigator.of(context).pushNamed(AppRouter.artworkPreviewPage,
                      arguments: payload);
                }
              },
            );
          },
          childCount: tokens.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ];

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
      if (!mounted) return;
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
        injector<CustomerSupportService>().triggerReloadMessages.value += 1;
        injector<CustomerSupportService>().getIssues();
        if (notificationIssueID == memoryValues.viewingSupportThreadIssueID) {
          event.complete(null);
          return;
        }
        break;

      case 'gallery_new_nft':
        Future.wait([getAddresses(), getManualTokenIds()]).then((value) {
          final addresses = value[0];
          final indexerIds = value[1];
          context.read<NftCollectionBloc>().add(
              RefreshTokenEvent(addresses: addresses, debugTokens: indexerIds));
        });
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
                DetailIssuePayload(reportIssueType: "", issueID: issueID));
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
      final addresses = await getAddresses();
      final manualTokenIds = await getManualTokenIds();
      final hiddenAddress =
          await injector<AccountService>().getHiddenAddresses();
      final nftBloc = context.read<NftCollectionBloc>();
      nftBloc.add(UpdateHiddenTokens(ownerAddresses: hiddenAddress));
      nftBloc.add(
          RefreshTokenEvent(addresses: addresses, debugTokens: manualTokenIds));
      nftBloc.add(RequestIndexEvent(addresses));
      await injector<AWSService>()
          .storeEventWithDeviceData("device_foreground");
    });

    injector<VersionService>().checkForUpdate();

    // Reload token in Isolate
    final jwtToken =
        (await injector<AuthService>().getAuthToken(forceRefresh: true))
            .jwtToken;
    injector<FeedService>().refreshJWTToken(jwtToken);

    injector<CustomerSupportService>().getIssues();
    injector<CustomerSupportService>().processMessages();
  }

  void _handleBackground() {
    injector<AWSService>().storeEventWithDeviceData("device_background");
    _cloudBackup();
    FileLogger.shrinkLogFileIfNeeded();
  }
}
