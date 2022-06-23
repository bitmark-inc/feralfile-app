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
  bool _missingToken = false;

  @override
  void initState() {
    super.initState();

    context.read<FeedBloc>().add(GetFeedsEvent());

    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      context.read<FeedBloc>().add(RetryMissingTokenInFeedsEvent());
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
        if (state.viewingToken?.artistName == null) return;
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

        return Container(
            child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.loose,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: (details) {
                      if (details.delta.dx <= -8) {
                        swipeDirection = 'left';
                      } else if (details.delta.dx >= 8) {
                        swipeDirection = 'right';
                      }
                    },
                    onPanEnd: (details) {
                      if (swipeDirection == null) return;
                      if (swipeDirection == 'left') {
                        context.read<FeedBloc>().add(MoveToNextFeedEvent());
                        _disposeCurrentDisplay();
                      }
                      if (swipeDirection == 'right') {
                        context.read<FeedBloc>().add(MoveToPreviousFeedEvent());
                        _disposeCurrentDisplay();
                      }

                      swipeDirection = null;
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
      padding: EdgeInsets.only(top: safeAreaTop),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              disabledColor: Colors.black,
              onPressed: () => null,
              icon: SvgPicture.asset("assets/images/iconInfo.svg",
                  color: AppColorTheme.secondarySpanishGrey)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Text(followingName, style: theme.textTheme.bodyText1),
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
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: 32,
            ),
          ),
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
      padding: EdgeInsets.only(top: safeAreaTop),
      child: GestureDetector(
        onTap: () => _moveToInfo(asset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: SvgPicture.asset("assets/images/iconInfo.svg",
                  color: Colors.white),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    Text(followingName, style: theme.textTheme.bodyText1),
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
                            text: asset.title,
                            style: theme.textTheme.caption,
                          ),
                          if (event.action == 'transfer') ...[
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
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: 32,
              ),
            ),
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

    _renderingWidget = buildRenderingWidget(token);
    return _renderingWidget!.build(context);
  }

  Widget _emptyOrLoadingDiscoveryWidget(AppFeedData? appFeedData) {
    return Padding(
      padding: pageEdgeInsets,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
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
