//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/artwork_preview_state.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/screen/settings/subscription/upgrade_box_view.dart';
import 'package:autonomy_flutter/service/iap_service.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:cast/cast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_to_airplay/flutter_to_airplay.dart';
import 'package:mime/mime.dart';
import 'package:nft_collection/models/asset_token.dart';
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
  final _focusNode = FocusNode();

  INFTRenderingWidget? _renderingWidget;

  List<ArtworkIdentity> tokens = [];
  Timer? _timer;
  late int initialPage;

  final metricClient = injector.get<MetricClientService>();

  PlayControlModel? playControl;

  @override
  void initState() {
    tokens = List.from(widget.payload.identities);
    final initialTokenID = tokens[widget.payload.currentIndex];
    playControl = widget.payload.playControl;
    if (playControl?.isShuffle ?? false) {
      tokens.shuffle();
    }
    initialPage = tokens.indexOf(initialTokenID);

    controller = PageController(initialPage: initialPage);
    _bloc = context.read<ArtworkPreviewBloc>();
    final currentIdentity = tokens[initialPage];
    _bloc.add(ArtworkPreviewGetAssetTokenEvent(currentIdentity,
        useIndexer: widget.payload.useIndexer));
    super.initState();
  }

  setTimer({int? time}) {
    _timer?.cancel();
    if (playControl != null) {
      final defauftDuration =
          playControl!.timer == 0 ? time ?? 10 : playControl!.timer;
      _timer = Timer.periodic(Duration(seconds: defauftDuration), (timer) {
        if (!(_timer?.isActive ?? false)) return;
        if (controller.page?.toInt() == tokens.length - 1) {
          controller.jumpTo(0);
        } else {
          controller.nextPage(
              duration: const Duration(microseconds: 1), curve: Curves.linear);
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    disableLandscapeMode();
    Wakelock.disable();
    _timer?.cancel();
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
    setTimer();
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

  Future _moveToInfo(AssetToken? assetToken) async {
    if (assetToken == null) return;
    metricClient.addEvent(
      MixpanelEvent.clickArtworkInfo,
      data: {
        "id": assetToken.id,
      },
    );
    keyboardManagerKey.currentState?.hideKeyboard();

    final currentIndex = tokens.indexWhere((element) =>
        element.id == assetToken.id && element.owner == assetToken.owner);
    if (currentIndex == initialPage) {
      Navigator.of(context).pop();
      return;
    }

    disableLandscapeMode();

    Wakelock.disable();
    _timer?.cancel();

    Navigator.of(context).pushNamed(
      AppRouter.artworkDetailsPage,
      arguments: widget.payload.copyWith(
        currentIndex: currentIndex,
        ids: tokens,
      ),
    );
  }

  void onClickFullScreen(AssetToken? assetToken) {
    final theme = Theme.of(context);
    metricClient.addEvent(
      MixpanelEvent.seeArtworkFullScreen,
      data: {
        "id": assetToken?.id,
      },
    );
    _bloc.add(ChangeFullScreen(isFullscreen: true));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.auSuperTeal.withOpacity(0.9),
            borderRadius: BorderRadius.circular(64),
          ),
          child: Text(
            'shake_exit'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.ppMori600Black12,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Future<void> onCastTap(AssetToken? assetToken) async {
    final canCast = assetToken?.medium == "video" ||
        assetToken?.medium == "image" ||
        assetToken?.mimeType?.startsWith("audio/") == true;

    keyboardManagerKey.currentState?.hideKeyboard();

    if (!canCast) {
      return UIHelper.showUnavailableCastDialog(
        context: context,
        assetToken: assetToken,
      );
    }
    return UIHelper.showDialog(
      context,
      "select_device".tr(),
      FutureBuilder<List<CastDevice>>(
        future: CastDiscoveryService().search(),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.isEmpty ||
              snapshot.hasError) {
            if (assetToken?.medium == "video") {
              _castDevices = _defaultCastDevices;
            }
          } else {
            _castDevices = (assetToken?.medium == "video"
                    ? _defaultCastDevices
                    : List<AUCastDevice>.empty()) +
                snapshot.data!
                    .map((e) => AUCastDevice(AUCastDeviceType.Chromecast, e))
                    .toList();
          }

          var castDevices = _castDevices;
          if (assetToken?.medium == "image") {
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
                                    ? theme.textTheme.ppMori400Grey14
                                    : theme.textTheme.ppMori400Grey16,
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
                            assetToken: assetToken,
                          ),
                        ),
                        OutlineButton(
                          onTap: () => Navigator.pop(context),
                          text: "cancel_dialog".tr(),
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
      {AssetToken? assetToken}) {
    final theme = Theme.of(context);

    if (devices.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 42),
          child: Text(
            'no_device_detected'.tr(),
            style: ResponsiveLayout.isMobile
                ? theme.textTheme.ppMori400Grey14
                : theme.textTheme.ppMori400Grey16,
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
                  onTap: () {
                    metricClient.addEvent(MixpanelEvent.streamArtwork, data: {
                      'id': assetToken?.id,
                      'device type': AUCastDeviceType.Airplay.name
                    });
                  },
                  child: _airplayItem(context, isSubscribed));
            case AUCastDeviceType.Chromecast:
              return GestureDetector(
                onTap: isSubscribed
                    ? () {
                        metricClient.addEvent(MixpanelEvent.streamArtwork,
                            data: {
                              'id': assetToken?.id,
                              'device type': AUCastDeviceType.Chromecast.name
                            });
                        UIHelper.hideInfoDialog(context);
                        var copiedDevice = _castDevices[index];
                        if (copiedDevice.isActivated) {
                          _stopAndDisconnectChomecast(index);
                        } else {
                          _connectAndCast(index: index, assetToken: assetToken);
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
                      SvgPicture.asset(
                        'assets/images/cast_icon.svg',
                        color: isSubscribed
                            ? theme.colorScheme.secondary
                            : AppColor.secondaryDimGrey,
                      ),
                      const SizedBox(width: 17),
                      Text(
                        device.chromecastDevice!.name,
                        style: theme.primaryTextTheme.ppMori400White14.copyWith(
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
                  style: theme.primaryTextTheme.ppMori400White14.copyWith(
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
                    child: Icon(
                      Icons.airplay_outlined,
                      color: AppColor.secondaryDimGrey,
                    ),
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

  Future<void> _connectAndCast(
      {required int index, AssetToken? assetToken}) async {
    final device = _castDevices[index];
    if (device.chromecastDevice == null) return;
    if (assetToken == null) return;
    final session = await CastSessionManager()
        .startSession(device.chromecastDevice!, const Duration(seconds: 5));
    device.chromecastSession = session;
    _castDevices[index] = device;

    log.info("[Chromecast] Connecting to ${device.chromecastDevice!.name}");
    session.stateStream.listen((state) {
      log.info("[Chromecast] device status: ${state.name}");
      if (state == CastSessionState.connected) {
        log.info(
            "[Chromecast] send cast message with url: ${assetToken.getPreviewUrl()}");
        _sendMessagePlayVideo(session: session, assetToken: assetToken);
      }
    });

    session.messageStream.listen((message) {});

    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': 'CC1AD845', // set the appId of your app here
    });
  }

  void _sendMessagePlayVideo(
      {required CastSession session, required AssetToken assetToken}) {
    var message = {
      // Here you can plug an URL to any mp4, webm, mp3 or jpg file with the proper contentType.
      'contentId': assetToken.getPreviewUrl() ?? '',
      'contentType': assetToken.mimeType ??
          lookupMimeType(assetToken.getPreviewUrl() ?? ''),
      'streamType': 'BUFFERED',
      // or LIVE

      // Title and cover displayed while buffering
      'metadata': {
        'type': 0,
        'metadataType': 0,
        'title': assetToken.title,
        'images': [
          {'url': assetToken.getGalleryThumbnailUrl() ?? ''},
          {'url': assetToken.getPreviewUrl()},
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
    final identityBloc = context.read<IdentityBloc>();

    return BlocConsumer<ArtworkPreviewBloc, ArtworkPreviewState>(
      builder: (context, state) {
        AssetToken? assetToken;
        bool isFullScreen = false;
        if (state is ArtworkPreviewLoadedState) {
          assetToken = state.assetToken;
          isFullScreen = state.isFullScreen;
        }
        final hasKeyboard = assetToken?.medium == "software" ||
            assetToken?.medium == "other" ||
            assetToken?.medium == null;

        return Scaffold(
          appBar: isFullScreen
              ? null
              : AppBar(
                  backgroundColor: theme.colorScheme.primary,
                  leadingWidth: 0,
                  centerTitle: false,
                  title: GestureDetector(
                    onTap: () => _moveToInfo(assetToken),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assetToken?.title ?? '',
                          style: theme.textTheme.ppMori400White16,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        BlocBuilder<IdentityBloc, IdentityState>(
                          bloc: identityBloc
                            ..add(GetIdentityEvent([
                              assetToken?.artistName ?? '',
                            ])),
                          builder: (context, state) {
                            final artistName = assetToken?.artistName
                                ?.toIdentityOrMask(state.identityMap);
                            if (artistName != null) {
                              return Row(
                                children: [
                                  const SizedBox(height: 4.0),
                                  Expanded(
                                    child: Text(
                                      "by".tr(args: [artistName]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.ppMori400White14,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(
                        maxWidth: 44,
                        maxHeight: 44,
                      ),
                      icon: Icon(
                        AuIcon.close,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                      tooltip: 'close_icon',
                    )
                  ],
                ),
          backgroundColor: theme.colorScheme.primary,
          resizeToAvoidBottomInset: !hasKeyboard,
          body: SafeArea(
            top: false,
            bottom: false,
            left: !isFullScreen,
            right: !isFullScreen,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    child: PageView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (value) {
                        _timer?.cancel();
                        final currentId = tokens[value];
                        _bloc.add(ArtworkPreviewGetAssetTokenEvent(currentId,
                            useIndexer: widget.payload.useIndexer));
                        _stopAllChromecastDevices();
                        keyboardManagerKey.currentState?.hideKeyboard();
                      },
                      controller: controller,
                      itemCount: tokens.length,
                      itemBuilder: (context, index) => ArtworkPreviewWidget(
                        identity: tokens[index],
                        onLoaded: setTimer,
                        focusNode: _focusNode,
                        useIndexer: widget.payload.useIndexer,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: !isFullScreen,
                  child: Container(
                    color: theme.colorScheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 15,
                        bottom: 30,
                        right: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Visibility(
                            visible: (assetToken?.medium == 'software' ||
                                assetToken?.medium == 'other' ||
                                (assetToken?.medium?.isEmpty ?? true)),
                            child: KeyboardManagerWidget(
                              key: keyboardManagerKey,
                              focusNode: _focusNode,
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          CastButton(
                            assetToken: assetToken,
                            onCastTap: () => onCastTap(assetToken),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          GestureDetector(
                            onTap: () => onClickFullScreen(assetToken),
                            child: Semantics(
                              label: "fullscreen_icon",
                              child: SvgPicture.asset(
                                'assets/images/fullscreen_icon.svg',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      listener: (context, state) {},
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

    return GestureDetector(
      onTap: onCastTap,
      child: Semantics(
        label: 'cast_icon',
        child: SvgPicture.asset(
          'assets/images/cast_icon.svg',
          color: canCast ? theme.colorScheme.secondary : theme.disableColor,
        ),
      ),
    );
  }
}

class KeyboardManagerWidget extends StatefulWidget {
  final FocusNode? focusNode;

  const KeyboardManagerWidget({Key? key, this.focusNode}) : super(key: key);

  @override
  State<KeyboardManagerWidget> createState() => KeyboardManagerWidgetState();
}

class KeyboardManagerWidgetState extends State<KeyboardManagerWidget> {
  bool _isShowKeyboard = false;

  @override
  void initState() {
    widget.focusNode?.addListener(() {
      if (widget.focusNode?.hasFocus ?? false) {
        setState(() {
          _isShowKeyboard = true;
        });
      } else {
        setState(() {
          _isShowKeyboard = false;
        });
      }
    });
    super.initState();
  }

  void showKeyboard() async {
    setState(() {
      widget.focusNode?.requestFocus();
      _isShowKeyboard = true;
    });
  }

  void hideKeyboard() async {
    setState(() {
      widget.focusNode?.unfocus();
      _isShowKeyboard = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isShowKeyboard ? hideKeyboard : showKeyboard,
      child: SvgPicture.asset('assets/images/keyboard_icon.svg'),
    );
  }
}
