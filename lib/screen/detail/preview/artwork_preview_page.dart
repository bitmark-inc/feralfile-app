//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_bloc.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_state.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_view.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cast/cast.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_to_airplay/airplay_route_picker_view.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:photo_view/photo_view.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shake/shake.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

enum AUCastDeviceType { Airplay, Chromecast }

class AUCastDevice {
  final AUCastDeviceType type;
  bool isActivated = false;
  final CastDevice? chromecastDevice;
  CastSession? chromecastSession;

  AUCastDevice(this.type, [this.chromecastDevice]);
}

class ArtworkPreviewPage extends StatefulWidget {
  final ArtworkDetailPayload payload;

  const ArtworkPreviewPage({Key? key, required this.payload}) : super(key: key);

  @override
  State<ArtworkPreviewPage> createState() => _ArtworkPreviewPageState();
}

class _ArtworkPreviewPageState extends State<ArtworkPreviewPage>
    with
        RouteAware,
        WidgetsBindingObserver,
        AfterLayoutMixin<ArtworkPreviewPage> {
  VideoPlayerController? _controller;
  bool isFullscreen = false;
  AssetToken? asset;
  late int currentIndex;
  WebViewController? _webViewController;
  Future<List<CastDevice>> _castDevicesFuture = CastDiscoveryService().search();

  static List<AUCastDevice> _defaultCastDevices = [
    AUCastDevice(AUCastDeviceType.Airplay)
  ];

  List<AUCastDevice> _castDevices = [];

  ShakeDetector? _detector;

  @override
  void afterFirstLayout(BuildContext context) {
    // Calling the same function "after layout" to resolve the issue.
    _detector = ShakeDetector.autoStart(onPhoneShake: () {
      if (isFullscreen) {
        setState(() {
          isFullscreen = false;
          if (Platform.isAndroid) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
          }
        });
      }
    });

    _detector?.startListening();

    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void initState() {
    super.initState();

    currentIndex = widget.payload.currentIndex;
    final id = widget.payload.ids[currentIndex];

    context
        .read<ArtworkPreviewBloc>()
        .add(ArtworkPreviewGetAssetTokenEvent(id));
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    enableLandscapeMode();
    Wakelock.enable();
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    enableLandscapeMode();
    Wakelock.enable();
    _controller?.play();
    _webViewController
        ?.runJavascript("document.getElementsByTagName('video')[0].play()");
    super.didPopNext();
  }

  @override
  void dispose() async {
    disableLandscapeMode();
    Wakelock.disable();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance?.removeObserver(this);
    _stopAllChromecastDevices();
    _controller?.dispose();
    _controller = null;
    _webViewController = null;
    _detector?.stopListening();
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    }
    Sentry.getSpan()?.finish(status: SpanStatus.ok());
    super.dispose();
  }

  void _disposeCurrentDisplay() {
    _stopAllChromecastDevices();
    _controller?.dispose();
    _controller = null;
    loadedPath = null;
    _webViewController = null;
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
      body: BlocConsumer<ArtworkPreviewBloc, ArtworkPreviewState>(
          listener: (context, state) {
        if (state.asset?.artistName == null) return;
        context
            .read<IdentityBloc>()
            .add(GetIdentityEvent([state.asset!.artistName!]));
      }, builder: (context, state) {
        if (state.asset != null) {
          asset = state.asset!;
          Sentry.startTransaction("view: " + asset!.id, "load");

          if (asset!.medium == "video" && loadedPath != asset!.previewURL) {
            _startPlay(asset!.previewURL!);
          }

          final identityState = context.watch<IdentityBloc>().state;
          final artistName =
              asset?.artistName?.toIdentityOrMask(identityState.identityMap);

          return SafeArea(
              top: !isFullscreen,
              bottom: false,
              left: !isFullscreen,
              right: !isFullscreen,
              child: Column(
                children: [
                  !isFullscreen
                      ? Container(
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              _titleAndArtistNameWidget(asset!, artistName),
                              IconButton(
                                onPressed: () {
                                  currentIndex = currentIndex <= 0
                                      ? widget.payload.ids.length - 1
                                      : currentIndex - 1;
                                  final id = widget.payload.ids[currentIndex];
                                  _disposeCurrentDisplay();
                                  context.read<ArtworkPreviewBloc>().add(
                                      ArtworkPreviewGetAssetTokenEvent(id));
                                },
                                icon: Icon(
                                  CupertinoIcons.back,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  currentIndex = currentIndex >=
                                          widget.payload.ids.length - 1
                                      ? 0
                                      : currentIndex + 1;
                                  final id = widget.payload.ids[currentIndex];
                                  _disposeCurrentDisplay();
                                  context.read<ArtworkPreviewBloc>().add(
                                      ArtworkPreviewGetAssetTokenEvent(id));
                                },
                                icon: Icon(
                                  CupertinoIcons.forward,
                                  color: Colors.white,
                                ),
                              ),
                              _castButton(context),
                              IconButton(
                                onPressed: () async {
                                  setState(() {
                                    isFullscreen = true;
                                  });

                                  if (Platform.isAndroid) {
                                    SystemChrome.setEnabledSystemUIMode(
                                        SystemUiMode.immersiveSticky);
                                  }

                                  if (injector<ConfigurationService>()
                                      .isFullscreenIntroEnabled()) {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return _fullscreenIntroPopup();
                                      },
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(),
                  Expanded(
                    child: Center(
                      child: _getArtworkView(asset!),
                    ),
                  ),
                ],
              ));
        } else {
          return SizedBox();
        }
      }),
    );
  }

  Widget _titleAndArtistNameWidget(AssetToken asset, String? artistName) {
    final isImmediatePlaybackEnabled =
        injector<ConfigurationService>().isImmediatePlaybackEnabled();

    var titleStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        fontFamily: "AtlasGrotesk");
    var artistNameStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w300,
        fontSize: 12,
        fontFamily: "AtlasGrotesk");

    if (isImmediatePlaybackEnabled) {
      titleStyle = makeLinkStyle(titleStyle);
      artistNameStyle = makeLinkStyle(artistNameStyle);
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset.title,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
            if (artistName != null) ...[
              SizedBox(height: 4.0),
              Text(
                "by $artistName",
                overflow: TextOverflow.ellipsis,
                style: artistNameStyle,
              )
            ]
          ],
        ),
        onTap: () {
          if (!isImmediatePlaybackEnabled) return;
          final currentIndex = widget.payload.ids.indexOf(asset.id);

          disableLandscapeMode();
          Wakelock.disable();
          _clearPrevious();
          Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
              arguments: widget.payload.copyWith(currentIndex: currentIndex));
        },
      ),
    );
  }

  Widget _getArtworkView(AssetToken asset) {
    switch (asset.medium) {
      case "image":
        final ext = p.extension(asset.previewURL!);
        return ext == ".svg"
            ? AspectRatio(
                aspectRatio: 1,
                child: Container(
                    color: Colors.white,
                    child: SvgPicture.network(
                      asset.previewURL!,
                      placeholderBuilder: (context) => _previewPlaceholder,
                    )))
            : CachedNetworkImage(
                imageUrl: asset.previewURL!,
                imageBuilder: (context, imageProvider) => PhotoView(
                  imageProvider: imageProvider,
                ),
                placeholder: (context, url) => _previewPlaceholder,
                placeholderFadeInDuration: Duration(milliseconds: 300),
                errorWidget: (context, url, error) => Center(
                  child: SvgPicture.asset(
                    'assets/images/image_error.svg',
                    width: 148,
                    height: 158,
                  ),
                ),
                fit: BoxFit.cover,
              );
      case "video":
        if (_controller != null) {
          return AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          );
        } else {
          return SizedBox();
        }
      default:
        switch (asset.mimeType) {
          case "application/pdf":
            return SfPdfViewer.network(asset.previewURL!,
                key: Key(asset.assetID ?? asset.id));
          default:
            return WebView(
                key: Key(asset.assetID ?? asset.id),
                initialUrl: asset.previewURL,
                zoomEnabled: false,
                initialMediaPlaybackPolicy:
                    AutoMediaPlaybackPolicy.always_allow,
                onWebViewCreated: (WebViewController webViewController) {
                  _webViewController = webViewController;
                  Sentry.getSpan()?.setTag("url", asset.previewURL!);
                },
                onWebResourceError: (WebResourceError error) {
                  Sentry.getSpan()?.throwable = error;
                  Sentry.getSpan()?.finish(status: SpanStatus.internalError());
                },
                onPageFinished: (some) async {
                  Sentry.getSpan()?.finish(status: SpanStatus.ok());
                  final javascriptString = '''
                var meta = document.createElement('meta');
                            meta.setAttribute('name', 'viewport');
                            meta.setAttribute('content', 'width=device-width');
                            document.getElementsByTagName('head')[0].appendChild(meta);
                            document.body.style.overflow = 'hidden';
                ''';
                  await _webViewController?.runJavascript(javascriptString);
                },
                javascriptMode: JavascriptMode.unrestricted,
                allowsInlineMediaPlayback: true,
                backgroundColor: Colors.black);
        }
    }
  }

  Widget get _previewPlaceholder {
    return Center(
      child: CupertinoActivityIndicator(color: Colors.white, radius: 16),
    );
  }

  Widget _fullscreenIntroPopup() {
    return Container(
      height: 300,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Full screen",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  fontFamily: "AtlasGrotesk"),
            ),
            SizedBox(height: 40.0),
            Text(
              "Shake your phone to exit fullscreen mode.",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontFamily: "AtlasGrotesk"),
            ),
            SizedBox(height: 40.0),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "OK",
                    color: Colors.white,
                    textStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: "IBMPlexMono"),
                    onPress: () {
                      Navigator.of(context).pop();
                    },
                  ),
                )
              ],
            ),
            SizedBox(height: 14.0),
            Center(
              child: GestureDetector(
                child: Text(
                  "DON’T SHOW AGAIN",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      fontFamily: "IBMPlexMono"),
                ),
                onTap: () {
                  injector<ConfigurationService>()
                      .setFullscreenIntroEnable(false);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? loadedPath;

  Future<bool> _clearPrevious() async {
    await _controller?.pause();
    await _webViewController
        ?.runJavascript("document.getElementsByTagName('video')[0].pause()");
    return true;
  }

  _updateWebviewSize() {
    if (_webViewController != null) {
      EasyDebounce.debounce(
          'screen_rotate', // <-- An ID for this particular debouncer
          Duration(milliseconds: 100), // <-- The debounce duration
          () => _webViewController?.runJavascript(
              "window.dispatchEvent(new Event('resize'));") // <-- The target method
          );
    }
  }

  Future<void> _initializePlay(String videoPath) async {
    _controller = VideoPlayerController.network(videoPath);
    Sentry.getSpan()?.setTag("url", videoPath);
    _controller!.initialize().then((_) {
      _controller?.play();
      _controller?.setLooping(true);
      setState(() {});
      Sentry.getSpan()?.finish(status: SpanStatus.ok());
    });
  }

  Future<void> _startPlay(String videoPath) async {
    loadedPath = videoPath;

    Future.delayed(const Duration(milliseconds: 200), () {
      _clearPrevious().then((_) {
        _initializePlay(videoPath);
      });
    });
  }

  Widget _castButton(BuildContext context) {
    return InkWell(
      onTap: () => _showCastDialog(context),
      child: SvgPicture.asset('assets/images/cast.svg'),
    );
  }

  Widget _airplayItem(BuildContext context, bool isSubscribed) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);
    return Padding(
        child: SizedBox(
          height: 44,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 41, bottom: 5),
                  child: Text(
                    "Airplay",
                    style: theme.textTheme.headline4?.copyWith(
                        color: isSubscribed
                            ? Colors.white
                            : AppColorTheme.secondaryDimGrey),
                  ),
                ),
              ),
              isSubscribed
                  ? AirPlayRoutePickerView(
                      tintColor: Colors.grey,
                      activeTintColor: Colors.grey,
                      backgroundColor: Colors.transparent,
                      prioritizesVideoDevices: true,
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.airplay_outlined,
                          color: AppColorTheme.secondaryDimGrey),
                    ),
            ],
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 6));
  }

  Widget _castingListView(
      BuildContext context, List<AUCastDevice> devices, bool isSubscribed) {
    final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);
    return ConstrainedBox(
        constraints: new BoxConstraints(
          minHeight: 35.0,
          maxHeight: 160.0,
        ),
        child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: ((context, index) {
              final device = devices[index];

              switch (device.type) {
                case AUCastDeviceType.Airplay:
                  return _airplayItem(context, isSubscribed);
                case AUCastDeviceType.Chromecast:
                  return GestureDetector(
                    child: Padding(
                      child: Row(
                        children: [
                          Icon(Icons.cast,
                              color: isSubscribed
                                  ? Colors.white
                                  : AppColorTheme.secondaryDimGrey),
                          SizedBox(width: 17),
                          Text(
                            device.chromecastDevice!.name,
                            style: theme.textTheme.headline4?.copyWith(
                                color: isSubscribed
                                    ? Colors.white
                                    : AppColorTheme.secondaryDimGrey),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 17),
                    ),
                    onTap: isSubscribed
                        ? () {
                            UIHelper.hideInfoDialog(context);
                            var copiedDevice = _castDevices[index];
                            if (copiedDevice.isActivated) {
                              _stopAndDisconnectChomecast(index);
                            } else {
                              _connectAndCast(index);
                            }

                            // invert the state
                            copiedDevice.isActivated =
                                !copiedDevice.isActivated;
                            _castDevices[index] = copiedDevice;
                          }
                        : null,
                  );
              }
            }),
            separatorBuilder: ((context, index) => Divider(
                  thickness: 1,
                  color: AppColorTheme.secondarySpanishGrey,
                )),
            itemCount: devices.length));
  }

  Future<void> _showCastDialog(BuildContext context) {
    return UIHelper.showDialog(
        context,
        "Select a device",
        FutureBuilder<List<CastDevice>>(
          future: _castDevicesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData ||
                snapshot.data!.isEmpty ||
                snapshot.hasError) {
              if (asset?.medium == "video") {
                _castDevices = _defaultCastDevices;
              }
            } else {
              _castDevices = (asset?.medium == "video"
                      ? _defaultCastDevices
                      : List<AUCastDevice>.empty()) +
                  snapshot.data!
                      .map((e) => AUCastDevice(AUCastDeviceType.Chromecast, e))
                      .toList();
            }

            var castDevices = _castDevices;
            if (asset?.medium == "image") {
              // remove the airplay option
              castDevices = _castDevices
                  .where((element) => element.type != AUCastDeviceType.Airplay)
                  .toList();
            }

            final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

            return FutureBuilder<bool>(
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!) {
                    return Column(
                      children: [
                        _castingListView(context, castDevices, true),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "CANCEL",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: "IBMPlexMono"),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Get more Autonomy",
                              style: theme.textTheme.headline4,
                            ),
                            BlocProvider.value(
                              value: UpgradesBloc(injector(), injector()),
                              child: _SubscribeView(),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Subscribe to play your collection on external devices.",
                          style: theme.textTheme.bodyText1,
                        ),
                        SizedBox(height: 20),
                        _castingListView(context, castDevices, false),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "CANCEL",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: "IBMPlexMono"),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  }
                },
                future: injector<IAPService>().isSubscribed());
          },
        ),
        isDismissible: true);
  }

  Future<void> _connectAndCast(int index) async {
    final device = _castDevices[index];
    if (device.chromecastDevice == null) return;
    final session = await CastSessionManager()
        .startSession(device.chromecastDevice!, Duration(seconds: 5));
    device.chromecastSession = session;
    _castDevices[index] = device;

    log.info("[Chromecast] Connecting to ${device.chromecastDevice!.name}");
    session.stateStream.listen((state) {
      log.info("[Chromecast] device status: ${state.name}");
      if (state == CastSessionState.connected) {
        log.info(
            "[Chromecast] send cast message with url: ${asset!.previewURL!}");
      }
    });

    var i = 0;

    session.messageStream.listen((message) {
      i += 1;

      print('receive message: $message');

      if (i == 2) {
        Future.delayed(Duration(seconds: 5)).then((x) {
          _sendMessagePlayVideo(session);
        });
      }
    });

    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': 'CC1AD845', // set the appId of your app here
    });
  }

  void _sendMessagePlayVideo(CastSession session) {
    var message = {
      // Here you can plug an URL to any mp4, webm, mp3 or jpg file with the proper contentType.
      'contentId': asset!.previewURL!,
      'contentType': lookupMimeType(asset!.previewURL!),
      'streamType': 'BUFFERED',
      // or LIVE

      // Title and cover displayed while buffering
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': asset!.title,
        'images': [
          {'url': asset!.previewURL!}
        ]
      }
    };

    session.sendMessage(CastSession.kNamespaceMedia, {
      'type': 'LOAD',
      'autoPlay': true,
      'currentTime': 0,
      'media': message,
    });
  }

  void _stopAndDisconnectChomecast(int index) {
    final session = _castDevices[index].chromecastSession;
    session?.close();
  }

  void _stopAllChromecastDevices() {
    _castDevices.forEach((element) {
      element.chromecastSession?.close();
    });
    _castDevices = [];
  }
}

class _SubscribeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.read<UpgradesBloc>().add(UpgradeQueryInfoEvent());
    return BlocBuilder<UpgradesBloc, UpgradeState>(builder: (context, state) {
      return Container(
          height: 24.0,
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // <-- Radius
                ),
                side: BorderSide(width: 1.0, color: Colors.white),
                // maximumSize: Size.fromHeight(30)
              ),
              onPressed: () => UpgradesView.showSubscriptionDialog(
                      context, state.productDetails?.price, (() {
                    context.read<UpgradesBloc>().add(UpgradePurchaseEvent());
                    Navigator.of(context).pop();
                  })),
              child: Text(
                "SUBSCRIBE",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    fontFamily: "IBMPlexMono"),
              )));
    });
  }
}
