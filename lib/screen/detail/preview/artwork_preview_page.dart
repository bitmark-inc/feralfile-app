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
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/detail/preview/keyboard_control_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/canvas_device_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shake/shake.dart';
import 'package:wakelock/wakelock.dart';

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
  late CanvasDeviceBloc _canvasDeviceBloc;

  ShakeDetector? _detector;
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
    _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
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

  void _uncasting() {
    final canvasDeviceState = _canvasDeviceBloc.state;
    for (var e in canvasDeviceState.devices) {
      if (e.status == DeviceStatus.playing) {
        _canvasDeviceBloc.add(CanvasDeviceUncastingSingleEvent(e.device));
      }
    }
  }

  @override
  void dispose() {
    _uncasting();
    _focusNode.dispose();
    disableLandscapeMode();
    Wakelock.disable();
    _timer?.cancel();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _onCastTap(AssetToken? assetToken) async {
    keyboardManagerKey.currentState?.hideKeyboard();
    UIHelper.showFlexibleDialog(
      context,
      BlocProvider.value(
        value: _canvasDeviceBloc,
        child: CanvasDeviceView(
          sceneId: assetToken?.id ?? "",
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      isDismissible: true,
    );
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
                  child: BlocBuilder<CanvasDeviceBloc, CanvasDeviceState>(
                      builder: (context, state) {
                    final isCasting = state.isCasting;
                    final playingDevice = state.playingDevice;
                    return Container(
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
                                  (assetToken?.medium?.isEmpty ?? true) ||
                                  isCasting),
                              child: KeyboardManagerWidget(
                                key: keyboardManagerKey,
                                focusNode: _focusNode,
                                onTap: isCasting
                                    ? () {
                                        Navigator.of(context).pushNamed(
                                            AppRouter.keyboardControlPage,
                                            arguments:
                                                KeyboardControlPagePayload(
                                                    assetToken!,
                                                    playingDevice[0]));
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            CastButton(
                              assetToken: assetToken,
                              onCastTap: () => _onCastTap(assetToken),
                              isCasting: isCasting,
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: isCasting
                                  ? null
                                  : () => onClickFullScreen(assetToken),
                              child: Semantics(
                                label: "fullscreen_icon",
                                child: SvgPicture.asset(
                                  'assets/images/fullscreen_icon.svg',
                                  color: isCasting
                                      ? AppColor.disabledColor
                                      : AppColor.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
  final bool isCasting;

  const CastButton(
      {Key? key, this.assetToken, this.onCastTap, this.isCasting = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onCastTap,
      child: Semantics(
        label: 'cast_icon',
        child: SvgPicture.asset(
          'assets/images/cast_icon.svg',
          color: isCasting ? theme.auSuperTeal : theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

class KeyboardManagerWidget extends StatefulWidget {
  final FocusNode? focusNode;
  final Function()? onTap;

  const KeyboardManagerWidget({Key? key, this.focusNode, this.onTap})
      : super(key: key);

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
      onTap: () {
        _isShowKeyboard ? hideKeyboard : showKeyboard;
        widget.onTap?.call();
      },
      child: SvgPicture.asset('assets/images/keyboard_icon.svg'),
    );
  }
}
