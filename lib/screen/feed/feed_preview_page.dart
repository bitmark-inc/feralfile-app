//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';

import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock/wakelock.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class FeedPreviewPage extends StatefulWidget {
  const FeedPreviewPage({Key? key}) : super(key: key);

  @override
  State<FeedPreviewPage> createState() => _FeedPreviewPageState();
}

class _FeedPreviewPageState extends State<FeedPreviewPage>
    with RouteAware, AfterLayoutMixin<FeedPreviewPage>, WidgetsBindingObserver {
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

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _bloc.add(RetryMissingTokenInFeedsEvent());
    });
  }

  void setMaxTimeToken() {
    _maxTimeTokenTimer?.cancel();
    _maxTimeTokenTimer = Timer(const Duration(seconds: 10), () {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final metricClient = injector.get<MetricClientService>();
    metricClient.addEvent(
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

    setMaxTimeToken();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: BlocConsumer<FeedBloc, FeedState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state.isFinishedOnBoarding() &&
                ((state.feedTokens?.isEmpty ?? true) ||
                    (state.feedEvents?.isEmpty ?? true))) {
              return _emptyOrLoadingDiscoveryWidget(state.appFeedData);
            }

            final feedTokens = state.feedTokens;
            final currentIndex = state.viewingIndex ?? 0;

            if (!state.isFinishedOnBoarding()) {
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        PageView.builder(
                          onPageChanged: (value) {
                            _bloc.add(ChangeOnBoardingEvent(index: value));
                          },
                          itemCount: 4,
                          itemBuilder: (context, index) => Center(
                            child: _getOnBoardingView(index),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: _controlViewOnBoarding(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _controller,
                        onPageChanged: (value) {
                          final event = state.feedEvents![value];
                          final asset = state.feedTokens![value];
                          final neededIdentities = [
                            asset?.artistName ?? '',
                            event.recipient
                          ];
                          neededIdentities
                              .removeWhere((element) => element == '');
                          if (neededIdentities.isNotEmpty) {
                            context
                                .read<IdentityBloc>()
                                .add(GetIdentityEvent(neededIdentities));
                          }
                          _bloc.add(ChangePageEvent(index: value));
                        },
                        itemCount: feedTokens?.length,
                        itemBuilder: (context, index) => Center(
                          child: FeedArtwork(
                            assetToken: state.feedTokens![index],
                            onInit: setMaxTimeToken,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: _controlView(
                          state.feedEvents![currentIndex],
                          state.feedTokens![currentIndex],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }

  Widget _controlViewWhenNoAsset(FeedEvent event) {
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 5, 0),
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
                          ? theme.textTheme.atlasWhiteBold12
                          : theme.textTheme.atlasWhiteBold14,
                      overflow: TextOverflow.ellipsis,
                    );
                  })),
                  Text(" • ", style: theme.primaryTextTheme.headline5),
                  Text(getDateTimeRepresentation(event.timestamp.toLocal()),
                      style: theme.primaryTextTheme.headline5),
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
                              ? theme.textTheme.atlasWhiteItalic12
                              : theme.textTheme.atlasWhiteItalic14,
                        ),
                      ],
                    )),
              ],
            ),
          ),
          const SizedBox(),
          previewCloseIcon(context),
        ],
      ),
    );
  }

  Widget _controlViewOnBoarding() {
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      height: MediaQuery.of(context).padding.top + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop + 2, 5, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/images/iconFeed.svg",
              color: theme.colorScheme.secondary),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "h_autonomy".tr(),
                  style: ResponsiveLayout.isMobile
                      ? theme.textTheme.atlasWhiteBold12
                      : theme.textTheme.atlasWhiteBold14,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "introducing_discovery".tr(),
                  style: theme.primaryTextTheme.headline5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(),
          previewCloseIcon(context),
        ],
      ),
    );
  }

  Widget _controlView(FeedEvent event, AssetToken? asset) {
    if (asset == null) {
      return _controlViewWhenNoAsset(event);
    }

    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 5, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _moveToInfo(asset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/iconInfo.svg",
                color: theme.colorScheme.secondary),
            const SizedBox(width: 13),
            Expanded(
              child: BlocBuilder<IdentityBloc, IdentityState>(
                  builder: (context, identityState) {
                final followingName = event.recipient
                        .toIdentityOrMask(identityState.identityMap) ??
                    event.recipient;
                final artistName = asset.artistName
                    ?.toIdentityOrMask(identityState.identityMap);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          followingName,
                          style: ResponsiveLayout.isMobile
                              ? theme.textTheme.atlasWhiteBold12
                              : theme.textTheme.atlasWhiteBold14,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(" • ", style: theme.primaryTextTheme.headline5),
                      Text(getDateTimeRepresentation(event.timestamp.toLocal()),
                          style: theme.primaryTextTheme.headline5),
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
                              text: asset.title.isEmpty
                                  ? 'nft'
                                  : '${asset.title} ',
                              style: ResponsiveLayout.isMobile
                                  ? theme.textTheme.atlasWhiteItalic12
                                  : theme.textTheme.atlasWhiteItalic14,
                            ),
                            if (event.action == 'transfer' &&
                                artistName != null) ...[
                              TextSpan(
                                  text: 'by'.tr(args: [artistName]),
                                  style: theme.primaryTextTheme.headline5),
                            ]
                          ],
                        )),
                  ],
                );
              }),
            ),
            const SizedBox(),
            previewCloseIcon(context),
          ],
        ),
      ),
    );
  }

  Future _moveToInfo(AssetToken asset) async {
    _maxTimeTokenTimer?.cancel();
    Wakelock.disable();

    Navigator.of(context).pushNamed(
      AppRouter.feedArtworkDetailsPage,
      arguments: context.read<FeedBloc>(),
    );
  }

  Widget _getOnBoardingView(int step) {
    final theme = Theme.of(context);

    final String assetPath;
    final String title;

    switch (step) {
      case 1:
        assetPath = "assets/images/feed_onboarding_insight.png";
        title = "get_insights".tr(); //"Get insights about the artwork";
        break;
      case 2:
        assetPath = "assets/images/feed_onboarding_swipe.png";
        title = "swipe_to".tr(); // "Swipe to discover more artworks";
        break;
      case 0:
        assetPath = "assets/images/feed_onboarding.png";
        title = "discover_what"
            .tr(); // "Discover what your collected artists mint or collect";
        break;
      default:
        return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.primaryTextTheme.headline2,
          ),
          const SizedBox(height: 24),
          Image.asset(
            assetPath,
            height: MediaQuery.of(context).size.height * 2 / 3,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _emptyOrLoadingDiscoveryWidget(AppFeedData? appFeedData) {
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageEdgeInsets
          .copyWith(top: safeAreaTop + 2, right: 5),
      child: Stack(
        children: [
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
          ]
          else if (appFeedData.events.isEmpty) ...[
            Column(
              children:[
                const SizedBox(height: 100),
                Container(
                  padding: ResponsiveLayout.pageEdgeInsets.copyWith(top: 0, left: 0, bottom: 0),
                  child: Text(
                    "discovery_keep_you_up".tr(),
                    //'Discovery keeps you up to date on what your favorite artists are creating and collecting.
                    // For now they haven’t created or collected anything new yet. Once they do, you can view it here. ',
                    style: theme.primaryTextTheme.bodyText1,
                    textAlign: TextAlign.justify,
                  ),
                )]
            )
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/iconFeed.svg",
                color: theme.colorScheme.secondary,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
                child: Text(
                  "h_discovery".tr().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'IBMPlexMono',
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ),
              const Spacer(),
              previewCloseIcon(context)
            ],
          ),
        ]
      )
    );
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
    with RouteAware, WidgetsBindingObserver {
  bool _missingToken = false;
  INFTRenderingWidget? _renderingWidget;

  @override
  void initState() {
    // TODO: implement initState
    if (widget.assetToken == null) {
      _missingToken = true;
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

    return BlocProvider(
      create: (_) => RetryCubit(),
      child: BlocBuilder<RetryCubit, int>(builder: (context, attempt) {
        if (attempt > 0) {
          _renderingWidget?.dispose();
          _renderingWidget = null;
        }
        if (_renderingWidget == null ||
            _renderingWidget!.previewURL !=
                widget.assetToken?.getPreviewUrl()) {
          _renderingWidget = buildRenderingWidget(context, widget.assetToken!,
              attempt: attempt > 0 ? attempt : null);
        }
        return Container(child: _renderingWidget!.build(context));
      }),
    );
  }
}
