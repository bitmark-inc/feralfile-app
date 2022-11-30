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
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/screen/wallet_connect/wc_connect_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/audit_service.dart';
import 'package:autonomy_flutter/service/auth_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/backup_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/mixPanel_client_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/pending_token_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/tezos_beacon_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/service/wallet_connect_service.dart';
import 'package:autonomy_flutter/service/wc2_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/inapp_notifications.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/penrose_top_bar_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wallet_connect/models/wc_peer_meta.dart';

import '../../util/token_ext.dart';

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
  late MetricClientService metricClient;
  late MixPanelClientService mixPanelClient;
  int _cachedImageSize = 0;

  ValueNotifier<List<PlayListModel>?> playlists = ValueNotifier([]);

  Future<List<String>> getAddresses() async {
    final accountService = injector<AccountService>();
    return await accountService.getAllAddresses();
  }

  Future<List<PlayListModel>?> getPlaylist() async {
    final configurationService = injector.get<ConfigurationService>();
    if (configurationService.isDemoArtworksMode()) {
      return injector<VersionService>().getDemoAccountFromGithub();
    }
    return configurationService.getPlayList();
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
    metricClient = injector.get<MetricClientService>();
    mixPanelClient = injector<MixPanelClientService>();
    _checkForKeySync();
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController();
    _refreshTokens();
    context.read<HomeBloc>().add(CheckReviewAppEvent());
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
    injector<TezosBeaconService>().cleanup();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() async {
    super.didPopNext();
    final connectivityResult = await (Connectivity().checkConnectivity());
    _refreshTokens();
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (!mounted) return;
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
      metricClient.addEvent("collection_has_tezos");
      injector<ConfigurationService>()
          .setSentTezosArtworkMetric(hashedAddresses);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentWidget =
        BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
            builder: (context, state) {
      final hiddenTokens =
          injector<ConfigurationService>().getTempStorageHiddenTokenIDs();
      final sentArtworks =
          injector<ConfigurationService>().getRecentlySentToken();
      final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);
      return NftCollectionGrid(
        state: state.state,
        tokens: state.tokens
            .where((element) =>
                !hiddenTokens.contains(element.id) &&
                !sentArtworks.any((e) => e.isHidden(
                    tokenID: element.id,
                    address: element.ownerAddress,
                    timestamp: expiredTime)))
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

    return BlocListener<UpgradesBloc, UpgradeState>(
      listener: (context, state) {
        ConfigurationService config = injector<ConfigurationService>();
        WCPeerMeta? peerMeta = config.getTVConnectPeerMeta();
        int? id = config.getTVConnectID();
        if (peerMeta != null || id != null) {
          if (state.status == IAPProductStatus.trial ||
              state.status == IAPProductStatus.completed) {
            injector<NavigationService>().navigateTo(AppRouter.tvConnectPage,
                arguments: WCConnectPageArgs(id!, peerMeta!));
            config.deleteTVConnectData();
          } else if (state.status != IAPProductStatus.loading &&
              state.status != IAPProductStatus.pending) {
            injector<WalletConnectService>().rejectRequest(peerMeta!, id!);
            config.deleteTVConnectData();
          }
        }
      },
      child: PrimaryScrollController(
        controller: _controller,
        child: Scaffold(
          backgroundColor: theme.backgroundColor,
          body: Stack(
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
          padding: const EdgeInsets.fromLTRB(0, 72, 0, 48),
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
          padding: const EdgeInsets.fromLTRB(0, 72, 0, 48),
          child: autonomyLogo,
        ),
        Text(
          "collection_empty_now".tr(),
          //"Your collection is empty for now.",
          style: theme.textTheme.bodyText1,
        ),
      ],
    );
  }

  Widget _assetsWidget(BuildContext context, List<AssetToken> tokens) {
    tokens.sortToken();
    final accountIdentities = tokens
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => ArtworkIdentity(element.id, element.ownerAddress))
        .toList();

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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(0, 72, 0, 30),
              child: autonomyLogo,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                height: 68,
                child: ValueListenableBuilder(
                  valueListenable: playlists,
                  builder: (context, value, child) => ListPlaylistWidget(
                    playlists: playlists.value,
                    onUpdateList: () async {
                      if (injector
                          .get<ConfigurationService>()
                          .isDemoArtworksMode()) return;
                      await injector
                          .get<ConfigurationService>()
                          .setPlayList(playlists.value, override: true);
                      injector.get<SettingsDataService>().backup();
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
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
              child: asset.pending == true && !asset.hasMetadata
                  ? PendingTokenWidget(
                      thumbnail: asset.galleryThumbnailURL,
                      tokenId: asset.tokenId,
                    )
                  : tokenGalleryThumbnailWidget(
                      context,
                      asset,
                      _cachedImageSize,
                    ),
              onTap: () {
                if (asset.pending == true && !asset.hasMetadata) return;

                final index = tokens
                    .where((e) => e.pending != true || e.hasMetadata)
                    .toList()
                    .indexOf(asset);
                final payload = ArtworkDetailPayload(accountIdentities, index);

                if (injector<ConfigurationService>()
                    .isImmediateInfoViewEnabled()) {
                  Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
                      arguments: payload);
                } else {
                  Navigator.of(context).pushNamed(AppRouter.artworkPreviewPage,
                      arguments: payload);
                }

                mixPanelClient
                    .trackEvent("view_artwork", data: {"id": asset.id});
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
    final accountService = injector<AccountService>();
    final backup = injector<BackupService>();
    await backup.backupCloudDatabase(await accountService.getDefaultAccount());
  }

  Future<void> _checkForKeySync() async {
    final cloudDatabase = injector<CloudDatabase>();
    final defaultAccounts = await cloudDatabase.personaDao.getDefaultPersonas();

    if (defaultAccounts.length >= 2) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRouter.keySyncPage);
    }
  }

  void _refreshTokens({checkPendingToken = false}) async {
    final accountService = injector<AccountService>();
    playlists.value = await getPlaylist();

    Future.wait([
      getAddresses(),
      getManualTokenIds(),
      accountService.getHiddenAddresses(),
    ]).then((value) async {
      final addresses = value[0];
      final indexerIds = value[1];
      final hiddenAddresses = value[2];
      final activeAddresses = addresses
          .where((element) => !hiddenAddresses.contains(element))
          .toList();
      final nftBloc = context.read<NftCollectionBloc>();
      final isDemo = injector.get<ConfigurationService>().isDemoArtworksMode();
      if (isDemo) {
        playlists.value?.forEach((element) {
          indexerIds.addAll(element.tokenIDs ?? []);
        });
      }
      nftBloc.add(UpdateHiddenTokens(ownerAddresses: hiddenAddresses));
      nftBloc.add(RefreshTokenEvent(
          addresses: activeAddresses, debugTokens: indexerIds));
      nftBloc.add(RequestIndexEvent(activeAddresses));
      if (checkPendingToken) {
        final pendingTokenService = injector<PendingTokenService>();
        activeAddresses
            .where((address) => address.startsWith("tz"))
            .forEach((address) {
          pendingTokenService.checkPendingTezosTokens(address, maxRetries: 1);
        });
      }
    });
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
      case "artwork_created":
      case "artwork_received":
        injector<FeedService>().checkNewFeeds();
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

      case "artwork_created":
      case "artwork_received":
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.feedPreviewPage,
          ((route) =>
              route.settings.name == AppRouter.homePage ||
              route.settings.name == AppRouter.homePageNoTransition),
        );
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

    injector<WalletConnectService>().initSessions(forced: true);
    injector<Wc2Service>().activateParings();

    _refreshTokens(checkPendingToken: true);

    metricClient.addEvent("device_foreground");
    _subscriptionNotify();
    injector<VersionService>().checkForUpdate();

    // Reload token in Isolate
    final jwtToken =
        (await injector<AuthService>().getAuthToken(forceRefresh: true))
            .jwtToken;

    final feedService = injector<FeedService>();
    feedService
        .refreshJWTToken(jwtToken)
        .then((value) => feedService.checkNewFeeds());

    injector<CustomerSupportService>().getIssues();
    injector<CustomerSupportService>().processMessages();
  }

  Future _subscriptionNotify() async {
    final configService = injector<ConfigurationService>();
    final iapService = injector<IAPService>();

    if (configService.isNotificationEnabled() != true ||
        await iapService.isSubscribed() ||
        !configService.shouldShowSubscriptionHint() ||
        configService
                .getLastTimeAskForSubscription()
                ?.isAfter(DateTime.now().subtract(const Duration(days: 2))) ==
            true) {
      return;
    }

    log.info("[HomePage] Show subscription notification");
    await configService.setLastTimeAskForSubscription(DateTime.now());
    const key = Key("subscription");
    showInfoNotification(
      key,
      "subscription_hint".tr(),
      duration: const Duration(seconds: 5),
      openHandler: () {
        UpgradesView.showSubscriptionDialog(context, null, null, () {
          hideOverlay(key);
          context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
        });
      },
    );
  }

  void _handleBackground() {
    metricClient.addEvent("device_background");
    metricClient.sendAndClearMetrics();
    mixPanelClient.trackEvent("device_background");
    mixPanelClient.sendData();
    _cloudBackup();
    FileLogger.shrinkLogFileIfNeeded();
  }
}

class ListPlaylistWidget extends StatefulWidget {
  final Function onUpdateList;

  const ListPlaylistWidget({
    Key? key,
    required this.playlists,
    required this.onUpdateList,
  }) : super(key: key);

  final List<PlayListModel?>? playlists;

  @override
  State<ListPlaylistWidget> createState() => _ListPlaylistWidgetState();
}

class _ListPlaylistWidgetState extends State<ListPlaylistWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ReorderableListView.builder(
        onReorderStart: (index) {
          Vibrate.feedback(FeedbackType.light);
        },
        proxyDecorator: (child, index, animation) {
          return PlaylistItem(
            name: widget.playlists?[index]?.name,
            thumbnailURL: widget.playlists?[index]?.thumbnailURL,
            onHold: true,
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final element = widget.playlists?.removeAt(oldIndex);
            if (element != null) widget.playlists?.insert(newIndex, element);
            widget.playlists?.removeWhere((element) => element == null);
            widget.onUpdateList.call();
          });
        },
        scrollDirection: Axis.horizontal,
        footer: injector.get<ConfigurationService>().isDemoArtworksMode()
            ? null
            : AddPlayListItem(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(AppRouter.createPlayListPage)
                      .then((value) {
                    if (value != null && value is PlayListModel) {
                      Navigator.pushNamed(context, AppRouter.viewPlayListPage,
                          arguments: value);
                    }
                  });
                },
              ),
        itemBuilder: (context, index) => PlaylistItem(
          key: ValueKey(widget.playlists?[index]?.id ?? index),
          name: widget.playlists?[index]?.name,
          thumbnailURL: widget.playlists?[index]?.thumbnailURL,
          onSelected: () => Navigator.pushNamed(
            context,
            AppRouter.viewPlayListPage,
            arguments: widget.playlists?[index],
          ),
        ),
        itemCount: widget.playlists?.length ?? 0,
      ),
    );
  }
}

class PlaylistItem extends StatefulWidget {
  final Function()? onSelected;
  final String? name;
  final String? thumbnailURL;
  final bool onHold;

  const PlaylistItem({
    Key? key,
    this.onSelected,
    this.name,
    this.thumbnailURL,
    this.onHold = false,
  }) : super(key: key);

  @override
  State<PlaylistItem> createState() => _PlaylistItemState();
}

class _PlaylistItemState extends State<PlaylistItem> {
  @override
  void didUpdateWidget(covariant PlaylistItem oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onSelected,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: widget.onHold ? 52 : 48,
              height: widget.onHold ? 52 : 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(width: widget.onHold ? 2 : 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: widget.thumbnailURL == null
                      ? Image.asset(
                          'assets/images/moma_logo.png',
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.thumbnailURL ?? '',
                          fit: BoxFit.cover,
                          cacheManager: injector.get<CacheManager>(),
                          errorWidget: (context, url, error) =>
                              const GalleryThumbnailErrorWidget(),
                          memCacheHeight: 1000,
                          memCacheWidth: 1000,
                          maxWidthDiskCache: 1000,
                          maxHeightDiskCache: 1000,
                          fadeInDuration: Duration.zero,
                        ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              (widget.name?.isNotEmpty ?? false) ? widget.name! : 'Untitled',
              style: widget.onHold
                  ? theme.textTheme.headline5
                      ?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.headline5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AddPlayListItem extends StatelessWidget {
  final Function()? onTap;

  const AddPlayListItem({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: const Icon(
                    Icons.add,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              'new list',
              style: theme.textTheme.headline5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
