//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/feed/feed_bloc.dart';
import 'package:autonomy_flutter/service/feed_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock/wakelock.dart';
import 'package:autonomy_flutter/util/string_ext.dart';

class FeedPreviewPage extends StatefulWidget {
  const FeedPreviewPage({Key? key}) : super(key: key);

  @override
  State<FeedPreviewPage> createState() => _FeedPreviewPageState();
}

class _FeedPreviewPageState extends State<FeedPreviewPage>
    with RouteAware, WidgetsBindingObserver {
  String? swipeDirection;
  INFTRenderingWidget? _renderingWidget;
  Timer? _timer;
  Timer? _maxTimeTokenTimer;
  bool _missingToken = false;
  AssetToken? latestToken;

  @override
  void initState() {
    super.initState();

    context.read<FeedBloc>().add(GetFeedsEvent());

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      context.read<FeedBloc>().add(RetryMissingTokenInFeedsEvent());
    });
  }

  void setMaxTimeToken() {
    _maxTimeTokenTimer?.cancel();
    _maxTimeTokenTimer = Timer(Duration(seconds: 15), () {
      context.read<FeedBloc>().add(MoveToNextFeedEvent());
    });
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
    super.didPopNext();
  }

  @override
  void dispose() {
    Wakelock.disable();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _renderingWidget?.dispose();
    Sentry.getSpan()?.finish(status: SpanStatus.ok());
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<FeedBloc, FeedState>(listener: (context, state) {
        if (state.viewingToken?.id != null &&
            latestToken?.id != state.viewingToken?.id) {
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
        if (state.appFeedData == null || state.viewingFeedEvent == null)
          return _emptyOrLoadingDiscoveryWidget(state.appFeedData);

        // dispose previous playback when viewingToken is changed
        if (latestToken != null && latestToken?.id == state.viewingToken?.id) {
          _disposeCurrentDisplay();
        }

        latestToken = state.viewingToken;

        return Container(
            child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.loose,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (dragEndDetails) {
                      print(dragEndDetails.primaryVelocity);
                      if (dragEndDetails.primaryVelocity! < -300) {
                        context.read<FeedBloc>().add(MoveToNextFeedEvent());
                      } else if (dragEndDetails.primaryVelocity! > 300) {
                        context.read<FeedBloc>().add(MoveToPreviousFeedEvent());
                      }
                    },
                    child: Container(
                      color: Colors.black,
                      child: Center(
                          child: _getArtworkPreviewView(state.viewingToken)),
                    ),
                  ),
                  // ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: _controlView(
                        state.viewingFeedEvent!, state.viewingToken),
                  ),
                ],
              ),
            ),
          ],
        ));
      }),
    );
  }

  Widget _controlViewWhenNoAsset(FeedEvent event) {
    double safeAreaTop = MediaQuery.of(context).padding.top;

    final identityState = context.watch<IdentityBloc>().state;
    final followingName =
        event.recipient.toIdentityOrMask(identityState.identityMap) ??
            event.recipient;

    final theme = AuThemeManager.get(AppTheme.previewNFTTheme);

    return Container(
      color: Colors.black,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/images/iconInfo.svg",
              color: AppColorTheme.secondarySpanishGrey),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      followingName,
                      style: theme.textTheme.bodyText1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(" • ", style: theme.textTheme.bodyText2),
                  Text(getDateTimeRepresentation(event.timestamp.toLocal()),
                      style: theme.textTheme.bodyText2),
                ]),
                SizedBox(height: 4),
                RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: theme.textTheme.bodyText2,
                      children: <TextSpan>[
                        TextSpan(
                          text: event.actionRepresentation + ' ',
                        ),
                        TextSpan(
                          text: 'nft currently indexing...',
                          style: theme.textTheme.caption,
                        ),
                      ],
                    )),
              ],
            ),
          ),
          SizedBox(),
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
    final theme = AuThemeManager.get(AppTheme.previewNFTTheme);

    return Container(
      color: Colors.black,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _moveToInfo(asset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/iconInfo.svg", color: Colors.white),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        followingName,
                        style: theme.textTheme.bodyText1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(" • ", style: theme.textTheme.bodyText2),
                    Text(getDateTimeRepresentation(event.timestamp.toLocal()),
                        style: theme.textTheme.bodyText2),
                  ]),
                  SizedBox(height: 4),
                  RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: theme.textTheme.bodyText2,
                        children: <TextSpan>[
                          TextSpan(
                            text: event.actionRepresentation + ' ',
                          ),
                          TextSpan(
                            text: asset.title.isEmpty ? 'nft' : asset.title,
                            style: theme.textTheme.caption,
                          ),
                          if (event.action == 'transfer' &&
                              artistName != null) ...[
                            TextSpan(
                                text: ' by $artistName',
                                style: theme.textTheme.bodyText2),
                          ]
                        ],
                      )),
                ],
              ),
            ),
            SizedBox(),
            previewCloseIcon(context),
          ],
        ),
      ),
    );
  }

  Future _moveToInfo(AssetToken asset) async {
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

  Widget _getArtworkPreviewView(AssetToken? token) {
    if (token == null) {
      _missingToken = true;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      return Container(
        color: AppColorTheme.secondarySpanishGrey,
        width: screenWidth,
        height: screenHeight * 0.55,
      );
    }

    if (_missingToken) {
      Vibrate.feedback(FeedbackType.light);
      _missingToken = false;
    }

    _renderingWidget = buildRenderingWidget(context, token);
    return Container(child: _renderingWidget!.build(context));
  }

  Widget _emptyOrLoadingDiscoveryWidget(AppFeedData? appFeedData) {
    double safeAreaTop = MediaQuery.of(context).padding.top;

    return Padding(
      padding: pageEdgeInsets.copyWith(top: safeAreaTop + 6, right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              previewCloseIcon(context),
            ],
          ),
          SizedBox(height: 24),
          Text(
            "Discovery",
            style: appTextTheme.headline1?.copyWith(color: Colors.white),
          ),
          SizedBox(height: 48),
          if (appFeedData == null) ...[
            Center(child: loadingIndicator(valueColor: Colors.white)),
          ] else if (appFeedData.events.isEmpty) ...[
            Text(
              'Your favorite artists haven’t created or collected anything new yet. Once they do, you can view it here.',
              style: appTextTheme.bodyText1?.copyWith(color: Colors.white),
            )
          ]
        ],
      ),
    );
  }
}
