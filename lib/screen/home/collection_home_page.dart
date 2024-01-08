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
import 'package:autonomy_flutter/model/blockchain.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_screen.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/home/home_bloc.dart';
import 'package:autonomy_flutter/screen/home/home_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/autonomy_service.dart';
import 'package:autonomy_flutter/service/client_token_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/customer_support_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/locale_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/settings_data_service.dart';
import 'package:autonomy_flutter/service/versions_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/token_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:nft_collection/models/models.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CollectionHomePage extends StatefulWidget {
  const CollectionHomePage({super.key});

  @override
  State<CollectionHomePage> createState() => CollectionHomePageState();
}

class CollectionHomePageState extends State<CollectionHomePage>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<CollectionHomePage>,
        AutomaticKeepAliveClientMixin {
  StreamSubscription<FGBGType>? _fgbgSubscription;
  late ScrollController _controller;
  late MetricClientService _metricClient;
  int _cachedImageSize = 0;
  final _clientTokenService = injector<ClientTokenService>();
  final _configurationService = injector<ConfigurationService>();

  final nftBloc = injector<ClientTokenService>().nftBloc;
  late GlobalKey<CollectionProState> collectionProKey;

  @override
  void initState() {
    super.initState();
    collectionProKey = GlobalKey<CollectionProState>();
    _metricClient = injector.get<MetricClientService>();
    WidgetsBinding.instance.addObserver(this);
    _fgbgSubscription = FGBGEvents.stream.listen(_handleForeBackground);
    _controller = ScrollController()..addListener(_scrollListenerToLoadMore);
    unawaited(_configurationService.setAutoShowPostcard(true));
    NftCollectionBloc.eventController.stream.listen((event) async {
      switch (event.runtimeType) {
        case ReloadEvent:
        case GetTokensByOwnerEvent:
        case UpdateTokensEvent:
        case GetTokensBeforeByOwnerEvent:
          nftBloc.add(event);
          break;
        default:
      }
    });
    unawaited(
        _clientTokenService.refreshTokens(syncAddresses: true).then((value) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: PageKey.init()));
    }));

    context.read<HomeBloc>().add(CheckReviewAppEvent());

    unawaited(injector<IAPService>().setup());
    memoryValues.inGalleryView = true;
  }

  void _scrollListenerToLoadMore() {
    if (_controller.position.pixels + 100 >=
        _controller.position.maxScrollExtent) {
      final nextKey = nftBloc.state.nextKey;
      if (nextKey == null || nextKey.isLoaded) {
        return;
      }
      nftBloc.add(GetTokensByOwnerEvent(pageKey: nextKey));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void afterFirstLayout(BuildContext context) {
    unawaited(_handleForeground());
    unawaited(injector<AutonomyService>().postLinkedAddresses());
    unawaited(_checkForKeySync(context));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    unawaited(_fgbgSubscription?.cancel());
    _controller.dispose();
    super.dispose();
  }

  @override
  Future<void> didPopNext() async {
    super.didPopNext();
    final connectivityResult = await Connectivity().checkConnectivity();
    unawaited(_clientTokenService.refreshTokens());
    unawaited(refreshNotification());
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
    memoryValues.inGalleryView = true;
  }

  @override
  void didPushNext() {
    memoryValues.inGalleryView = false;
    super.didPushNext();
  }

  Future<void> _onTokensUpdate(List<CompactedAssetToken> tokens) async {
    //check minted postcard and navigator to artwork detail
    final config = injector.get<ConfigurationService>();
    final listTokenMints = config.getListPostcardMint();
    if (tokens.any((element) =>
        listTokenMints.contains(element.id) && element.pending != true)) {
      final tokenMints = tokens
          .where(
            (element) =>
                listTokenMints.contains(element.id) && element.pending != true,
          )
          .map((e) => e.identity)
          .toList();
      if (config.isAutoShowPostcard()) {
        log.info('Auto show minted postcard');
        final payload = PostcardDetailPagePayload(tokenMints, 0);
        unawaited(Navigator.of(context).pushNamed(
          AppRouter.claimedPostcardDetailsPage,
          arguments: payload,
        ));
      }

      unawaited(config.setListPostcardMint(
        tokenMints.map((e) => e.id).toList(),
        isRemoved: true,
      ));
    }

    // Check if there is any Tezos token in the list
    List<String> allAccountNumbers = await injector<AccountService>()
        .getAllAddresses(logHiddenAddress: true);
    final hashedAddresses = allAccountNumbers.fold(
        0, (int previousValue, element) => previousValue + element.hashCode);

    if (_configurationService.sentTezosArtworkMetricValue() !=
            hashedAddresses &&
        tokens.any((asset) =>
            asset.blockchain == Blockchain.TEZOS.name.toLowerCase())) {
      unawaited(_metricClient.addEvent('collection_has_tezos'));
      unawaited(
          _configurationService.setSentTezosArtworkMetric(hashedAddresses));
    }
  }

  List<CompactedAssetToken> _updateTokens(List<CompactedAssetToken> tokens) {
    tokens = tokens.filterAssetToken();
    final nextKey = nftBloc.state.nextKey;
    if (nextKey != null &&
        !nextKey.isLoaded &&
        tokens.length < COLLECTION_INITIAL_MIN_SIZE) {
      nftBloc.add(GetTokensByOwnerEvent(pageKey: nextKey));
    }
    return tokens;
  }

  Future<void> refreshPlaylists() async {
    await collectionProKey.currentState?.refreshCollectionSection();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final contentWidget =
        BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
      bloc: nftBloc,
      builder: (context, state) => NftCollectionGrid(
        state: state.state,
        tokens: _updateTokens(state.tokens.items),
        loadingIndicatorBuilder: _loadingView,
        emptyGalleryViewBuilder: _emptyGallery,
        customGalleryViewBuilder: (context, tokens) =>
            _assetsWidget(context, tokens),
      ),
      listener: (context, state) async {
        log.info('[NftCollectionBloc] State update $state');
        if (state.state == NftLoadingState.done) {
          unawaited(_onTokensUpdate(state.tokens.items));
        }
      },
    );

    return PrimaryScrollController(
      controller: _controller,
      child: Scaffold(
        appBar: getDarkEmptyAppBar(Colors.transparent),
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: AppColor.primaryBlack,
        body: contentWidget,
      ),
    );
  }

  Widget _header(BuildContext context) {
    final paddingTop = MediaQuery.of(context).viewPadding.top;
    return Padding(
      padding: EdgeInsets.only(top: paddingTop),
      child: HeaderView(title: 'collection'.tr()),
    );
  }

  Widget _loadingView(BuildContext context) => Center(
          child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          _header(context),
          loadingIndicator(valueColor: AppColor.white),
        ],
      ));

  Widget _emptyGallery(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: ResponsiveLayout.getPadding.copyWith(left: 0, right: 0),
      children: [
        SizedBox(
          height: MediaQuery.of(context).padding.top,
        ),
        _header(context),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            'collection_empty_now'.tr(),
            //"Your collection is empty for now.",
            style: theme.textTheme.ppMori400White14,
          ),
        ),
      ],
    );
  }

  Widget _assetsWidget(BuildContext context, List<CompactedAssetToken> tokens) {
    final accountIdentities = tokens
        .where((e) => e.pending != true || e.hasMetadata)
        .map((element) => element.identity)
        .toList();

    const int cellPerRowPhone = 3;
    const int cellPerRowTablet = 6;
    const double cellSpacing = 3;
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
        child: SizedBox(
          height: MediaQuery.of(context).padding.top,
        ),
      ),
      SliverToBoxAdapter(
        child: _header(context),
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

            if (asset.pending == true && asset.isPostcard) {
              return MintTokenWidget(
                thumbnail: asset.galleryThumbnailURL,
                tokenId: asset.tokenId,
              );
            }

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
                      usingThumbnailID: index > 50,
                    ),
              onTap: () {
                if (asset.pending == true && !asset.hasMetadata) {
                  return;
                }

                final index = tokens
                    .where((e) => e.pending != true || e.hasMetadata)
                    .toList()
                    .indexOf(asset);
                final payload = asset.isPostcard
                    ? PostcardDetailPagePayload(accountIdentities, index)
                    : ArtworkDetailPayload(accountIdentities, index);

                final pageName = asset.isPostcard
                    ? AppRouter.claimedPostcardDetailsPage
                    : AppRouter.artworkDetailsPage;
                unawaited(Navigator.of(context)
                    .pushNamed(pageName, ////need change to pageName
                        arguments: payload));

                unawaited(_metricClient.addEvent(MixpanelEvent.viewArtwork,
                    data: {'id': asset.id}));
              },
            );
          },
          childCount: tokens.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: sources,
      controller: _controller,
    );
  }

  Future<void> _checkForKeySync(BuildContext context) async {
    final cloudDatabase = injector<CloudDatabase>();
    final defaultAccounts = await cloudDatabase.personaDao.getDefaultPersonas();

    if (defaultAccounts.length >= 2) {
      if (!mounted) {
        return;
      }
      unawaited(Navigator.of(context).pushNamed(AppRouter.keySyncPage));
    }
  }

  void scrollToTop() {
    unawaited(_controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn));
  }

  Future refreshNotification() async {
    await injector<CustomerSupportService>().getIssuesAndAnnouncement();
  }

  Future<void> _handleForeBackground(FGBGType event) async {
    switch (event) {
      case FGBGType.foreground:
        unawaited(_handleForeground());
        break;
      case FGBGType.background:
        _handleBackground();
        break;
    }
  }

  Future<void> _handleForeground() async {
    final locale = Localizations.localeOf(context);
    unawaited(LocaleService.refresh(locale));
    memoryValues.inForegroundAt = DateTime.now();
    await injector<ConfigurationService>().reload();
    try {
      await injector<SettingsDataService>().restoreSettingsData();
    } catch (exception) {
      if (exception is DioException && exception.response?.statusCode == 404) {
        // if there is no backup, upload one.
        await injector<SettingsDataService>().backup();
      } else {
        unawaited(Sentry.captureException(exception));
      }
    }

    unawaited(_clientTokenService.refreshTokens(checkPendingToken: true));
    unawaited(refreshNotification());
    unawaited(_metricClient.addEvent('device_foreground'));
    unawaited(injector<VersionService>().checkForUpdate());
    // Reload token in Isolate

    unawaited(injector<CustomerSupportService>().getIssuesAndAnnouncement());
    unawaited(injector<CustomerSupportService>().processMessages());
  }

  void _handleBackground() {
    unawaited(_metricClient.addEvent(MixpanelEvent.deviceBackground));
    unawaited(_metricClient.sendAndClearMetrics());
    unawaited(FileLogger.shrinkLogFileIfNeeded());
  }

  @override
  bool get wantKeepAlive => true;
}
