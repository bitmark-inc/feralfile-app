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
import 'package:autonomy_flutter/screen/detail/report_rendering_issue/any_problem_nft_widget.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_box_view.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:cast/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_to_airplay/airplay_route_picker_view.dart';
import 'package:mime/mime.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shake/shake.dart';
import 'package:wakelock/wakelock.dart';

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
  bool isFullscreen = false;
  AssetToken? asset;
  late int currentIndex;
  INFTRenderingWidget? _renderingWidget;

  final Future<List<CastDevice>> _castDevicesFuture = CastDiscoveryService().search();
  String? swipeDirection;


  static final List<AUCastDevice> _defaultCastDevices =
  Platform.isIOS ? [AUCastDevice(AUCastDeviceType.Airplay)] : [];

  List<AUCastDevice> _castDevices = [];

  ShakeDetector? _detector;

  @override
  void afterFirstLayout(BuildContext context) {
    // Calling the same function "after layout" to resolve the issue.
    _detector = ShakeDetector.autoStart(onPhoneShake: () {
      if (isFullscreen) {
        setState(() {
          isFullscreen = false;
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
              overlays: SystemUiOverlay.values);
        });
      }
    });

    _detector?.startListening();

    WidgetsBinding.instance.addObserver(this);
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

    _renderingWidget?.didPopNext();
    super.didPopNext();
  }

  @override
  void dispose() async {
    disableLandscapeMode();
    Wakelock.disable();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _stopAllChromecastDevices();
    _renderingWidget?.dispose();

    _detector?.stopListening();
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    }
    Sentry.getSpan()?.finish(status: const SpanStatus.ok());
    super.dispose();
  }

  void _disposeCurrentDisplay() {
    _stopAllChromecastDevices();
    _renderingWidget?.dispose();
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
          Sentry.startTransaction("view: ${asset!.id}", "load");

          return SafeArea(
              top: false,
              bottom: false,
              left: !isFullscreen,
              right: !isFullscreen,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragEnd: (dragEndDetails) {
                            if (isFullscreen) {
                              return;
                            }
                            if (dragEndDetails.primaryVelocity! < -300) {
                              _moveNextToken();
                            } else if (dragEndDetails.primaryVelocity! > 300) {
                              _movePreviousToken();
                            }
                          },
                          child: Center(
                            child: _getArtworkView(asset!),
                          ),
                        ),
                        // ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Opacity(
                              opacity: isFullscreen ? 0 : 1,
                              child: _controlView(asset!)),
                        ),

                        if (!isFullscreen) ...[
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Opacity(
                              // height: !isFullscreen ? 64 : 0,
                              opacity: isFullscreen ? 0 : 1,
                              child: SizedBox(
                                height: 64,
                                child: AnyProblemNFTWidget(
                                    asset: asset!,
                                    theme: AuThemeManager.get(
                                        AppTheme.anyProblemNFTDarkTheme)),
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ],
              ));
        } else {
          return const SizedBox();
        }
      }),
    );
  }

  Widget _controlView(AssetToken asset) {
    final identityState = context.watch<IdentityBloc>().state;
    final artistName =
        asset.artistName?.toIdentityOrMask(identityState.identityMap);
    double safeAreaTop = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.black,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _moveToInfo(asset),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/images/iconInfo.svg",
                      color: Colors.white),
                  const SizedBox(width: 13),
                  _titleAndArtistNameWidget(asset, artistName),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
          _castButton(context),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              setState(() {
                isFullscreen = true;
              });

              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

              if (injector<ConfigurationService>().isFullscreenIntroEnabled()) {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return _fullscreenIntroPopup();
                  },
                );
              }
            },
            icon: const Icon(
              Icons.fullscreen,
              color: Colors.white,
              size: 32,
            ),
          ),
          previewCloseIcon(context),
        ],
      ),
    );
  }

  Future _moveToInfo(AssetToken asset) async {
    final isImmediateInfoViewEnabled =
        injector<ConfigurationService>().isImmediateInfoViewEnabled();

    final currentIndex = widget.payload.ids.indexOf(asset.id);
    if (isImmediateInfoViewEnabled &&
        currentIndex == widget.payload.currentIndex) {
      Navigator.of(context).pop();
      return;
    }

    disableLandscapeMode();
    Wakelock.disable();
    _clearPrevious();
    Navigator.of(context).pushNamed(AppRouter.artworkDetailsPage,
        arguments: widget.payload.copyWith(currentIndex: currentIndex));
  }

  Future _movePreviousToken() async {
    currentIndex =
        currentIndex <= 0 ? widget.payload.ids.length - 1 : currentIndex - 1;
    final id = widget.payload.ids[currentIndex];
    _disposeCurrentDisplay();
    context
        .read<ArtworkPreviewBloc>()
        .add(ArtworkPreviewGetAssetTokenEvent(id));
  }

  Future _moveNextToken() async {
    currentIndex =
        currentIndex >= widget.payload.ids.length - 1 ? 0 : currentIndex + 1;
    final id = widget.payload.ids[currentIndex];
    _disposeCurrentDisplay();
    context
        .read<ArtworkPreviewBloc>()
        .add(ArtworkPreviewGetAssetTokenEvent(id));
  }

  Widget _titleAndArtistNameWidget(AssetToken asset, String? artistName) {
    final theme = AuThemeManager.get(AppTheme.previewNFTTheme);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            asset.title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyText1,
          ),
          if (artistName != null) ...[
            const SizedBox(height: 4.0),
            Text(
              "by $artistName",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyText2,
            )
          ]
        ],
      ),
    );
  }

  Widget _getArtworkView(AssetToken asset) {
    if (_renderingWidget == null ||
        _renderingWidget!.previewURL != asset.previewURL) {
      _renderingWidget = buildRenderingWidget(context, asset);
    }

    return Container(
      child: _renderingWidget?.build(context),
    );
  }

  Widget _fullscreenIntroPopup() {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              "Full screen",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  fontFamily: "AtlasGrotesk"),
            ),
            const SizedBox(height: 40.0),
            const Text(
              "Shake your phone to exit fullscreen mode.",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontFamily: "AtlasGrotesk"),
            ),
            const SizedBox(height: 40.0),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "OK",
                    color: Colors.white,
                    textStyle: const TextStyle(
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
            const SizedBox(height: 14.0),
            Center(
              child: GestureDetector(
                child: const Text(
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

  Future<bool> _clearPrevious() async {
    _renderingWidget?.clearPrevious();
    return true;
  }

  _updateWebviewSize() {
    if (_renderingWidget != null &&
        _renderingWidget is WebviewNFTRenderingWidget) {
      (_renderingWidget as WebviewNFTRenderingWidget).updateWebviewSize();
    }
  }

  Widget _castButton(BuildContext context) {
    if (asset?.medium == "video" ||
        asset?.medium == "image" ||
        asset?.mimeType?.startsWith("audio/") == true) {
      return InkWell(
        onTap: () => _showCastDialog(context),
        child: SvgPicture.asset('assets/images/chromecast.svg'),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _airplayItem(BuildContext context, bool isSubscribed) {
    final theme = AuThemeManager.get(AppTheme.sheetTheme);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SizedBox(
          height: 44,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 41, bottom: 5),
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
                  ? const AirPlayRoutePickerView(
                      tintColor: Colors.grey,
                      activeTintColor: Colors.grey,
                      backgroundColor: Colors.transparent,
                      prioritizesVideoDevices: true,
                    )
                  : const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.airplay_outlined,
                          color: AppColorTheme.secondaryDimGrey),
                    ),
            ],
          ),
        ));
  }

  Widget _castingListView(
      BuildContext context, List<AUCastDevice> devices, bool isSubscribed) {
    final theme = AuThemeManager.get(AppTheme.sheetTheme);
    return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 35.0,
          maxHeight: 160.0,
        ),
        child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: ((context, index) {
              final device = devices[index];

              switch (device.type) {
                case AUCastDeviceType.Airplay:
                  return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        injector<AWSService>()
                            .storeEventWithDeviceData("stream_airplay");
                      },
                      child: _airplayItem(context, isSubscribed));
                case AUCastDeviceType.Chromecast:
                  return GestureDetector(
                    onTap: isSubscribed
                        ? () {
                            injector<AWSService>()
                                .storeEventWithDeviceData("stream_chromecast");
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      child: Row(
                        children: [
                          Icon(Icons.cast,
                              color: isSubscribed
                                  ? Colors.white
                                  : AppColorTheme.secondaryDimGrey),
                          const SizedBox(width: 17),
                          Text(
                            device.chromecastDevice!.name,
                            style: theme.textTheme.headline4?.copyWith(
                                color: isSubscribed
                                    ? Colors.white
                                    : AppColorTheme.secondaryDimGrey),
                          ),
                        ],
                      ),
                    ),
                  );
              }
            }),
            separatorBuilder: ((context, index) => const Divider(
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

            final theme = AuThemeManager.get(AppTheme.sheetTheme);

            return FutureBuilder<bool>(
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!) {
                    return Column(
                      children: [
                        _castingListView(context, castDevices, true),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "CANCEL",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: "IBMPlexMono"),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        UpgradeBoxView.getMoreAutonomyWidget(
                            theme, PremiumFeature.AutonomyTV),
                        _castingListView(context, castDevices, false),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "CANCEL",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: "IBMPlexMono"),
                          ),
                        ),
                        const SizedBox(height: 20),
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
        .startSession(device.chromecastDevice!, const Duration(seconds: 5));
    device.chromecastSession = session;
    _castDevices[index] = device;

    log.info("[Chromecast] Connecting to ${device.chromecastDevice!.name}");
    session.stateStream.listen((state) {
      log.info("[Chromecast] device status: ${state.name}");
      if (state == CastSessionState.connected) {
        log.info(
            "[Chromecast] send cast message with url: ${asset!.previewURL!}");
        _sendMessagePlayVideo(session);
      }
    });

    session.messageStream.listen((message) {
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
      'contentType': asset?.mimeType ?? lookupMimeType(asset!.previewURL!),
      'streamType': 'BUFFERED',
      // or LIVE

      // Title and cover displayed while buffering
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': asset!.title,
        'images': [
          {'url': asset?.thumbnailURL ?? ''},
          {'url': asset!.previewURL!},
        ]
      }
    };

    session.sendMessage(CastSession.kNamespaceMedia, {
      'type': 'LOAD',
      'autoPlay': true,
      'currentTime': 0,
      'media': message,
    });
    log.info("[Chromecast] Send message play video: $message");
  }

  void _stopAndDisconnectChomecast(int index) {
    final session = _castDevices[index].chromecastSession;
    session?.close();
  }

  void _stopAllChromecastDevices() {
    for (var element in _castDevices) {
      element.chromecastSession?.close();
    }
    _castDevices = [];
  }
}
