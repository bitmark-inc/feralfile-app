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
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_rendering/nft_rendering.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shake/shake.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    final currentIdentity = tokens[initialPage];
    _bloc.add(ArtworkPreviewGetAssetTokenEvent(currentIdentity,
        useIndexer: widget.payload.useIndexer));
    super.initState();
  }

  setTimer({int? time}) {
    _timer?.cancel();
    if (playControl != null) {
      final defaultDuration =
          playControl!.timer == 0 ? time ?? 10 : playControl!.timer;
      _timer = Timer.periodic(Duration(seconds: defaultDuration), (timer) {
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
    WakelockPlus.disable();
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
    WakelockPlus.enable();
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    enableLandscapeMode();
    WakelockPlus.enable();
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

    WakelockPlus.disable();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        final hideArtist = assetToken?.isPostcard ?? false;
        final identityState = context.watch<IdentityBloc>().state;
        final artistName =
            assetToken?.artistName?.toIdentityOrMask(identityState.identityMap);
        var subTitle = "";
        if (artistName != null && artistName.isNotEmpty) {
          subTitle = artistName;
        }
        return Scaffold(
          appBar: isFullScreen
              ? null
              : AppBar(
                  systemOverlayStyle: systemUiOverlayDarkStyle,
                  backgroundColor: theme.colorScheme.primary,
                  leadingWidth: 0,
                  centerTitle: false,
                  title: GestureDetector(
                      onTap: () => _moveToInfo(assetToken),
                      child: ArtworkDetailsHeader(
                        title: assetToken?.title ?? '',
                        subTitle: subTitle,
                        hideArtist: hideArtist,
                      )),
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
                    itemBuilder: (context, index) {
                      if (tokens[index].id.isPostcardId) {
                        return PostcardPreviewWidget(
                          identity: tokens[index],
                          useIndexer: widget.payload.useIndexer,
                        );
                      }
                      return ArtworkPreviewWidget(
                        identity: tokens[index],
                        onLoaded: (
                            {InAppWebViewController? webViewController,
                            int? time}) {
                          setTimer(time: time);
                        },
                        focusNode: _focusNode,
                        useIndexer: widget.payload.useIndexer,
                      );
                    },
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
                          GestureDetector(
                            onTap: () => onClickFullScreen(assetToken),
                            child: Semantics(
                              label: "fullscreen_icon",
                              child: SvgPicture.asset(
                                'assets/images/fullscreen_icon.svg',
                                colorFilter: const ColorFilter.mode(
                                    AppColor.white, BlendMode.srcIn),
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
      listener: (context, state) {
        AssetToken? assetToken;
        if (state is ArtworkPreviewLoadedState) {
          assetToken = state.assetToken;
        }
        final identitiesList = [
          assetToken?.artistName ?? '',
        ];
        context.read<IdentityBloc>().add(GetIdentityEvent(identitiesList));
      },
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
