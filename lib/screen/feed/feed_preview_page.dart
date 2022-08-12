//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';

import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
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
  INFTRenderingWidget? _renderingWidget;
  Timer? _timer;
  Timer? _maxTimeTokenTimer;
  bool _missingToken = false;
  AssetToken? latestToken;
  FeedEvent? latestEvent;

  @override
  void initState() {
    super.initState();

    context.read<FeedBloc>().add(GetFeedsEvent());

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      context.read<FeedBloc>().add(RetryMissingTokenInFeedsEvent());
    });
  }

  void setMaxTimeToken() {
    _maxTimeTokenTimer?.cancel();
    _maxTimeTokenTimer = Timer(const Duration(seconds: 10), () {
      context.read<FeedBloc>().add(MoveToNextFeedEvent());
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    injector<AWSService>().storeEventWithDeviceData(
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

    _renderingWidget?.didPopNext();
    setMaxTimeToken();
    super.didPopNext();
  }

  @override
  void dispose() {
    Wakelock.disable();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _renderingWidget?.dispose();
    Sentry.getSpan()?.finish(status: const SpanStatus.ok());
    _timer?.cancel();
    _maxTimeTokenTimer?.cancel();
    super.dispose();
  }

  void _disposeCurrentDisplay() {
    _renderingWidget?.dispose();
  }

  Future<bool> _clearPrevious() async {
    _renderingWidget?.clearPrevious();
    return true;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateWebviewSize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: BlocConsumer<FeedBloc, FeedState>(listener: (context, state) {
        if (state.isFinishedOnBoarding()) {
          setMaxTimeToken();
          return;
        }

        if (state.viewingFeedEvent?.id != null &&
            latestEvent?.id != state.viewingFeedEvent?.id) {
          setMaxTimeToken();
        }

        final neededIdentities = [
          state.viewingToken?.artistName ?? '',
          state.viewingFeedEvent?.recipient ?? ''
        ];
        neededIdentities.removeWhere((element) => element == '');

        if (neededIdentities.isNotEmpty) {
          context.read<IdentityBloc>().add(GetIdentityEvent(neededIdentities));
        }
      }, builder: (context, state) {
        if (state.isFinishedOnBoarding() &&
            (state.appFeedData == null || state.viewingFeedEvent == null)) {
          return _emptyOrLoadingDiscoveryWidget(state.appFeedData);
        }

        latestToken = state.viewingToken;
        latestEvent = state.viewingFeedEvent;

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (dragEndDetails) {
                      if (dragEndDetails.primaryVelocity! < -300) {
                        _disposeCurrentDisplay();
                        context.read<FeedBloc>().add(MoveToNextFeedEvent());
                      } else if (dragEndDetails.primaryVelocity! > 300) {
                        _disposeCurrentDisplay();
                        context.read<FeedBloc>().add(MoveToPreviousFeedEvent());
                      }
                    },
                    child: Container(
                      color: theme.colorScheme.primary,
                      child: Center(
                          child: state.isFinishedOnBoarding()
                              ? _getArtworkPreviewView(state.viewingToken)
                              : _getOnBoardingView(state.onBoardingStep)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: state.isFinishedOnBoarding()
                        ? _controlView(
                            state.viewingFeedEvent!, state.viewingToken)
                        : _controlViewOnBoarding(),
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

    final identityState = context.watch<IdentityBloc>().state;
    final followingName =
        event.recipient.toIdentityOrMask(identityState.identityMap) ??
            event.recipient;

    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/images/iconInfo.svg",
              color: AppColor.secondarySpanishGrey),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      followingName,
                      style: theme.textTheme.atlasWhiteBold12,
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
                          text: 'nft currently indexing...',
                          style: theme.textTheme.atlasWhiteItalic12,
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
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
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
                  "Autonomy",
                  style: theme.textTheme.atlasWhiteBold12,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "introducing Discovery",
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

    final identityState = context.watch<IdentityBloc>().state;
    final followingName =
        event.recipient.toIdentityOrMask(identityState.identityMap) ??
            event.recipient;
    final artistName =
        asset.artistName?.toIdentityOrMask(identityState.identityMap);
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        followingName,
                        style: theme.textTheme.atlasWhiteBold12,
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
                            text: asset.title.isEmpty ? 'nft' : asset.title,
                            style: theme.textTheme.atlasWhiteItalic12,
                          ),
                          if (event.action == 'transfer' &&
                              artistName != null) ...[
                            TextSpan(
                                text: ' by $artistName',
                                style: theme.primaryTextTheme.headline5),
                          ]
                        ],
                      )),
                ],
              ),
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
    _clearPrevious();

    Navigator.of(context).pushNamed(
      AppRouter.feedArtworkDetailsPage,
      arguments: context.read<FeedBloc>(),
    );
  }

  _updateWebviewSize() {
    if (_renderingWidget != null &&
        _renderingWidget is WebviewNFTRenderingWidget) {
      (_renderingWidget as WebviewNFTRenderingWidget).updateWebviewSize();
    }
  }

  Widget _getOnBoardingView(int step) {
    final theme = Theme.of(context);

    final String assetPath;
    final String title;

    switch (step) {
      case 1:
        assetPath = "assets/images/feed_onboarding_insight.png";
        title = "Get insights about the artwork";
        break;
      case 2:
        assetPath = "assets/images/feed_onboarding_swipe.png";
        title = "Swipe to discover more artworks";
        break;
      default:
        assetPath = "assets/images/feed_onboarding.png";
        title = "Discover what your collected artists mint or collect";
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

  Widget _getArtworkPreviewView(AssetToken? token) {
    if (token == null) {
      _missingToken = true;
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

    if (_renderingWidget == null ||
        _renderingWidget!.previewURL != latestToken?.previewURL) {
      _renderingWidget = buildRenderingWidget(context, token);
    }

    return Container(child: _renderingWidget!.build(context));
  }

  Widget _emptyOrLoadingDiscoveryWidget(AppFeedData? appFeedData) {
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);

    return Padding(
      padding: pageEdgeInsets.copyWith(top: safeAreaTop + 6, right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              previewCloseIcon(context),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Discovery",
            style: theme.primaryTextTheme.headline1,
          ),
          const SizedBox(height: 48),
          if (appFeedData == null) ...[
            Center(
                child:
                    loadingIndicator(valueColor: theme.colorScheme.secondary)),
          ] else if (appFeedData.events.isEmpty) ...[
            Text(
              'Your favorite artists haven’t created or collected anything new yet. Once they do, you can view it here.',
              style: theme.primaryTextTheme.bodyText1,
            )
          ]
        ],
      ),
    );
  }
}
