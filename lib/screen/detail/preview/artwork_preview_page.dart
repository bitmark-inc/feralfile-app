//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_box_view.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:cast/cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';
import 'package:metric_client/metric_client.dart';
import 'package:mime/mime.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shake/shake.dart';
import 'package:wakelock/wakelock.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';

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
        AfterLayoutMixin<ArtworkPreviewPage>,
        RouteAware,
        WidgetsBindingObserver {
  late PageController controller;
  late ArtworkPreviewBloc _bloc;
  List<AUCastDevice> _castDevices = [];

  ShakeDetector? _detector;

  static final List<AUCastDevice> _defaultCastDevices =
      Platform.isIOS ? [AUCastDevice(AUCastDeviceType.Airplay)] : [];
  final keyboardManagerKey = GlobalKey<KeyboardManagerWidgetState>();

  final Future<List<CastDevice>> _castDevicesFuture =
      CastDiscoveryService().search();
  INFTRenderingWidget? _renderingWidget;

  @override
  void initState() {
    controller = PageController(initialPage: widget.payload.currentIndex);
    _bloc = context.read<ArtworkPreviewBloc>();
    final currentId = widget.payload.ids[widget.payload.currentIndex];
    _bloc.add(ArtworkPreviewGetAssetTokenEvent(currentId));
    super.initState();
  }

  @override
  void dispose() {
    disableLandscapeMode();
    Wakelock.disable();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _stopAllChromecastDevices();

    _detector?.stopListening();
    if (Platform.isAndroid) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    }
    controller.dispose();
    Sentry.getSpan()?.finish(status: const SpanStatus.ok());
    super.dispose();
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
  void afterFirstLayout(BuildContext context) {
    // Calling the same function "after layout" to resolve the issue.
    _detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        _bloc.add(ChangeFullScreen());
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      },
    );

    _detector?.startListening();

    WidgetsBinding.instance.addObserver(this);
  }

  Future _moveToInfo(AssetToken? asset) async {
    if (asset == null) return;
    keyboardManagerKey.currentState?.hideKeyboard();
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

    Navigator.of(context).pushNamed(
      AppRouter.artworkDetailsPage,
      arguments: widget.payload.copyWith(currentIndex: currentIndex),
    );
  }

  void onClickFullScreen() {
    _bloc.add(ChangeFullScreen(isFullscreen: true));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (injector<ConfigurationService>().isFullscreenIntroEnabled()) {
      showModalBottomSheet<void>(
        context: context,
        constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.isMobile
                ? double.infinity
                : Constants.maxWidthModalTablet),
        builder: (BuildContext context) {
          return const FullscreenIntroPopup();
        },
      );
    }
  }

  Future<void> onCastTap(AssetToken? asset) async {
    final canCast = asset?.medium == "video" ||
        asset?.medium == "image" ||
        asset?.mimeType?.startsWith("audio/") == true;

    if (!canCast) {
      return UIHelper.showUnavailableCastDialog(
        context: context,
        assetToken: asset,
      );
    }
    return UIHelper.showDialog(
      context,
      "select_a_device".tr(),
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

          final theme = Theme.of(context);

          return ValueListenableBuilder<Map<String, IAPProductStatus>>(
            valueListenable: injector<IAPService>().purchases,
            builder: (context, purchases, child) {
              return FutureBuilder<bool>(
                builder: (context, subscriptionSnapshot) {
                  final isSubscribed = subscriptionSnapshot.hasData &&
                      subscriptionSnapshot.data == true;
                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        if (!isSubscribed) ...[
                          UpgradeBoxView.getMoreAutonomyWidget(
                              theme, PremiumFeature.AutonomyTV,
                              autoClose: false)
                        ],
                        if (!snapshot.hasData) ...[
                          // Searching for cast devices.
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 42),
                              child: Text(
                                'searching_for_device'.tr(),
                                style: ResponsiveLayout.isMobile
                                    ? theme.textTheme.atlasSpanishGreyBold16
                                    : theme.textTheme.atlasSpanishGreyBold20,
                              ),
                            ),
                          )
                        ],
                        Visibility(
                          visible: snapshot.hasData,
                          child: _castingListView(
                            context,
                            castDevices,
                            isSubscribed,
                            asset: asset,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "cancel".tr(),
                            style: theme.primaryTextTheme.button,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                future: injector<IAPService>().isSubscribed(),
              );
            },
          );
        },
      ),
      isDismissible: true,
    );
  }

  Widget _castingListView(
      BuildContext context, List<AUCastDevice> devices, bool isSubscribed,
      {AssetToken? asset}) {
    final theme = Theme.of(context);

    if (devices.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 42),
          child: Text(
            'no_device_detected'.tr(),
            style: ResponsiveLayout.isMobile
                ? theme.textTheme.atlasSpanishGreyBold16
                : theme.textTheme.atlasSpanishGreyBold20,
          ),
        ),
      );
    }
    final metricClient = injector.get<MetricClientService>();

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
                  onTap: () async {
                    await metricClient.addEvent("stream_airplay");
                  },
                  child: _airplayItem(context, isSubscribed));
            case AUCastDeviceType.Chromecast:
              return GestureDetector(
                onTap: isSubscribed
                    ? () {
                        metricClient.addEvent("stream_chromecast");
                        UIHelper.hideInfoDialog(context);
                        var copiedDevice = _castDevices[index];
                        if (copiedDevice.isActivated) {
                          _stopAndDisconnectChomecast(index);
                        } else {
                          _connectAndCast(index: index, asset: asset);
                        }

                        // invert the state
                        copiedDevice.isActivated = !copiedDevice.isActivated;
                        _castDevices[index] = copiedDevice;
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cast,
                        color: isSubscribed
                            ? theme.colorScheme.secondary
                            : AppColor.secondaryDimGrey,
                      ),
                      const SizedBox(width: 17),
                      Text(
                        device.chromecastDevice!.name,
                        style: theme.primaryTextTheme.headline4?.copyWith(
                          color: isSubscribed
                              ? theme.colorScheme.secondary
                              : AppColor.secondaryDimGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
          }
        }),
        separatorBuilder: ((context, index) => const Divider(
              thickness: 1,
              color: AppColor.secondaryDimGrey,
            )),
        itemCount: devices.length,
      ),
    );
  }

  Widget _airplayItem(BuildContext context, bool isSubscribed) {
    final theme = Theme.of(context);
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
                  "airplay".tr(),
                  style: theme.primaryTextTheme.headline4?.copyWith(
                      color: isSubscribed
                          ? theme.colorScheme.secondary
                          : AppColor.secondaryDimGrey),
                ),
              ),
            ),
            isSubscribed
                ? AirPlayRoutePickerView(
                    tintColor: theme.colorScheme.surface,
                    activeTintColor: theme.colorScheme.surface,
                    backgroundColor: Colors.transparent,
                    prioritizesVideoDevices: true,
                  )
                : const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.airplay_outlined,
                        color: AppColor.secondaryDimGrey),
                  ),
          ],
        ),
      ),
    );
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

  Future<void> _connectAndCast({required int index, AssetToken? asset}) async {
    final device = _castDevices[index];
    if (device.chromecastDevice == null) return;
    if (asset == null) return;
    final session = await CastSessionManager()
        .startSession(device.chromecastDevice!, const Duration(seconds: 5));
    device.chromecastSession = session;
    _castDevices[index] = device;

    log.info("[Chromecast] Connecting to ${device.chromecastDevice!.name}");
    session.stateStream.listen((state) {
      log.info("[Chromecast] device status: ${state.name}");
      if (state == CastSessionState.connected) {
        log.info(
            "[Chromecast] send cast message with url: ${asset.getPreviewUrl()}");
        _sendMessagePlayVideo(session: session, asset: asset);
      }
    });

    session.messageStream.listen((message) {});

    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': 'CC1AD845', // set the appId of your app here
    });
  }

  void _sendMessagePlayVideo(
      {required CastSession session, required AssetToken asset}) {
    var message = {
      // Here you can plug an URL to any mp4, webm, mp3 or jpg file with the proper contentType.
      'contentId': asset.getPreviewUrl() ?? '',
      'contentType':
          asset.mimeType ?? lookupMimeType(asset.getPreviewUrl() ?? ''),
      'streamType': 'BUFFERED',
      // or LIVE

      // Title and cover displayed while buffering
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': asset.title,
        'images': [
          {'url': asset.getThumbnailUrl() ?? ''},
          {'url': asset.getPreviewUrl()},
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      resizeToAvoidBottomInset: false,
      body: BlocConsumer<ArtworkPreviewBloc, ArtworkPreviewState>(
        builder: (context, state) {
          AssetToken? assetToken;
          bool isFullScreen = false;
          if (state is ArtworkPreviewLoadedState) {
            assetToken = state.asset;
            isFullScreen = state.isFullScreen;
          }
          return SafeArea(
            top: false,
            bottom: false,
            left: !isFullScreen,
            right: !isFullScreen,
            child: Column(
              children: [
                Visibility(
                  visible: !isFullScreen,
                  child: ControlView(
                    assetToken: assetToken,
                    onClickInfo: () => _moveToInfo(assetToken),
                    onClickFullScreen: onClickFullScreen,
                    onClickCast: (assetToken) => onCastTap(assetToken),
                    keyboardManagerKey: keyboardManagerKey,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    physics: isFullScreen
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    onPageChanged: (value) {
                      final currentId = widget.payload.ids[value];
                      _bloc.add(ArtworkPreviewGetAssetTokenEvent(currentId));
                      _stopAllChromecastDevices();
                      keyboardManagerKey.currentState?.hideKeyboard();
                    },
                    controller: controller,
                    itemCount: widget.payload.ids.length,
                    itemBuilder: (context, index) => Center(
                      child: ArtworkPreviewWidget(
                        id: widget.payload.ids[index],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        listener: (context, state) {},
      ),
    );
  }
}

class ControlView extends StatelessWidget {
  final AssetToken? assetToken;
  final VoidCallback? onClickFullScreen;
  final Function(AssetToken?)? onClickCast;
  final VoidCallback? onClickInfo;
  final Key? keyboardManagerKey;
  const ControlView({
    Key? key,
    this.assetToken,
    this.onClickFullScreen,
    this.onClickCast,
    this.onClickInfo,
    this.keyboardManagerKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identityBloc = context.read<IdentityBloc>();
    double safeAreaTop = MediaQuery.of(context).padding.top;
    final neededIdentities = [
      assetToken?.artistName ?? '',
    ];

    return Container(
      color: theme.colorScheme.primary,
      height: safeAreaTop + 52,
      padding: EdgeInsets.fromLTRB(15, safeAreaTop, 15, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onClickInfo,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/images/iconInfo.svg",
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          assetToken?.title ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: ResponsiveLayout.isMobile
                              ? theme.textTheme.atlasWhiteBold12
                              : theme.textTheme.atlasWhiteBold14,
                        ),
                        BlocBuilder<IdentityBloc, IdentityState>(
                          bloc: identityBloc
                            ..add(GetIdentityEvent(neededIdentities)),
                          builder: (context, state) {
                            final artistName = assetToken?.artistName
                                ?.toIdentityOrMask(state.identityMap);
                            if (artistName != null) {
                              return Row(
                                children: [
                                  const SizedBox(height: 4.0),
                                  Text(
                                    "by".tr(args: [artistName]),
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.primaryTextTheme.headline5,
                                  )
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
          Visibility(
            visible: (assetToken?.medium == 'software' ||
                    (assetToken?.medium?.isEmpty ?? true)) &&
                Platform.isAndroid,
            child: KeyboardManagerWidget(
              key: keyboardManagerKey,
            ),
          ),
          Visibility(
            visible: assetToken?.medium == 'software' ||
                (assetToken?.medium?.isEmpty ?? true),
            child: const SizedBox(width: 8),
          ),
          CastButton(
            assetToken: assetToken,
            onCastTap: () => onClickCast?.call(assetToken),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClickFullScreen,
            icon: Icon(
              Icons.fullscreen,
              color: theme.colorScheme.secondary,
              size: 32,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: closeIcon(color: theme.colorScheme.secondary),
            tooltip: "CloseArtwork",
          )
        ],
      ),
    );
  }
}

class CastButton extends StatelessWidget {
  final AssetToken? assetToken;
  final VoidCallback? onCastTap;
  const CastButton({Key? key, this.assetToken, this.onCastTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canCast = assetToken?.medium == "video" ||
        assetToken?.medium == "image" ||
        assetToken?.mimeType?.startsWith("audio/") == true;

    return InkWell(
      onTap: onCastTap,
      child: SvgPicture.asset(
        'assets/images/chromecast.svg',
        color: canCast ? theme.colorScheme.secondary : theme.disableColor,
      ),
    );
  }
}

class FullscreenIntroPopup extends StatelessWidget {
  const FullscreenIntroPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      color: theme.colorScheme.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "full_screen".tr(),
              style: theme.primaryTextTheme.headline1,
            ),
            const SizedBox(height: 40.0),
            Text(
              "shake_exit".tr(),
              //"Shake your phone to exit fullscreen mode.",
              style: theme.primaryTextTheme.bodyText1,
            ),
            const SizedBox(height: 40.0),
            Row(
              children: [
                Expanded(
                  child: AuFilledButton(
                    text: "ok".tr(),
                    color: theme.colorScheme.secondary,
                    textStyle: theme.textTheme.button,
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
                child: Text(
                  "dont_show_again".tr(),
                  textAlign: TextAlign.center,
                  style: theme.primaryTextTheme.button,
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
}

class KeyboardManagerWidget extends StatefulWidget {
  const KeyboardManagerWidget({Key? key}) : super(key: key);

  @override
  State<KeyboardManagerWidget> createState() => KeyboardManagerWidgetState();
}

class KeyboardManagerWidgetState extends State<KeyboardManagerWidget> {
  bool _isShowKeyboard = false;

  @override
  void initState() {
    super.initState();
  }

  void showKeyboard() async {
    await SystemChannels.textInput.invokeMethod('TextInput.show');
    setState(() {
      _isShowKeyboard = true;
    });
  }

  void hideKeyboard() async {
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() {
      _isShowKeyboard = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _isShowKeyboard
        ? IconButton(
            icon: Icon(
              Icons.keyboard_alt_outlined,
              color: theme.colorScheme.secondary,
            ),
            onPressed: hideKeyboard,
          )
        : IconButton(
            icon: Icon(
              Icons.keyboard_alt_rounded,
              color: theme.colorScheme.secondary,
            ),
            onPressed: showKeyboard,
          );
  }
}
