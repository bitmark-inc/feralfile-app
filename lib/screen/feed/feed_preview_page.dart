//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_state.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/ethereum_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/service/mixPanel_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:measured_size/measured_size.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/widgets/nft_collection_bloc.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock/wakelock.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:web3dart/crypto.dart';

Map<String, double> heightMap = {};

class FeedPreviewPage extends StatelessWidget {
  FeedPreviewPage({Key? key}) : super(key: key);

  final nftCollectionBloc = injector<NftCollectionBloc>();

  Widget get discoveryTab {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FeedBloc(
            injector(),
            injector(),
            nftCollectionBloc.database.assetDao,
          ),
        ),
        BlocProvider(
            create: (_) => IdentityBloc(injector<AppDatabase>(), injector())),
      ],
      child: const FeedPreviewScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _tabs = <String>['Discovery', 'Editorial'];
    heightMap = {};
    double safeAreaTop = MediaQuery.of(context).padding.top;
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver:  SliverAppBar(
                  expandedHeight: safeAreaTop + 120,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(top: 0, left: 0, bottom: 15),
                    title: Padding(
                      padding: EdgeInsets.only(top: safeAreaTop + 69, left: 15),
                      child: SizedBox(
                        width: 50,
                          height: 50,
                          child: Image.asset("assets/images/moma_logo.png", color: Colors.white,)
                      ),
                    ),
                  ),
                  floating: true,
                  pinned: true,
                  snap: false,
                  forceElevated: innerBoxIsScrolled,
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(102),
                    child:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(width: 10, color: Colors.yellow),
                          TabBar(
                            labelPadding: EdgeInsets.zero,
                            indicatorPadding: EdgeInsets.only(left: 5, right: 5,),
                            indicatorColor: Colors.yellow,
                            padding: EdgeInsets.only(right: 0, bottom: 0),
                            tabs: _tabs.map((String name) =>
                                Padding(
                                  padding: const EdgeInsets.only(left: 5, right: 5),
                                  child: Container(
                                    padding: EdgeInsets.zero,
                                      child: Tab(text: name, iconMargin: EdgeInsets.zero,
                                      )
                                  ),
                                )
                            ).toList(),
                            indicator: const UnderlineTabIndicator(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Colors.green,
                                ),
                                insets: EdgeInsets.only(
                                    bottom: 45)
                            ),
                            isScrollable: true,
                          ),
                          Container(width: 10, color: Colors.yellow),
                        ],
                      ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => FeedBloc(
                      injector(),
                      injector(),
                      nftCollectionBloc.database.assetDao,
                    ),
                  ),
                BlocProvider(
                  create: (_) => IdentityBloc(injector<AppDatabase>(), injector())),
                ],
                child: const FeedPreviewScreen(),
              ),
              Container(color: Colors.yellow, height: 500,),
            ]
          ),
        ),
      ),
    );
  }
}

class FeedPreviewScreen extends StatefulWidget {
  const FeedPreviewScreen({Key? key}) : super(key: key);

  @override
  State<FeedPreviewScreen> createState() => _FeedPreviewScreenState();
}

class _FeedPreviewScreenState extends State<FeedPreviewScreen>
    with
        RouteAware,
        AfterLayoutMixin<FeedPreviewScreen>,
        WidgetsBindingObserver,
        TickerProviderStateMixin{
  String? swipeDirection;
  Timer? _timer;
  Timer? _maxTimeTokenTimer;

  final _configurationService = GetIt.I.get<ConfigurationService>();

  final _controller = PageController();

  late FeedBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<FeedBloc>();
    if (_configurationService.isFinishedFeedOnBoarding()) {
      _bloc.add(GetFeedsEvent());
    }

  }

  @override
  void afterFirstLayout(BuildContext context) {
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent(
      "view_discovery",
    );
    final mixPanelClient = injector.get<MixPanelClientService>();
    mixPanelClient.trackEvent(
      "view_discovery",
    );
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    Wakelock.enable();
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    Wakelock.enable();

    super.didPopNext();
  }

  @override
  void didPushNext() {
    _maxTimeTokenTimer?.cancel();
    super.didPopNext();
  }

  @override
  void dispose() {
    Wakelock.disable();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    Sentry.getSpan()?.finish(status: const SpanStatus.ok());
    _timer?.cancel();
    _maxTimeTokenTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  final nftCollectionBloc = injector<NftCollectionBloc>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double safeAreaTop = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: BlocConsumer<FeedBloc, FeedState>(
          listener: (context, state) {},
          builder: (context, state) {
            if ((state.feedTokens?.isEmpty ?? true) ||
                    (state.feedEvents?.isEmpty ?? true)) {
              return _emptyOrLoadingDiscoveryWidget(state.appFeedData);
            }
            //final feedTokens = state.feedTokens;
            return Container(
              //color: Colors.lightBlue,
              //padding: EdgeInsets.only(top: 102),
              child: Stack(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    addAutomaticKeepAlives: true,
                    itemCount: state.feedTokens?.length,
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    cacheExtent: 500,

                    itemBuilder: (context, index) => _listItem(
                        state.feedEvents![index],
                        state.feedTokens![index]
                    )
                  ),
                ]
              ),
            );
          }),
    );
  }

  Widget _listItem(FeedEvent event, AssetToken? asset){
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        if (asset == null){
          return;
        }
        _moveToInfo(asset, event);
      },
      child: Column(
          children: [
            Center(
              child: FeedArtwork(
                assetToken: asset,
              ),
            ),

            const SizedBox(height: 10,),
            Align(
              alignment: Alignment.topCenter,
              child: _controlView(event, asset,),
            ),
            const SizedBox(height: 60,),

          ]
      ),
    );
  }

  Widget _controlViewWhenNoAsset(FeedEvent event) {
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: EdgeInsets.only(left: 15, right: 5,),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Flexible(child: BlocBuilder<IdentityBloc, IdentityState>(
                      builder: (context, identityState) {
                    final followingName = event.recipient
                            .toIdentityOrMask(identityState.identityMap) ??
                        event.recipient;

                    return Text(
                      followingName,
                      style: ResponsiveLayout.isMobile
                          ? theme.textTheme.ppMori400White14
                          : theme.textTheme.atlasWhiteBold14,
                      overflow: TextOverflow.ellipsis,
                    );
                  })),
                ]),
                const SizedBox(height: 4),
                RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: theme.primaryTextTheme.headline5,
                      children: <TextSpan>[
                        TextSpan(
                          text: '${event.actionRepresentation} ',
                        ),
                        TextSpan(
                          text: 'nft_indexing'.tr(),
                          style: ResponsiveLayout.isMobile
                              ? theme.textTheme.ppMori400White12
                              : theme.textTheme.atlasWhiteItalic14,
                        ),
                      ],
                    )),
              ],
            ),
          ),
          const SizedBox(),
        ],
      ),
    );
  }

  Widget _controlView(FeedEvent event, AssetToken? asset) {
    //return _controlViewWhenNoAsset(event);
    if (asset == null) {
      return _controlViewWhenNoAsset(event);
    }

    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      padding: EdgeInsets.only(left: 15, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: BlocBuilder<IdentityBloc, IdentityState>(
                builder: (context, identityState) {
              final artistName = asset.artistName
                  ?.toIdentityOrMask(identityState.identityMap);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            asset.title.isEmpty
                                ? 'nft'
                                : '${asset.title} ',
                          overflow: TextOverflow.ellipsis,
                            style: ResponsiveLayout.isMobile
                                ? theme.textTheme.ppMori400White14
                                : theme.textTheme.atlasWhiteItalic14,
                        ),
                        const SizedBox(height: 6,),
                        if (artistName != null) ...[
                          RichText(
                            overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                  text: 'by'.tr(args: [artistName]),
                                  style: theme.textTheme.ppMori400White14),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Future _moveToInfo(AssetToken asset, FeedEvent event) async {
    _maxTimeTokenTimer?.cancel();
    Wakelock.disable();

    Navigator.of(context).pushNamed(
      AppRouter.feedArtworkDetailsPage,
      arguments: FeedDetailPayload(asset, event),
    );
  }

  Widget _emptyOrLoadingDiscoveryWidget(AppFeedData? appFeedData) {
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Padding(
        padding: ResponsiveLayout.pageEdgeInsets
            .copyWith(top: safeAreaTop + 2, right: 5),
        child: Stack(children: [
          // loading
          if (appFeedData == null) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  loadingIndicator(valueColor: Colors.white),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    "loading...".tr(),
                    style: ResponsiveLayout.isMobile
                        ? theme.textTheme.atlasGreyNormal12
                        : theme.textTheme.atlasGreyNormal14,
                  ),
                ],
              ),
            )
          ] else if (appFeedData.events.isEmpty) ...[
            Column(children: [
              const SizedBox(height: 100),
              Container(
                padding: ResponsiveLayout.pageEdgeInsets
                    .copyWith(top: 0, left: 0, bottom: 0),
                child: Text(
                  "discovery_keep_you_up".tr(),
                  //'Discovery keeps you up to date on what your favorite artists are creating and collecting.
                  // For now they haven’t created or collected anything new yet. Once they do, you can view it here. ',
                  style: theme.primaryTextTheme.bodyText1,
                  textAlign: TextAlign.justify,
                ),
              )
            ])
          ],
        ]));
  }
}

class FeedArtwork extends StatefulWidget {
  final AssetToken? assetToken;
  final Function? onInit;

  const FeedArtwork({Key? key, this.assetToken, this.onInit}) : super(key: key);

  @override
  State<FeedArtwork> createState() => _FeedArtworkState();
}

class _FeedArtworkState extends State<FeedArtwork>
    with RouteAware, WidgetsBindingObserver
        //AutomaticKeepAliveClientMixin
{
  bool _missingToken = false;
  INFTRenderingWidget? _renderingWidget;

  final _bloc = ArtworkPreviewDetailBloc(
    injector<NftCollectionBloc>().database.assetDao,
    injector<EthereumService>(),
  );

  @override
  void initState() {
    if (widget.assetToken == null) {
      _missingToken = true;
    } else {
      _bloc.add(ArtworkFeedPreviewDetailGetAssetTokenEvent(widget.assetToken!));
    }
    widget.onInit?.call();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _renderingWidget?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    _renderingWidget?.didPopNext();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    _renderingWidget?.clearPrevious();
    super.didPushNext();

  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateWebviewSize();
  }

  _updateWebviewSize() {
    if (_renderingWidget != null &&
        _renderingWidget is WebviewNFTRenderingWidget) {
      (_renderingWidget as WebviewNFTRenderingWidget).updateWebviewSize();
    }
  }

  // @override
  // bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    if (widget.assetToken == null) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      return Container(
        color: AppColor.secondarySpanishGrey,
        width: screenWidth,
        height: screenHeight * 0.55,
      );
    }

    if (_missingToken) {
      Vibrate.feedback(FeedbackType.light);
      _missingToken = false;
    }

    return BlocBuilder<ArtworkPreviewDetailBloc, ArtworkPreviewDetailState>(
      bloc: _bloc,
      builder: (context, state) {
        print(state.runtimeType);
        switch (state.runtimeType) {
          case ArtworkPreviewDetailLoadingState:
            final screenWidth = MediaQuery.of(context).size.width;
            return SizedBox(
              height: heightMap[widget.assetToken?.id] ?? screenWidth,
                width: screenWidth,
                child: const CircularProgressIndicator(color: Colors.white,));
          case ArtworkPreviewDetailLoadedState:
            final asset = (state as ArtworkPreviewDetailLoadedState).asset;
            if (asset != null) {
              return MeasuredSize(
                onChange: (Size size){
                  final id = asset.id;
                  if (id == null){
                    return;
                  }
                  heightMap[id] = size.height;
                },
                child: BlocProvider(
                  create: (_) => RetryCubit(),
                  child: BlocBuilder<RetryCubit, int>(
                    builder: (context, attempt) {
                      if (attempt > 0) {
                        _renderingWidget?.dispose();
                        _renderingWidget = null;
                      }
                      if (_renderingWidget == null ||
                          _renderingWidget!.previewURL != asset.getPreviewUrl()) {
                        _renderingWidget = buildRenderingWidget(
                          context,
                          asset,
                          attempt: attempt > 0 ? attempt : null,
                          overriddenHtml: state.overriddenHtml,
                        );
                      }
                      final mimeType = asset.getMimeType;
                      switch (mimeType) {
                        case "image":
                        case "svg":
                        case 'gif':
                        case "audio":
                        case "video":
                          return Container(
                            child: _renderingWidget?.build(context),
                          );
                        default:
                          return AspectRatio(
                            aspectRatio: 1,
                            child: _renderingWidget?.build(context),
                          );
                      }

                    },
                  ),
                ),
              );
            }
            return SizedBox(
            );
          default:
            return SizedBox();
        }
      },
    );
  }
}

class FeedDetailPayload {
  AssetToken? feedToken;
  FeedEvent? feedEvent;

  FeedDetailPayload(this.feedToken, this.feedEvent,);

  FeedDetailPayload copyWith(
  AssetToken? feedToken,  FeedEvent? feedEvent) {
    return FeedDetailPayload(
      feedToken ?? this.feedToken,
      feedEvent ?? this.feedEvent,
    );
  }
}
